#!/bin/bash

# DNS Verification Script for jlam.nl
# Created: 2025-08-27

echo "================================================"
echo "DNS Email Records Verification for jlam.nl"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if record exists
check_record() {
    local record_type="$1"
    local record_name="$2"
    local expected_contains="$3"
    local description="$4"
    
    echo -n "Checking $description... "
    
    result=$(dig +short "$record_name" "$record_type" 2>/dev/null)
    
    if [ -z "$result" ]; then
        echo -e "${RED}❌ NOT FOUND${NC}"
        echo "  Expected: $expected_contains"
        return 1
    elif [[ "$result" == *"$expected_contains"* ]]; then
        echo -e "${GREEN}✅ FOUND${NC}"
        echo "  Value: ${result:0:100}..." # Show first 100 chars
        return 0
    else
        echo -e "${YELLOW}⚠️  FOUND but different${NC}"
        echo "  Found: $result"
        echo "  Expected to contain: $expected_contains"
        return 2
    fi
}

echo "1. SPF Record Check"
echo "-------------------"
check_record "TXT" "jlam.nl" "_spf.tem.scaleway.com" "SPF record with Scaleway TEM"
echo ""

echo "2. DKIM Record Check (Scaleway TEM)"
echo "------------------------------------"
check_record "TXT" "scw._domainkey.jlam.nl" "v=DKIM1" "DKIM record for Scaleway TEM"
echo ""

echo "3. DMARC Record Check"
echo "---------------------"
check_record "TXT" "_dmarc.jlam.nl" "v=DMARC1" "DMARC policy record"
echo ""

echo "4. MX Records Check"
echo "-------------------"
mx_records=$(dig +short jlam.nl MX)
echo "MX Records found:"
echo "$mx_records"
if [[ "$mx_records" == *"blackhole.scw-tem.cloud"* ]]; then
    echo -e "${GREEN}✅ Scaleway TEM backup MX found${NC}"
else
    echo -e "${YELLOW}⚠️  Scaleway TEM backup MX not found${NC}"
    echo "  Expected: blackhole.scw-tem.cloud with priority 10 or higher"
fi
echo ""

echo "5. Nameservers"
echo "--------------"
ns_records=$(dig +short jlam.nl NS)
echo "Nameservers:"
echo "$ns_records"
if [[ "$ns_records" == *"transip"* ]]; then
    echo -e "${GREEN}✅ Domain managed by TransIP${NC}"
else
    echo -e "${YELLOW}⚠️  Domain not managed by TransIP${NC}"
fi
echo ""

echo "================================================"
echo "Summary:"
echo "================================================"

# Count issues
issues=0

# Check each critical record
spf_ok=$(dig +short jlam.nl TXT | grep -c "_spf.tem.scaleway.com")
dkim_ok=$(dig +short scw._domainkey.jlam.nl TXT | grep -c "v=DKIM1")
dmarc_ok=$(dig +short _dmarc.jlam.nl TXT | grep -c "v=DMARC1")
mx_ok=$(dig +short jlam.nl MX | grep -c "blackhole.scw-tem.cloud")

if [ "$spf_ok" -eq 0 ]; then
    echo -e "${RED}❌ SPF: Missing Scaleway TEM include${NC}"
    ((issues++))
else
    echo -e "${GREEN}✅ SPF: Configured correctly${NC}"
fi

if [ "$dkim_ok" -eq 0 ]; then
    echo -e "${RED}❌ DKIM: NOT CONFIGURED - Add immediately in TransIP!${NC}"
    ((issues++))
else
    echo -e "${GREEN}✅ DKIM: Configured correctly${NC}"
fi

if [ "$dmarc_ok" -eq 0 ]; then
    echo -e "${RED}❌ DMARC: Not configured${NC}"
    ((issues++))
else
    echo -e "${GREEN}✅ DMARC: Configured correctly${NC}"
fi

if [ "$mx_ok" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  MX: Scaleway TEM backup MX not found (optional but recommended)${NC}"
else
    echo -e "${GREEN}✅ MX: Scaleway TEM backup configured${NC}"
fi

echo ""
if [ "$issues" -eq 0 ]; then
    echo -e "${GREEN}✨ All email authentication records are properly configured!${NC}"
else
    echo -e "${RED}⚠️  Found $issues issue(s) that need attention${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Login to TransIP Control Panel: https://www.transip.nl/cp/"
    echo "2. Go to: Domains → jlam.nl → DNS Settings"
    echo "3. Add the missing DKIM TXT record as specified in dns-records-to-add.md"
fi

echo ""
echo "To re-run this check: ./verify-dns.sh"