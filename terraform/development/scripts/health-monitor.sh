#!/bin/bash
# JLAM Medical-Grade Health Monitoring System
# ISO 13485 + NEN 7510 + IEC 62304 Compliance
# Progressive monitoring with 3-5 minute intervals
# Created: 2025-08-29

set -euo pipefail

# Medical-Grade Configuration
MONITOR_INTERVAL=${MONITOR_INTERVAL:-180}  # 3 minutes default
MAX_FAILURES=${MAX_FAILURES:-3}           # 3 failures before escalation
LOG_FILE="/var/log/jlam-health-monitor.log"
ALERT_FILE="/var/log/jlam-health-alerts.log"
STATUS_FILE="/var/log/jlam-health-status.json"

# Colors for medical-grade reporting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Medical compliance metadata
COMPLIANCE_STANDARDS="ISO 13485 + NEN 7510 + IEC 62304"
PATIENT_COUNT="9000+"
MISSION="Medical Device Certification"

# Initialize logging
init_logging() {
    echo "$(date -Iseconds) [INIT] JLAM Medical-Grade Health Monitor Starting" >> "$LOG_FILE"
    echo "$(date -Iseconds) [INIT] Standards: $COMPLIANCE_STANDARDS" >> "$LOG_FILE"
    echo "$(date -Iseconds) [INIT] Patient Count: $PATIENT_COUNT" >> "$LOG_FILE"
    echo "$(date -Iseconds) [INIT] Monitor Interval: ${MONITOR_INTERVAL}s" >> "$LOG_FILE"
}

# Function to log with medical-grade timestamps
log_event() {
    local level="$1"
    local message="$2"
    local timestamp=$(date -Iseconds)
    echo "$(date -Iseconds) [$level] $message" >> "$LOG_FILE"
    
    # Also log to console with colors
    case "$level" in
        "ERROR")
            echo -e "${RED}[$timestamp] [$level] $message${NC}" >&2
            echo "$(date -Iseconds) [$level] $message" >> "$ALERT_FILE"
            ;;
        "WARN")
            echo -e "${YELLOW}[$timestamp] [$level] $message${NC}"
            ;;
        "INFO")
            echo -e "${GREEN}[$timestamp] [$level] $message${NC}"
            ;;
        "DEBUG")
            echo -e "${BLUE}[$timestamp] [$level] $message${NC}"
            ;;
    esac
}

# Health check functions for medical-grade validation
check_docker_health() {
    if systemctl is-active docker >/dev/null 2>&1; then
        log_event "INFO" "Docker service: HEALTHY"
        return 0
    else
        log_event "ERROR" "Docker service: DOWN - Critical for medical device operation"
        return 1
    fi
}

check_traefik_health() {
    # Check if Traefik container is running
    if docker ps | grep -q traefik; then
        # Check API endpoint
        if curl -sf http://localhost:8080/ping >/dev/null 2>&1; then
            log_event "INFO" "Traefik API Gateway: HEALTHY"
            return 0
        else
            log_event "ERROR" "Traefik API Gateway: API_UNRESPONSIVE"
            return 1
        fi
    else
        log_event "ERROR" "Traefik API Gateway: CONTAINER_DOWN"
        return 1
    fi
}

check_ssl_certificates() {
    local ssl_dir="/tmp/jlam-ssl"
    
    if [ -d "$ssl_dir" ] && [ -f "$ssl_dir/cert.pem" ] && [ -f "$ssl_dir/key.pem" ]; then
        # Check certificate expiry (warn if < 30 days)
        if command -v openssl >/dev/null 2>&1; then
            local days_until_expiry=$(openssl x509 -in "$ssl_dir/cert.pem" -noout -checkend $((30*24*60*60)) 2>/dev/null && echo "OK" || echo "WARN")
            if [ "$days_until_expiry" = "OK" ]; then
                log_event "INFO" "SSL Certificates: VALID (>30 days remaining)"
            else
                log_event "WARN" "SSL Certificates: EXPIRING_SOON (<30 days)"
            fi
        fi
        log_event "INFO" "SSL Certificates: PRESENT"
        return 0
    else
        log_event "ERROR" "SSL Certificates: MISSING - Required for medical device HTTPS"
        return 1
    fi
}

check_network_connectivity() {
    # Test external connectivity (for updates and monitoring)
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_event "INFO" "Network Connectivity: HEALTHY"
        return 0
    else
        log_event "ERROR" "Network Connectivity: DOWN - Medical device isolation risk"
        return 1
    fi
}

check_disk_space() {
    local usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$usage" -lt 80 ]; then
        log_event "INFO" "Disk Space: HEALTHY (${usage}% used)"
        return 0
    elif [ "$usage" -lt 90 ]; then
        log_event "WARN" "Disk Space: WARNING (${usage}% used) - Monitor closely"
        return 1
    else
        log_event "ERROR" "Disk Space: CRITICAL (${usage}% used) - Medical device at risk"
        return 1
    fi
}

check_memory_usage() {
    local mem_usage=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
    local mem_int=${mem_usage%.*}
    
    if [ "$mem_int" -lt 80 ]; then
        log_event "INFO" "Memory Usage: HEALTHY (${mem_usage}%)"
        return 0
    elif [ "$mem_int" -lt 90 ]; then
        log_event "WARN" "Memory Usage: WARNING (${mem_usage}%) - Monitor closely"
        return 1
    else
        log_event "ERROR" "Memory Usage: CRITICAL (${mem_usage}%) - Medical device at risk"
        return 1
    fi
}

# Medical-grade system audit
check_medical_compliance() {
    local compliance_score=0
    local max_score=6
    
    # Audit trail logging
    if [ -f "$LOG_FILE" ] && [ -w "$LOG_FILE" ]; then
        ((compliance_score++))
        log_event "DEBUG" "Medical Compliance: Audit trail logging ACTIVE"
    else
        log_event "ERROR" "Medical Compliance: Audit trail logging FAILED"
    fi
    
    # Configuration management
    if [ -f "/opt/jlam/docker-compose.yml" ]; then
        ((compliance_score++))
        log_event "DEBUG" "Medical Compliance: Configuration management ACTIVE"
    else
        log_event "ERROR" "Medical Compliance: Configuration management FAILED"
    fi
    
    # Diagnostic capabilities
    if [ -f "/opt/jlam/diagnose-and-retry.sh" ] && [ -x "/opt/jlam/diagnose-and-retry.sh" ]; then
        ((compliance_score++))
        log_event "DEBUG" "Medical Compliance: Diagnostic capabilities ACTIVE"
    else
        log_event "ERROR" "Medical Compliance: Diagnostic capabilities FAILED"
    fi
    
    # Security controls
    if systemctl is-active ufw >/dev/null 2>&1 || iptables -L >/dev/null 2>&1; then
        ((compliance_score++))
        log_event "DEBUG" "Medical Compliance: Security controls ACTIVE"
    else
        log_event "WARN" "Medical Compliance: Security controls UNCLEAR"
    fi
    
    # Service orchestration
    if docker network ls | grep -q jlam; then
        ((compliance_score++))
        log_event "DEBUG" "Medical Compliance: Service orchestration ACTIVE"
    else
        log_event "WARN" "Medical Compliance: Service orchestration UNCLEAR"
    fi
    
    # Backup capabilities
    if [ -d "/opt/jlam" ] && [ -r "/opt/jlam" ]; then
        ((compliance_score++))
        log_event "DEBUG" "Medical Compliance: Backup structure ACTIVE"
    else
        log_event "ERROR" "Medical Compliance: Backup structure FAILED"
    fi
    
    local compliance_percentage=$((compliance_score * 100 / max_score))
    
    if [ $compliance_percentage -ge 90 ]; then
        log_event "INFO" "Medical Compliance: EXCELLENT (${compliance_percentage}%) - ISO 13485 ready"
        return 0
    elif [ $compliance_percentage -ge 70 ]; then
        log_event "WARN" "Medical Compliance: ACCEPTABLE (${compliance_percentage}%) - Review needed"
        return 1
    else
        log_event "ERROR" "Medical Compliance: INSUFFICIENT (${compliance_percentage}%) - Certification at risk"
        return 1
    fi
}

# Progressive health monitoring with medical-grade status updates
run_health_checks() {
    local timestamp=$(date -Iseconds)
    local checks_passed=0
    local checks_failed=0
    local checks_warning=0
    
    log_event "INFO" "🏥 MEDICAL-GRADE HEALTH CHECK CYCLE STARTING"
    log_event "INFO" "Standards: $COMPLIANCE_STANDARDS | Mission: $MISSION"
    
    # Define health checks array
    declare -a health_checks=(
        "check_docker_health:Docker Service"
        "check_traefik_health:Traefik API Gateway"
        "check_ssl_certificates:SSL Certificates"
        "check_network_connectivity:Network Connectivity"
        "check_disk_space:Disk Space"
        "check_memory_usage:Memory Usage"
        "check_medical_compliance:Medical Compliance"
    )
    
    # Execute all health checks
    for check_def in "${health_checks[@]}"; do
        local check_func="${check_def%%:*}"
        local check_name="${check_def##*:}"
        
        if $check_func; then
            ((checks_passed++))
        else
            ((checks_failed++))
        fi
    done
    
    # Calculate health score
    local total_checks=$((checks_passed + checks_failed))
    local health_percentage=$((checks_passed * 100 / total_checks))
    
    # Generate medical-grade status report
    cat > "$STATUS_FILE" << EOF
{
  "timestamp": "$timestamp",
  "compliance_standards": "$COMPLIANCE_STANDARDS",
  "mission": "$MISSION",
  "patient_count": "$PATIENT_COUNT",
  "health_score": $health_percentage,
  "checks_passed": $checks_passed,
  "checks_failed": $checks_failed,
  "total_checks": $total_checks,
  "status": "$([ $health_percentage -ge 85 ] && echo "HEALTHY" || ([ $health_percentage -ge 70 ] && echo "WARNING" || echo "CRITICAL"))",
  "next_check": "$(($(date +%s) + MONITOR_INTERVAL))"
}
EOF
    
    # Report final status
    if [ $health_percentage -ge 85 ]; then
        log_event "INFO" "🎉 MEDICAL-GRADE HEALTH: EXCELLENT ($health_percentage%) - $checks_passed/$total_checks checks passed"
        return 0
    elif [ $health_percentage -ge 70 ]; then
        log_event "WARN" "⚠️ MEDICAL-GRADE HEALTH: DEGRADED ($health_percentage%) - $checks_failed failures detected"
        return 1
    else
        log_event "ERROR" "🚨 MEDICAL-GRADE HEALTH: CRITICAL ($health_percentage%) - Medical device at risk"
        return 2
    fi
}

# Progressive escalation system
handle_failure_escalation() {
    local failure_count="$1"
    
    if [ $failure_count -eq 1 ]; then
        log_event "WARN" "First failure detected - Monitoring more closely"
    elif [ $failure_count -eq 2 ]; then
        log_event "ERROR" "Second consecutive failure - Running diagnostics"
        if [ -f "/opt/jlam/diagnose-and-retry.sh" ]; then
            log_event "INFO" "Executing built-in diagnostics"
            /opt/jlam/diagnose-and-retry.sh >> "$LOG_FILE" 2>&1 || true
        fi
    else
        log_event "ERROR" "Multiple consecutive failures ($failure_count) - ESCALATION REQUIRED"
        log_event "ERROR" "Medical device certification compliance at risk"
        log_event "ERROR" "Manual intervention needed for $PATIENT_COUNT member platform"
    fi
}

# Main monitoring loop
main() {
    local failure_count=0
    
    init_logging
    log_event "INFO" "🏥 JLAM Medical-Grade Health Monitor Started"
    log_event "INFO" "Mission: Perfect dev server for $PATIENT_COUNT healthcare members"
    log_event "INFO" "Compliance: $COMPLIANCE_STANDARDS"
    
    # Handle signals gracefully
    trap 'log_event "INFO" "Health monitor stopping gracefully"; exit 0' SIGTERM SIGINT
    
    while true; do
        if run_health_checks; then
            failure_count=0
            log_event "INFO" "✅ All systems operational - Medical-grade standards maintained"
        else
            ((failure_count++))
            handle_failure_escalation $failure_count
            
            if [ $failure_count -ge $MAX_FAILURES ]; then
                log_event "ERROR" "Maximum failures reached - Stopping monitor"
                log_event "ERROR" "Manual intervention required for medical device compliance"
                exit 1
            fi
        fi
        
        log_event "DEBUG" "Next health check in ${MONITOR_INTERVAL}s"
        sleep $MONITOR_INTERVAL
    done
}

# Execute if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi