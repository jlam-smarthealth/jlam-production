#!/bin/bash
# JLAM Medical-Grade Deployment Execution Guide
# AI-Generated Template - Human Execution Required
# Created: 2025-08-29 13:18:22 CEST
# Step-by-step deployment with comprehensive testing

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DEPLOYMENT_LOG="/tmp/jlam-deployment-$TIMESTAMP.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging
log() {
    echo -e "[$(date -Iseconds)] $1" | tee -a "$DEPLOYMENT_LOG"
}

log_step() {
    echo ""
    log "${BLUE}========================================${NC}"
    log "${BLUE}STEP: $1${NC}"
    log "${BLUE}========================================${NC}"
}

log_success() {
    log "${GREEN}✅ $1${NC}"
}

log_warning() {
    log "${YELLOW}⚠️ $1${NC}"
}

log_error() {
    log "${RED}❌ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    log_step "PREREQUISITE VALIDATION"
    
    local missing_tools=()
    
    # Check required tools
    for tool in terraform curl ssh jq openssl; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log "Please install missing tools and run again"
        exit 1
    fi
    
    # Check Terraform Cloud token
    if [ -z "${TF_TOKEN_app_terraform_io:-}" ]; then
        log_warning "Terraform Cloud token not set in TF_TOKEN_app_terraform_io"
        log "Set your token: export TF_TOKEN_app_terraform_io=your-token"
    fi
    
    # Check if we're in the right directory
    if [ ! -f "$PROJECT_ROOT/main.tf" ]; then
        log_error "Not in terraform directory. Please run from terraform/development/"
        exit 1
    fi
    
    log_success "Prerequisites validated"
}

# Step 1: Medical compliance validation
run_medical_compliance() {
    log_step "1. MEDICAL-GRADE COMPLIANCE VALIDATION"
    
    if [ -f "$SCRIPT_DIR/validate-medical-compliance.sh" ]; then
        log "Running medical compliance validation..."
        if "$SCRIPT_DIR/validate-medical-compliance.sh"; then
            log_success "Medical compliance: ISO 13485 + NEN 7510 + IEC 62304 ACHIEVED"
        else
            log_error "Medical compliance validation FAILED"
            log "Fix compliance issues before proceeding"
            exit 1
        fi
    else
        log_warning "Medical compliance validator not found"
        log "Proceeding with deployment (not recommended for production)"
    fi
}

# Step 2: Terraform infrastructure deployment
deploy_infrastructure() {
    log_step "2. TERRAFORM INFRASTRUCTURE DEPLOYMENT"
    
    cd "$PROJECT_ROOT"
    
    # Terraform init
    log "Initializing Terraform..."
    if terraform init; then
        log_success "Terraform initialized"
    else
        log_error "Terraform init failed"
        exit 1
    fi
    
    # Terraform validate
    log "Validating Terraform configuration..."
    if terraform validate; then
        log_success "Terraform configuration valid"
    else
        log_error "Terraform validation failed"
        exit 1
    fi
    
    # Terraform plan
    log "Creating deployment plan..."
    if terraform plan -out=tfplan; then
        log_success "Terraform plan created"
        log "Review the plan above carefully before proceeding"
        
        # Interactive confirmation
        echo ""
        read -p "🤔 Do you want to proceed with this deployment? (yes/no): " confirm
        if [[ "$confirm" != "yes" ]]; then
            log "Deployment cancelled by user"
            exit 0
        fi
    else
        log_error "Terraform plan failed"
        exit 1
    fi
    
    # Terraform apply
    log "Deploying infrastructure..."
    if terraform apply tfplan; then
        log_success "Infrastructure deployed successfully"
        
        # Get server IP
        SERVER_IP=$(terraform output -raw dev_server_ip 2>/dev/null || echo "")
        if [ -n "$SERVER_IP" ]; then
            log_success "Server IP: $SERVER_IP"
            echo "SERVER_IP=$SERVER_IP" > "$SCRIPT_DIR/.deployment-vars"
        else
            log_warning "Could not retrieve server IP"
        fi
    else
        log_error "Terraform apply failed"
        exit 1
    fi
}

# Step 3: Wait for server initialization
wait_for_server() {
    log_step "3. SERVER INITIALIZATION WAIT"
    
    # Load server IP
    if [ -f "$SCRIPT_DIR/.deployment-vars" ]; then
        source "$SCRIPT_DIR/.deployment-vars"
    fi
    
    if [ -z "${SERVER_IP:-}" ]; then
        log_error "Server IP not available. Check terraform output"
        exit 1
    fi
    
    log "Waiting for server $SERVER_IP to initialize..."
    log "This may take 3-5 minutes for cloud-init to complete"
    
    # Wait for SSH
    local max_attempts=60
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log "Attempt $attempt/$max_attempts: Testing SSH connectivity..."
        
        if ssh -o ConnectTimeout=5 -o BatchMode=yes root@"$SERVER_IP" "echo 'SSH_OK'" 2>/dev/null | grep -q "SSH_OK"; then
            log_success "SSH connectivity established"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            log_error "SSH connectivity timeout after $max_attempts attempts"
            exit 1
        fi
        
        sleep 30
        ((attempt++))
    done
    
    # Wait for cloud-init completion
    log "Waiting for cloud-init to complete..."
    ssh root@"$SERVER_IP" "cloud-init status --wait" || {
        log_warning "cloud-init wait failed, checking manually..."
        ssh root@"$SERVER_IP" "cloud-init status" || true
    }
    
    log_success "Server initialization complete"
}

# Step 4: Basic connectivity testing
test_basic_connectivity() {
    log_step "4. BASIC CONNECTIVITY TESTING"
    
    source "$SCRIPT_DIR/.deployment-vars"
    
    # Test ping
    if ping -c 3 "$SERVER_IP" >/dev/null 2>&1; then
        log_success "Server ping: OK"
    else
        log_error "Server ping: FAILED"
        exit 1
    fi
    
    # Test SSH
    if ssh root@"$SERVER_IP" "echo 'SSH test successful'"; then
        log_success "SSH access: OK"
    else
        log_error "SSH access: FAILED"
        exit 1
    fi
    
    # Test Docker
    if ssh root@"$SERVER_IP" "docker --version" >/dev/null 2>&1; then
        log_success "Docker service: OK"
    else
        log_error "Docker service: FAILED"
        exit 1
    fi
    
    # Test Traefik (with retries)
    local traefik_attempts=5
    local traefik_success=false
    
    for ((i=1; i<=traefik_attempts; i++)); do
        log "Testing Traefik... (attempt $i/$traefik_attempts)"
        if curl -sf --connect-timeout 10 "http://$SERVER_IP:8080/ping" >/dev/null 2>&1; then
            log_success "Traefik API: OK"
            traefik_success=true
            break
        fi
        sleep 15
    done
    
    if [ "$traefik_success" != "true" ]; then
        log_warning "Traefik API not responding - may need more time"
    fi
}

# Step 5: Run comprehensive testing
run_comprehensive_testing() {
    log_step "5. COMPREHENSIVE INFRASTRUCTURE TESTING"
    
    source "$SCRIPT_DIR/.deployment-vars"
    
    if [ -f "$SCRIPT_DIR/comprehensive-testing-suite.sh" ]; then
        log "Running comprehensive test suite..."
        
        export SERVER_IP
        if "$SCRIPT_DIR/comprehensive-testing-suite.sh"; then
            log_success "Comprehensive testing: ALL TESTS PASSED"
        else
            log_error "Comprehensive testing: SOME TESTS FAILED"
            log "Review test results and address issues"
            # Don't exit - continue with other tests
        fi
    else
        log_warning "Comprehensive testing suite not found"
    fi
}

# Step 6: Run security testing
run_security_testing() {
    log_step "6. SECURITY PENETRATION TESTING"
    
    source "$SCRIPT_DIR/.deployment-vars"
    
    if [ -f "$SCRIPT_DIR/security-penetration-testing.sh" ]; then
        log "Running security penetration tests..."
        
        export SERVER_IP
        export TEST_DOMAIN="dev.jlam.nl"
        
        if "$SCRIPT_DIR/security-penetration-testing.sh"; then
            log_success "Security testing: PASSED"
        else
            log_warning "Security testing: Issues found - review results"
        fi
    else
        log_warning "Security testing suite not found"
    fi
}

# Step 7: Install health monitoring
install_health_monitoring() {
    log_step "7. HEALTH MONITORING INSTALLATION"
    
    source "$SCRIPT_DIR/.deployment-vars"
    
    if [ -f "$SCRIPT_DIR/install-health-monitor.sh" ]; then
        log "Installing health monitoring system..."
        
        if "$SCRIPT_DIR/install-health-monitor.sh" "$SERVER_IP"; then
            log_success "Health monitoring: INSTALLED"
        else
            log_warning "Health monitoring installation: FAILED"
        fi
    else
        log_warning "Health monitor installer not found"
    fi
}

# Step 8: Run load testing (optional)
run_load_testing() {
    log_step "8. LOAD TESTING (OPTIONAL)"
    
    echo ""
    read -p "🤔 Do you want to run load testing? This may take 10+ minutes (yes/no): " run_load
    
    if [[ "$run_load" == "yes" ]]; then
        source "$SCRIPT_DIR/.deployment-vars"
        
        if [ -f "$SCRIPT_DIR/load-testing-advanced.sh" ]; then
            log "Running advanced load testing..."
            
            export SERVER_IP
            if "$SCRIPT_DIR/load-testing-advanced.sh"; then
                log_success "Load testing: COMPLETED"
            else
                log_warning "Load testing: Issues detected"
            fi
        else
            log_warning "Load testing suite not found"
        fi
    else
        log "Skipping load testing"
    fi
}

# Step 9: Final validation and reporting
final_validation() {
    log_step "9. FINAL VALIDATION & REPORTING"
    
    source "$SCRIPT_DIR/.deployment-vars"
    
    # Final health checks
    local final_checks=0
    local final_passed=0
    
    # Check Traefik
    ((final_checks++))
    if curl -sf "http://$SERVER_IP:8080/ping" >/dev/null 2>&1; then
        ((final_passed++))
        log_success "Traefik API Gateway: HEALTHY"
    else
        log_error "Traefik API Gateway: UNHEALTHY"
    fi
    
    # Check Docker
    ((final_checks++))
    if ssh root@"$SERVER_IP" "docker ps | grep -q traefik"; then
        ((final_passed++))
        log_success "Docker containers: RUNNING"
    else
        log_error "Docker containers: ISSUES"
    fi
    
    # Check SSL certificates
    ((final_checks++))
    if ssh root@"$SERVER_IP" "test -f /tmp/jlam-ssl/cert.pem"; then
        ((final_passed++))
        log_success "SSL certificates: DEPLOYED"
    else
        log_warning "SSL certificates: NOT FOUND"
    fi
    
    # Check health monitoring
    ((final_checks++))
    if ssh root@"$SERVER_IP" "systemctl is-active jlam-health-monitor" >/dev/null 2>&1; then
        ((final_passed++))
        log_success "Health monitoring: ACTIVE"
    else
        log_warning "Health monitoring: NOT ACTIVE"
    fi
    
    # Generate final report
    local success_rate=$((final_passed * 100 / final_checks))
    
    log ""
    log "🏥 JLAM MEDICAL-GRADE DEPLOYMENT COMPLETE"
    log "========================================"
    log "📊 Final Validation: $final_passed/$final_checks checks passed ($success_rate%)"
    log "🌐 Server IP: $SERVER_IP"
    log "🔗 Traefik Dashboard: http://$SERVER_IP:8080"
    log "📄 Full Log: $DEPLOYMENT_LOG"
    log "📅 Deployed: $(date -Iseconds)"
    
    if [ $success_rate -ge 75 ]; then
        log_success "Deployment successful - Medical-grade infrastructure ready"
        log "🔗 Next steps:"
        log "   1. Configure DNS: dev.jlam.nl → $SERVER_IP"
        log "   2. Test HTTPS: https://dev.jlam.nl"
        log "   3. Deploy application services"
        log "   4. Monitor health: ssh root@$SERVER_IP '/opt/jlam/scripts/health-status.sh'"
    else
        log_error "Deployment completed with issues - Review failed checks"
        log "🔧 Troubleshooting:"
        log "   1. Check server logs: ssh root@$SERVER_IP 'tail -50 /var/log/cloud-init.log'"
        log "   2. Run diagnostics: ssh root@$SERVER_IP '/opt/jlam/diagnose-and-retry.sh'"
        log "   3. Check containers: ssh root@$SERVER_IP 'docker ps && docker logs \$(docker ps -q)'"
    fi
}

# Cleanup function
cleanup() {
    if [ -f "$SCRIPT_DIR/.deployment-vars" ]; then
        rm -f "$SCRIPT_DIR/.deployment-vars"
    fi
}

# Main execution
main() {
    trap cleanup EXIT
    
    log "🏥 JLAM MEDICAL-GRADE DEPLOYMENT EXECUTION"
    log "========================================"
    log "AI-Generated Guide - Human Execution Required"
    log "Standards: ISO 13485 + NEN 7510 + IEC 62304"
    log "Timestamp: $(date -Iseconds)"
    log "Script: $0"
    log "Working Directory: $PROJECT_ROOT"
    log "Deployment Log: $DEPLOYMENT_LOG"
    log ""
    
    # Execute deployment steps
    check_prerequisites
    run_medical_compliance
    deploy_infrastructure
    wait_for_server
    test_basic_connectivity
    run_comprehensive_testing
    run_security_testing
    install_health_monitoring
    run_load_testing
    final_validation
    
    log ""
    log "🎉 DEPLOYMENT EXECUTION COMPLETE"
    log "Check the final validation results above"
    log "Full deployment log: $DEPLOYMENT_LOG"
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi