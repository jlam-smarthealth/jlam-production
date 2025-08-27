#!/bin/bash
# Confirm Apply for Staged Deployment - Correct API Format
# Uses proper Terraform Cloud API endpoint for run confirmation

echo "✅ TERRAFORM CLOUD - CONFIRM APPLY (V2)"
echo "======================================="

# Configuration
RUN_ID="run-zVgeTvMTVui8L3Yd"
API_TOKEN=$(cat ~/.terraform.d/credentials.tfrc.json | jq -r '.credentials."app.terraform.io".token')

echo "🎯 Run ID: $RUN_ID" 
echo "📋 Confirming apply for critical infrastructure fixes"
echo ""

# Method 1: Try confirm endpoint
echo "🚀 Attempting confirmation..."
confirm_result=$(curl -s --request POST \
    --header "Authorization: Bearer $API_TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    "https://app.terraform.io/api/v2/runs/$RUN_ID/actions/confirm")

echo "Response: $confirm_result"

# Check if it worked by examining the response
if echo "$confirm_result" | jq -e '.data.attributes.status' >/dev/null 2>&1; then
    new_status=$(echo "$confirm_result" | jq -r '.data.attributes.status')
    echo "✅ Confirmation successful!"
    echo "📊 New status: $new_status"
    
    if [ "$new_status" = "applying" ]; then
        echo ""
        echo "🚀 DEPLOYMENT IS NOW RUNNING!"
        echo ""
        echo "⏱️ Expected timeline:"
        echo "   ⚙️ 1-2 min: Server recreation with 80GB disk"
        echo "   📦 2-3 min: Cloud-init setup (Docker, docker-compose)"
        echo "   🐳 3-4 min: Docker containers deployment"
        echo "   ✅ 4-5 min: Services fully operational at jlam.nl"
        echo ""
        echo "🔍 Monitor progress:"
        echo "   ./monitor-deployment.sh"
        echo "🌐 Dashboard:"
        echo "   https://app.terraform.io/app/jlam/workspaces/jlam-staging/runs/$RUN_ID"
    fi
else
    echo "⚠️ API response unclear - checking alternative approaches..."
    
    # Try alternative endpoint format
    echo ""
    echo "🔄 Trying alternative confirmation method..."
    alt_result=$(curl -s --request POST \
        --header "Authorization: Bearer $API_TOKEN" \
        --header "Content-Type: application/vnd.api+json" \
        --data '{}' \
        "https://app.terraform.io/api/v2/runs/$RUN_ID/actions/confirm")
    
    echo "Alternative response: $alt_result"
    
    if echo "$alt_result" | jq -e '.data' >/dev/null 2>&1; then
        echo "✅ Alternative method worked!"
    else
        echo ""
        echo "💡 Manual confirmation required:"
        echo "   1. Visit: https://app.terraform.io/app/jlam/workspaces/jlam-staging/runs/$RUN_ID"
        echo "   2. Click 'Confirm & Apply' button"
        echo "   3. Run ./monitor-deployment.sh to track progress"
        echo ""
        echo "🔍 The plan is ready and validated - just needs manual click"
    fi
fi