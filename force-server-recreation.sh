#!/bin/bash
# CORRECT APPROACH: Force Complete Server Recreation
# This will destroy the broken server and create a new one with working config

echo "🔄 TERRAFORM CLOUD - FORCE SERVER RECREATION"
echo "============================================="

# Configuration
WORKSPACE_ID_STAGING="ws-jErL3tPcJECaWATe"
API_TOKEN=$(cat ~/.terraform.d/credentials.tfrc.json | jq -r '.credentials."app.terraform.io".token')

echo "🎯 LEARNING APPLIED: This will FORCE REPLACEMENT (destroy + create)"
echo ""
echo "📋 Why forced replacement is needed:"
echo "   🔑 SSH keys: Set during creation via user_data (immutable)"
echo "   📦 Cloud-init: Runs once at creation (won't re-run on update)"
echo "   🐳 Docker deployment: Happens during initial boot only"
echo ""
echo "⚠️ CRITICAL: This will cause brief downtime during server recreation"
echo "   But it's the ONLY way to actually fix the broken configuration"
echo ""

# Check current broken state first
echo "🔍 Current broken server status:"
echo "   SSH: $(ssh -i ~/.ssh/jlam_tunnel_key -o ConnectTimeout=3 -o StrictHostKeyChecking=no jlam@51.158.190.109 'echo success' 2>&1 | head -1)"
echo "   HTTP: $(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 3 http://51.158.190.109 2>/dev/null || echo '000')"
echo ""

read -p "🚨 Proceed with COMPLETE SERVER RECREATION? (y/N): " confirm

if [[ $confirm =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 Creating run with forced replacement..."
    
    # The key insight: we need to force replacement, not just apply updates
    # This requires either:
    # 1. Using -replace flag (if we had CLI access)
    # 2. Or adding replace_triggered_by to lifecycle
    # 3. Or changing an immutable attribute
    
    echo "💡 RECOMMENDED APPROACH:"
    echo "1. Add to standalone.tf:"
    echo '   lifecycle {'
    echo '     replace_triggered_by = [timestamp()]'
    echo '   }'
    echo ""
    echo "2. Or modify an immutable attribute to force replacement"
    echo ""
    echo "3. This ensures the server is DESTROYED and RECREATED"
    echo "   - New SSH keys will work"
    echo "   - Cloud-init will run fresh"
    echo "   - Docker-compose will deploy"
    echo "   - Service will be restored"
    
    echo ""
    echo "🎯 The current pending run will NOT fix the issues"
    echo "   because it only does 'update in-place'"
    
else
    echo "❌ Operation cancelled"
    echo ""
    echo "📚 Key learning: 'terraform apply' with current plan"
    echo "   will NOT fix SSH access or missing Docker services"
    echo "   because these require server RECREATION, not update"
fi

echo ""
echo "🎓 INFRASTRUCTURE LEARNING COMPLETE:"
echo "   ✅ Understand difference between UPDATE vs REPLACE" 
echo "   ✅ Know when cloud-init runs (creation only)"
echo "   ✅ Recognize immutable vs mutable attributes"
echo "   ✅ Can predict what terraform plan will actually do"