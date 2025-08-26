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

runcmd:
  - systemctl enable docker
  - systemctl start docker
  - usermod -aG docker jlam
  - curl -L "https://github.com/docker/compose/releases/download/2.20.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  - chmod +x /usr/local/bin/docker-compose
  - echo "✅ Staging server setup complete" > /var/log/staging-setup.log

users:
  - name: jlam
    groups: docker, sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... # SSH key will be injected

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
  address = "51.158.190.109"  # Use existing production IP
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
    environment      = "staging"
    server_ip        = data.scaleway_instance_ip.existing_ip.address
    deployment_time  = local.deployment_timestamp
    purpose          = "Testing clean configuration on existing server"
    next_step        = "Verify deployment and test infrastructure patterns"
  }
}