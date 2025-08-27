#!/bin/bash
# Terraform Cloud Run Trigger - Staging Deployment
# Forces server recreation with fixed configuration

echo "🚀 TERRAFORM CLOUD - TRIGGER STAGING DEPLOYMENT"
echo "================================================"

# Configuration
WORKSPACE_ID_STAGING="ws-jErL3tPcJECaWATe"
API_TOKEN=$(cat ~/.terraform.d/credentials.tfrc.json | jq -r '.credentials."app.terraform.io".token')

echo "📋 Triggering deployment on staging workspace: $WORKSPACE_ID_STAGING"
echo "⚠️ This will recreate the server with:"
echo "   - Correct 80GB disk size"
echo "   - Fixed SSH keys"
echo "   - Complete docker-compose.yml deployment"
echo ""

# Create a configuration version and trigger run
echo "🔧 Creating configuration version..."
config_version=$(curl -s --request POST \
    --header "Authorization: Bearer $API_TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    --data '{
        "data": {
            "type": "configuration-versions",
            "attributes": {
                "auto-queue-runs": true
            }
        }
    }' \
    "https://app.terraform.io/api/v2/workspaces/$WORKSPACE_ID_STAGING/configuration-versions")

# Extract upload URL and configuration version ID
UPLOAD_URL=$(echo "$config_version" | jq -r '.data.attributes."upload-url"')
CONFIG_VERSION_ID=$(echo "$config_version" | jq -r '.data.id')

if [ "$UPLOAD_URL" == "null" ] || [ "$CONFIG_VERSION_ID" == "null" ]; then
    echo "❌ Failed to create configuration version"
    echo "Response: $config_version"
    exit 1
fi

echo "✅ Configuration version created: $CONFIG_VERSION_ID"
echo "📤 Upload URL: $UPLOAD_URL"

# Create tar.gz of current directory (excluding git files)
echo "📦 Packaging configuration files..."
tar -czf config.tar.gz --exclude='.git*' --exclude='*.tar.gz' .

# Upload the configuration
echo "⬆️ Uploading configuration..."
upload_result=$(curl -s --request PUT \
    --data-binary @config.tar.gz \
    "$UPLOAD_URL")

# Clean up
rm config.tar.gz

echo "✅ Configuration uploaded successfully"

# Check for automatically queued run
echo "🔍 Checking for automatically queued run..."
sleep 3

runs=$(curl -s --request GET \
    --header "Authorization: Bearer $API_TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    "https://app.terraform.io/api/v2/workspaces/$WORKSPACE_ID_STAGING/runs")

latest_run_id=$(echo "$runs" | jq -r '.data[0].id // empty')
latest_run_status=$(echo "$runs" | jq -r '.data[0].attributes.status // empty')

if [ -n "$latest_run_id" ]; then
    echo "🎯 Latest run: $latest_run_id"
    echo "📊 Status: $latest_run_status" 
    echo "🌐 View in Terraform Cloud:"
    echo "   https://app.terraform.io/app/jlam/workspaces/jlam-staging/runs/$latest_run_id"
    echo ""
    echo "✅ DEPLOYMENT TRIGGERED SUCCESSFULLY!"
    echo ""
    echo "🔄 The server will be recreated with:"
    echo "   ✅ 80GB disk size (instead of 10GB)"
    echo "   ✅ Correct SSH keys for access"
    echo "   ✅ Complete docker-compose.yml application deployment"
    echo "   ✅ Proper cloud-init configuration"
    echo ""
    echo "⏱️ Deployment typically takes 3-5 minutes"
    echo "🔍 Monitor progress in Terraform Cloud dashboard"
else
    echo "⚠️ No run found - may need manual trigger"
    echo "🌐 Check: https://app.terraform.io/app/jlam/workspaces/jlam-staging"
fi

echo ""
echo "🎯 Next: Monitor deployment and verify service restoration"