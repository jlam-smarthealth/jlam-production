#!/bin/bash
# 🛡️ DevOps Standards Validation Script
# Comprehensive validation of DevOps best practices and enterprise standards

set -euo pipefail

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# ============================================
# UTILITY FUNCTIONS
# ============================================
print_header() {
    echo -e "${BOLD}${BLUE}================================${NC}"
    echo -e "${BOLD}${BLUE}$1${NC}"
    echo -e "${BOLD}${BLUE}================================${NC}"
}

print_section() {
    echo -e "\n${BOLD}${YELLOW}📋 $1${NC}"
    echo "----------------------------------------"
}

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
    ((WARNINGS++))
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# ============================================
# INFRASTRUCTURE AS CODE VALIDATION
# ============================================
validate_iac() {
    print_section "Infrastructure as Code Standards"
    
    # Terraform validation
    if [[ -d "terraform" ]]; then
        if command -v terraform >/dev/null 2>&1; then
            cd terraform
            if terraform fmt -check -recursive >/dev/null 2>&1; then
                pass "Terraform code properly formatted"
            else
                fail "Terraform code formatting issues"
            fi
            
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
    
    # Docker Compose validation
    if docker-compose config >/dev/null 2>&1; then
        pass "Docker Compose configuration valid"
    else
        fail "Docker Compose configuration invalid"
    fi
    
    # Monitoring stack validation
    if [[ -f "docker-compose.monitoring.yml" ]]; then
        if docker-compose -f docker-compose.monitoring.yml config >/dev/null 2>&1; then
            pass "Monitoring stack configuration valid"
        else
            fail "Monitoring stack configuration invalid"
        fi
    else
        warn "No monitoring stack configuration found"
    fi
}

# ============================================
# SECURITY STANDARDS VALIDATION
# ============================================
validate_security() {
    print_section "Security Standards"
    
    # Check for secrets in code
    if git log --all --full-history --grep="password\|secret\|key" --oneline 2>/dev/null | grep -v "test\|example" | head -5 | grep -q .; then
        fail "Potential secrets found in git history"
    else
        pass "No secrets detected in git history"
    fi
    
    # Check for .env file in gitignore
    if grep -q "\.env$" .gitignore 2>/dev/null; then
        pass ".env files excluded from git"
    else
        fail ".env files not excluded from git"
    fi
    
    # Check for SSL/TLS configuration
    if grep -r "tls.*true" --include="*.yml" . >/dev/null 2>&1; then
        pass "TLS configuration found"
    else
        warn "No explicit TLS configuration found"
    fi
    
    # Check for security headers
    if find . -name "*.yml" -exec grep -l "X-Frame-Options\|X-Content-Type-Options\|Strict-Transport-Security" {} \; 2>/dev/null | grep -q .; then
        pass "Security headers configured"
    else
        warn "Security headers not explicitly configured"
    fi
    
    # Check for non-root containers
    if grep -r "user:" --include="*.yml" . >/dev/null 2>&1; then
        pass "Non-root user configuration found"
    else
        warn "No explicit non-root user configuration"
    fi
}

# ============================================
# MONITORING AND OBSERVABILITY VALIDATION
# ============================================
validate_monitoring() {
    print_section "Monitoring & Observability"
    
    # Check for health checks
    if grep -r "healthcheck:" --include="*.yml" . >/dev/null 2>&1; then
        pass "Health checks configured"
    else
        fail "No health checks found"
    fi
    
    # Check for monitoring stack
    components=("prometheus" "grafana" "alertmanager")
    for component in "${components[@]}"; do
        if grep -r "$component" --include="*.yml" . >/dev/null 2>&1; then
            pass "$component monitoring component found"
        else
            warn "$component not configured"
        fi
    done
    
    # Validate Prometheus configuration
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
    fi
    
    # Check for alert rules
    if find monitoring -name "*.yml" -path "*/alerts/*" 2>/dev/null | grep -q .; then
        pass "Alert rules configured"
    else
        warn "No alert rules found"
    fi
}

# ============================================
# BACKUP AND RECOVERY VALIDATION
# ============================================
validate_backup() {
    print_section "Backup & Recovery"
    
    # Check for backup scripts
    if [[ -f "scripts/backup.sh" ]]; then
        pass "Backup script exists"
        
        # Validate backup script
        if bash -n scripts/backup.sh 2>/dev/null; then
            pass "Backup script syntax valid"
        else
            fail "Backup script has syntax errors"
        fi
        
        # Check for encryption in backup
        if grep -q "gpg\|encrypt" scripts/backup.sh; then
            pass "Backup encryption configured"
        else
            warn "Backup encryption not found"
        fi
        
        # Check for retention policy
        if grep -q "retention\|RETENTION" scripts/backup.sh; then
            pass "Backup retention policy configured"
        else
            warn "Backup retention policy not found"
        fi
    else
        fail "No backup script found"
    fi
    
    # Check for database backup procedures
    if grep -r "pg_dump\|mysqldump\|backup" scripts/ 2>/dev/null | grep -q .; then
        pass "Database backup procedures found"
    else
        warn "No database backup procedures found"
    fi
}

# ============================================
# CI/CD PIPELINE VALIDATION
# ============================================
validate_cicd() {
    print_section "CI/CD Pipeline"
    
    # Check for GitHub Actions
    if [[ -d ".github/workflows" ]]; then
        pass "GitHub Actions workflows directory exists"
        
        # Count workflow files
        workflow_count=$(find .github/workflows -name "*.yml" -o -name "*.yaml" | wc -l)
        if [[ $workflow_count -gt 0 ]]; then
            pass "$workflow_count workflow(s) configured"
        else
            warn "No workflow files found"
        fi
        
        # Check for quality gates
        if grep -r "test\|validate\|security" .github/workflows/ >/dev/null 2>&1; then
            pass "Quality gates configured in CI/CD"
        else
            warn "No quality gates found in workflows"
        fi
    else
        warn "No CI/CD workflows configured"
    fi
    
    # Check for environment separation
    if [[ -d "environments" ]] || grep -r "staging\|production" --include="*.yml" . >/dev/null 2>&1; then
        pass "Environment separation configured"
    else
        warn "No environment separation found"
    fi
}

# ============================================
# DOCUMENTATION STANDARDS VALIDATION
# ============================================
validate_documentation() {
    print_section "Documentation Standards"
    
    # Required documentation files
    required_docs=(
        "README.md"
        "docs/DEVOPS-INFRASTRUCTURE-REPORT.md"
        "docs/GITHUB-SECRETS-SETUP.md"
    )
    
    for doc in "${required_docs[@]}"; do
        if [[ -f "$doc" ]]; then
            pass "Required documentation exists: $doc"
            
            # Check documentation quality
            word_count=$(wc -w < "$doc" 2>/dev/null || echo 0)
            if [[ $word_count -gt 100 ]]; then
                pass "$doc has substantial content ($word_count words)"
            else
                warn "$doc appears minimal ($word_count words)"
            fi
        else
            fail "Missing required documentation: $doc"
        fi
    done
    
    # Check for inline documentation
    if grep -r "^#" --include="*.sh" --include="*.yml" . | wc -l | xargs test 50 -lt; then
        pass "Good inline documentation coverage"
    else
        warn "Limited inline documentation"
    fi
}

# ============================================
# PERFORMANCE AND SCALABILITY VALIDATION
# ============================================
validate_performance() {
    print_section "Performance & Scalability"
    
    # Check for resource limits
    if grep -r "mem_limit\|cpus\|memory" --include="*.yml" . >/dev/null 2>&1; then
        pass "Resource limits configured"
    else
        warn "No resource limits configured"
    fi
    
    # Check for restart policies
    if grep -r "restart:" --include="*.yml" . >/dev/null 2>&1; then
        pass "Restart policies configured"
    else
        warn "No restart policies configured"
    fi
    
    # Check for scaling configuration
    if grep -r "replicas\|scale" --include="*.yml" . >/dev/null 2>&1; then
        pass "Scaling configuration found"
    else
        info "No explicit scaling configuration (may use external orchestrator)"
    fi
}

# ============================================
# COMPLIANCE VALIDATION
# ============================================
validate_compliance() {
    print_section "Compliance & Standards"
    
    # Check for audit logging
    if grep -r "audit\|log" --include="*.yml" . >/dev/null 2>&1; then
        pass "Logging configuration found"
    else
        warn "No explicit logging configuration"
    fi
    
    # Check for data retention policies
    if grep -r "retention" scripts/ monitoring/ 2>/dev/null | grep -q .; then
        pass "Data retention policies configured"
    else
        warn "No data retention policies found"
    fi
    
    # Check for GDPR/healthcare compliance indicators
    if grep -ri "gdpr\|privacy\|healthcare\|patient" . >/dev/null 2>&1; then
        pass "Compliance awareness indicators found"
    else
        info "No explicit compliance indicators (may be handled elsewhere)"
    fi
}

# ============================================
# FINAL VALIDATION SUMMARY
# ============================================
generate_report() {
    print_header "🏆 VALIDATION SUMMARY"
    
    local total=$((PASSED + FAILED + WARNINGS))
    local score=$((PASSED * 100 / (PASSED + FAILED)))
    
    echo -e "\n📊 ${BOLD}Results:${NC}"
    echo -e "   ✅ Passed: ${GREEN}$PASSED${NC}"
    echo -e "   ❌ Failed: ${RED}$FAILED${NC}" 
    echo -e "   ⚠️  Warnings: ${YELLOW}$WARNINGS${NC}"
    echo -e "   📊 Total Checks: $total"
    echo -e "   🎯 Score: ${BOLD}$score%${NC}"
    
    echo -e "\n🎯 ${BOLD}DevOps Maturity Assessment:${NC}"
    if [[ $score -ge 95 && $FAILED -eq 0 ]]; then
        echo -e "   ${GREEN}🏆 ENTERPRISE GRADE${NC} - Exceeds industry standards"
    elif [[ $score -ge 80 && $FAILED -le 2 ]]; then
        echo -e "   ${GREEN}🥇 PRODUCTION READY${NC} - Meets enterprise standards"
    elif [[ $score -ge 60 && $FAILED -le 5 ]]; then
        echo -e "   ${YELLOW}🥈 GOOD PRACTICES${NC} - Solid foundation with room for improvement"
    else
        echo -e "   ${RED}🥉 NEEDS IMPROVEMENT${NC} - Address critical issues before production"
    fi
    
    echo -e "\n🚀 ${BOLD}Deployment Recommendation:${NC}"
    if [[ $FAILED -eq 0 ]]; then
        echo -e "   ${GREEN}✅ APPROVED${NC} - Ready for production deployment"
        return 0
    elif [[ $FAILED -le 2 ]]; then
        echo -e "   ${YELLOW}⚠️  CONDITIONAL${NC} - Address critical issues first"
        return 1
    else
        echo -e "   ${RED}❌ BLOCKED${NC} - Too many critical issues for production"
        return 2
    fi
}

# ============================================
# MAIN EXECUTION
# ============================================
main() {
    print_header "🛡️ JLAM DevOps Standards Validation"
    
    echo -e "${BOLD}Target:${NC} Enterprise-grade DevOps practices"
    echo -e "${BOLD}Standard:${NC} Production-ready infrastructure validation"
    echo -e "${BOLD}Scope:${NC} JLAM Healthcare Platform"
    echo ""
    
    # Execute all validation categories
    validate_iac
    validate_security
    validate_monitoring
    validate_backup
    validate_cicd
    validate_documentation
    validate_performance
    validate_compliance
    
    # Generate final report
    if generate_report; then
        exit 0
    else
        exit $?
    fi
}

# Execute main function
main "$@"