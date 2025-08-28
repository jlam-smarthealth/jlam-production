# 🔐 Authentik SSO Integration for JLAM Monitoring Stack
*Created: 2025-08-27*  
*Purpose: Replace basic auth with enterprise-grade SSO*

## 🎯 OVERVIEW

This guide configures **Authentik SSO integration** for the JLAM monitoring stack, providing:

✅ **Single Sign-On** across Grafana, Prometheus, and Alertmanager  
✅ **Centralized User Management** via Authentik  
✅ **Enhanced Security** - No more basic auth  
✅ **Professional Admin Experience** - One login for everything  
✅ **Role-Based Access Control** - Administrators, Editors, Viewers  

## 🚀 IMPLEMENTATION STEPS

### STEP 1: Configure Authentik Applications

Login to **https://auth.jlam.nl** as admin and create these applications:

#### 1.1 Grafana OAuth2 Application

**Applications → Create Application:**
- **Name:** `JLAM Grafana`
- **Provider Type:** `OAuth2/OpenID Provider`
- **Configuration:**
  ```
  Client Type: Confidential
  Client ID: [Auto-generated - copy this!]
  Client Secret: [Auto-generated - copy this!]
  Redirect URIs: https://monitor.jlam.nl/login/generic_oauth
  Scopes: openid, email, profile, groups
  Subject Mode: Based on User's UUID
  Include claims in id_token: ✅
  ```

#### 1.2 Forward Auth Application (Prometheus/Alertmanager)

**Applications → Create Application:**
- **Name:** `JLAM Monitoring Forward Auth`
- **Provider Type:** `Proxy Provider`
- **Configuration:**
  ```
  Authorization flow: default-authorization-flow
  Mode: Forward auth (single application)
  External host: https://metrics.jlam.nl,https://alerts.jlam.nl
  Internal host: http://prometheus:9090,http://alertmanager:9093
  ```

#### 1.3 Create Outpost (if not exists)

**Applications → Outposts → Create:**
- **Name:** `JLAM Traefik Outpost`
- **Type:** `Proxy`
- **Applications:** Select both Grafana and Forward Auth apps
- **Configuration:**
  ```yaml
  authentik_host: https://auth.jlam.nl/
  object_naming_template: ak-outpost-%(name)s
  docker_network: jlam-network
  ```

### STEP 2: Configure User Groups (Optional)

**Directory → Groups → Create:**

1. **JLAM Administrators**
   - Members: Wim Tilburgs, other admins
   - Permissions: Full access to all monitoring

2. **JLAM Editors** 
   - Members: Developers, DevOps team
   - Permissions: Dashboard editing, alert configuration

3. **JLAM Viewers**
   - Members: Other team members
   - Permissions: Read-only access

### STEP 3: Environment Variables Setup

Copy credentials from Authentik and update environment:

```bash
# Copy example environment file
cp .env.monitoring.example .env.monitoring

# Edit with real values
nano .env.monitoring
```

**Required values:**
```bash
GRAFANA_OAUTH_CLIENT_ID=your_client_id_from_authentik
GRAFANA_OAUTH_CLIENT_SECRET=your_client_secret_from_authentik
SMTP_USER=your_tem_username
SMTP_PASSWORD=your_tem_password
JLAM_DATABASE_PASSWORD=your_database_password
```

### STEP 4: Deploy Updated Configuration

```bash
# Stop monitoring stack
docker-compose -f docker-compose.monitoring.yml down

# Remove old Grafana data (to reset admin user)
docker volume rm jlam-production_grafana_data

# Start with new configuration
docker-compose -f docker-compose.monitoring.yml up -d

# Check all services are healthy
docker-compose -f docker-compose.monitoring.yml ps
```

## 🧪 TESTING AUTHENTICATION

### Test Grafana OAuth2
1. Visit **https://monitor.jlam.nl**
2. Should redirect to Authentik login
3. Login with your Authentik account
4. Should redirect back to Grafana dashboard
5. Check user profile shows Authentik info

### Test Prometheus Forward Auth
1. Visit **https://metrics.jlam.nl**
2. Should redirect to Authentik login
3. After auth, should show Prometheus interface
4. Test a query to verify functionality

### Test Alertmanager Forward Auth  
1. Visit **https://alerts.jlam.nl**
2. Same authentication flow as Prometheus
3. Should show Alertmanager interface

## 🔧 TROUBLESHOOTING

### Common Issues:

**1. OAuth2 redirect loops:**
```bash
# Check Grafana logs
docker logs jlam-grafana

# Verify redirect URI matches exactly in Authentik
# Must be: https://monitor.jlam.nl/login/generic_oauth
```

**2. Forward auth 401 errors:**
```bash
# Check Traefik logs
docker logs jlam-traefik

# Verify Authentik outpost is running
# Check Applications → Outposts → JLAM Traefik Outpost
```

**3. Database connection errors:**
```bash
# Test database connectivity
docker run --rm -it postgres:13 psql "postgresql://jlam_app:PASSWORD@51.158.128.5:5457/jlam_production" -c "SELECT version();"
```

**4. SMTP configuration issues:**
```bash
# Test TEM SMTP
docker run --rm -it alpine/mail \
  -h smtp.tem.scaleway.com \
  -p 587 \
  -t your_email@jlam.nl \
  -s "Test from Grafana" \
  -b "SMTP test successful"
```

## 📊 ACCESS MATRIX

| Service | URL | Authentication | Role Access |
|---------|-----|---------------|-------------|
| **Grafana** | https://monitor.jlam.nl | OAuth2 | Admin/Editor/Viewer |
| **Prometheus** | https://metrics.jlam.nl | Forward Auth | Admin/Editor only |
| **Alertmanager** | https://alerts.jlam.nl | Forward Auth | Admin/Editor only |

## 🎯 POST-SETUP CONFIGURATION

### Configure Grafana Data Sources

After first login to Grafana:

1. **Add Prometheus Data Source:**
   ```
   URL: http://prometheus:9090
   Access: Server (default)
   HTTP Method: GET
   ```

2. **Add Loki Data Source:**
   ```  
   URL: http://loki:3100
   Access: Server (default)
   ```

### Import Dashboards

Recommended community dashboards:
- **Node Exporter Full**: Dashboard ID `1860`
- **Docker and System Monitoring**: Dashboard ID `179`
- **Traefik Dashboard**: Dashboard ID `4475`

## 🔒 SECURITY CONSIDERATIONS

1. **Outpost Security:** The Authentik outpost runs in the same Docker network
2. **Role Mapping:** Grafana roles mapped to Authentik groups automatically  
3. **Session Security:** All sessions managed by Authentik with proper timeout
4. **Audit Logging:** All access logged in Authentik for compliance

## 📝 MAINTENANCE

### Regular Tasks:
- Monitor Authentik outpost health
- Review user access quarterly
- Update OAuth2 client secrets annually
- Test backup/restore procedures monthly

---

## 🆘 EMERGENCY ACCESS

If Authentik is down and you need monitoring access:

1. **Temporarily enable basic auth** in docker-compose.monitoring.yml
2. **Access via localhost** on server: http://localhost:3000, :9090, :9093
3. **Fix Authentik** and re-enable SSO

**Never leave basic auth enabled permanently in production!**

---

*This setup provides enterprise-grade authentication for the JLAM monitoring infrastructure while maintaining security and usability.*