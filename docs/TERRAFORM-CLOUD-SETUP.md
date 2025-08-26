# ☁️ Terraform Cloud Setup Guide
*Enterprise state management voor JLAM Production Infrastructure*

---

## 🎯 **WAAROM TERRAFORM CLOUD?**

### **Enterprise Benefits:**
- ✅ **Remote state management**: Geen lokale .tfstate files meer
- ✅ **Team collaboration**: Multiple developers kunnen veilig deployen
- ✅ **State locking**: Voorkomt concurrent modifications  
- ✅ **Audit trail**: Complete deployment geschiedenis
- ✅ **Secrets management**: Veilige environment variables
- ✅ **Free tier**: Tot 5 users gratis - perfect voor JLAM

### **vs Lokale State Problems:**
- ❌ `.tfstate` files kunnen corrupt raken
- ❌ Concurrent deployments veroorzaken conflicts
- ❌ State files bevatten secrets (security risk)
- ❌ Geen backup/restore capabilities
- ❌ Geen deployment geschiedenis

---

## 🚀 **SETUP PROCESS**

### **Step 1: Create Terraform Cloud Account**
1. Go to: https://app.terraform.io/signup
2. Create account met je email
3. **Organization name**: `jlam` 
4. Choose **Free tier** (perfect voor ons)

### **Step 2: Create Workspace**
```bash
# In Terraform Cloud dashboard:
1. Click "New Workspace"
2. Choose "Version control workflow"
3. Connect GitHub repository: "jlam-production"
4. Workspace name: "jlam-production"
5. Advanced settings:
   - Working Directory: "terraform/"
   - Auto apply: Disabled (for safety)
```

### **Step 3: Configure Environment Variables**
In Terraform Cloud workspace → Variables, add:

**Terraform Variables** (TF_VAR_):
```bash
# Database Configuration
TF_VAR_jlam_database_host        = "[your-database-host]" (SENSITIVE)
TF_VAR_jlam_database_port        = "20832"  
TF_VAR_jlam_database_user        = "jlam_user"
TF_VAR_jlam_database_password    = "your-password" (SENSITIVE)
TF_VAR_jlam_database_name        = "rdb"

# Application Configuration
TF_VAR_secret_key_base           = "your-64-char-key" (SENSITIVE)
TF_VAR_deployment_timestamp      = "2025-08-26"
```

**Environment Variables**:
```bash
# Scaleway Provider
SCALEWAY_ACCESS_KEY              = "your-access-key" (SENSITIVE)
SCALEWAY_SECRET_KEY              = "your-secret-key" (SENSITIVE)
SCALEWAY_DEFAULT_PROJECT_ID      = "your-project-id"
SCALEWAY_DEFAULT_ORGANIZATION_ID = "your-org-id"
SCW_DEFAULT_ZONE                 = "nl-ams-1"
SCW_DEFAULT_REGION               = "nl-ams"
```

### **Step 4: GitHub Integration**
```bash
# In repository Settings → Secrets:
TERRAFORM_CLOUD_API_TOKEN        = "your-tf-cloud-api-token"

# Get API token from:
# Terraform Cloud → User Settings → Tokens → Create API token
```

---

## 🔧 **CONFIGURATION FILES**

### **Workspace Settings:**
```json
{
  "name": "jlam-production",
  "working_directory": "terraform/",
  "trigger_prefixes": ["terraform/"],
  "auto_apply": false,
  "terraform_version": "1.7.0",
  "execution_mode": "remote"
}
```

### **Required Provider Configuration:**
Onze `terraform/main.tf` bevat al:
```hcl
terraform {
  cloud {
    organization = "jlam"
    workspaces {
      name = "jlam-production"
    }
  }
}
```

---

## 🎯 **DEPLOYMENT WORKFLOWS**

### **Method 1: GitHub Actions (Recommended)**
GitHub Actions automatically triggers Terraform Cloud:
```yaml
# In .github/workflows/production-deploy.yml
- name: Setup Terraform
  uses: hashicorp/setup-terraform@v3
  with:
    cli_config_credentials_token: ${{ secrets.TERRAFORM_CLOUD_API_TOKEN }}

- name: Terraform Plan
  run: terraform plan

- name: Terraform Apply  
  run: terraform apply -auto-approve
```

### **Method 2: Direct Terraform Cloud**
1. Push code changes to GitHub
2. Terraform Cloud auto-detects changes
3. Plan runs automatically
4. Manual approval required for apply (safety)

### **Method 3: Local CLI (Development)**
```bash
# Install Terraform Cloud CLI
terraform login

# Plan deployment
cd terraform/
terraform plan

# Apply (with Terraform Cloud backend)
terraform apply
```

---

## 📊 **MONITORING & MANAGEMENT**

### **Terraform Cloud Dashboard:**
- **Runs**: See all deployment history
- **State**: Browse current infrastructure state
- **Variables**: Manage secrets and configuration
- **Settings**: Workspace configuration
- **Costs**: Track infrastructure costs (estimate)

### **Key URLs:**
- **Organization**: https://app.terraform.io/app/jlam
- **Workspace**: https://app.terraform.io/app/jlam/workspaces/jlam-production
- **Runs History**: https://app.terraform.io/app/jlam/workspaces/jlam-production/runs

### **Monitoring Commands:**
```bash
# Check workspace status
terraform workspace show

# View current state
terraform state list

# Check recent runs
# (via Terraform Cloud web interface)
```

---

## 🚨 **TROUBLESHOOTING**

### **Common Issues:**

#### **1. Authentication Problems**
```bash
# Error: "Invalid workspace configuration"
Solution:
- Verify organization name: "jlam"
- Verify workspace name: "jlam-production"
- Check API token is correctly configured

# Test authentication:
terraform login
terraform workspace list
```

#### **2. Variable Configuration**
```bash
# Error: "Required variable not set"
Solution:
- Check all TF_VAR_ variables are set in workspace
- Verify SENSITIVE flag is set for passwords
- Ensure variable names match exactly (case sensitive)
```

#### **3. State Lock Issues**
```bash
# Error: "State locked by another operation"
Solution:
- Wait for current operation to complete
- Check Terraform Cloud runs dashboard
- Force unlock only if run is truly stuck:
  terraform force-unlock <lock-id>
```

#### **4. GitHub Integration**
```bash
# Error: "Failed to retrieve workspace"
Solution:
- Verify TERRAFORM_CLOUD_API_TOKEN in GitHub secrets
- Check workspace has correct GitHub repository connected
- Ensure working directory is set to "terraform/"
```

---

## 🔐 **SECURITY BEST PRACTICES**

### **Secrets Management:**
- ✅ All secrets marked as SENSITIVE in Terraform Cloud
- ✅ API tokens stored in GitHub Secrets only
- ✅ No secrets in code or state files
- ✅ Workspace access restricted to team members

### **Access Control:**
```bash
# Terraform Cloud Team Settings:
- Owners: Full access
- Contributors: Plan/Apply permissions
- Viewers: Read-only access

# GitHub Repository Protection:
- Require pull request reviews
- Restrict pushes to main branch
- Require status checks (including Terraform)
```

### **Audit Trail:**
- All deployments logged in Terraform Cloud
- Git commits linked to Terraform runs
- Variables changes tracked
- API access logged

---

## 💰 **COST MANAGEMENT**

### **Free Tier Limits:**
- ✅ **5 users**: Perfect voor JLAM team
- ✅ **Unlimited private workspaces**
- ✅ **State management & locking**
- ✅ **Remote operations**
- ✅ **Variable management**

### **Usage Monitoring:**
```bash
# Check current usage:
# Terraform Cloud → Settings → Billing

# Resource cost estimation:
# Automatic cost estimation in plan output
```

---

## 🎉 **SUCCESS CRITERIA**

### **Setup Complete When:**
- ✅ Terraform Cloud workspace created
- ✅ All variables configured (sensitive marked)
- ✅ GitHub integration working
- ✅ First successful plan/apply via GitHub Actions
- ✅ State stored remotely (no local .tfstate)
- ✅ Team members have appropriate access

### **Daily Operations:**
- ✅ Push to GitHub triggers Terraform plan
- ✅ Manual approval required for production apply
- ✅ All deployments auditable in dashboard
- ✅ State always consistent and backed up

---

## 📞 **SUPPORT RESOURCES**

### **Documentation:**
- **Terraform Cloud Docs**: https://developer.hashicorp.com/terraform/cloud-docs
- **GitHub Actions Integration**: https://developer.hashicorp.com/terraform/cloud-docs/vcs/github-actions
- **Scaleway Provider**: https://registry.terraform.io/providers/scaleway/scaleway

### **Emergency Procedures:**
```bash
# If Terraform Cloud is down:
1. Use local state temporarily:
   terraform init -migrate-state
2. Apply changes locally
3. Re-migrate to cloud when available:
   terraform init -migrate-state

# State corruption recovery:
1. Download state backup from Terraform Cloud
2. Restore from known good state
3. Investigate and fix root cause
```

---

**🏆 Result**: Enterprise-grade infrastructure management met professional state backend, team collaboration ready, en zero local state file problemen!