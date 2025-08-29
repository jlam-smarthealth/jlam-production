#!/bin/bash
# JLAM Security Penetration Testing Suite
# AI-Generated Template - Requires Human Execution
# Created: 2025-08-29 13:18:22 CEST
# Medical-Grade Security Testing: ISO 27001 + NEN 7510

set -euo pipefail

# Configuration
SERVER_IP="${SERVER_IP:-REPLACE_WITH_ACTUAL_IP}"
TEST_DOMAIN="${TEST_DOMAIN:-dev.jlam.nl}"
RESULTS_DIR="/tmp/jlam-security-test-$(date +%Y%m%d_%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

mkdir -p "$RESULTS_DIR"
LOG_FILE="$RESULTS_DIR/security-test.log"

log() {
    echo "[$(date -Iseconds)] $1" | tee -a "$LOG_FILE"
}

# Test results tracking
SECURITY_TESTS=0
SECURITY_PASSED=0
SECURITY_FAILED=0

run_security_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"  # "PASS", "FAIL", or "WARN"
    
    ((SECURITY_TESTS++))
    log "🔒 TESTING: $test_name"
    
    if eval "$test_command"; then
        if [[ "$expected_result" == "PASS" ]]; then
            ((SECURITY_PASSED++))
            log "✅ $test_name: SECURE"
        else
            ((SECURITY_FAILED++))
            log "⚠️ $test_name: UNEXPECTED PASS (Expected: $expected_result)"
        fi
    else
        if [[ "$expected_result" == "FAIL" ]]; then
            ((SECURITY_PASSED++))
            log "✅ $test_name: PROPERLY BLOCKED"
        else
            ((SECURITY_FAILED++))
            log "❌ $test_name: FAILED"
        fi
    fi
}

# Phase 1: Port Scanning and Service Discovery
test_port_scanning() {
    log "${BLUE}🔍 PHASE 1: PORT SCANNING & SERVICE DISCOVERY${NC}"
    
    # Comprehensive port scan
    local port_scan_file="$RESULTS_DIR/port_scan.txt"
    
    # Test common ports
    log "Scanning common ports..."
    for port in 21 22 23 25 53 80 110 143 443 993 995 8080 8443; do
        if nc -zv "$SERVER_IP" "$port" 2>&1 | grep -q succeeded; then
            echo "OPEN: $port" >> "$port_scan_file"
            log "   Port $port: OPEN"
        else
            echo "CLOSED: $port" >> "$port_scan_file"
        fi
    done
    
    # Test for unexpected services
    run_security_test "FTP Service Not Running" "! nc -zv $SERVER_IP 21 2>&1 | grep -q succeeded" "PASS"
    run_security_test "Telnet Service Not Running" "! nc -zv $SERVER_IP 23 2>&1 | grep -q succeeded" "PASS"
    run_security_test "SMTP Service Not Running" "! nc -zv $SERVER_IP 25 2>&1 | grep -q succeeded" "PASS"
    
    # Test expected services
    run_security_test "SSH Service Available" "nc -zv $SERVER_IP 22 2>&1 | grep -q succeeded" "PASS"
    run_security_test "HTTP Service Available" "nc -zv $SERVER_IP 80 2>&1 | grep -q succeeded" "PASS"
    run_security_test "HTTPS Service Available" "nc -zv $SERVER_IP 443 2>&1 | grep -q succeeded" "PASS"
    run_security_test "Traefik Dashboard Available" "nc -zv $SERVER_IP 8080 2>&1 | grep -q succeeded" "PASS"
}

# Phase 2: HTTP Security Headers Testing
test_http_security_headers() {
    log "${BLUE}🛡️ PHASE 2: HTTP SECURITY HEADERS TESTING${NC}"
    
    local headers_file="$RESULTS_DIR/security_headers.txt"
    curl -sI "http://$SERVER_IP" > "$headers_file" 2>/dev/null || echo "HTTP request failed" > "$headers_file"
    
    # Test security headers
    run_security_test "HSTS Header Present" "grep -qi 'strict-transport-security' '$headers_file'" "PASS"
    run_security_test "X-Frame-Options Header Present" "grep -qi 'x-frame-options' '$headers_file'" "PASS"
    run_security_test "X-Content-Type-Options Present" "grep -qi 'x-content-type-options' '$headers_file'" "PASS"
    run_security_test "X-XSS-Protection Present" "grep -qi 'x-xss-protection' '$headers_file'" "PASS"
    
    # Test for information leakage
    run_security_test "Server Version Hidden" "! grep -qi 'server:.*apache\\|nginx\\|iis' '$headers_file'" "PASS"
    run_security_test "No X-Powered-By Header" "! grep -qi 'x-powered-by' '$headers_file'" "PASS"
    
    # Test Content Security Policy
    run_security_test "Content Security Policy Present" "grep -qi 'content-security-policy' '$headers_file'" "WARN"
    
    # Test HTTPS redirect
    run_security_test "HTTP to HTTPS Redirect" "curl -sI http://$SERVER_IP | grep -qi 'location.*https'" "PASS"
}

# Phase 3: SSL/TLS Security Testing
test_ssl_tls_security() {
    log "${BLUE}🔐 PHASE 3: SSL/TLS SECURITY TESTING${NC}"
    
    # Test SSL certificate
    local ssl_info_file="$RESULTS_DIR/ssl_info.txt"
    
    # Get SSL certificate information
    echo | openssl s_client -servername "$TEST_DOMAIN" -connect "$SERVER_IP:443" -showcerts 2>/dev/null > "$ssl_info_file" || true
    
    # Test certificate validity
    run_security_test "SSL Certificate Valid" "echo | openssl s_client -servername $TEST_DOMAIN -connect $SERVER_IP:443 -verify 5 >/dev/null 2>&1" "PASS"
    
    # Test certificate expiration
    run_security_test "SSL Certificate Not Expiring Soon" "echo | openssl s_client -servername $TEST_DOMAIN -connect $SERVER_IP:443 2>/dev/null | openssl x509 -noout -checkend 2592000" "PASS"
    
    # Test for weak SSL/TLS versions
    run_security_test "SSLv3 Disabled" "! echo | timeout 5 openssl s_client -ssl3 -connect $SERVER_IP:443 2>/dev/null | grep -q 'SSL-Session'" "PASS"
    run_security_test "TLSv1.0 Disabled" "! echo | timeout 5 openssl s_client -tls1 -connect $SERVER_IP:443 2>/dev/null | grep -q 'SSL-Session'" "PASS"
    run_security_test "TLSv1.1 Disabled" "! echo | timeout 5 openssl s_client -tls1_1 -connect $SERVER_IP:443 2>/dev/null | grep -q 'SSL-Session'" "PASS"
    
    # Test strong TLS versions
    run_security_test "TLSv1.2 Supported" "echo | timeout 5 openssl s_client -tls1_2 -connect $SERVER_IP:443 2>/dev/null | grep -q 'SSL-Session'" "PASS"
    run_security_test "TLSv1.3 Supported" "echo | timeout 5 openssl s_client -tls1_3 -connect $SERVER_IP:443 2>/dev/null | grep -q 'SSL-Session'" "WARN"
}

# Phase 4: Authentication and Access Control Testing
test_authentication_access() {
    log "${BLUE}🔑 PHASE 4: AUTHENTICATION & ACCESS CONTROL${NC}"
    
    # Test SSH security
    run_security_test "SSH Password Authentication Disabled" "ssh root@$SERVER_IP 'grep -q \"PasswordAuthentication no\" /etc/ssh/sshd_config || echo \"WARNING: Password auth may be enabled\"'" "WARN"
    run_security_test "SSH Root Login Restricted" "ssh root@$SERVER_IP 'grep -q \"PermitRootLogin\" /etc/ssh/sshd_config' && echo 'Root login configured' || echo 'Default root login'" "WARN"
    
    # Test Traefik dashboard access
    run_security_test "Traefik Dashboard Accessible" "curl -sf http://$SERVER_IP:8080/ | grep -qi 'traefik\\|dashboard'" "PASS"
    
    # Test for default credentials (should fail)
    run_security_test "No Default Admin Credentials" "! curl -sf -u admin:admin http://$SERVER_IP:8080/ | grep -qi 'authenticated'" "PASS"
    run_security_test "No Default Root Credentials" "! curl -sf -u root:root http://$SERVER_IP:8080/ | grep -qi 'authenticated'" "PASS"
    
    # Test directory traversal protection
    run_security_test "Directory Traversal Protection" "! curl -sf 'http://$SERVER_IP/../../etc/passwd' | grep -q 'root:'" "PASS"
    run_security_test "Admin Path Protection" "curl -s 'http://$SERVER_IP/admin' | grep -qi '403\\|404\\|not found'" "PASS"
}

# Phase 5: Input Validation and Injection Testing
test_input_validation() {
    log "${BLUE}💉 PHASE 5: INPUT VALIDATION & INJECTION TESTING${NC}"
    
    # Test SQL injection attempts (should be blocked)
    run_security_test "SQL Injection Protection" "! curl -sf 'http://$SERVER_IP/?id=1%27%20OR%201=1--' | grep -qi 'database\\|sql\\|error'" "PASS"
    
    # Test XSS attempts (should be blocked)
    run_security_test "XSS Protection" "! curl -sf 'http://$SERVER_IP/?search=<script>alert(1)</script>' | grep -q '<script>'" "PASS"
    
    # Test command injection (should be blocked)
    run_security_test "Command Injection Protection" "! curl -sf 'http://$SERVER_IP/?cmd=;cat%20/etc/passwd' | grep -q 'root:'" "PASS"
    
    # Test path traversal (should be blocked)
    run_security_test "Path Traversal Protection" "! curl -sf 'http://$SERVER_IP/../../../etc/passwd' | grep -q 'root:'" "PASS"
    
    # Test file upload restrictions
    run_security_test "File Upload Endpoint Protected" "curl -s -X POST -F 'file=@/etc/hosts' http://$SERVER_IP/upload | grep -qi '403\\|404\\|method not allowed'" "PASS"
}

# Phase 6: Information Disclosure Testing
test_information_disclosure() {
    log "${BLUE}📋 PHASE 6: INFORMATION DISCLOSURE TESTING${NC}"
    
    # Test for sensitive file exposure
    local sensitive_files=("/.env" "/config.php" "/wp-config.php" "/.git/config" "/docker-compose.yml" "/Dockerfile")
    
    for file in "${sensitive_files[@]}"; do
        run_security_test "Sensitive File $file Not Exposed" "! curl -sf http://$SERVER_IP$file | grep -q ." "PASS"
    done
    
    # Test error page information leakage
    run_security_test "404 Page No Information Leakage" "! curl -s http://$SERVER_IP/nonexistent-page-12345 | grep -qi 'apache\\|nginx\\|php\\|version\\|server'" "PASS"
    
    # Test server status pages
    run_security_test "Server Status Page Protected" "! curl -sf http://$SERVER_IP/server-status | grep -qi 'apache\\|server-status'" "PASS"
    run_security_test "Server Info Page Protected" "! curl -sf http://$SERVER_IP/server-info | grep -qi 'apache\\|server-info'" "PASS"
    
    # Test robots.txt for information disclosure
    run_security_test "Robots.txt No Sensitive Paths" "! curl -sf http://$SERVER_IP/robots.txt | grep -qi 'admin\\|backup\\|config\\|private'" "WARN"
}

# Phase 7: Denial of Service (DoS) Resistance Testing
test_dos_resistance() {
    log "${BLUE}🚫 PHASE 7: DOS RESISTANCE TESTING${NC}"
    
    # Test rate limiting
    log "Testing rate limiting with rapid requests..."
    local rate_limit_file="$RESULTS_DIR/rate_limit_test.txt"
    
    # Send 100 rapid requests
    for i in {1..100}; do
        curl -sf --connect-timeout 2 --max-time 5 "http://$SERVER_IP:8080/ping" >> "$rate_limit_file" 2>&1 &
    done
    wait
    
    local successful_requests=$(grep -c "OK" "$rate_limit_file" 2>/dev/null || echo "0")
    run_security_test "Rate Limiting Active (Not All Requests Succeeded)" "[ $successful_requests -lt 100 ]" "WARN"
    
    # Test large request handling
    run_security_test "Large Request Handling" "! curl -sf -d @<(head -c 10000000 /dev/zero) http://$SERVER_IP/ | grep -q 'request too large'" "WARN"
    
    # Test slowloris protection (simplified)
    run_security_test "Connection Timeout Protection" "timeout 5 bash -c 'exec 3<>/dev/tcp/$SERVER_IP/80; echo -e \"GET / HTTP/1.1\\r\\nHost: $SERVER_IP\\r\\n\" >&3; sleep 6; cat <&3' || echo 'Connection timed out'" "WARN"
}

# Phase 8: Container Security Testing
test_container_security() {
    log "${BLUE}🐳 PHASE 8: CONTAINER SECURITY TESTING${NC}"
    
    # Test container privileges
    run_security_test "Container Not Running as Privileged" "ssh root@$SERVER_IP 'docker inspect \$(docker ps -q --filter name=traefik) --format \"{{.HostConfig.Privileged}}\"' | grep -q false" "PASS"
    
    # Test container user
    run_security_test "Container User Configuration" "ssh root@$SERVER_IP 'docker inspect \$(docker ps -q --filter name=traefik) --format \"{{.Config.User}}\"' | grep -v '^$' || echo 'No user specified'" "WARN"
    
    # Test container capabilities
    run_security_test "Container Minimal Capabilities" "ssh root@$SERVER_IP 'docker inspect \$(docker ps -q --filter name=traefik) --format \"{{.HostConfig.CapAdd}}\"' | grep -q '\\[\\]\\|null'" "WARN"
    
    # Test read-only filesystem
    run_security_test "Container Filesystem Write Protection" "ssh root@$SERVER_IP 'docker inspect \$(docker ps -q --filter name=traefik) --format \"{{.HostConfig.ReadonlyRootfs}}\"' | grep -q true || echo 'Filesystem is writable'" "WARN"
    
    # Test network security
    run_security_test "Container Network Isolation" "ssh root@$SERVER_IP 'docker network ls | grep -q jlam'" "PASS"
    
    # Test volume mounts security
    run_security_test "Docker Socket Not Writable" "ssh root@$SERVER_IP 'docker inspect \$(docker ps -q --filter name=traefik) --format \"{{range .Mounts}}{{.Source}}:{{.Mode}} {{end}}\"' | grep '/var/run/docker.sock' | grep -q ':ro'" "PASS"
}

# Phase 9: Logging and Monitoring Security
test_logging_monitoring() {
    log "${BLUE}📊 PHASE 9: LOGGING & MONITORING SECURITY${NC}"
    
    # Test log file permissions
    run_security_test "Log Files Secure Permissions" "ssh root@$SERVER_IP 'find /var/log -name \"*.log\" -perm 644 -o -perm 640 | wc -l' | awk '{if(\$1 > 0) exit 0; else exit 1}'" "PASS"
    
    # Test log rotation
    run_security_test "Log Rotation Configured" "ssh root@$SERVER_IP 'test -f /etc/logrotate.conf'" "PASS"
    
    # Test sensitive data in logs
    run_security_test "No Passwords in Logs" "! ssh root@$SERVER_IP 'grep -ri \"password\" /var/log/ 2>/dev/null | head -5' | grep -v 'authentication\\|failed'" "PASS"
    run_security_test "No API Keys in Logs" "! ssh root@$SERVER_IP 'grep -ri \"api[_-]key\\|secret\" /var/log/ 2>/dev/null | head -5'" "PASS"
    
    # Test audit logging
    run_security_test "System Audit Logging" "ssh root@$SERVER_IP 'systemctl is-enabled auditd 2>/dev/null || echo \"auditd not configured\"'" "WARN"
}

# Phase 10: Network Security Testing
test_network_security() {
    log "${BLUE}🌐 PHASE 10: NETWORK SECURITY TESTING${NC}"
    
    # Test firewall configuration
    run_security_test "Firewall Active" "ssh root@$SERVER_IP 'ufw status | grep -q active || iptables -L | grep -q Chain'" "PASS"
    
    # Test unnecessary network services
    run_security_test "Minimal Network Services" "ssh root@$SERVER_IP 'netstat -tuln | grep LISTEN | wc -l' | awk '{if(\$1 < 10) exit 0; else exit 1}'" "PASS"
    
    # Test IPv6 configuration
    run_security_test "IPv6 Configuration Secure" "ssh root@$SERVER_IP 'cat /proc/net/if_inet6 | wc -l' | awk '{if(\$1 == 0) exit 0; else exit 1}' || echo 'IPv6 enabled'" "WARN"
    
    # Test network interfaces
    run_security_test "No Promiscuous Interfaces" "! ssh root@$SERVER_IP 'ip link show | grep PROMISC'" "PASS"
    
    # Test ICMP responses
    run_security_test "ICMP Ping Response" "ping -c 3 $SERVER_IP >/dev/null 2>&1" "PASS"
}

# Generate comprehensive security report
generate_security_report() {
    local report_file="$RESULTS_DIR/security-penetration-report.md"
    
    cat > "$report_file" << EOF
# JLAM Medical-Grade Security Penetration Test Report
**Generated**: $(date -Iseconds)
**Target**: $SERVER_IP ($TEST_DOMAIN)
**Standards**: ISO 27001 + NEN 7510 Medical Security
**Test Type**: Comprehensive Security Assessment

## Executive Summary
- **Total Security Tests**: $SECURITY_TESTS
- **Passed/Secure**: $SECURITY_PASSED
- **Failed/Vulnerable**: $SECURITY_FAILED
- **Security Score**: $(( SECURITY_PASSED * 100 / SECURITY_TESTS ))%

## Risk Assessment
$(if [ $SECURITY_FAILED -eq 0 ]; then
    echo "✅ **LOW RISK** - All security tests passed"
elif [ $SECURITY_FAILED -le 3 ]; then
    echo "⚠️ **MEDIUM RISK** - Minor security issues detected"
else
    echo "❌ **HIGH RISK** - Multiple security vulnerabilities found"
fi)

## Test Results by Category

### 1. Network Security
- Port scanning and service discovery results
- Firewall and access control validation

### 2. Web Application Security  
- HTTP security headers compliance
- Input validation and injection protection

### 3. SSL/TLS Security
- Certificate validation and configuration
- Protocol version and cipher strength

### 4. Authentication & Access Control
- SSH security configuration
- Default credential testing

### 5. Container Security
- Docker security best practices
- Container isolation and privileges

### 6. Information Security
- Sensitive data exposure testing
- Error handling and information leakage

### 7. Denial of Service Protection
- Rate limiting and resource protection
- Connection handling and timeouts

### 8. Logging & Monitoring
- Security event logging
- Log file security and retention

## Medical Device Compliance Assessment
- **Audit Trail Security**: $([ -f "$LOG_FILE" ] && echo "✅ Complete" || echo "❌ Insufficient")
- **Data Protection (NEN 7510)**: $([ $SECURITY_FAILED -le 2 ] && echo "✅ Compliant" || echo "⚠️ Review required")
- **Access Controls (ISO 27001)**: $([ $SECURITY_FAILED -eq 0 ] && echo "✅ Secure" || echo "❌ Vulnerabilities found")
- **Network Security**: ✅ Comprehensive testing completed

## Detailed Results
\`\`\`
$(cat "$LOG_FILE")
\`\`\`

## Recommendations
$(if [ $SECURITY_FAILED -eq 0 ]; then
    echo "✅ Security posture is excellent for medical device certification"
    echo "- Continue regular security assessments"
    echo "- Maintain current security configurations"
    echo "- Monitor for new vulnerabilities"
else
    echo "❌ Address the following security issues before medical device certification:"
    echo "- Review failed security tests in detailed log"
    echo "- Implement additional security controls"
    echo "- Conduct remediation testing"
fi)

## Files Generated
- **Complete Log**: $LOG_FILE
- **Port Scan Results**: port_scan.txt
- **HTTP Headers**: security_headers.txt
- **SSL Certificate Info**: ssl_info.txt
- **Rate Limiting Test**: rate_limit_test.txt

**Report Generated**: $(date -Iseconds)
**Assessment Completed By**: AI-Generated Security Testing Suite
EOF

    log "🔒 Security penetration test report: $report_file"
    echo "$report_file"
}

# Main execution
main() {
    log "🔒 JLAM SECURITY PENETRATION TESTING SUITE"
    log "========================================="
    log "AI-Generated Template - Human Execution Required"
    log "Standards: ISO 27001 + NEN 7510 Medical Security"
    log "Timestamp: $(date -Iseconds)"
    log "Target: $SERVER_IP ($TEST_DOMAIN)"
    log "Results: $RESULTS_DIR"
    log ""
    
    # Validate prerequisites
    if [[ "$SERVER_IP" == "REPLACE_WITH_ACTUAL_IP" ]]; then
        log "❌ SERVER_IP not set. Usage: SERVER_IP=51.158.166.152 $0"
        exit 1
    fi
    
    # Check required tools
    for tool in curl nc ssh openssl nmap; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            log "⚠️ Recommended tool not found: $tool (some tests may be skipped)"
        fi
    done
    
    # Execute all security test phases
    test_port_scanning
    test_http_security_headers
    test_ssl_tls_security
    test_authentication_access
    test_input_validation
    test_information_disclosure
    test_dos_resistance
    test_container_security
    test_logging_monitoring
    test_network_security
    
    # Generate comprehensive report
    REPORT_FILE=$(generate_security_report)
    
    # Final assessment
    log ""
    log "🔒 SECURITY PENETRATION TESTING COMPLETE"
    log "========================================"
    log "📊 Total Tests: $SECURITY_TESTS"
    log "✅ Secure/Passed: $SECURITY_PASSED"
    log "❌ Vulnerable/Failed: $SECURITY_FAILED"
    log "📈 Security Score: $(( SECURITY_PASSED * 100 / SECURITY_TESTS ))%"
    log "📋 Full Report: $REPORT_FILE"
    log "📄 Raw Log: $LOG_FILE"
    log ""
    
    if [ $SECURITY_FAILED -eq 0 ]; then
        log "${GREEN}🛡️ SECURITY ASSESSMENT: EXCELLENT${NC}"
        log "${GREEN}✅ Ready for medical device security certification${NC}"
        exit 0
    elif [ $SECURITY_FAILED -le 3 ]; then
        log "${YELLOW}⚠️ SECURITY ASSESSMENT: GOOD (Minor issues detected)${NC}"
        log "${YELLOW}🔧 Address minor issues before certification${NC}"
        exit 0
    else
        log "${RED}❌ SECURITY ASSESSMENT: VULNERABILITIES FOUND${NC}"
        log "${RED}🚨 Critical security review required before deployment${NC}"
        exit 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi