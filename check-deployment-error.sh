#!/bin/bash
# Check Terraform Cloud Deployment Error Details

echo "🚨 TERRAFORM CLOUD - ERROR INVESTIGATION"
echo "========================================"

# Configuration
RUN_ID="run-eifVZAFSFunhpGmh"
API_TOKEN=$(cat ~/.terraform.d/credentials.tfrc.json | jq -r '.credentials."app.terraform.io".token')

echo "🎯 Investigating Run: $RUN_ID"
echo ""

# Get detailed run information
echo "📋 Fetching run details..."
run_details=$(curl -s --request GET \
    --header "Authorization: Bearer $API_TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    "https://app.terraform.io/api/v2/runs/$RUN_ID?include=plan")

echo "Run Status: $(echo "$run_details" | jq -r '.data.attributes.status')"
echo "Run Message: $(echo "$run_details" | jq -r '.data.attributes.message')"
echo "Created At: $(echo "$run_details" | jq -r '.data.attributes."created-at"')"
echo ""

# Get plan details if available
plan_id=$(echo "$run_details" | jq -r '.included[]? | select(.type == "plans") | .id')

if [ "$plan_id" != "" ] && [ "$plan_id" != "null" ]; then
    echo "📊 Plan ID: $plan_id"
    
    # Get plan logs
    echo "📝 Fetching plan logs..."
    plan_logs=$(curl -s --request GET \
        --header "Authorization: Bearer $API_TOKEN" \
        "https://app.terraform.io/api/v2/plans/$plan_id/json-output")
    
    echo "📄 Plan Output:"
    echo "$plan_logs" | jq -r '.[]? | select(.type == "diagnostic") | .message'
    echo ""
fi

# Try to get configuration version details
echo "🔧 Configuration version analysis..."
config_runs=$(curl -s --request GET \
    --header "Authorization: Bearer $API_TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    "https://app.terraform.io/api/v2/workspaces/ws-jErL3tPcJECaWATe/runs?page%5Bsize%5D=5")

echo "📊 Recent runs status:"
echo "$config_runs" | jq -r '.data[] | "\(.id): \(.attributes.status) - \(.attributes.message // "No message")"'

echo ""
echo "🌐 Dashboard Link:"
echo "https://app.terraform.io/app/jlam/workspaces/jlam-staging/runs/$RUN_ID"