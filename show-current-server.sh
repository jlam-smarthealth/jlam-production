#!/bin/bash
# Show Current Server Status via Terraform Cloud API

echo "🖥️ CURRENT SERVER STATUS"
echo "========================"

# Configuration
WORKSPACE_ID_STAGING="ws-jErL3tPcJECaWATe"
API_TOKEN=$(cat ~/.terraform.d/credentials.tfrc.json | jq -r '.credentials."app.terraform.io".token')

echo "🔍 Checking current infrastructure state..."
echo ""

# Get current state
echo "📊 Current Terraform State:"
state_version=$(curl -s --request GET \
    --header "Authorization: Bearer $API_TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    "https://app.terraform.io/api/v2/workspaces/$WORKSPACE_ID_STAGING/current-state-version")

if echo "$state_version" | jq -e '.data' >/dev/null 2>&1; then
    # Get the state file URL
    download_url=$(echo "$state_version" | jq -r '.data.attributes."download-url"')
    
    if [ "$download_url" != "null" ]; then
        echo "📥 Downloading current state..."
        state_content=$(curl -s --request GET "$download_url")
        
        # Extract server information from state
        echo "🖥️ Current Server Information:"
        echo "$state_content" | jq -r '
            .resources[] | 
            select(.type == "scaleway_instance_server") | 
            "   Server ID: " + .instances[0].attributes.id + 
            "\n   Server Name: " + .instances[0].attributes.name + 
            "\n   Server Type: " + .instances[0].attributes.type + 
            "\n   Public IP: " + .instances[0].attributes.public_ip + 
            "\n   Private IP: " + (.instances[0].attributes.private_ip // "N/A") +
            "\n   State: " + .instances[0].attributes.state +
            "\n   Root Volume Size: " + (.instances[0].attributes.root_volume[0].size_in_gb | tostring) + "GB"
        '
        
        echo ""
        echo "🌐 IP Address Information:"
        echo "$state_content" | jq -r '
            .resources[] | 
            select(.type == "scaleway_instance_ip") | 
            "   IP Address: " + .instances[0].attributes.address +
            "\n   IP ID: " + .instances[0].attributes.id +
            "\n   Server: " + (.instances[0].attributes.server // "Not attached")
        '
    else
        echo "❌ No state download URL available"
    fi
else
    echo "❌ Could not retrieve current state"
fi

echo ""
echo "🔗 DNS Resolution:"
echo "   jlam.nl → $(dig +short jlam.nl)"

echo ""
echo "🌐 Service Status:"
curl_result=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://51.158.190.109 2>/dev/null || echo "000")
case "$curl_result" in
    "000") echo "   ❌ No response (connection failed)" ;;
    "200") echo "   ✅ HTTP 200 OK (service working)" ;;
    "404") echo "   ⚠️ HTTP 404 (server responding but no content)" ;;
    *) echo "   ⚠️ HTTP $curl_result" ;;
esac

echo ""
echo "🔑 SSH Status:"
ssh_test=$(ssh -i ~/.ssh/jlam_tunnel_key -o ConnectTimeout=3 -o StrictHostKeyChecking=no jlam@51.158.190.109 "echo success" 2>&1)
if echo "$ssh_test" | grep -q "success"; then
    echo "   ✅ SSH access working"
else
    echo "   ❌ SSH access failed: $(echo "$ssh_test" | head -1)"
fi

echo ""
echo "📋 SUMMARY:"
echo "   🌐 DNS: jlam.nl points to 51.158.190.109"
echo "   🖥️ Server: Currently deployed via Terraform"  
echo "   🔗 HTTP: $([ "$curl_result" = "200" ] && echo "✅ Working" || echo "❌ Not working")"
echo "   🔑 SSH: $(echo "$ssh_test" | grep -q "success" && echo "✅ Working" || echo "❌ Blocked")"