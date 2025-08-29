#!/bin/bash
# JLAM Medical-Grade Health Monitor Installation
# Deploys progressive health monitoring system to server
# ISO 13485 + NEN 7510 + IEC 62304 Compliance
# Created: 2025-08-29

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HEALTH_MONITOR_SCRIPT="$SCRIPT_DIR/health-monitor.sh"
SERVER_USER="${SERVER_USER:-root}"
SERVER_IP="${SERVER_IP:-}"

# Colors for reporting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Usage information
usage() {
    echo "Usage: $0 <server_ip>"
    echo ""
    echo "Install JLAM Medical-Grade Health Monitor on server"
    echo ""
    echo "Arguments:"
    echo "  server_ip    IP address of the JLAM server"
    echo ""
    echo "Environment Variables:"
    echo "  SERVER_USER  SSH username (default: root)"
    echo ""
    echo "Examples:"
    echo "  $0 51.158.166.152"
    echo "  SERVER_USER=ubuntu $0 51.158.166.152"
    exit 1
}

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date -Iseconds)
    
    case "$level" in
        "ERROR")
            echo -e "${RED}[$timestamp] [ERROR] $message${NC}" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}[$timestamp] [WARN] $message${NC}"
            ;;
        "INFO")
            echo -e "${GREEN}[$timestamp] [INFO] $message${NC}"
            ;;
        "DEBUG")
            echo -e "${BLUE}[$timestamp] [DEBUG] $message${NC}"
            ;;
    esac
}

# Validate prerequisites
validate_prerequisites() {
    log "INFO" "🏥 JLAM Medical-Grade Health Monitor Installation"
    log "INFO" "Standards: ISO 13485 + NEN 7510 + IEC 62304"
    
    # Check if server IP provided
    if [ -z "$SERVER_IP" ]; then
        log "ERROR" "Server IP address required"
        usage
    fi
    
    # Check if health monitor script exists
    if [ ! -f "$HEALTH_MONITOR_SCRIPT" ]; then
        log "ERROR" "Health monitor script not found: $HEALTH_MONITOR_SCRIPT"
        exit 1
    fi
    
    # Check if script is executable
    if [ ! -x "$HEALTH_MONITOR_SCRIPT" ]; then
        log "ERROR" "Health monitor script not executable"
        exit 1
    fi
    
    # Test SSH connectivity
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$SERVER_USER@$SERVER_IP" "echo 'SSH connectivity test'" >/dev/null 2>&1; then
        log "ERROR" "Cannot connect to $SERVER_USER@$SERVER_IP via SSH"
        log "ERROR" "Ensure SSH key authentication is set up"
        exit 1
    fi
    
    log "INFO" "✅ Prerequisites validated"
}

# Install health monitor on server
install_health_monitor() {
    log "INFO" "📦 Installing health monitor on $SERVER_IP"
    
    # Create directory structure
    ssh "$SERVER_USER@$SERVER_IP" "mkdir -p /opt/jlam/scripts /var/log"
    
    # Copy health monitor script
    scp "$HEALTH_MONITOR_SCRIPT" "$SERVER_USER@$SERVER_IP:/opt/jlam/scripts/"
    
    # Make script executable on server
    ssh "$SERVER_USER@$SERVER_IP" "chmod +x /opt/jlam/scripts/health-monitor.sh"
    
    # Create systemd service for continuous monitoring
    ssh "$SERVER_USER@$SERVER_IP" "cat > /etc/systemd/system/jlam-health-monitor.service << 'EOF'
[Unit]
Description=JLAM Medical-Grade Health Monitor
Documentation=https://github.com/jlam-platform/infrastructure
After=network.target docker.service
Wants=docker.service

[Service]
Type=simple
User=root
Group=root
ExecStart=/opt/jlam/scripts/health-monitor.sh
Restart=always
RestartSec=30
StandardOutput=journal
StandardError=journal
SyslogIdentifier=jlam-health-monitor

# Medical-grade service hardening
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/var/log /opt/jlam
PrivateTmp=yes

# Environment
Environment=MONITOR_INTERVAL=180
Environment=MAX_FAILURES=3

[Install]
WantedBy=multi-user.target
EOF"
    
    # Enable and start service
    ssh "$SERVER_USER@$SERVER_IP" "
        systemctl daemon-reload
        systemctl enable jlam-health-monitor.service
        systemctl start jlam-health-monitor.service
    "
    
    log "INFO" "✅ Health monitor service installed and started"
}

# Verify installation
verify_installation() {
    log "INFO" "🔍 Verifying health monitor installation"
    
    # Check service status
    if ssh "$SERVER_USER@$SERVER_IP" "systemctl is-active jlam-health-monitor.service" >/dev/null 2>&1; then
        log "INFO" "✅ Health monitor service is active"
    else
        log "ERROR" "❌ Health monitor service is not active"
        return 1
    fi
    
    # Check if monitoring is working
    sleep 5
    
    if ssh "$SERVER_USER@$SERVER_IP" "test -f /var/log/jlam-health-monitor.log"; then
        log "INFO" "✅ Health monitor logging is active"
        
        # Show recent log entries
        log "INFO" "📋 Recent health monitor activity:"
        ssh "$SERVER_USER@$SERVER_IP" "tail -5 /var/log/jlam-health-monitor.log" | sed 's/^/    /'
    else
        log "WARN" "⚠️ Health monitor logs not yet available"
    fi
    
    # Show service status
    log "INFO" "📊 Service status:"
    ssh "$SERVER_USER@$SERVER_IP" "systemctl status jlam-health-monitor.service --no-pager -l" | sed 's/^/    /'
    
    log "INFO" "✅ Installation verification complete"
}

# Create management commands
create_management_commands() {
    log "INFO" "🛠️ Creating management commands"
    
    # Create health status command
    ssh "$SERVER_USER@$SERVER_IP" "cat > /opt/jlam/scripts/health-status.sh << 'EOF'
#!/bin/bash
# JLAM Health Monitor Status Check
echo \"🏥 JLAM Medical-Grade Health Monitor Status\"
echo \"===========================================\"
echo \"Service Status: \$(systemctl is-active jlam-health-monitor.service)\"
echo \"\"
if [ -f /var/log/jlam-health-status.json ]; then
    echo \"Current Health Status:\"
    cat /var/log/jlam-health-status.json | jq . 2>/dev/null || cat /var/log/jlam-health-status.json
else
    echo \"Health status not yet available\"
fi
echo \"\"
echo \"Recent Activity:\"
tail -10 /var/log/jlam-health-monitor.log 2>/dev/null || echo \"No logs available yet\"
EOF"
    
    # Create log viewer command
    ssh "$SERVER_USER@$SERVER_IP" "cat > /opt/jlam/scripts/health-logs.sh << 'EOF'
#!/bin/bash
# JLAM Health Monitor Log Viewer
LINES=\${1:-50}
echo \"🏥 JLAM Health Monitor - Last \$LINES log entries\"
echo \"=============================================\"
tail -\$LINES /var/log/jlam-health-monitor.log 2>/dev/null || echo \"No logs available\"
EOF"
    
    # Make commands executable
    ssh "$SERVER_USER@$SERVER_IP" "
        chmod +x /opt/jlam/scripts/health-status.sh
        chmod +x /opt/jlam/scripts/health-logs.sh
    "
    
    log "INFO" "✅ Management commands created:"
    log "INFO" "   - /opt/jlam/scripts/health-status.sh"
    log "INFO" "   - /opt/jlam/scripts/health-logs.sh [lines]"
}

# Display success information
show_success_info() {
    log "INFO" "🎉 JLAM Medical-Grade Health Monitor Successfully Installed!"
    log "INFO" ""
    log "INFO" "📋 Medical Device Compliance: ISO 13485 + NEN 7510 + IEC 62304"
    log "INFO" "🔍 Monitoring Interval: 3 minutes"
    log "INFO" "📊 Health Checks: 7 comprehensive validations"
    log "INFO" "🚨 Escalation: Progressive failure handling"
    log "INFO" ""
    log "INFO" "📱 Management Commands (on server):"
    log "INFO" "   • Check Status: /opt/jlam/scripts/health-status.sh"
    log "INFO" "   • View Logs: /opt/jlam/scripts/health-logs.sh [lines]"
    log "INFO" "   • Service Control: systemctl {start|stop|restart} jlam-health-monitor"
    log "INFO" ""
    log "INFO" "📂 Log Files:"
    log "INFO" "   • Health Monitor: /var/log/jlam-health-monitor.log"
    log "INFO" "   • Health Alerts: /var/log/jlam-health-alerts.log"
    log "INFO" "   • Status JSON: /var/log/jlam-health-status.json"
    log "INFO" ""
    log "INFO" "🔗 Next Steps:"
    log "INFO" "   1. Monitor service: ssh $SERVER_USER@$SERVER_IP '/opt/jlam/scripts/health-status.sh'"
    log "INFO" "   2. Check logs: ssh $SERVER_USER@$SERVER_IP '/opt/jlam/scripts/health-logs.sh'"
    log "INFO" "   3. Verify continuous operation over next 15 minutes"
    log "INFO" ""
    log "INFO" "✅ Medical-grade progressive health monitoring active!"
}

# Main installation process
main() {
    # Parse command line arguments
    if [ $# -eq 0 ]; then
        usage
    fi
    
    SERVER_IP="$1"
    
    # Execute installation steps
    validate_prerequisites
    install_health_monitor
    verify_installation
    create_management_commands
    show_success_info
}

# Execute if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi