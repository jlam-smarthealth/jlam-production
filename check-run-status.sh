#!/bin/bash
# Check Current Run Status and Available Actions

echo "📊 TERRAFORM CLOUD - RUN STATUS CHECK"  
echo "===================================="

# Configuration
RUN_ID="run-zVgeTvMTVui8L3Yd"
API_TOKEN=$(cat ~/.terraform.d/credentials.tfrc.json | jq -r '.credentials."app.terraform.io".token')

echo "🎯 Checking Run: $RUN_ID"
echo ""

# Get detailed run information including available actions
echo "📋 Fetching run details with actions..."
run_details=$(curl -s --request GET \
    --header "Authorization: Bearer $API_TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    "https://app.terraform.io/api/v2/runs/$RUN_ID")

echo "📊 Current Status: $(echo "$run_details" | jq -r '.data.attributes.status')"
echo "💬 Message: $(echo "$run_details" | jq -r '.data.attributes.message')"
echo "📅 Created: $(echo "$run_details" | jq -r '.data.attributes."created-at"')"
echo ""

# Check available actions
echo "🎮 Available Actions:"
actions=$(echo "$run_details" | jq -r '.data.attributes.actions')
if [ "$actions" != "null" ]; then
    echo "$actions" | jq -r 'to_entries[] | "   \(.key): \(.value)"'
else
    echo "   No actions data available"
fi
echo ""

# Check if auto-apply is enabled
auto_apply=$(echo "$run_details" | jq -r '.data.attributes."auto-apply"')
echo "🤖 Auto-apply enabled: $auto_apply"

# Get workspace info to understand why apply needs confirmation
workspace_details=$(curl -s --request GET \
    --header "Authorization: Bearer $API_TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    "https://app.terraform.io/api/v2/workspaces/ws-jErL3tPcJECaWATe")

workspace_auto_apply=$(echo "$workspace_details" | jq -r '.data.attributes."auto-apply"')
echo "🌐 Workspace auto-apply: $workspace_auto_apply"

echo ""
echo "🎯 Dashboard Link:"
echo "https://app.terraform.io/app/jlam/workspaces/jlam-staging/runs/$RUN_ID"
echo ""

# Show specific guidance based on status
status=$(echo "$run_details" | jq -r '.data.attributes.status')
case "$status" in
    "planned")
        echo "💡 Next Step: Visit dashboard and click 'Confirm & Apply' to proceed"
        ;;
    "applying")
        echo "🚀 Deployment in progress - monitor for completion"
        ;;
    "applied")
        echo "✅ Deployment completed successfully!"
        ;;
    *)
        echo "⚠️ Status '$status' - check dashboard for details"
        ;;
esac