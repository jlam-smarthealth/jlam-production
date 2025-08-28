# 🔒 JLAM Universal SSL Certificate Module

**Enterprise-grade SSL certificate deployment for all JLAM environments**

## 🎯 Purpose
Reusable Terraform module that deploys *.jlam.nl wildcard SSL certificates to any JLAM server via cloud-init. Works identically across development, staging, and production environments.

## ✅ Features
- **Universal**: Works for all environments (dev/staging/production)
- **Secure**: Certificates stored in Terraform Cloud encrypted variables
- **Automated**: Deployed via cloud-init (Infrastructure as Code)
- **Consistent**: Same SSL setup across all servers
- **Validated**: Environment validation built-in

## 📋 Usage

### 1. In your main Terraform configuration:

```hcl
module "ssl_certificates" {
  source = "./modules/jlam-ssl"
  
  environment      = "development"  # or "staging" or "production"
  ssl_certificate  = var.ssl_certificate
  ssl_private_key  = var.ssl_private_key
  ssl_ca_bundle    = var.ssl_ca_bundle  # optional
  ssl_directory    = "/tmp/jlam-ssl"    # optional, defaults to this
}

resource "scaleway_instance_server" "app" {
  name  = "jlam-${module.ssl_certificates.environment}"
  # ... other configuration ...
  
  cloud_init = templatefile("${path.module}/cloud-init.yml", {
    ssl_write_files = module.ssl_certificates.cloud_init_write_files
    ssl_runcmds     = module.ssl_certificates.cloud_init_runcmds
    ssl_directory   = module.ssl_certificates.ssl_directory
  })
}
```

### 2. In your cloud-init.yml template:

```yaml
#cloud-config
write_files:
%{ for file in ssl_write_files ~}
  - path: ${file.path}
    content: |
      ${file.content}
    permissions: '${file.permissions}'
    owner: ${file.owner}
%{ endfor ~}

runcmd:
%{ for cmd in ssl_runcmds ~}
  - ${cmd}
%{ endfor ~}
  # Your other runcmd entries...
```

## 🔐 Required Terraform Cloud Variables

Add these as **sensitive variables** in your Terraform Cloud workspace:

| Variable Name | Type | Sensitive | Description |
|---------------|------|-----------|-------------|
| `ssl_certificate` | string | ✅ Yes | Complete *.jlam.nl certificate content |
| `ssl_private_key` | string | ✅ Yes | Private key content |
| `ssl_ca_bundle` | string | ✅ Yes | CA bundle/chain (optional) |

## 📁 Generated File Structure

```
/tmp/jlam-ssl/
├── cert.pem     (0600, root:root)
├── key.pem      (0600, root:root)  
└── ca-bundle.pem (0644, root:root) [if provided]
```

## 🚀 Benefits

✅ **DRY Principle**: Write once, use everywhere
✅ **Security**: Certificates encrypted in Terraform Cloud
✅ **Consistency**: Identical SSL setup across all environments
✅ **Automation**: No manual certificate deployment
✅ **Infrastructure as Code**: Fully reproducible
✅ **Validation**: Environment name validation built-in

## 🔄 Environments Supported

- **development**: Development servers (dev.jlam.nl)
- **staging**: Staging servers (staging.jlam.nl)  
- **production**: Production servers (app.jlam.nl)

---

## 🚨 CRITICAL WARNINGS

**🛡️ SECURITY NOTE:** Never commit SSL certificates to git repositories. Always use Terraform Cloud encrypted workspace variables.

**⚠️ IP PRESERVATION CRITICAL:** NEVER change existing server IPs! DNS records depend on stable IPs:
- Development: 51.158.166.152 (dev.jlam.nl)  
- Staging: [Existing IP - DO NOT CHANGE]
- Production: [Existing IP - DO NOT CHANGE]

**Before any terraform apply:**
1. Check existing resources: `terraform import` if servers exist
2. Verify IP addresses won't change
3. Test with `terraform plan` first
4. NEVER destroy/recreate existing servers