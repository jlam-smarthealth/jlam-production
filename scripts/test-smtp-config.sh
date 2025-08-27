#!/bin/bash

# JLAM SMTP Configuration Test
# Tests Scaleway TEM integration with Authentik
# Created: 2025-01-27

echo "🔧 JLAM SMTP Configuration Test"
echo "================================"

# Load environment variables
if [ -f "../.env" ]; then
    source ../.env
    echo "✅ Main .env loaded"
else
    echo "❌ Main .env file not found"
    exit 1
fi

if [ -f "../authentik/.env" ]; then
    source ../authentik/.env
    echo "✅ Authentik .env loaded"
else
    echo "⚠️  Authentik .env file not found"
fi

echo ""
echo "📧 SMTP Configuration Check:"
echo "----------------------------"
echo "Host: ${SMTP_HOST:-NOT SET}"
echo "Port: ${SMTP_PORT:-NOT SET}"
echo "From: ${SMTP_FROM:-${SMTP_FROM_EMAIL:-NOT SET}}"
echo "TLS: ${SMTP_TLS:-NOT SET}"
echo "User: ${SMTP_USER:+***CONFIGURED***}"
echo "Pass: ${SMTP_PASS:-${SMTP_PASSWORD:-NOT SET}}"

echo ""
echo "🔍 Connectivity Test:"
echo "--------------------"

# Test SMTP connectivity
if command -v telnet >/dev/null 2>&1; then
    echo "Testing connection to ${SMTP_HOST:-smtp.tem.scw.cloud}:${SMTP_PORT:-587}..."
    timeout 5 telnet ${SMTP_HOST:-smtp.tem.scw.cloud} ${SMTP_PORT:-587} 2>/dev/null && echo "✅ Connection successful" || echo "❌ Connection failed"
else
    echo "⚠️  telnet not available for connection test"
fi

# Test DNS resolution
echo "Testing DNS resolution for ${SMTP_HOST:-smtp.tem.scw.cloud}..."
nslookup ${SMTP_HOST:-smtp.tem.scw.cloud} >/dev/null 2>&1 && echo "✅ DNS resolution successful" || echo "❌ DNS resolution failed"

echo ""
echo "📝 Required Actions:"
echo "-------------------"
if [ -z "$SMTP_USER" ] && [ -z "$SMTP_PASSWORD" ]; then
    echo "❌ SMTP credentials not configured"
    echo "   1. Go to: https://console.scaleway.com/"
    echo "   2. Navigate to: Messaging → Transactional Email (TEM)"
    echo "   3. Create SMTP credentials"
    echo "   4. Update .env files with credentials"
fi

if [ -z "$SMTP_HOST" ]; then
    echo "❌ SMTP host not configured"
    echo "   Set SMTP_HOST=smtp.tem.scw.cloud"
fi

if [ "$SMTP_PORT" != "587" ]; then
    echo "⚠️  Recommended SMTP port is 587 (current: ${SMTP_PORT:-NOT SET})"
fi

if [ "$SMTP_TLS" != "true" ]; then
    echo "⚠️  TLS should be enabled for security (current: ${SMTP_TLS:-NOT SET})"
fi

echo ""
echo "🚀 Next Steps:"
echo "-------------"
echo "1. Configure SMTP credentials in .env files"
echo "2. Restart Authentik containers: cd authentik && docker-compose restart"
echo "3. Test email in Authentik admin: Events → Transports → Test Email"
echo "4. Verify password reset emails work"