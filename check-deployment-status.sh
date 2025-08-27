#!/bin/bash
# JLAM Infrastructure Deployment Status Checker
echo "🔍 JLAM INFRASTRUCTURE STATUS CHECK"
echo "=================================="
echo ""

echo "📋 Current Docker Services:"
docker-compose ps 2>/dev/null || echo "No local services running"
echo ""

echo "🌐 Health Check Tests:"
echo "Local Traefik (port 9080):"
curl -s -w "Response: %{http_code} | Time: %{time_total}s\n" http://localhost:9080/api/rawdata -o /dev/null || echo "Not accessible"

echo "Local Web (port 8082):"
curl -s -w "Response: %{http_code} | Time: %{time_total}s\n" http://localhost:8082/ -o /dev/null || echo "Not accessible" 

echo ""
echo "🔐 SSL Certificate Check (if accessible):"
echo | openssl s_client -connect localhost:8443 -servername localhost 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "SSL not accessible"

echo ""
echo "📊 System Resources:"
echo "Memory: $(free -h 2>/dev/null | grep Mem | awk '{print $3"/"$2}' || echo 'macOS - use Activity Monitor')"
echo "Disk: $(df -h . | tail -1 | awk '{print $5}' | sed 's/%/ used/')"

echo ""
echo "✅ Status check complete!"
