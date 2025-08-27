#!/bin/bash
# Terraform Cloud Variables Setup Script
# Elite DevOps Master - API Automation

echo "🔧 TERRAFORM CLOUD VARIABLES - API AUTOMATION"
echo "=============================================="

# Configuration
WORKSPACE_ID_STAGING="ws-jErL3tPcJECaWATe"
WORKSPACE_ID_PROD="ws-LknVhYroPYeYuMK8"
API_TOKEN=$(cat ~/.terraform.d/credentials.tfrc.json | jq -r '.credentials."app.terraform.io".token')

# Get credentials
echo "📋 Retrieving credentials..."
DB_PASSWORD=$(OP_SERVICE_ACCOUNT_TOKEN="$OP_SERVICE_ACCOUNT_TOKEN" op item get "🚀 JLAM Production Database" --vault "JLAM Operations" --fields password 2>/dev/null)
SECRET_KEY=$(openssl rand -hex 64)

# Function to create variable
create_variable() {
    local workspace_id="$1"
    local key="$2"
    local value="$3"
    local sensitive="$4"
    local description="$5"
    
    echo -n "Setting $key: "
    
    result=$(curl -s --request POST \
        --header "Authorization: Bearer $API_TOKEN" \
        --header "Content-Type: application/vnd.api+json" \
        --data "{
            \"data\": {
                \"type\": \"vars\",
                \"attributes\": {
                    \"key\": \"$key\",
                    \"value\": \"$value\",
                    \"description\": \"$description\",
                    \"category\": \"terraform\",
                    \"hcl\": false,
                    \"sensitive\": $sensitive
                }
            }
        }" \
        "https://app.terraform.io/api/v2/workspaces/$workspace_id/vars")
    
    if echo "$result" | jq -e '.data.attributes.key' >/dev/null 2>&1; then
        echo "✅ Created"
    else
        echo "⚠️ $(echo "$result" | jq -r '.errors[0].detail // "Unknown error"')"
    fi
}

# Set variables for staging
echo ""
echo "🎯 STAGING WORKSPACE: $WORKSPACE_ID_STAGING"
create_variable "$WORKSPACE_ID_STAGING" "TF_VAR_jlam_database_host" "51.158.130.103" "true" "JLAM PostgreSQL database host"
create_variable "$WORKSPACE_ID_STAGING" "TF_VAR_jlam_database_port" "20832" "false" "JLAM PostgreSQL database port"
create_variable "$WORKSPACE_ID_STAGING" "TF_VAR_jlam_database_name" "rdb" "false" "JLAM PostgreSQL database name"
create_variable "$WORKSPACE_ID_STAGING" "TF_VAR_jlam_database_user" "jlam_user" "true" "JLAM PostgreSQL database user"
create_variable "$WORKSPACE_ID_STAGING" "TF_VAR_jlam_database_password" "$DB_PASSWORD" "true" "JLAM PostgreSQL database password"
create_variable "$WORKSPACE_ID_STAGING" "TF_VAR_secret_key_base" "$SECRET_KEY" "true" "Application secret key base"

echo ""
echo "🚀 PRODUCTION WORKSPACE: $WORKSPACE_ID_PROD"
create_variable "$WORKSPACE_ID_PROD" "TF_VAR_jlam_database_host" "51.158.130.103" "true" "JLAM PostgreSQL database host"
create_variable "$WORKSPACE_ID_PROD" "TF_VAR_jlam_database_port" "20832" "false" "JLAM PostgreSQL database port"
create_variable "$WORKSPACE_ID_PROD" "TF_VAR_jlam_database_name" "rdb" "false" "JLAM PostgreSQL database name"
create_variable "$WORKSPACE_ID_PROD" "TF_VAR_jlam_database_user" "jlam_user" "true" "JLAM PostgreSQL database user"
create_variable "$WORKSPACE_ID_PROD" "TF_VAR_jlam_database_password" "$DB_PASSWORD" "true" "JLAM PostgreSQL database password"
create_variable "$WORKSPACE_ID_PROD" "TF_VAR_secret_key_base" "$SECRET_KEY" "true" "Application secret key base"

echo ""
echo "✅ TERRAFORM CLOUD VARIABLES SETUP COMPLETE!"
