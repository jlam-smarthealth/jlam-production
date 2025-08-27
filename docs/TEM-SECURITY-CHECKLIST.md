# Scaleway TEM Security Checklist for JLAM
*Created: 2025-01-27*

## 🔐 SMTP Credentials Security

### ✅ Required Actions:
- [ ] Store SMTP credentials ONLY in `.env` files (never in code)
- [ ] Ensure `.env` files are in `.gitignore`
- [ ] Use strong, unique passwords for SMTP authentication
- [ ] Rotate SMTP credentials every 90 days
- [ ] Store backup credentials in 1Password or secure vault

### ✅ TEM Configuration Security:
- [ ] Enable SPF record: `v=spf1 include:_spf.scw-tem.cloud ~all`
- [ ] Configure DKIM signing in TEM console
- [ ] Set up DMARC policy: `v=DMARC1; p=quarantine; ruf=admin@jlam.nl`
- [ ] Monitor email delivery rates and reputation
- [ ] Configure bounce/complaint handling

### ✅ Authentik Integration Security:
- [ ] Use TLS encryption (port 587, not 25)
- [ ] Configure proper FROM address (noreply@jlam.nl)
- [ ] Set up email template customization
- [ ] Enable email verification for new users
- [ ] Configure password reset email templates
- [ ] Test email delivery in staging first

### ✅ Monitoring & Alerts:
- [ ] Set up delivery failure alerts
- [ ] Monitor bounce rates (<5%)
- [ ] Track spam complaint rates (<0.1%)
- [ ] Configure email rate limiting
- [ ] Monitor TEM quota usage

## 🚨 Security Red Flags:
- Using port 25 (unencrypted)
- SMTP credentials in code/logs
- Missing SPF/DKIM/DMARC records
- High bounce/complaint rates
- No email delivery monitoring

## 📧 Email Templates:
Customize these in Authentik for JLAM branding:
- Password reset emails
- Account verification emails
- Login notification emails
- Admin alert emails

## 🔧 Troubleshooting:
1. Check TEM dashboard for delivery stats
2. Verify DNS records (MX, SPF, DKIM, DMARC)
3. Test SMTP connectivity: `scripts/test-smtp-config.sh`
4. Check Authentik logs: `docker logs authentik-server`
5. Validate email templates in Authentik admin