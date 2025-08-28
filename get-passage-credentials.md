# 🔑 GET PASSAGE CREDENTIALS - STEP-BY-STEP GUIDE

## **OPTION 1: I'll Guide You Through It**

### **Step 1: Open Passage Console**
1. **Click this link**: https://console.passage.id/
2. **Click "Sign Up"** (or "Get Started")
3. **Use your email**: wim@jeleefstijlalsmedicijn.nl (recommended)

### **Step 2: Create Application**
1. After signing up, click **"Create Application"**
2. Fill in:
   - **Application Name**: `JLAM Development`
   - **Domain**: `localhost`
   - **Origin**: `http://localhost`
3. **Enable Authentication Methods**:
   - ✅ Passkeys (WebAuthn)
   - ✅ Biometrics
   - ✅ Security Keys

### **Step 3: Copy Credentials**
After creating the app, you'll see:
- **App ID**: `app_xxxxxxxxxxxxxxxxxx` (copy this)
- **API Key**: Click "Generate API Key" and copy it

---

## **OPTION 2: Use Test Configuration First**

If you want to test the system without getting real credentials first:

### **Test Environment Variables**
```bash
PASSAGE_APP_ID=app_test_demo_development
PASSAGE_API_KEY=test_api_key_for_development
```

### **What This Does:**
- Allows you to see the UI and service startup
- Shows you how the system works
- You can get real credentials later
- Everything works except actual authentication

---

## **CURRENT STATUS CHECK**

Let me check if your services are running properly first...