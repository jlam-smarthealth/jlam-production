# 🔐 PASSAGE AUTHENTICATION SETUP GUIDE
*Setup Date: 2025-08-27*  
*Environment: Local Development*  
*Purpose: Week 1 Testing of Authentication Evolution Strategy*

## 🎯 **OVERVIEW**

This guide walks you through setting up Passage by 1Password for local development testing. This replaces Authentik completely and implements biometric authentication for the JLAM platform.

---

## 📋 **PREREQUISITES**

### **System Requirements:**
- ✅ Docker & Docker Compose
- ✅ Node.js 18+ (for development)  
- ✅ Modern browser with WebAuthn support
- ✅ Device with biometric authentication (Touch ID, Face ID, fingerprint)

### **Authentik Cleanup Status:**
- ✅ **Authentik containers stopped and removed**
- ✅ **Authentik volumes cleaned up** (freed ~16 volumes)
- ✅ **Authentik images removed** (freed ~3.2GB disk space)
- ✅ **Configuration files archived** in `archive/authentik-backup-20250827/`

---

## 🚀 **STEP 1: PASSAGE ACCOUNT SETUP**

### **1.1 Create Passage Account**
1. Visit: https://console.passage.id/
2. Click "Sign Up" and create your account
3. Verify your email address

### **1.2 Create New Application**
1. In Passage Console, click "Create Application"
2. **Application Name**: `JLAM Development`
3. **Domain**: `localhost` (for local development)
4. **Authentication Methods**: Enable all biometric options:
   - ✅ Passkeys (WebAuthn)
   - ✅ Biometrics (Touch ID, Face ID)
   - ✅ Security Keys

### **1.3 Get Your Credentials**
After creating the app, you'll get:
- **App ID**: `app_xxxxxxxxxxxxxxxxxx` (copy this)
- **API Key**: Generate a new API key (copy this)

---

## 🔧 **STEP 2: LOCAL ENVIRONMENT SETUP**

### **2.1 Environment Configuration**
```bash
# Copy the example environment file
cp .env.dev.example .env.dev

# Edit the file with your Passage credentials
nano .env.dev
```

**Update these values in `.env.dev`:**
```env
PASSAGE_APP_ID=app_your_actual_app_id_here
PASSAGE_API_KEY=your_actual_api_key_here
```

### **2.2 Install Dependencies**
The Passage authentication service is already set up with all dependencies:
```bash
# Dependencies already installed in passage-auth-service/
cd passage-auth-service && npm list
```

---

## 🐳 **STEP 3: LOCAL DEVELOPMENT DEPLOYMENT**

### **3.1 Start Development Environment**
```bash
# Start all services with development configuration
docker-compose -f docker-compose.dev.yml up -d

# Check service status
docker-compose -f docker-compose.dev.yml ps
```

**Expected Services:**
- `jlam-dev-traefik` - API Gateway (ports 80, 443, 8080)
- `jlam-dev-passage-auth` - Authentication service
- `jlam-dev-api` - Backend API
- `jlam-dev-landing` - Frontend application

### **3.2 Verify Service Health**
```bash
# Check all services are healthy
curl http://localhost/auth/health
curl http://localhost/api/system/health  
curl http://localhost/health
```

### **3.3 Test Passage Configuration**
```bash
# Test Passage connectivity
curl http://localhost/auth/test-config
```

**Expected Response:**
```json
{
  "status": "configured",
  "app_id": "app_your_app_id",
  "app_name": "JLAM Development",
  "message": "Passage is properly configured"
}
```

---

## 🧪 **STEP 4: TESTING BIOMETRIC AUTHENTICATION**

### **4.1 Access Development Environment**
1. Open: http://localhost
2. You should see the JLAM landing page
3. Navigate to login/authentication area

### **4.2 Test Biometric Login**
1. **First Time Setup**:
   - Click on biometric login component
   - Browser will prompt for biometric authentication
   - Use Touch ID, Face ID, or fingerprint
   - Complete user registration

2. **Subsequent Logins**:
   - One-touch biometric authentication
   - No passwords required
   - Immediate access

### **4.3 Development Tools**
In development mode, you'll see additional debugging information:
- Authentication service logs in console
- User information display
- Service health status
- Forward auth headers

---

## 🔍 **STEP 5: DEBUGGING & MONITORING**

### **5.1 View Service Logs**
```bash
# Authentication service logs
docker logs jlam-dev-passage-auth -f

# API service logs  
docker logs jlam-dev-api -f

# Traefik logs
docker logs jlam-dev-traefik -f
```

### **5.2 Traefik Dashboard**
- URL: http://localhost:8080
- Monitor routing rules and service discovery
- View middleware status

### **5.3 Common Issues & Solutions**

**Issue**: "Passage not configured" error
**Solution**: 
```bash
# Check environment variables are loaded
docker exec jlam-dev-passage-auth env | grep PASSAGE
```

**Issue**: Biometric authentication not working
**Solution**:
- Ensure you're using HTTPS (required for WebAuthn)
- Check browser supports WebAuthn
- Verify device has biometric capability

**Issue**: API returns 401 Unauthorized
**Solution**:
```bash
# Check forward auth is working
curl -H "Authorization: Bearer invalid_token" http://localhost/api/system/health
# Should return 401, confirming auth is active
```

---

## 📊 **STEP 6: PERFORMANCE VALIDATION**

### **6.1 Authentication Speed Test**
Expected performance targets:
- **Initial biometric setup**: < 3 seconds
- **Biometric login**: < 1 second  
- **API Gateway auth**: < 200ms
- **Forward auth overhead**: < 50ms

### **6.2 Load Testing** (Optional)
```bash
# Install wrk for load testing
# Test authentication endpoint
wrk -t4 -c10 -d30s http://localhost/auth/health

# Test protected API endpoints
wrk -t4 -c10 -d30s -H "Authorization: Bearer valid_token" http://localhost/api/system/health
```

---

## 🎯 **SUCCESS CRITERIA**

### **✅ Functional Requirements:**
- [ ] Biometric login working on your device
- [ ] API authentication protecting backend endpoints
- [ ] User session maintained across requests
- [ ] Forward auth headers properly set
- [ ] No Authentik dependencies remaining

### **✅ Performance Requirements:**
- [ ] Authentication latency < 200ms
- [ ] Biometric login < 1 second
- [ ] API response times unchanged from baseline
- [ ] Memory usage < 100MB for auth service

### **✅ Security Requirements:**
- [ ] WebAuthn/FIDO2 standards compliance
- [ ] No passwords stored anywhere
- [ ] Secure token handling
- [ ] Proper CORS configuration

---

## 🚀 **NEXT STEPS**

### **Week 1 Validation Complete:**
Once local testing is successful:
1. **Deploy to staging** using the same configuration
2. **User acceptance testing** with real biometric devices
3. **Performance benchmarking** under load
4. **Security audit** of authentication flow

### **Week 2 Preparation:**
1. **Redis caching layer** setup and testing
2. **Session management** optimization
3. **API response caching** implementation

---

## 🆘 **TROUBLESHOOTING**

### **Quick Fixes:**
```bash
# Restart all services
docker-compose -f docker-compose.dev.yml restart

# Rebuild with latest changes  
docker-compose -f docker-compose.dev.yml up --build -d

# Clean restart (removes containers and networks)
docker-compose -f docker-compose.dev.yml down
docker-compose -f docker-compose.dev.yml up -d
```

### **Reset Development Environment:**
```bash
# Complete cleanup and restart
docker-compose -f docker-compose.dev.yml down -v
docker system prune -f
docker-compose -f docker-compose.dev.yml up --build -d
```

### **Get Support:**
- **Passage Documentation**: https://docs.passage.id/
- **Passage Community**: https://github.com/passageidentity
- **JLAM Development**: Check logs and GitHub issues

---

## 📈 **METRICS TO TRACK**

During your testing, monitor:
- **Authentication Success Rate**: Should be > 99%
- **User Experience**: One-touch login satisfaction
- **Performance Impact**: Latency comparisons vs Authentik
- **Error Rate**: Should be < 0.1%
- **Device Compatibility**: Test across devices/browsers

---

**🎉 Congratulations! You now have a completely Authentik-free development environment with modern biometric authentication!**

*Next: Deploy this configuration to staging and begin Week 2 (Redis caching) implementation.*

---
*Generated by: 👑 QUEEN Claude Controller*  
*Setup Guide Complete: 2025-08-27*