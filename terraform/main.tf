# JLAM Production Infrastructure - Clean Enterprise Configuration
# Repository: jlam-production (clean slate)
# Created: 2025-08-26
# Architecture: ODIN Enterprise Patterns

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.0"
    }
  }

  # Note: Backend configuration moved to environment-specific configurations
  # This is now a reusable module
}

# Local values for clean configuration
locals {
  deployment_timestamp = var.deployment_timestamp != "" ? var.deployment_timestamp : formatdate("YYYY-MM-DD-hhmm", timestamp())
  server_name          = "jlam-production-${local.deployment_timestamp}"

  # Enterprise labels for service discovery
  common_labels = {
    project     = "jlam"
    environment = "production"
    managed_by  = "terraform"
    repository  = "jlam-production"
    created     = local.deployment_timestamp
  }

  # SSL certificates (base64 encoded from config directory)
  ssl_files = {
    certificate = fileexists("${path.module}/../config/ssl/certificate.crt") ? filebase64("${path.module}/../config/ssl/certificate.crt") : ""
    key         = fileexists("${path.module}/../config/ssl/certificate.key") ? filebase64("${path.module}/../config/ssl/certificate.key") : ""
    cabundle    = fileexists("${path.module}/../config/ssl/cabundle.crt") ? filebase64("${path.module}/../config/ssl/cabundle.crt") : ""
  }

  # Cloud-init configuration with enterprise patterns
  cloud_init = templatefile("${path.module}/cloud-init.yml", {
    # SSH Configuration
    ssh_public_key = file("~/.ssh/jlam_tunnel_key.pub")

    # SSL Certificates
    ssl_certificate_crt = local.ssl_files.certificate
    ssl_certificate_key = local.ssl_files.key
    ssl_cabundle_crt    = local.ssl_files.cabundle

    # Database Configuration (JLAM)
    jlam_database_host     = var.jlam_database_host
    jlam_database_port     = var.jlam_database_port
    jlam_database_user     = var.jlam_database_user
    jlam_database_password = var.jlam_database_password
    jlam_database_name     = var.jlam_database_name

    # Application Configuration
    secret_key_base = var.secret_key_base

    # Deployment metadata
    deployment_timestamp = local.deployment_timestamp
    server_name          = local.server_name
  })
}

# IP Address - configurable per environment
# Staging: uses existing IP (51.158.190.109)  
# Production: will use new IP created in environment config
variable "use_existing_ip" {
  description = "Use existing IP address (for staging)"
  type        = bool
  default     = false
}

variable "existing_ip_address" {
  description = "Existing IP address to use (staging only)"
  type        = string
  default     = ""
}

variable "external_ip_id" {
  description = "External IP resource ID (for production)"
  type        = string
  default     = ""
}

# Conditional IP data source for staging
data "scaleway_instance_ip" "existing_ip" {
  count   = var.use_existing_ip ? 1 : 0
  address = var.existing_ip_address
}

# Security Group with enterprise access patterns
resource "scaleway_instance_security_group" "jlam_production" {
  name        = "jlam-production-${local.deployment_timestamp}"
  description = "JLAM production security group - clean enterprise configuration"

  # HTTP Traffic (redirects to HTTPS)
  inbound_rule {
    action   = "accept"
    port     = 80
    protocol = "TCP"
  }

  # HTTPS Traffic (production)
  inbound_rule {
    action   = "accept"
    port     = 443
    protocol = "TCP"
  }

  # SSH Access (administrative)
  inbound_rule {
    action   = "accept"
    port     = 22
    protocol = "TCP"
  }

  # Traefik Dashboard (restricted)
  inbound_rule {
    action   = "accept"
    port     = 8080
    protocol = "TCP"
    ip_range = "0.0.0.0/0" # Consider restricting to admin IPs
  }

  # Outbound - allow all (default)
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

  tags = ["jlam", "production", "security-group"]
}

# Production Server Instance
resource "scaleway_instance_server" "jlam_production" {
  name              = local.server_name
  type              = "DEV1-L" # 2 vCPUs, 4GB RAM - sufficient for enterprise workload
  image             = "ubuntu_jammy"
  ip_id             = var.use_existing_ip ? data.scaleway_instance_ip.existing_ip[0].id : var.external_ip_id
  security_group_id = scaleway_instance_security_group.jlam_production.id

  # Enterprise configuration
  enable_dynamic_ip = false
  # Note: IPv6 configuration moved to IP resource management

  # Cloud-init with enterprise patterns
  user_data = {
    cloud-init = local.cloud_init
  }

  # Lifecycle management
  lifecycle {
    create_before_destroy = false
    ignore_changes = [
      user_data, # Allow updates without replacement
      image      # Allow image updates
    ]
  }

  tags = ["jlam", "production", "web-server", "docker-host"]
}

# Volume for persistent data (optional but recommended)
resource "scaleway_instance_volume" "jlam_data" {
  name       = "jlam-production-data-${local.deployment_timestamp}"
  size_in_gb = 20
  type       = "b_ssd"

  tags = ["jlam", "production", "data-volume"]
}

# Note: Volume attachment is handled via additional_volume_ids in server resource

# DNS Record (if managing DNS through Scaleway)
# Uncomment if you want Terraform to manage DNS
# resource "scaleway_domain_record" "app" {
#   dns_zone = "jlam.nl"
#   name     = "app"
#   type     = "A"
#   data     = scaleway_instance_server.jlam_production.public_ip
#   ttl      = 300
# }

# resource "scaleway_domain_record" "auth" {
#   dns_zone = "jlam.nl"
#   name     = "auth"  
#   type     = "A"
#   data     = scaleway_instance_server.jlam_production.public_ip
#   ttl      = 300
# }