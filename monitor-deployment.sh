#!/bin/bash
# Monitor Terraform Cloud Deployment Progress
# Real-time status monitoring for staging deployment

echo "📊 TERRAFORM CLOUD - DEPLOYMENT MONITOR"
echo "========================================"

# Configuration
WORKSPACE_ID_STAGING="ws-jErL3tPcJECaWATe"
RUN_ID="run-zVgeTvMTVui8L3Yd"
API_TOKEN=$(cat ~/.terraform.d/credentials.tfrc.json | jq -r '.credentials."app.terraform.io".token')

echo "🎯 Monitoring Run: $RUN_ID"
echo "🌐 Dashboard: https://app.terraform.io/app/jlam/workspaces/jlam-staging/runs/$RUN_ID"
echo ""

# Function to check run status
check_status() {
    local run_data=$(curl -s --request GET \
        --header "Authorization: Bearer $API_TOKEN" \
        --header "Content-Type: application/vnd.api+json" \
        "https://app.terraform.io/api/v2/runs/$RUN_ID")
    
    local status=$(echo "$run_data" | jq -r '.data.attributes.status')
    local message=$(echo "$run_data" | jq -r '.data.attributes.message // "No message"')
    local created_at=$(echo "$run_data" | jq -r '.data.attributes."created-at"')
    
    echo "$(date '+%H:%M:%S') | Status: $status | Message: $message"
    echo "$status"
}

# Monitor deployment progress
echo "⏱️ Starting deployment monitoring..."
echo ""

while true; do
    status=$(check_status)
    
    case "$status" in
        "plan_queued"|"planning"|"cost_estimating")
            echo "   🔄 Planning phase in progress..."
            ;;
        "planned")
            echo "   ✅ Plan completed successfully!"
            echo "   🎯 Waiting for apply confirmation..."
            ;;
        "confirmed")
            echo "   👍 Apply confirmed - starting deployment..."
            ;;
        "applying")
            echo "   🚀 Deploying infrastructure changes..."
            ;;
        "applied")
            echo ""
            echo "✅ DEPLOYMENT COMPLETED SUCCESSFULLY!"
            echo ""
            echo "🎯 Server recreation finished with:"
            echo "   ✅ 80GB disk size"
            echo "   ✅ Correct SSH keys"  
            echo "   ✅ Complete docker-compose.yml deployment"
            echo ""
            echo "🔍 Next steps:"
            echo "   1. Verify SSH access: ssh -i ~/.ssh/jlam_tunnel_key jlam@51.158.190.109"
            echo "   2. Check service status: docker ps"
            echo "   3. Test jlam.nl accessibility"
            echo "   4. Monitor logs: docker logs -f jlam-traefik"
            break
            ;;
        "errored"|"canceled"|"discarded")
            echo ""
            echo "❌ DEPLOYMENT FAILED!"
            echo "   Status: $status"
            echo "   🌐 Check logs: https://app.terraform.io/app/jlam/workspaces/jlam-staging/runs/$RUN_ID"
            echo ""
            echo "🔍 Common issues to check:"
            echo "   - Template syntax errors"
            echo "   - Cloud-init configuration"
            echo "   - Resource limits or quotas"
            echo "   - Network connectivity"
            break
            ;;
        *)
            echo "   ⏳ Status: $status"
            ;;
    esac
    
    sleep 10
done