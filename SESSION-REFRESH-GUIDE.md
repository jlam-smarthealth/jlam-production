# 🔄 Claude Session Refresh Guide
*For maintaining context when starting new Claude Code sessions*  
*Last Updated: 2025-08-26*

---

## 🚨 CRITICAL CONTEXT - Read This First

### 🏥 **Project Overview**
- **Platform**: JLAM (Je Leefstijl Als Medicijn) - Healthcare transformation platform
- **Mission**: Transform 8 billion people from pharmaceutical dependency to lifestyle medicine
- **Owner**: JAFFAR (Wim Tilburgs) - 65-year-old veteran who overcame diabetes without medication
- **Status**: Production platform serving 447+ users, scaling to 10,000+

### 🏗️ **Infrastructure Status** (as of Aug 26, 2025)
- **Production Server**: 51.158.190.109 (Scaleway DEV1-L, 2 vCPU, 4GB RAM)
- **Main Database**: 51.158.130.103:20832 (JLAM application data)
- **Auth Database**: 51.158.128.5:5457 (Authentik SSO - NEW as of today)
- **Domains**: 
  - Main: https://app.jlam.nl ✅ Working
  - Auth: https://auth.jlam.nl ⚠️ Recently deployed
  - Monitor: https://monitor.jlam.nl

---

## 🛠️ CURRENT INFRASTRUCTURE STATE

### **Recently Completed Work**
**Date**: August 26, 2025  
**Task**: Authentik SSO Installation with Dedicated Database

#### ✅ **What's Working**:
```yaml
Services Running:
  - jlam-traefik: ✅ Healthy (ports 80, 443, 8080)
  - jlam-web: ✅ Healthy (nginx serving app.jlam.nl)
  - jlam-authentik-server: ✅ Healthy (connected to 51.158.128.5:5457)
  - jlam-authentik-worker: ✅ Healthy
  - jlam-authentik-redis: ✅ Healthy

Database Connections:
  - Main JLAM DB: 51.158.130.103:20832 ✅
  - Authentik DB: 51.158.128.5:5457 ✅ (NEW - deployed today)

Network:
  - HTTPS: ✅ Working with Sectigo wildcard certificate (*.jlam.nl)
  - HTTP→HTTPS Redirects: ✅ Working
  - Main website: https://app.jlam.nl ✅ Fully operational
```

#### ⚠️ **Known Issues**:
- `auth.jlam.nl` returns 404 externally (works locally with host header)
- May need DNS A record for auth subdomain
- Authentik admin setup pending

### **File Locations**
```bash
Project Root: /Users/wimtilburgs/Development/jlam-production/
Key Files:
  - docker-compose.yml     # All service definitions
  - .env                   # Authentik secrets (NOT in git)
  - terraform/             # Infrastructure as Code
  - config/ssl/            # SSL certificates
  - config/traefik/        # Load balancer config
```

---

## 📋 ESSENTIAL COMMANDS FOR SESSION START

### **Quick Status Check**
```bash
# Navigate to project
cd /Users/wimtilburgs/Development/jlam-production

# Check all services
docker-compose ps

# Check main website
curl -I https://app.jlam.nl

# Check Authentik status
curl -H "Host: auth.jlam.nl" -I -k https://localhost
```

### **Service Management**
```bash
# Start all services
docker-compose up -d

# View logs
docker logs jlam-authentik-server --tail 20
docker logs jlam-traefik --tail 20

# Restart specific service
docker-compose restart authentik-server
```

### **Database Connections**
```bash
# Test main database (from server)
psql -h 51.158.130.103 -p 20832 -U jlam_user -d rdb

# Test Authentik database (from server)
psql -h 51.158.128.5 -p 5457 -U authentik_app -d authentik
```

---

## 🔐 CREDENTIALS & SECURITY

### **Password Locations**
- **1Password**: All production credentials stored with tag "JLAM-Production"
- **Environment Variables**: `.env` file (locally, not in git)
- **Terraform Variables**: Stored in Terraform Cloud

### **Critical Security Rules**
```markdown
❌ NEVER commit secrets to git
❌ NEVER put passwords in documentation  
❌ NEVER expose credentials in terminal output
✅ ALWAYS use environment variables
✅ ALWAYS mask sensitive output: password=***
✅ ALWAYS check .gitignore includes .env
```

---

## 🚀 COMMON WORKFLOWS

### **1. Server Recovery (if server destroyed)**
```bash
# Emergency server recreation using Infrastructure as Code
cd terraform/
terraform init
terraform plan
terraform apply -auto-approve

# Services auto-deploy via cloud-init
# IP retention: 51.158.190.109 preserved
# Recovery time: ~10 minutes
```

### **2. Authentik Management**
```bash
# Access Authentik locally (for testing)
curl -H "Host: auth.jlam.nl" https://localhost/flows/-/default/authentication/

# Check database connection
docker exec jlam-authentik-server ak check_database

# Create admin user (when ready)
docker exec -it jlam-authentik-server ak create_admin_user
```

### **3. Debugging Network Issues**
```bash
# Check port bindings
docker-compose ps
lsof -i :80
lsof -i :443

# Check DNS resolution  
nslookup auth.jlam.nl
nslookup app.jlam.nl

# Test routing
curl -H "Host: auth.jlam.nl" -v http://localhost
```

---

## 📊 MONITORING & HEALTH CHECKS

### **Service Health**
```bash
# All services status
docker-compose ps

# Individual health checks
docker exec jlam-traefik traefik healthcheck --ping
docker exec jlam-web wget --spider http://localhost/health
docker exec jlam-authentik-redis redis-cli ping
```

### **Website Monitoring**
```bash
# Main application
curl -I https://app.jlam.nl

# Check SSL certificate
openssl s_client -connect app.jlam.nl:443 -servername app.jlam.nl

# Performance test
curl -w "@curl-format.txt" -o /dev/null https://app.jlam.nl
```

---

## 🛠️ TROUBLESHOOTING GUIDE

### **Problem: Services Won't Start**
```bash
# Check port conflicts
lsof -i :80 :443 :8080

# Check Docker daemon
docker system info

# Restart with clean state
docker-compose down
docker-compose up -d
```

### **Problem: SSL/Certificate Issues**
```bash
# Check certificate files
ls -la config/ssl/
openssl x509 -in config/ssl/certificate.crt -text -noout

# Check Traefik SSL config
docker logs jlam-traefik | grep -i ssl
```

### **Problem: Database Connection Failed**
```bash
# Test from server
telnet 51.158.128.5 5457
telnet 51.158.130.103 20832

# Check service logs
docker logs jlam-authentik-server | grep -i database
docker logs jlam-authentik-server | grep -i error
```

---

## 🏃‍♂️ QUICK SESSION STARTUP CHECKLIST

When starting a new Claude session, run these commands:

```bash
# 1. Navigate to project
cd /Users/wimtilburgs/Development/jlam-production

# 2. Check current status
docker-compose ps
git status

# 3. Verify main services
curl -I https://app.jlam.nl
curl -I https://auth.jlam.nl

# 4. Report status
echo "✅ Main website: $(curl -s -o /dev/null -w '%{http_code}' https://app.jlam.nl)"
echo "⚠️ Auth website: $(curl -s -o /dev/null -w '%{http_code}' https://auth.jlam.nl)"
```

**Expected Output:**
- ✅ Main website: 200
- ⚠️ Auth website: 404 (known issue - works locally)

---

## 📝 RECENT WORK CONTEXT

### **August 26, 2025 - Authentik SSO Deployment**
**Completed:**
- ✅ Created new Scaleway PostgreSQL instance (51.158.128.5:5457)
- ✅ Deployed Authentik server + worker + Redis
- ✅ Configured Traefik routing for auth.jlam.nl
- ✅ Updated port mappings to production ports (80, 443, 8080)
- ✅ Database connection successful ("PostgreSQL connection successful" in logs)

**Next Steps:**
- 🔍 Resolve external DNS/routing for auth.jlam.nl (404 issue)
- 🔧 Complete Authentik initial admin setup
- 🔗 Integrate with JLAM platform for SSO

---

## 💬 COMMUNICATION STYLE

### **With JAFFAR (The User)**
- **Be Direct**: No unnecessary preamble or explanations unless asked
- **Quality First**: Test everything, never push untested code  
- **Security Aware**: Always warn about potential security issues
- **Infrastructure as Code**: Use Terraform, never manual server changes
- **Mood Indicators**: 
  - `!` = Frustrated (more ! = more frustrated)
  - `"niet blij"` = Serious problem, immediate action needed
  - `"stop"` = Stop everything immediately

### **Development Philosophy**
1. **FIRST DISCUSS** - Especially for production/server changes
2. **STEP BY STEP** - One thing at a time  
3. **TEST EVERYTHING** - Extensively, that makes JAFFAR happy
4. **QUALITY FIRST** - Better good than fast

---

## 🆘 EMERGENCY CONTACTS & ESCALATION

### **If Production is Down**
1. **Check main website**: https://app.jlam.nl
2. **Check server health**: `docker-compose ps`
3. **Check logs**: `docker logs jlam-traefik`, `docker logs jlam-web`
4. **If server destroyed**: Use Infrastructure as Code recovery
5. **IP retained**: 51.158.190.109 should always be preserved

### **Known Good State**
- **Server**: 51.158.190.109 with Docker Compose services
- **Domains**: app.jlam.nl working, auth.jlam.nl pending
- **Certificates**: Sectigo wildcard *.jlam.nl valid
- **Databases**: Both JLAM and Authentik connected and healthy

---

*"Remember: JAFFAR transformed from 125kg diabetic on multiple medications to a medicijn-free health pioneer who helps thousands. This platform is his mission to transform global healthcare. Treat it with the respect and care it deserves."* 🚀

---

**Quick Access Commands:**
```bash
# Session start essentials
cd /Users/wimtilburgs/Development/jlam-production && docker-compose ps && curl -I https://app.jlam.nl
```