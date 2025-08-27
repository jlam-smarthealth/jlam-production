# Scaleway TEM (Transactional Email) Setup Guide

## Current Status
- **Organization ID**: c57d808d-1af5-4117-9edc-a4f5680611e6
- **Region**: nl-ams (Amsterdam)
- **Service Status**: Not yet activated

## Steps to Enable TEM and Get SMTP Credentials

### 1. Activate TEM Service via Scaleway Console
1. Login to [Scaleway Console](https://console.scaleway.com)
2. Navigate to **Messaging** → **Transactional Email**
3. Click **Activate TEM** for your project
4. Select the **nl-ams** region

### 2. Configure Domain
Once TEM is activated:
1. Go to **Domains** section
2. Add domain: `jlam.nl`
3. You'll receive DNS records to add:
   - SPF record
   - DKIM records
   - Optional: DMARC record

### 3. Generate SMTP Credentials
After domain verification:
1. Go to **SMTP Credentials** section
2. Click **Generate new SMTP credentials**
3. Name: `authentik-smtp`
4. Save the generated password immediately!

### 4. SMTP Configuration for Authentik

```env
# Add to authentik/.env
AUTHENTIK_EMAIL__HOST=smtp.tem.scw.cloud
AUTHENTIK_EMAIL__PORT=587
AUTHENTIK_EMAIL__USERNAME=c57d808d-1af5-4117-9edc-a4f5680611e6
AUTHENTIK_EMAIL__PASSWORD=<GENERATED_SMTP_PASSWORD>
AUTHENTIK_EMAIL__USE_TLS=true
AUTHENTIK_EMAIL__USE_SSL=false
AUTHENTIK_EMAIL__FROM=noreply@jlam.nl
```

### 5. Store in 1Password
Create new item in **JLAM Operations** vault:
- **Title**: Scaleway TEM SMTP Credentials
- **Username**: c57d808d-1af5-4117-9edc-a4f5680611e6
- **Password**: [Generated SMTP password]
- **Host**: smtp.tem.scw.cloud
- **Port**: 587
- **Notes**: Used for Authentik SSO email notifications

## Alternative: Use API to Create SMTP Credentials

Once TEM is activated, you can use the CLI:

```bash
# List existing SMTP credentials
scw tem smtp-credential list

# Create new SMTP credential
scw tem smtp-credential create \
  name=authentik-smtp \
  project-id=<project-id>

# The response will include the password - save it immediately!
```

## DNS Records Required

You'll need to add these to your DNS provider:

1. **SPF Record** (TXT):
   ```
   v=spf1 include:_spf.scw-tem.cloud ~all
   ```

2. **DKIM Records** (will be provided by Scaleway)

3. **DMARC Record** (TXT, optional but recommended):
   ```
   _dmarc.jlam.nl.  IN  TXT  "v=DMARC1; p=quarantine; rua=mailto:dmarc@jlam.nl"
   ```

## Testing Email Configuration

Once configured, test in Authentik:
1. Go to Authentik Admin → System → System Tasks
2. Run the email test task
3. Check logs for any errors

## Troubleshooting

- **Port 587**: Standard SMTP submission port with STARTTLS
- **Port 465**: Alternative SSL/TLS port (if needed)
- **Authentication**: Always use the organization ID as username
- **TLS**: Must be enabled for security
- **Rate limits**: Check Scaleway documentation for sending limits

## Security Notes

⚠️ **NEVER** commit SMTP passwords to git
⚠️ **ALWAYS** use environment variables
⚠️ **STORE** credentials in 1Password immediately
⚠️ **ROTATE** credentials periodically

## Contact Support

If you encounter issues:
- Scaleway Support: https://console.scaleway.com/support
- Check service status: https://status.scaleway.com/