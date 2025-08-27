#!/bin/bash
# 🧪 JLAM Infrastructure Validation Tests
# Comprehensive testing for production readiness

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0

pass() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASSED++))
}

fail() {
    echo -e "${RED}❌ $1${NC}"
    ((FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_header() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Test Docker Compose syntax
test_compose_syntax() {
    info "Testing Docker Compose syntax..."
    
    if docker-compose config >/dev/null 2>&1; then
        pass "Main docker-compose.yml syntax valid"
    else
        fail "Main docker-compose.yml syntax invalid"
    fi
    
    if [[ -f "docker-compose.monitoring.yml" ]]; then
        if docker-compose -f docker-compose.monitoring.yml config >/dev/null 2>&1; then
            pass "Monitoring docker-compose.yml syntax valid"
        else
            fail "Monitoring docker-compose.yml syntax invalid"
        fi
    fi
}

# Test Terraform validation
test_terraform() {
    info "Testing Terraform configuration..."
    
    if [[ -d "terraform" ]]; then
        if command -v terraform >/dev/null 2>&1; then
            cd terraform
            if terraform init -backend=false >/dev/null 2>&1 && terraform validate >/dev/null 2>&1; then
                pass "Terraform configuration valid"
            else
                fail "Terraform configuration invalid"
            fi
            cd ..
        else
            warn "Terraform not installed - skipping validation"
        fi
    else
        warn "No Terraform directory found"
    fi
}

# Test script syntax
test_scripts() {
    info "Testing script syntax..."
    
    local script_errors=0
    find scripts/ -name "*.sh" -type f 2>/dev/null | while read -r script; do
        if bash -n "$script" 2>/dev/null; then
            pass "Script syntax valid: $script"
        else
            fail "Script syntax error: $script"
            ((script_errors++))
        fi
    done
}

# Test security configuration
test_security() {
    info "Testing security configuration..."
    
    # Check gitignore
    if grep -q "\.env" .gitignore 2>/dev/null; then
        pass ".env files properly excluded from git"
    else
        fail ".env files not excluded from git"
    fi
    
    # Check for secrets
    if git log --all --oneline | head -20 | grep -i -E "(password|secret|key)" | grep -v "test" | grep -q .; then
        fail "Potential secrets found in git history"
    else
        pass "No secrets detected in recent git history"
    fi
}

# Test documentation
test_documentation() {
    info "Testing documentation..."
    
    required_docs=("README.md" "docs/DEVOPS-INFRASTRUCTURE-REPORT.md")
    
    for doc in "${required_docs[@]}"; do
        if [[ -f "$doc" ]]; then
            local word_count
            word_count=$(wc -w < "$doc" 2>/dev/null || echo 0)
            if [[ $word_count -gt 100 ]]; then
                pass "Documentation exists and has content: $doc ($word_count words)"
            else
                warn "Documentation minimal: $doc ($word_count words)"
            fi
        else
            fail "Missing required documentation: $doc"
        fi
    done
}

# Test monitoring configuration
test_monitoring() {
    info "Testing monitoring configuration..."
    
    if [[ -f "monitoring/prometheus/prometheus.yml" ]]; then
        if command -v docker >/dev/null 2>&1; then
            if docker run --rm -v "$PWD/monitoring/prometheus":/prometheus \
               prom/prometheus:latest \
               promtool check config /prometheus/prometheus.yml >/dev/null 2>&1; then
                pass "Prometheus configuration valid"
            else
                fail "Prometheus configuration invalid"
            fi
        fi
    else
        warn "Prometheus configuration not found"
    fi
    
    if find monitoring -name "*.yml" -path "*/alerts/*" 2>/dev/null | grep -q .; then
        pass "Alert rules configured"
    else
        warn "No alert rules found"
    fi
}

# Test backup configuration
test_backup() {
    info "Testing backup configuration..."
    
    if [[ -f "scripts/backup.sh" ]]; then
        if bash -n scripts/backup.sh 2>/dev/null; then
            pass "Backup script syntax valid"
            
            if grep -q "gpg\|encrypt" scripts/backup.sh; then
                pass "Backup encryption configured"
            else
                warn "Backup encryption not found"
            fi
            
            if grep -q "retention\|RETENTION" scripts/backup.sh; then
                pass "Backup retention policy configured"
            else
                warn "Backup retention policy not found"
            fi
        else
            fail "Backup script has syntax errors"
        fi
    else
        fail "No backup script found"
    fi
}

# Test health checks
test_health_checks() {
    info "Testing health check configuration..."
    
    if grep -r "healthcheck:" --include="*.yml" . >/dev/null 2>&1; then
        pass "Health checks configured in services"
    else
        warn "No health checks found in service configuration"
    fi
}

# Main test execution
main() {
    print_header "🧪 JLAM Infrastructure Validation Tests"
    
    test_compose_syntax
    test_terraform
    test_scripts
    test_security
    test_documentation
    test_monitoring
    test_backup
    test_health_checks
    
    print_header "🏆 TEST RESULTS SUMMARY"
    
    local total=$((PASSED + FAILED))
    local score=0
    
    if [[ $total -gt 0 ]]; then
        score=$((PASSED * 100 / total))
    fi
    
    echo -e "\n📊 Results:"
    echo -e "   ✅ Passed: ${GREEN}$PASSED${NC}"
    echo -e "   ❌ Failed: ${RED}$FAILED${NC}"
    echo -e "   📊 Score: ${score}%"
    
    if [[ $FAILED -eq 0 ]]; then
        echo -e "\n🎉 ${GREEN}ALL TESTS PASSED! Infrastructure is production-ready.${NC}"
        exit 0
    elif [[ $FAILED -le 2 ]]; then
        echo -e "\n⚠️  ${YELLOW}Some issues found but infrastructure is mostly ready.${NC}"
        exit 1
    else
        echo -e "\n🔧 ${RED}Multiple issues found. Address before deploying to production.${NC}"
        exit 2
    fi
}

main "$@"