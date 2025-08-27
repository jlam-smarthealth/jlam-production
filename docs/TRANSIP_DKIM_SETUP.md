# TransIP DKIM Record Setup for jlam.nl
*Created: 2025-01-27*

## 🎯 Goal
Add the Scaleway TEM DKIM record to jlam.nl domain via TransIP.

## 📋 DKIM Record Details

**Record to add:**
- **Name:** `scw._domainkey`
- **Type:** `TXT`
- **TTL:** `3600` (1 hour)
- **Value:** 
```
v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAw/ZCpjmIYUnl+mz5kLqeMtWKk7y6qaLQRujjjTCDUf0SSAWBdPZVzvwX+jdVEtTFXC3xua6NIoJi+g+kzCThccJUNCGGEtdgL9ZsW+MEsFuOGUBwLNZ3GCVvfYRl9oQnfHHym1n8F6r2Km9sD0BIn96SX/+wxL842mJE+aPGsxDagvwZzedDEUH8VVXivJOqLZz7NGV9e+o+s6y41A0jkQozcP6j496ndssu82dXvSwSX7RR1K5skrCzANoncD4KmNDHEQ2OT0GbqulpAnQC4mviHJr3j6YzrNI1yuOpGdvrbzQaBHpmX7s/qG1jUxgz6YQ8A4yJmrLMa6tgDP3RLwIDAQAB
```

## 🔧 Method 1: Via TransIP Control Panel (EASIEST)

1. **Login to TransIP**
   - Go to: https://www.transip.nl/cp/
   - Username: `wim@jeleefstijlalsmedicijn.nl`
   - Password: From 1Password

2. **Navigate to DNS Settings**
   - Click on "Domeinnamen" (Domains)
   - Select `jlam.nl`
   - Click on "DNS" tab

3. **Add TXT Record**
   - Click "Toevoegen" (Add)
   - **Name:** `scw._domainkey`
   - **Type:** Select `TXT`
   - **TTL:** `3600`
   - **Value:** Paste the full DKIM value above
   - Click "Toevoegen" (Add)

4. **Save Changes**
   - Click "Opslaan" (Save)
   - Confirm the changes

## 🔧 Method 2: Via TransIP API (Using curl)

### Step 1: Get API Access Token

First, you need to enable API access and get a token:

1. Login to https://www.transip.nl/cp/
2. Click profile icon → "Mijn account" → "API"
3. Enable API if not already enabled
4. Generate a new key pair
5. Save the PRIVATE KEY securely

### Step 2: Generate Access Token

Create a file `/tmp/get_token.sh`:
```bash
#!/bin/bash
# You'll need to add your private key here
PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
[YOUR PRIVATE KEY HERE]
-----END PRIVATE KEY-----"

USERNAME="wim@jeleefstijlalsmedicijn.nl"

# This is a simplified version - you'll need proper signing
echo "Visit TransIP control panel to generate token manually"
echo "Or use the Python script provided"
```

### Step 3: Add DNS Record with curl

Once you have the token:
```bash
# Replace [YOUR_TOKEN] with your actual token
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer [YOUR_TOKEN]" \
  -d '{
    "dnsEntry": {
      "name": "scw._domainkey",
      "expire": 3600,
      "type": "TXT",
      "content": "v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAw/ZCpjmIYUnl+mz5kLqeMtWKk7y6qaLQRujjjTCDUf0SSAWBdPZVzvwX+jdVEtTFXC3xua6NIoJi+g+kzCThccJUNCGGEtdgL9ZsW+MEsFuOGUBwLNZ3GCVvfYRl9oQnfHHym1n8F6r2Km9sD0BIn96SX/+wxL842mJE+aPGsxDagvwZzedDEUH8VVXivJOqLZz7NGV9e+o+s6y41A0jkQozcP6j496ndssu82dXvSwSX7RR1K5skrCzANoncD4KmNDHEQ2OT0GbqulpAnQC4mviHJr3j6YzrNI1yuOpGdvrbzQaBHpmX7s/qG1jUxgz6YQ8A4yJmrLMa6tgDP3RLwIDAQAB"
    }
  }' \
  "https://api.transip.nl/v6/domains/jlam.nl/dns"
```

## 🔧 Method 3: Using Python Script

We have prepared two Python scripts in `/tmp/`:
- `/tmp/add_dkim_record.py` - Using python-transip library
- `/tmp/add_dkim_rest_api.py` - Using REST API directly

To use:
```bash
cd /tmp
source transip_env/bin/activate
python add_dkim_rest_api.py
# Follow the prompts to enter your API key
```

## ✅ Verification

After adding the record, verify with:

```bash
# Check if record exists (may take 5-60 minutes to propagate)
dig +short TXT scw._domainkey.jlam.nl

# Alternative commands
nslookup -type=TXT scw._domainkey.jlam.nl
host -t TXT scw._domainkey.jlam.nl

# Expected output should show the DKIM value
```

## 📊 Current Email Authentication Status

| Service | Record Type | Status | Value |
|---------|------------|--------|-------|
| Scaleway TEM | SPF | ✅ Configured | `v=spf1 include:scw.email ~all` |
| Scaleway TEM | DKIM | ⏳ To be added | `scw._domainkey` → TXT record |
| General | DMARC | 📌 Optional | Can be added for enhanced security |

## 🆘 Troubleshooting

### If DNS doesn't propagate:
1. Check TTL settings (lower = faster propagation)
2. Clear DNS cache: `sudo dscacheutil -flushcache` (macOS)
3. Test with different DNS servers: `dig @8.8.8.8 TXT scw._domainkey.jlam.nl`

### If API fails:
1. Verify API is enabled in TransIP account
2. Check private key format (must include BEGIN/END lines)
3. Ensure token hasn't expired (default 30 minutes)

## 📝 Next Steps

After DKIM is configured:
1. ✅ SPF record (already done)
2. ✅ DKIM record (this document)
3. 📌 Consider adding DMARC record for complete email authentication
4. 🧪 Test email delivery from Scaleway TEM

## 🔐 Security Note

**NEVER** commit API keys or private keys to Git!
- Store in 1Password
- Use environment variables
- Use GitHub Secrets for CI/CD

---

*Remember: DNS changes can take up to 48 hours to fully propagate, though typically complete within 5-60 minutes.*