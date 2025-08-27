#!/bin/bash
# Force Apply Staging Changes - Direct Terraform Cloud Execution

echo "⚡ TERRAFORM CLOUD - FORCE APPLY STAGING"
echo "========================================"

# Configuration
WORKSPACE_ID_STAGING="ws-jErL3tPcJECaWATe" 
API_TOKEN=$(cat ~/.terraform.d/credentials.tfrc.json | jq -r '.credentials."app.terraform.io".token')

echo "🎯 Workspace: jlam-staging"
echo "📋 This will apply the changes shown in the successful local plan:"
echo "   ✅ Root volume size: 10GB → 80GB"  
echo "   ✅ Server recreation with new configuration"
echo ""

# Get latest configuration version
echo "🔍 Getting latest configuration version..."
config_versions=$(curl -s --request GET \
    --header "Authorization: Bearer $API_TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    "https://app.terraform.io/api/v2/workspaces/$WORKSPACE_ID_STAGING/configuration-versions?page%5Bsize%5D=5")

latest_config_id=$(echo "$config_versions" | jq -r '.data[0].id')
latest_config_status=$(echo "$config_versions" | jq -r '.data[0].attributes.status')

echo "📦 Latest config version: $latest_config_id"
echo "📊 Status: $latest_config_status"

# Check if we can create a run with the latest config
if [ "$latest_config_status" = "uploaded" ]; then
    echo "✅ Configuration ready - creating run..."
    
    # Create run with specific configuration version
    run_result=$(curl -s --request POST \
        --header "Authorization: Bearer $API_TOKEN" \
        --header "Content-Type: application/vnd.api+json" \
        --data "{
            \"data\": {
                \"type\": \"runs\",
                \"attributes\": {
                    \"message\": \"RECOVERY: Apply fixed staging config with 80GB disk\",
                    \"auto-apply\": false
                },
                \"relationships\": {
                    \"workspace\": {
                        \"data\": {
                            \"type\": \"workspaces\",
                            \"id\": \"$WORKSPACE_ID_STAGING\"
                        }
                    },
                    \"configuration-version\": {
                        \"data\": {
                            \"type\": \"configuration-versions\",
                            \"id\": \"$latest_config_id\"
                        }
                    }
                }
            }
        }" \
        "https://app.terraform.io/api/v2/runs")
    
    run_id=$(echo "$run_result" | jq -r '.data.id')
    run_status=$(echo "$run_result" | jq -r '.data.attributes.status')
    
    if [ "$run_id" != "null" ] && [ "$run_id" != "" ]; then
        echo "✅ Run created successfully!"
        echo "🎯 Run ID: $run_id" 
        echo "📊 Status: $run_status"
        echo "🌐 Dashboard: https://app.terraform.io/app/jlam/workspaces/jlam-staging/runs/$run_id"
        echo ""
        echo "⏱️ Monitor this run for deployment progress"
    else
        echo "❌ Failed to create run"
        echo "Response: $run_result"
    fi
    
else
    echo "❌ Configuration not ready for deployment"
    echo "Status: $latest_config_status"
    echo "🌐 Check workspace: https://app.terraform.io/app/jlam/workspaces/jlam-staging"
fi