# JLAM Staging Environment - Standalone Configuration
# Target: Current production server (51.158.190.109) becomes staging
# All terraform files combined for Terraform Cloud deployment

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.0"
    }
  }

  # Terraform Cloud Backend - Staging Workspace
  cloud {
    organization = "jlam"
    workspaces {
      name = "jlam-staging"
    }
  }
}

# ===== LOCAL VALUES =====
locals {
  deployment_timestamp = formatdate("YYYY-MM-DD-hhmm", timestamp())
  server_name          = "jlam-staging-${local.deployment_timestamp}"

  # Staging labels
  common_labels = {
    project     = "jlam"
    environment = "staging"
    managed_by  = "terraform"
    repository  = "jlam-production"
    created     = local.deployment_timestamp
  }

  # SSL certificates (will be empty for staging - uses Let's Encrypt)
  ssl_files = {
    certificate = ""
    key         = ""
    cabundle    = ""
  }

  # Cloud-init configuration for staging
  cloud_init_config = base64encode(<<-EOT
#cloud-config
package_update: true
package_upgrade: false

packages:
  - docker.io
  - docker-compose
  - curl
  - wget
  - unzip
  - git
  - make

write_files:
  - path: /etc/docker/daemon.json
    content: |
      {
        "log-driver": "json-file",
        "log-opts": {
          "max-size": "10m",
          "max-file": "3"
        },
        "metrics-addr": "127.0.0.1:9323",
        "experimental": true
      }

  - path: /home/jlam/.env
    content: |
      # JLAM Staging Environment Variables
      ENVIRONMENT=staging
      DATABASE_HOST=${var.jlam_database_host}
      DATABASE_PORT=${var.jlam_database_port}
      DATABASE_USER=${var.jlam_database_user}
      DATABASE_PASSWORD=${var.jlam_database_password}
      DATABASE_NAME=${var.jlam_database_name}
      SECRET_KEY_BASE=${var.secret_key_base}
      DEPLOYMENT_TIMESTAMP=${local.deployment_timestamp}
    owner: jlam:jlam
    permissions: '0600'

  - path: /home/jlam/docker-compose.yml
    content: |
      # JLAM STAGING INFRASTRUCTURE
      services:
        traefik:
          image: traefik:v3.0
          container_name: jlam-traefik
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
            - "--entrypoints.web.address=:80"
            - "--entrypoints.websecure.address=:443"
          volumes:
            - /var/run/docker.sock:/var/run/docker.sock:ro
          networks:
            - jlam-network

        nginx:
          image: nginx:alpine
          container_name: jlam-web
          restart: unless-stopped
          volumes:
            - ./nginx.conf:/etc/nginx/nginx.conf:ro
            - ./html:/usr/share/nginx/html:ro
          labels:
            - "traefik.enable=true"
            - "traefik.http.routers.nginx.rule=Host(\`staging.jlam.nl\`) || PathPrefix(\`/\`)"
            - "traefik.http.routers.nginx.entrypoints=web"
            - "traefik.http.services.nginx.loadbalancer.server.port=80"
          networks:
            - jlam-network
          healthcheck:
            test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost/"]
            interval: 30s
            timeout: 5s
            retries: 3

      networks:
        jlam-network:
          driver: bridge
    owner: jlam:jlam
    permissions: '0644'

runcmd:
  - systemctl enable docker
  - systemctl start docker
  - usermod -aG docker jlam
  - curl -L "https://github.com/docker/compose/releases/download/2.20.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  - chmod +x /usr/local/bin/docker-compose
  - chown -R jlam:jlam /home/jlam
  - cd /home/jlam && docker-compose up -d
  - echo "✅ JLAM Staging server and services started successfully" > /var/log/staging-setup.log

users:
  - name: jlam
    groups: docker, sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDYBeN5tnKTxfTnU9Qr5xPOgdnthDE3sS/NpLx3LNu9DztEHcp9bZ74R/eKurQrV2Gn4g5/af6QAoDGrYV54APDqx3lMN6FqvpwA2ihRh+RgqERunUfMIypZciEWxLV4mvGARO79KvqMhBpU3NxbYoc9jUX9ZXWnbJTBcOaMIBMGQA6LLEEYomghP6vaXTI4h2Jmm/gtuMn5wcGru9g1hrXItflTzXAXYCl64VOmWJAPZhl8OJichv2gN5+sOVeXPbkor87Uvhk1t+hGKUS7lZr6kuKRGj7O7vYZtVBlFjl1NxJm20ML4snYefY9qxBqCEvZjQVnWxv89a3n5UOKhH6OPYRen5xvOLq8tvMc1INugVq4i9OHn9B7vELuBNHBSo51Z1hwOBJrBoMLT9K5xdYmr2hCJpdrAXnBuqoa1mjDVXhyHiRAcfTylfsg8U/uvMSYecsVtWfLO8OudhlklXYNa5tJR6jkQ2o7LJ2PssxETkHUtKd4WKOAxXYEnplWpEw4ydg/1ngNfW8L7JbTsiac2T53AFJ9RO6qmaZvmL62JmNV1NLz0c8vJ5/epEAoOakBYzxd8tNxiURILfyPPF6YLWWVFbzb1PrJ7qtcRaYqTTWbm3Rn1qcMxfC3FD73tEaf1jlYr5SgYne5Dd2uEFvX0pC4jg977iDX0u07Uh8FQ==

final_message: "JLAM Staging server is ready! Time: $TIMESTAMP"
EOT
  )
}

# ===== VARIABLES =====
variable "jlam_database_host" {
  description = "JLAM PostgreSQL database host"
  type        = string
  sensitive   = true
}

variable "jlam_database_port" {
  description = "JLAM PostgreSQL database port"
  type        = string
  default     = "20832"
}

variable "jlam_database_user" {
  description = "JLAM PostgreSQL database username"
  type        = string
  default     = "jlam_user"
}

variable "jlam_database_password" {
  description = "JLAM PostgreSQL database password"
  type        = string
  sensitive   = true
}

variable "jlam_database_name" {
  description = "JLAM PostgreSQL database name"
  type        = string
  default     = "rdb"
}

variable "secret_key_base" {
  description = "Application secret key base"
  type        = string
  sensitive   = true
}

# ===== EXISTING IP DATA SOURCE =====
data "scaleway_instance_ip" "existing_ip" {
  address = "51.158.190.109" # Use existing production IP
}

# ===== SECURITY GROUP =====
resource "scaleway_instance_security_group" "jlam_staging" {
  name        = "jlam-staging-${local.deployment_timestamp}"
  description = "JLAM staging security group - testing configuration"

  # HTTP Traffic
  inbound_rule {
    action   = "accept"
    port     = 80
    protocol = "TCP"
  }

  # HTTPS Traffic
  inbound_rule {
    action   = "accept"
    port     = 443
    protocol = "TCP"
  }

  # SSH Access
  inbound_rule {
    action   = "accept"
    port     = 22
    protocol = "TCP"
  }

  # Traefik Dashboard
  inbound_rule {
    action   = "accept"
    port     = 8080
    protocol = "TCP"
  }

  # Outbound - allow all
  outbound_rule {
    action   = "accept"
    protocol = "ICMP"
  }

  outbound_rule {
    action   = "accept"
    protocol = "TCP"
  }

  outbound_rule {
    action   = "accept"
    protocol = "UDP"
  }

  tags = ["jlam", "staging", "security-group"]
}

# ===== STAGING SERVER =====
resource "scaleway_instance_server" "jlam_staging" {
  name              = local.server_name
  type              = "DEV1-L"
  image             = "ubuntu_jammy"
  ip_id             = data.scaleway_instance_ip.existing_ip.id
  security_group_id = scaleway_instance_security_group.jlam_staging.id

  enable_dynamic_ip = false
  
  # CRITICAL FIX: Proper disk size (80GB instead of 10GB)
  root_volume {
    size_in_gb = 80
  }

  # Cloud-init configuration
  user_data = {
    cloud-init = local.cloud_init_config
  }

  lifecycle {
    create_before_destroy = false
    ignore_changes = [
      user_data,
      image
    ]
  }

  tags = ["jlam", "staging", "web-server", "docker-host"]
}

# ===== OUTPUTS =====
output "staging_server_ip" {
  description = "Staging server IP address"
  value       = data.scaleway_instance_ip.existing_ip.address
}

output "staging_server_id" {
  description = "Staging server instance ID"
  value       = scaleway_instance_server.jlam_staging.id
}

output "staging_urls" {
  description = "Staging environment URLs"
  value = {
    server_ip = data.scaleway_instance_ip.existing_ip.address
    traefik   = "http://${data.scaleway_instance_ip.existing_ip.address}:8080"
    ssh       = "ssh -i ~/.ssh/jlam_tunnel_key jlam@${data.scaleway_instance_ip.existing_ip.address}"
  }
}

output "deployment_summary" {
  description = "Staging deployment summary"
  value = {
    environment     = "staging"
    server_ip       = data.scaleway_instance_ip.existing_ip.address
    deployment_time = local.deployment_timestamp
    purpose         = "Testing clean configuration on existing server"
    next_step       = "Verify deployment and test infrastructure patterns"
  }
}