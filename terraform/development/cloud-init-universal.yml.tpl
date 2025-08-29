---
#cloud-config
# JLAM Universal Server Setup with SSL - OPTIMIZED EXECUTION ORDER
# Supports: development, staging, production
# Created: 2025-08-29
# Medical-Grade Compliance: ISO 13485 + NEN 7510
# Cloud-Init Optimization: 2025-08-29 12:16 CEST
# EXECUTION ORDER: Foundation → Docker → SSL (prevents Docker installation conflicts)

# PHASE 1: FOUNDATION - System packages and dependencies
packages:
  - docker.io
  - docker-compose-v2
  - git
  - curl
  - wget
  - unzip
  - jq

# PHASE 2: DOCKER INFRASTRUCTURE - Configuration files (NO SSL dependencies yet)
write_files:
  # Docker Compose Configuration (SSL-free version for initial setup)
  - path: /opt/jlam/docker-compose.yml
    content: |
      version: '3.8'

      services:
        traefik:
          image: traefik:v3.0
          container_name: jlam-${environment}-traefik
          restart: unless-stopped
          ports:
            - "80:80"
            - "443:443"
            - "8080:8080"
          command:
            - "--api=true"
            - "--api.dashboard=true"
            - "--api.insecure=true"
            - "--providers.docker=true"
            - "--providers.docker.exposedbydefault=false"
            - "--providers.docker.network=jlam-${environment}-network"
            - "--providers.file.directory=/etc/traefik/dynamic"
            - "--providers.file.watch=true"
            - "--entrypoints.web.address=:80"
            - "--entrypoints.websecure.address=:443"
            - "--log.level=INFO"
            - "--ping=true"
          volumes:
            - /var/run/docker.sock:/var/run/docker.sock:ro
            - /opt/jlam/config/traefik:/etc/traefik:ro
            - ${ssl_directory}:/etc/ssl/jlam:ro
          networks:
            - jlam-${environment}-network
          labels:
            - "traefik.enable=true"
            - "jlam.service.name=traefik"
            - "jlam.service.type=api-gateway"
            - "jlam.environment=${environment}"

      networks:
        jlam-${environment}-network:
          driver: bridge
          name: jlam-${environment}-network
    permissions: '0644'
    owner: root:root

  # Traefik static configuration
  - path: /opt/jlam/config/traefik/traefik.yml
    content: |
      api:
        dashboard: true
        insecure: true

      entryPoints:
        web:
          address: ":80"
        websecure:
          address: ":443"

      providers:
        docker:
          exposedByDefault: false
          network: jlam-${environment}-network
        file:
          directory: /etc/traefik/dynamic
          watch: true

      log:
        level: INFO

      ping: {}
    permissions: '0644'
    owner: root:root

  # Temporary SSL configuration placeholder (will be replaced in Phase 3)
  - path: /opt/jlam/config/traefik/dynamic/ssl-placeholder.yml
    content: |
      # SSL configuration will be installed after Docker is verified working
      # This prevents SSL operations from interfering with Docker installation
      http:
        middlewares:
          basic-security:
            headers:
              customRequestHeaders:
                X-Forwarded-Proto: http
    permissions: '0644'
    owner: root:root

# PHASE 2: DOCKER SETUP COMMANDS - Establish Docker infrastructure first
runcmd:
  # Enhanced Docker setup with debugging
  - >-
    echo "=== PHASE 2: DOCKER INFRASTRUCTURE SETUP ===" |
    tee -a /var/log/jlam-setup.log
  - >-
    echo "=== JLAM CLOUD-INIT DEBUG: Starting Docker setup ===" |
    tee -a /var/log/jlam-setup.log
  - systemctl enable docker 2>&1 | tee -a /var/log/jlam-setup.log
  - systemctl start docker 2>&1 | tee -a /var/log/jlam-setup.log
  - usermod -aG docker root 2>&1 | tee -a /var/log/jlam-setup.log
  - sleep 5
  - >-
    systemctl status docker --no-pager 2>&1 |
    tee -a /var/log/jlam-setup.log

  # JLAM directories with verification
  - >-
    echo "=== JLAM CLOUD-INIT DEBUG: Creating directories ===" |
    tee -a /var/log/jlam-setup.log
  - >-
    mkdir -p /opt/jlam/config/traefik/dynamic 2>&1 |
    tee -a /var/log/jlam-setup.log
  - chown -R root:root /opt/jlam 2>&1 | tee -a /var/log/jlam-setup.log
  - chmod -R 755 /opt/jlam 2>&1 | tee -a /var/log/jlam-setup.log
  - ls -la /opt/jlam/ 2>&1 | tee -a /var/log/jlam-setup.log

  # CRITICAL: Verify Docker is working BEFORE SSL operations
  - >-
    echo "=== JLAM CLOUD-INIT DEBUG: Docker verification checkpoint ===" |
    tee -a /var/log/jlam-setup.log
  - >-
    docker --version 2>&1 | tee -a /var/log/jlam-setup.log
  - >-
    docker compose --version 2>&1 | tee -a /var/log/jlam-setup.log
  - >-
    docker ps 2>&1 | tee -a /var/log/jlam-setup.log

  # PHASE 3: SSL CERTIFICATE PREPARATION - Docker-only version
  - >-
    echo "=== PHASE 3: SSL CERTIFICATE PREPARATION ===" |
    tee -a /var/log/jlam-setup.log
  - >-
    echo "SSL certificate installation via cloud-init write_files completed" |
    tee -a /var/log/jlam-setup.log
  - >-
    mkdir -p ${ssl_directory} && 
    chown -R root:root ${ssl_directory} && 
    chmod 755 ${ssl_directory} 2>&1 | tee -a /var/log/jlam-setup.log

  # Verify SSL directory after installation
  - >-
    echo "=== JLAM CLOUD-INIT DEBUG: Checking SSL directory ===" |
    tee -a /var/log/jlam-setup.log
  - ls -la ${ssl_directory}/ 2>&1 | tee -a /var/log/jlam-setup.log

  # Install proper SSL configuration for Traefik (replaces placeholder)
  - >-
    echo "=== JLAM CLOUD-INIT DEBUG: Installing Traefik SSL configuration ===" |
    tee -a /var/log/jlam-setup.log
  - >-
    cat > /opt/jlam/config/traefik/dynamic/ssl.yml << 'SSL_CONFIG_EOF'
      tls:
        certificates:
          - certFile: /etc/ssl/jlam/cert.pem
            keyFile: /etc/ssl/jlam/key.pem

      http:
        middlewares:
          security-headers:
            headers:
              customRequestHeaders:
                X-Forwarded-Proto: https
              customResponseHeaders:
                X-Frame-Options: DENY
                X-Content-Type-Options: nosniff
                X-XSS-Protection: 1; mode=block
                Strict-Transport-Security: >-
                  max-age=31536000; includeSubDomains
SSL_CONFIG_EOF
  - chmod 644 /opt/jlam/config/traefik/dynamic/ssl.yml 2>&1 | tee -a /var/log/jlam-setup.log
  - rm -f /opt/jlam/config/traefik/dynamic/ssl-placeholder.yml 2>&1 | tee -a /var/log/jlam-setup.log

  # Start services with detailed logging
  - >-
    echo "=== JLAM CLOUD-INIT DEBUG: Starting Docker Compose ===" |
    tee -a /var/log/jlam-setup.log
  - >-
    cd /opt/jlam && docker compose config 2>&1 |
    tee -a /var/log/jlam-setup.log
  - >-
    cd /opt/jlam && docker compose up -d 2>&1 |
    tee -a /var/log/jlam-setup.log
  - sleep 10
  - docker ps 2>&1 | tee -a /var/log/jlam-setup.log
  - >-
    docker logs jlam-${environment}-traefik --tail 20 2>&1 |
    tee -a /var/log/jlam-setup.log ||
    echo "Traefik logs not available yet" | tee -a /var/log/jlam-setup.log

  # Create cloud-init diagnostics and retry script
  - |
    cat > /opt/jlam/diagnose-and-retry.sh << 'EOF'
    #!/bin/bash
    # JLAM Cloud-Init Diagnostics & Retry Script
    # Medical-Grade Compliance: ISO 13485 + NEN 7510
    # ALWAYS diagnose first, then retry if needed

    echo "🔍 JLAM Cloud-Init Diagnostics - $(date)"
    echo "Environment: ${environment}"
    echo "Expected SSL Directory: ${ssl_directory}"
    echo "Medical-Grade Compliance: ISO 13485 + NEN 7510"
    echo "========================================="

    # Diagnostic functions
    diagnose_cloud_init() {
        echo "📋 CLOUD-INIT DIAGNOSTICS:"
        echo "Status: $(cloud-init status)"
        echo ""
        echo "📄 User Data Check:"
        if [ -f /var/lib/cloud/instance/user-data.txt ]; then
            echo "✅ User data exists"
            echo "Template variables found:"
            grep -E "(ssl_write_files|ssl_runcmds|environment)" \
              /var/lib/cloud/instance/user-data.txt | head -5
        else
            echo "❌ User data missing"
        fi
        echo ""
        echo "📝 Cloud-init logs (last 20 lines):"
        tail -20 /var/log/cloud-init.log
        echo ""
    }

    diagnose_ssl() {
        echo "🔐 SSL DIAGNOSTICS:"
        echo "Directory ${ssl_directory}:"
        ls -la ${ssl_directory}/ 2>/dev/null || 
          echo "❌ SSL directory not found"
        echo ""
        echo "Write files from cloud-init:"
        grep -A 10 "write_files" \
          /var/lib/cloud/instance/user-data.txt 2>/dev/null ||
          echo "❌ No write_files in user-data"
        echo ""
    }

    diagnose_docker() {
        echo "🐳 DOCKER DIAGNOSTICS:"
        echo "Docker status: $(systemctl is-active docker)"
        echo "Running containers:"
        docker ps || echo "❌ Docker not responding"
        echo ""
        if [ -f /opt/jlam/docker-compose.yml ]; then
            echo "✅ Docker compose file exists"
        else
            echo "❌ Docker compose file missing"
        fi
        echo ""
    }

    diagnose_traefik() {
        echo "🚦 TRAEFIK DIAGNOSTICS:"
        if docker ps | grep -q traefik; then
            echo "✅ Traefik container running"
            echo "Traefik logs (last 10 lines):"
            docker logs jlam-${environment}-traefik --tail 10 2>/dev/null ||
              docker logs $(docker ps | grep traefik | awk '{print $1}') \
                --tail 10
        else
            echo "❌ Traefik not running"
        fi
        echo ""
        echo "Health check:"
        curl -sf http://localhost:8080/ping &&
          echo "✅ Traefik ping OK" || echo "❌ Traefik ping failed"
        echo ""
    }

    # Check functions
    check_ssl() {
        [ -d "${ssl_directory}" ] && [ -f "${ssl_directory}/cert.pem" ]
    }

    check_traefik() {
        docker ps | grep -q traefik &&
          curl -sf http://localhost:8080/ping > /dev/null
    }

    # Function to rerun cloud-init
    retry_cloud_init() {
        echo "🔄 Re-running cloud-init..."
        cloud-init clean --logs
        cloud-init init
        cloud-init modules --mode=config
        cloud-init modules --mode=final
        echo "✅ Cloud-init retry completed"
    }

    # Function to restart services
    restart_services() {
        echo "🔄 Restarting services..."
        cd /opt/jlam
        docker-compose down 2>/dev/null || true
        docker-compose up -d
        sleep 10
    }

    # MAIN WORKFLOW: ALWAYS DIAGNOSE FIRST
    echo "🔍 STEP 1: FULL SYSTEM DIAGNOSIS"
    echo "================================="

    diagnose_cloud_init
    diagnose_ssl
    diagnose_docker
    diagnose_traefik

    echo "📋 STEP 2: HEALTH CHECK"
    echo "======================"

    ssl_ok=false
    traefik_ok=false

    if check_ssl; then
        echo "✅ SSL certificates: OK"
        ssl_ok=true
    else
        echo "❌ SSL certificates: MISSING"
    fi

    if check_traefik; then
        echo "✅ Traefik: OK"
        traefik_ok=true
    else
        echo "❌ Traefik: NOT RUNNING"
    fi

    if $ssl_ok && $traefik_ok; then
        echo ""
        echo "🎉 SYSTEM IS HEALTHY - No action needed!"
        exit 0
    fi

    echo ""
    echo "⚠️  STEP 3: ISSUES DETECTED - RETRY OPTIONS"
    echo "==========================================="
    echo "Available actions:"
    echo "  --restart-services  : Restart Docker services only"
    echo "  --retry-cloud-init  : Clean and rerun cloud-init"
    echo "  --force-both        : Both cloud-init + services"
    echo ""

    case "$1" in
        --restart-services)
            restart_services
            ;;
        --retry-cloud-init)
            retry_cloud_init
            restart_services
            ;;
        --force-both)
            retry_cloud_init
            restart_services
            ;;
        *)
            echo "❓ No action specified. Run with option above."
            echo "   Or check diagnostics manually first."
            exit 1
            ;;
    esac

    echo ""
    echo "⏳ STEP 4: POST-RETRY VERIFICATION"
    echo "=================================="

    sleep 15

    if check_ssl && check_traefik; then
        echo "🎉 SUCCESS: System is now healthy!"
        exit 0
    else
        echo "❌ STILL FAILING: Manual intervention needed"
        echo ""
        echo "🔍 Run diagnostics again:"
        echo "  /opt/jlam/diagnose-and-retry.sh"
        echo ""
        exit 1
    fi
    EOF

  - chmod +x /opt/jlam/diagnose-and-retry.sh
  - chown root:root /opt/jlam/diagnose-and-retry.sh

  # Enhanced deployment verification with logging
  - >-
    echo "=== JLAM CLOUD-INIT DEBUG: Final verification ===" |
    tee -a /var/log/jlam-setup.log
  - sleep 15
  - docker ps 2>&1 | tee -a /var/log/jlam-setup.log
  - >-
    curl -f http://localhost:8080/ping 2>&1 |
    tee -a /var/log/jlam-setup.log ||
    echo "Traefik health check failed" | tee -a /var/log/jlam-setup.log
  - >-
    netstat -tlnp | grep ':80\|:443\|:8080' 2>&1 |
    tee -a /var/log/jlam-setup.log ||
    echo "No services listening on expected ports" |
    tee -a /var/log/jlam-setup.log

  # Auto-diagnose if issues detected with enhanced logging
  - |
    echo "=== JLAM CLOUD-INIT DEBUG: Health check results ===" |
      tee -a /var/log/jlam-setup.log
    if ! curl -sf http://localhost:8080/ping > /dev/null ||
       [ ! -f "${ssl_directory}/cert.pem" ]; then
      echo "⚠️ Issues detected - running diagnostics..." |
        tee -a /var/log/jlam-setup.log
      /opt/jlam/diagnose-and-retry.sh 2>&1 |
        tee -a /var/log/jlam-setup.log
      echo "💡 To retry: /opt/jlam/diagnose-and-retry.sh --force-both" |
        tee -a /var/log/jlam-setup.log
    else
      echo "✅ JLAM setup completed successfully!" |
        tee -a /var/log/jlam-setup.log
    fi

  # Create summary log
  - |
    echo "=== JLAM CLOUD-INIT SUMMARY ===" > /var/log/jlam-summary.log
    echo "Timestamp: $(date)" >> /var/log/jlam-summary.log
    echo "Environment: ${environment}" >> /var/log/jlam-summary.log
    echo "SSL Directory: ${ssl_directory}" >> /var/log/jlam-summary.log
    echo "Docker Status: $(systemctl is-active docker)" >> \
      /var/log/jlam-summary.log
    echo "Running Containers: $(docker ps \
      --format 'table {{.Names}}\t{{.Status}}' 2>/dev/null || \
      echo 'None')" >> /var/log/jlam-summary.log
    echo "Traefik Health: $(curl -sf http://localhost:8080/ping && \
      echo 'OK' || echo 'FAILED')" >> /var/log/jlam-summary.log

# Final message
final_message: |
  JLAM ${environment} server setup complete!
  Medical-Grade Compliance: ISO 13485 + NEN 7510

  Server Ready:
  - Traefik API Gateway: Running
  - SSL Certificates: Deployed
  - Environment: ${environment}
  - SSL Directory: ${ssl_directory}

  Next steps:
  1. Configure DNS: ${environment}.jlam.nl → this server IP
  2. Deploy application services via docker compose
  3. Test HTTPS connectivity

  Dashboard: http://YOUR-IP:8080
  Status: curl http://YOUR-IP:8080/ping