# 🌍 Multi-Environment Deployment Guide
*Enterprise Migration Strategy: Production → Staging + New Production*

---

## 🎯 **DEPLOYMENT STRATEGY OVERVIEW**

### **Current Situation:**
- **Existing Production Server**: 51.158.190.109 (working configuration)
- **Goal**: Convert to staging + deploy clean config to new production

### **Migration Strategy:**
```
Current Production (51.158.190.109) → Staging Environment (testing)
                    ↓
               New Server → Production Environment (clean deployment)
```

---

## 🏗️ **TERRAFORM CLOUD WORKSPACE SETUP**

### **Required Workspaces:**
1. **`jlam-staging`**:
   - Target: Current server (51.158.190.109)
   - Purpose: Test clean configuration
   - Working Directory: `environments/staging/`

2. **`jlam-production`**:
   - Target: New server (fresh provision)
   - Purpose: Clean production deployment
   - Working Directory: `environments/production/`

### **Workspace Configuration:**
```bash
# Terraform Cloud Settings:
Organization: jlam
Workspaces:
├── jlam-staging (existing IP: 51.158.190.109)
└── jlam-production (new IP: provisioned)

# Environment Variables (both workspaces):
SCALEWAY_ACCESS_KEY              = [secret]
SCALEWAY_SECRET_KEY              = [secret]
SCALEWAY_DEFAULT_PROJECT_ID      = [value]
SCALEWAY_DEFAULT_ORGANIZATION_ID = [value]

# Terraform Variables (per workspace):
TF_VAR_jlam_database_host        = [secret]
TF_VAR_jlam_database_password    = [secret]
TF_VAR_secret_key_base           = [secret]
```

---

## 📊 **ENVIRONMENT COMPARISON**

| Aspect | Staging (51.158.190.109) | Production (New Server) |
|--------|---------------------------|--------------------------|
| **Purpose** | Test clean config | Enterprise production |
| **Server** | Existing (reused) | Fresh provision |
| **IP Address** | 51.158.190.109 | New static IP |
| **SSL** | Let's Encrypt | Sectigo wildcard |
| **Security** | Permissive (testing) | Enterprise hardened |
| **Storage** | 20GB | 50GB |
| **Backup** | 7 days | 30 days |
| **DNS** | staging.jlam.nl | app.jlam.nl (after cutover) |

---

## 🚀 **PHASE 1: STAGING DEPLOYMENT**

### **Objective**: Deploy clean configuration to existing server for testing

#### **Step 1: Terraform Cloud Staging Workspace**
```bash
# Create workspace in Terraform Cloud:
Organization: jlam
Workspace: jlam-staging
Working Directory: environments/staging/
Auto Apply: Disabled (manual approval)
```

#### **Step 2: Configure Variables**
```bash
# In jlam-staging workspace variables:
TF_VAR_jlam_database_host     = "[your-database-host]" (SENSITIVE)
TF_VAR_jlam_database_port     = "20832"
TF_VAR_jlam_database_user     = "jlam_user"
TF_VAR_jlam_database_password = [your-password] (SENSITIVE)
TF_VAR_jlam_database_name     = "rdb"
TF_VAR_secret_key_base        = [your-secret] (SENSITIVE)
```

#### **Step 3: Deploy to Staging**
```bash
# Via GitHub Actions or Terraform Cloud:
cd environments/staging/
terraform init
terraform plan    # Review changes to existing server
terraform apply   # Deploy clean configuration
```

#### **Step 4: Verify Staging**
```bash
# Test staging deployment:
curl -I http://51.158.190.109/health
curl -I https://staging.jlam.nl/health  # If DNS configured

# Expected Results:
✅ Clean docker-compose configuration
✅ Enterprise health checks working
✅ Security headers applied
✅ Performance optimizations active
✅ Makefile productivity tools
```

---

## 🏭 **PHASE 2: PRODUCTION DEPLOYMENT**

### **Objective**: Deploy clean configuration to new fresh server

#### **Step 1: Terraform Cloud Production Workspace**
```bash
# Create workspace in Terraform Cloud:
Organization: jlam  
Workspace: jlam-production
Working Directory: environments/production/
Auto Apply: Disabled (manual approval required)
```

#### **Step 2: Configure Production Variables**
```bash
# Same variables as staging, production values:
TF_VAR_jlam_database_host     = "[your-database-host]" (SENSITIVE)
TF_VAR_jlam_database_port     = "20832"
TF_VAR_jlam_database_user     = "jlam_user"  
TF_VAR_jlam_database_password = [your-password] (SENSITIVE)
TF_VAR_jlam_database_name     = "rdb"
TF_VAR_secret_key_base        = [your-secret] (SENSITIVE)
```

#### **Step 3: Deploy Production**
```bash
# Via GitHub Actions or Terraform Cloud:
cd environments/production/
terraform init
terraform plan    # Review new server creation
terraform apply   # Provision new production server

# Note: This creates a NEW server with NEW IP address
```

#### **Step 4: Get New Production IP**
```bash
# From Terraform output:
terraform output new_production_ip
# Example output: 51.158.xxx.xxx (new IP)
```

#### **Step 5: Verify Production (Before DNS)**
```bash
# Test production deployment on new IP:
NEW_IP=$(terraform output -raw new_production_ip)
curl -I http://$NEW_IP/health
curl -I http://$NEW_IP:8080  # Traefik dashboard

# Expected Results:
✅ Fresh server with clean configuration
✅ All enterprise patterns working  
✅ SSL certificates configured
✅ Performance optimized
✅ Security hardened
```

---

## 🌐 **PHASE 3: DNS CUTOVER**

### **Objective**: Switch production traffic to new server

#### **DNS Update Required:**
```bash
# Current DNS (pointing to staging):
app.jlam.nl      A  51.158.190.109
auth.jlam.nl     A  51.158.190.109  
monitor.jlam.nl  A  51.158.190.109

# New DNS (pointing to production):
app.jlam.nl      A  [new-production-ip]
auth.jlam.nl     A  [new-production-ip]
monitor.jlam.nl  A  [new-production-ip]

# Optional staging DNS:
staging.jlam.nl  A  51.158.190.109
```

#### **Cutover Process:**
1. **Verify Production Health**: All endpoints responding
2. **Update DNS Records**: Point to new production IP  
3. **Monitor DNS Propagation**: 15 minutes to 48 hours
4. **Verify Production URLs**: Test all app.jlam.nl endpoints
5. **Monitor Performance**: Check response times and errors

#### **Rollback Plan:**
```bash
# If issues occur, revert DNS:
app.jlam.nl      A  51.158.190.109  # Back to staging
auth.jlam.nl     A  51.158.190.109  # Back to staging
monitor.jlam.nl  A  51.158.190.109  # Back to staging
```

---

## 📋 **DEPLOYMENT CHECKLIST**

### **Pre-Deployment:**
- [ ] Terraform Cloud workspaces created (`jlam-staging`, `jlam-production`)
- [ ] Environment variables configured (both workspaces)
- [ ] GitHub Actions updated for multi-environment
- [ ] SSL certificates ready (staging: Let's Encrypt, production: Sectigo)
- [ ] Database connectivity verified
- [ ] Backup procedures in place

### **Staging Deployment:**
- [ ] Deploy clean config to existing server (51.158.190.109)
- [ ] Verify all enterprise patterns working
- [ ] Test health checks and monitoring
- [ ] Validate security headers and performance
- [ ] Confirm Makefile productivity tools work

### **Production Deployment:**
- [ ] Deploy clean config to new fresh server
- [ ] Verify new server IP and accessibility
- [ ] Test all endpoints on new IP (before DNS)
- [ ] Validate SSL certificates working
- [ ] Confirm enterprise security hardening
- [ ] Performance test under load

### **DNS Cutover:**
- [ ] Update DNS records to new production IP
- [ ] Monitor DNS propagation globally  
- [ ] Test all production URLs (app.jlam.nl, auth.jlam.nl, etc.)
- [ ] Monitor application performance and errors
- [ ] Verify staging still works as rollback option

### **Post-Deployment:**
- [ ] Monitor production for 24-48 hours
- [ ] Backup verification on both environments
- [ ] Team access to both staging and production
- [ ] Documentation updated with new IPs and URLs
- [ ] Incident response procedures tested

---

## 🚨 **TROUBLESHOOTING**

### **Common Issues:**

#### **Staging Deployment Fails:**
```bash
# Check existing server state:
ssh -i ~/.ssh/jlam_tunnel_key jlam@51.158.190.109
docker ps -a
systemctl status docker

# Terraform state conflicts:
terraform state list
terraform refresh
```

#### **Production Deployment Fails:**
```bash
# Check Terraform Cloud logs
# Verify Scaleway quotas and limits
# Check security group rules
# Validate cloud-init template
```

#### **DNS Issues:**
```bash
# Check DNS propagation:
dig app.jlam.nl @8.8.8.8
nslookup app.jlam.nl

# Test direct IP access:
curl -I http://[new-production-ip]/health
```

### **Emergency Rollback:**
1. **Immediate**: Update DNS back to staging (51.158.190.109)
2. **Investigation**: Check production server logs and health
3. **Fix**: Address issues on production server
4. **Re-cutover**: When production is stable

---

## 📈 **SUCCESS METRICS**

### **Staging Success:**
- ✅ Clean configuration deployed to existing server
- ✅ Zero downtime during migration
- ✅ All enterprise patterns working
- ✅ Performance equivalent to original
- ✅ Ready for production deployment testing

### **Production Success:**
- ✅ Fresh server with clean configuration  
- ✅ New IP address accessible and stable
- ✅ Enterprise security and performance
- ✅ SSL certificates working properly
- ✅ Ready for DNS cutover

### **Migration Success:**
- ✅ Production traffic on new clean server
- ✅ Staging environment available for testing  
- ✅ DNS cutover successful with no downtime
- ✅ Both environments monitored and backed up
- ✅ Team has access to both environments

---

**🎯 Result**: Clean enterprise infrastructure with staging for testing and production for live traffic, zero technical debt, full rollback capabilities!