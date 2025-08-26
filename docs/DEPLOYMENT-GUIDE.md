# 🚀 JLAM Production Deployment Guide
*Complete step-by-step deployment instructions*

---

## 📋 **PRE-DEPLOYMENT CHECKLIST**

### **1. Required Secrets (GitHub Secrets)**
Configure these secrets in your GitHub repository settings:

```bash
# Scaleway Configuration
SCALEWAY_ACCESS_KEY              # Your Scaleway API access key
SCALEWAY_SECRET_KEY              # Your Scaleway API secret key  
SCALEWAY_DEFAULT_PROJECT_ID      # Scaleway project ID
SCALEWAY_DEFAULT_ORGANIZATION_ID # Scaleway organization ID

# Database Configuration (Scaleway PostgreSQL)
JLAM_DATABASE_HOST               # Database host (SENSITIVE - set in Terraform Cloud)
JLAM_DATABASE_PORT               # Database port (e.g., 20832)
JLAM_DATABASE_USER               # Database username
JLAM_DATABASE_PASSWORD           # Database password (min 12 chars)
JLAM_DATABASE_NAME               # Database name (e.g., rdb)

# Application Configuration
SECRET_KEY_BASE                  # App secret key (min 64 chars)
```

### **2. SSH Key Setup**
Ensure your SSH key is available:
```bash
# Verify SSH key exists
ls -la ~/.ssh/jlam_tunnel_key*

# If not, create one:
ssh-keygen -t rsa -b 4096 -f ~/.ssh/jlam_tunnel_key -C "jlam-production"
```

### **3. SSL Certificates (Optional)**
If using custom SSL certificates, place them in:
```bash
config/ssl/certificate.crt   # Your SSL certificate
config/ssl/certificate.key   # Private key (never commit!)
config/ssl/cabundle.crt      # Certificate authority bundle
```

**Note**: If no custom certificates, Let's Encrypt will be used automatically.

---

## 🏗️ **DEPLOYMENT METHODS**

### **Method 1: GitHub Actions (Recommended)**

#### **Automatic Deployment:**
```bash
# Push to main branch triggers deployment
git add .
git commit -m "Deploy JLAM production infrastructure"
git push origin main
```

#### **Manual Deployment:**
1. Go to GitHub → Actions → "JLAM Production Deployment"
2. Click "Run workflow"
3. Select deployment type: `full-deployment`
4. Click "Run workflow"

#### **Emergency Rollback:**
1. Go to GitHub → Actions → "JLAM Production Deployment"  
2. Click "Run workflow"
3. Select deployment type: `emergency-rollback`
4. Click "Run workflow"

### **Method 2: Local Terraform (Advanced)**

#### **Prerequisites:**
```bash
# Install Terraform
brew install terraform  # macOS
# or download from: https://terraform.io/downloads

# Configure Scaleway CLI
brew install scw
scw init
```

#### **Local Deployment:**
```bash
cd terraform/

# Initialize Terraform
terraform init

# Create terraform.tfvars file:
cat > terraform.tfvars << EOF
jlam_database_host     = "your-database-host"
jlam_database_port     = "20832"
jlam_database_user     = "your-db-user"
jlam_database_password = "your-db-password"
jlam_database_name     = "rdb"
secret_key_base        = "your-64-char-secret-key"
EOF

# Plan deployment
terraform plan

# Deploy infrastructure
terraform apply
```

---

## 📊 **DEPLOYMENT MONITORING**

### **GitHub Actions Progress:**
1. **Security Validation** (2-3 minutes)
   - Secret scanning
   - Configuration validation
   - Makefile checks

2. **Terraform Validation** (1-2 minutes)
   - Syntax validation
   - Provider setup
   - Resource planning

3. **Production Deployment** (5-10 minutes)
   - Infrastructure provisioning
   - Server configuration
   - Service deployment

4. **Health Validation** (5-10 minutes)
   - Service startup
   - Endpoint testing
   - Performance validation

**Total Time**: ~15-25 minutes

### **Deployment Status Monitoring:**
```bash
# Monitor GitHub Actions
# Go to: https://github.com/your-org/jlam-production/actions

# SSH to server during deployment
ssh -i ~/.ssh/jlam_tunnel_key jlam@51.158.190.109

# Monitor startup logs
tail -f /var/log/jlam-startup.log
tail -f /var/log/cloud-init-output.log

# Check service status
make status
make health
```

---

## 🏥 **POST-DEPLOYMENT VERIFICATION**

### **1. Health Checks (Automatic)**
The deployment includes automatic health checks:
- ✅ Main application: https://app.jlam.nl
- ✅ Health endpoint: https://app.jlam.nl/health
- ✅ IP retention: 51.158.190.109 verified
- ✅ Response time: < 2 seconds

### **2. Manual Verification:**
```bash
# Test main endpoints
curl -I https://app.jlam.nl
curl -I https://app.jlam.nl/health

# Check Traefik dashboard  
curl -I http://51.158.190.109:8080

# Verify SSL certificate
openssl s_client -connect app.jlam.nl:443 -servername app.jlam.nl

# DNS verification
nslookup app.jlam.nl
# Should return: 51.158.190.109
```

### **3. Performance Verification:**
```bash
# SSH to server
ssh -i ~/.ssh/jlam_tunnel_key jlam@51.158.190.109

# Check system resources
htop
df -h
docker stats

# Verify enterprise patterns
make health
make performance
make test
```

---

## 🚨 **TROUBLESHOOTING**

### **Common Issues & Solutions:**

#### **1. GitHub Actions Failing**
```bash
# Check secrets are configured
# Go to: Repository Settings → Secrets and Variables → Actions

# Common missing secrets:
- SCALEWAY_ACCESS_KEY
- SCALEWAY_SECRET_KEY  
- JLAM_DATABASE_PASSWORD
- SECRET_KEY_BASE
```

#### **2. SSL Certificate Issues**
```bash
# If using Let's Encrypt (automatic):
- Domain must point to server IP (51.158.190.109)
- Ports 80/443 must be accessible
- DNS propagation can take 24-48 hours

# If using custom certificates:
- Check certificate files are in config/ssl/
- Verify certificate is not expired
- Ensure private key matches certificate
```

#### **3. Database Connection Issues**
```bash
# Test database connection
telnet your-database-host 20832

# Verify credentials in GitHub Secrets
# Check database server firewall allows connections from server IP
```

#### **4. Service Startup Issues**
```bash
# SSH to server and check logs
ssh -i ~/.ssh/jlam_tunnel_key jlam@51.158.190.109

# Check cloud-init logs
tail -f /var/log/cloud-init-output.log

# Check startup logs  
tail -f /var/log/jlam-startup.log

# Check Docker services
docker ps -a
docker-compose logs
```

### **Emergency Recovery:**

#### **Rollback Deployment:**
1. Use GitHub Actions "emergency-rollback" option
2. Or SSH to server and restore previous version:
```bash
ssh -i ~/.ssh/jlam_tunnel_key jlam@51.158.190.109
cd /home/jlam
docker-compose down
# Restore previous docker-compose.yml backup
docker-compose up -d
```

#### **Complete Infrastructure Reset:**
If needed, you can rebuild the entire server:
1. The IP address (51.158.190.109) will be retained
2. All data will be lost (ensure backups exist)
3. Fresh deployment will take ~20-30 minutes

---

## 📈 **SCALING & OPTIMIZATION**

### **Performance Monitoring:**
```bash
# SSH to server
ssh -i ~/.ssh/jlam_tunnel_key jlam@51.158.190.109

# Monitor resources
make performance
docker stats --no-stream

# Check logs for performance issues
docker-compose logs | grep ERROR
```

### **Scaling Options:**
1. **Vertical Scaling**: Upgrade server type in `variables.tf`
   - Current: DEV1-L (2 vCPUs, 4GB RAM)
   - Upgrade to: GP1-M (4 vCPUs, 8GB RAM)

2. **Horizontal Scaling**: Add more services
   - Redis caching
   - PostgreSQL read replicas
   - Load balancer instances

---

## 🔧 **MAINTENANCE**

### **Regular Tasks:**
```bash
# Monthly SSL certificate check
make test

# System updates (automated via cloud-init)
ssh -i ~/.ssh/jlam_tunnel_key jlam@51.158.190.109
sudo apt update && sudo apt upgrade -y

# Docker cleanup
make clean

# Backup verification
# (Configure backup strategy based on your needs)
```

### **Security Updates:**
- SSL certificates auto-renew via Let's Encrypt
- System packages auto-update (if enabled)
- Docker images should be updated manually

---

## 📞 **SUPPORT & CONTACTS**

### **Repository Information:**
- **Repository**: jlam-production (clean enterprise setup)
- **Architecture**: ODIN Enterprise Patterns
- **Deployment Method**: Infrastructure as Code (Terraform)
- **CI/CD**: GitHub Actions

### **Key URLs:**
- **Production App**: https://app.jlam.nl
- **Health Check**: https://app.jlam.nl/health  
- **Traefik Dashboard**: http://51.158.190.109:8080
- **GitHub Actions**: Repository → Actions tab

### **Emergency Procedures:**
1. **Service Down**: Use GitHub Actions emergency-rollback
2. **Complete Outage**: SSH access via `ssh -i ~/.ssh/jlam_tunnel_key jlam@51.158.190.109`
3. **DNS Issues**: Verify 51.158.190.109 IP retention
4. **SSL Issues**: Let's Encrypt logs in `/home/jlam/letsencrypt/`

---

**🎉 Success!** You now have a clean, enterprise-ready JLAM production infrastructure that deploys in ~15-25 minutes with zero technical debt!