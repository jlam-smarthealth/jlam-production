#!/bin/bash
# Confirm Apply for Staged Deployment
# Triggers the actual infrastructure changes

echo "✅ TERRAFORM CLOUD - CONFIRM APPLY"
echo "=================================="

# Configuration
RUN_ID="run-zVgeTvMTVui8L3Yd"
API_TOKEN=$(cat ~/.terraform.d/credentials.tfrc.json | jq -r '.credentials."app.terraform.io".token')

echo "🎯 Run ID: $RUN_ID"
echo "📋 Confirming apply for:"
echo "   ✅ Root volume resize: 10GB → 80GB"
echo "   ✅ Server recreation with fixed SSH keys"
echo "   ✅ Complete docker-compose.yml deployment"
echo ""

# Confirm the apply
echo "🚀 Confirming apply..."
confirm_result=$(curl -s --request POST \
    --header "Authorization: Bearer $API_TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    --data '{
        "comment": "RECOVERY: Confirmed apply for staging server with 80GB disk and fixed configuration"
    }' \
    "https://app.terraform.io/api/v2/runs/$RUN_ID/actions/confirm")

# Check the result
if echo "$confirm_result" | grep -q "error"; then
    echo "❌ Failed to confirm apply"
    echo "Response: $confirm_result"
else
    echo "✅ Apply confirmed successfully!"
    echo "🔄 Deployment is now running..."
    echo "🌐 Monitor at: https://app.terraform.io/app/jlam/workspaces/jlam-staging/runs/$RUN_ID"
    echo ""
    echo "⏱️ Expected timeline:"
    echo "   1-2 min: Server recreation with 80GB disk"
    echo "   2-3 min: Cloud-init installation (Docker, docker-compose)"
    echo "   3-4 min: Application deployment and startup"
    echo "   4-5 min: Services fully operational"
    echo ""
    echo "🎯 Run monitoring script to track progress:"
    echo "   ./monitor-deployment.sh"
fi