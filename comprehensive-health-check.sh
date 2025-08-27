#!/bin/bash
# JLAM Comprehensive Infrastructure Health Check
# Elite DevOps Master - Production Validation Suite

echo "🏥 JLAM INFRASTRUCTURE COMPREHENSIVE HEALTH CHECK"
echo "================================================="
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Function to check HTTP endpoint
check_endpoint() {
    local url="$1"
    local name="$2"
    local expected_code="${3:-200}"
    
    echo -n "🔍 $name: "
    result=$(curl -s -w "%{http_code}|%{time_total}|%{size_download}" -o /dev/null "$url" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        http_code=$(echo $result | cut -d'|' -f1)
        response_time=$(echo $result | cut -d'|' -f2)
        size=$(echo $result | cut -d'|' -f3)
        
        if [[ "$http_code" == "$expected_code" ]]; then
            echo "✅ HTTP $http_code | ${response_time}s | ${size} bytes"
        else
            echo "⚠️  HTTP $http_code (expected $expected_code) | ${response_time}s"
        fi
    else
        echo "❌ Connection failed"
    fi
}

# Local Infrastructure Tests
echo "📋 LOCAL INFRASTRUCTURE STATUS:"
echo "================================"
check_endpoint "http://localhost:8082/" "Local Web Server"
check_endpoint "http://localhost:9080/api/rawdata" "Traefik API"
check_endpoint "https://localhost:8443/" "HTTPS Endpoint" "200"

echo ""
echo "🐳 DOCKER SERVICES STATUS:"
echo "=========================="
if command -v docker &> /dev/null; then
    docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "No docker-compose services"
else
    echo "Docker not available"
fi

echo ""
echo "🌐 REMOTE INFRASTRUCTURE TESTS:"
echo "==============================="
# Test staging server if accessible
check_endpoint "http://51.158.190.109/" "Staging Server HTTP"
check_endpoint "https://51.158.190.109/" "Staging Server HTTPS"

echo ""
echo "🔐 SSL CERTIFICATE STATUS:"
echo "=========================="
echo -n "Local HTTPS Certificate: "
if echo | openssl s_client -connect localhost:8443 -servername localhost 2>/dev/null | openssl x509 -noout -dates 2>/dev/null; then
    echo "✅ Valid"
else
    echo "❌ Invalid or not accessible"
fi

echo ""
echo "📊 SYSTEM RESOURCES:"
echo "==================="
echo "Disk Usage: $(df -h . | tail -1 | awk '{print $5}' | sed 's/%/ used/')"
if command -v free &> /dev/null; then
    echo "Memory Usage: $(free -h | grep Mem | awk '{print $3"/"$2}')"
fi

echo ""
echo "✅ COMPREHENSIVE HEALTH CHECK COMPLETE"
echo "======================================"
