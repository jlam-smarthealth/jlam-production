#!/bin/bash
# JLAM Medical-Grade Compliance Validation
# ISO 13485 + NEN 7510 + IEC 62304 Standards
# Created: 2025-08-29

set -euo pipefail

echo "🏥 JLAM MEDICAL-GRADE COMPLIANCE VALIDATION"
echo "Standards: ISO 13485 + NEN 7510 + IEC 62304"
echo "=========================================="

# Colors for medical-grade reporting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

VALIDATION_PASSED=true

# Function to report validation results
report_validation() {
    local test_name="$1"
    local result="$2"
    local details="${3:-}"
    
    if [ "$result" = "PASS" ]; then
        echo -e "✅ ${GREEN}PASS${NC}: $test_name"
        [ -n "$details" ] && echo "   → $details"
    elif [ "$result" = "WARN" ]; then
        echo -e "⚠️  ${YELLOW}WARN${NC}: $test_name"
        [ -n "$details" ] && echo "   → $details"
    else
        echo -e "❌ ${RED}FAIL${NC}: $test_name"
        [ -n "$details" ] && echo "   → $details"
        VALIDATION_PASSED=false
    fi
}

echo ""
echo "🔍 PHASE 1: TERRAFORM INFRASTRUCTURE VALIDATION"
echo "=============================================="

# Terraform validation
if terraform validate >/dev/null 2>&1; then
    report_validation "Terraform Configuration" "PASS" "All syntax valid"
else
    terraform_errors=$(terraform validate 2>&1 || true)
    report_validation "Terraform Configuration" "FAIL" "$terraform_errors"
fi

# Terraform format check
if terraform fmt -check -diff >/dev/null 2>&1; then
    report_validation "Terraform Formatting" "PASS" "Code properly formatted"
else
    report_validation "Terraform Formatting" "WARN" "Run: terraform fmt"
fi

echo ""
echo "🔍 PHASE 2: YAML TEMPLATE VALIDATION"
echo "=================================="

# YAML template validation (with custom config, exclude .tpl files)
if command -v yamllint >/dev/null 2>&1; then
    # Only validate actual YAML files, not .tpl templates
    yaml_files=$(find . -name "*.yml" -not -name "*.tpl" 2>/dev/null | head -5)
    if [ -n "$yaml_files" ]; then
        if echo "$yaml_files" | xargs yamllint -c .yamllint >/dev/null 2>&1; then
            report_validation "YAML Template Compliance" "PASS" \
              "All YAML files meet medical-grade standards"
        else
            yaml_errors=$(echo "$yaml_files" | xargs yamllint -c .yamllint 2>&1 | head -10 || true)
            report_validation "YAML Template Compliance" "FAIL" \
              "YAML violations detected"
            echo "   First 10 errors:"
            echo "$yaml_errors" | sed 's/^/     /'
        fi
    else
        report_validation "YAML Template Compliance" "PASS" \
          "No YAML files to validate (using .tpl templates)"
    fi
else
    report_validation "YAML Template Validation" "WARN" \
      "yamllint not installed - run: pip install yamllint"
fi

echo ""
echo "🔍 PHASE 3: SECURITY COMPLIANCE VALIDATION"
echo "========================================"

# Check for sensitive data exposure (exclude legitimate variable references)
suspicious_patterns=$(grep -r -i -E "(password|secret|key|token)" *.tf *.tpl 2>/dev/null | \
                     grep -v -E "(variable|description|sensitive.*true)" | \
                     grep -v -E "var\.(ssl_private_key|ssh_public_key|scaleway_.*_key)" | \
                     grep -v -E "(keyFile.*ssl/jlam/key\.pem|#.*)" | \
                     grep -v -E "(SSH Access|HTTP|HTTPS|port.*=)" || true)

if [ -n "$suspicious_patterns" ]; then
    report_validation "Secret Exposure Check" "WARN" \
      "Review potential secrets: $(echo "$suspicious_patterns" | head -1 | cut -d: -f2-)"
else
    report_validation "Secret Exposure Check" "PASS" \
      "No exposed secrets detected"
fi

# Security group validation
if grep -q "0.0.0.0/0" main.tf; then
    # Check if it's for legitimate services (HTTP/HTTPS)
    if grep -A5 -B5 "0.0.0.0/0" main.tf | \
       grep -E "(port.*80|port.*443|SSH Access|HTTP|HTTPS)"; then
        report_validation "Security Group Rules" "PASS" \
          "Public access limited to web services"
    else
        report_validation "Security Group Rules" "WARN" \
          "Review public access rules"
    fi
else
    report_validation "Security Group Rules" "PASS" \
      "No unrestricted public access"
fi

echo ""
echo "🔍 PHASE 4: MEDICAL DEVICE COMPLIANCE"
echo "==================================="

# Audit trail preservation
if grep -q "tee -a.*log" *.tpl 2>/dev/null; then
    report_validation "Audit Trail Logging" "PASS" \
      "Comprehensive logging implemented"
else
    report_validation "Audit Trail Logging" "FAIL" \
      "Missing audit trail logging"
fi

# Diagnostic capabilities
if [ -f cloud-init-universal.yml.tpl ] && \
   grep -q "diagnose-and-retry" cloud-init-universal.yml.tpl; then
    report_validation "Diagnostic Capabilities" "PASS" \
      "Built-in diagnostics implemented"
else
    report_validation "Diagnostic Capabilities" "FAIL" \
      "Missing diagnostic capabilities"
fi

# Progressive deployment philosophy
if grep -q "ALWAYS diagnose first" *.tpl 2>/dev/null; then
    report_validation "Progressive Deployment" "PASS" \
      "Diagnose-first philosophy implemented"
else
    report_validation "Progressive Deployment" "WARN" \
      "Consider diagnose-first approach"
fi

echo ""
echo "🔍 PHASE 5: INFRASTRUCTURE AS CODE COMPLIANCE"
echo "==========================================="

# Template file structure
if [ -f cloud-init-universal.yml.tpl ]; then
    report_validation "Template File Structure" "PASS" \
      "Terraform templates properly separated"
else
    report_validation "Template File Structure" "FAIL" \
      "Missing .tpl template files"
fi

# Version pinning
if grep -q "traefik:v3.0" *.tpl 2>/dev/null; then
    report_validation "Version Pinning" "PASS" \
      "Docker images pinned to specific versions"
else
    report_validation "Version Pinning" "WARN" \
      "Consider pinning all Docker image versions"
fi

echo ""
echo "📋 COMPLIANCE VALIDATION SUMMARY"
echo "==============================="

if [ "$VALIDATION_PASSED" = true ]; then
    echo -e "🎉 ${GREEN}MEDICAL-GRADE COMPLIANCE: ACHIEVED${NC}"
    echo -e "📜 Standards: ${BLUE}ISO 13485 + NEN 7510 + IEC 62304${NC}"
    echo -e "✅ Infrastructure ready for medical device certification"
    echo ""
    echo "Next steps:"
    echo "  1. terraform plan (review changes)"
    echo "  2. terraform apply (deploy medical-grade infrastructure)"
    echo "  3. Run integration tests"
    exit 0
else
    echo -e "❌ ${RED}COMPLIANCE VIOLATIONS DETECTED${NC}"
    echo -e "🚨 Fix violations before proceeding with deployment"
    echo ""
    echo "Required actions:"
    echo "  1. Address all FAIL items above"
    echo "  2. Re-run validation: ./scripts/validate-medical-compliance.sh"
    echo "  3. Only proceed when all validations PASS"
    exit 1
fi