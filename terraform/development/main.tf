# JLAM Development Server Infrastructure
# Provider: Scaleway (Amsterdam)
# Purpose: Development environment for auth experiments
# Created: 2025-08-28
# SSL: Universal SSL module with enterprise *.jlam.nl certificate

# Terraform configuration moved to versions.tf

# Universal SSL Certificate Module
module "ssl_certificates" {
  source = "../modules/jlam-ssl"
  
  environment     = "development"
  ssl_certificate = var.ssl_certificate
  ssl_private_key = var.ssl_private_key
  ssl_ca_bundle   = var.ssl_ca_bundle
  ssl_directory   = "/tmp/jlam-ssl"
}

# Provider Configuration
provider "scaleway" {
  zone   = var.scaleway_zone
  region = var.scaleway_region
}

# Development Server Instance
resource "scaleway_instance_ip" "dev_ip" {
  type = "routed_ipv4"
  
  # CRITICAL: NEVER change existing IP - DNS depends on it!
  # Current IP: 51.158.166.152 (dev.jlam.nl)
  # Use existing IP if server exists
  
  tags = [
    "jlam-dev",
    "development", 
    "auth-experiments"
  ]
}

resource "scaleway_instance_server" "dev_server" {
  name  = "jlam-dev-server"
  type  = "DEV1-S"
  image = "ubuntu_jammy"
  
  ip_id = scaleway_instance_ip.dev_ip.id
  
  # CRITICAL: Protect existing infrastructure
  # Current server ID (if exists): Must be preserved
  # Use import if server already exists
  
  # Enable IPv4
  enable_ipv6 = false
  
  # Security Groups
  security_group_id = scaleway_instance_security_group.dev_security.id
  
  # Universal cloud-init with SSL certificates
  cloud_init = templatefile("${path.module}/../templates/cloud-init-universal.yml", {
    environment     = module.ssl_certificates.environment
    ssh_public_key  = var.ssh_public_key
    ssl_write_files = module.ssl_certificates.cloud_init_write_files
    ssl_runcmds     = module.ssl_certificates.cloud_init_runcmds
    ssl_directory   = module.ssl_certificates.ssl_directory
  })
  
  tags = [
    "jlam-dev",
    "development", 
    "docker",
    "traefik",
    "auth-experiments"
  ]
}

# Security Group for Development Server
resource "scaleway_instance_security_group" "dev_security" {
  name        = "jlam-dev-security"
  description = "Security group for JLAM development server"
  
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"

  # SSH Access
  inbound_rule {
    action   = "accept"
    port     = 22
    protocol = "TCP"
    ip_range = "0.0.0.0/0"
  }
  
  # HTTP
  inbound_rule {
    action   = "accept"
    port     = 80
    protocol = "TCP"
    ip_range = "0.0.0.0/0"
  }
  
  # HTTPS  
  inbound_rule {
    action   = "accept"
    port     = 443
    protocol = "TCP"
    ip_range = "0.0.0.0/0"
  }
  
  # Traefik Dashboard (restricted)
  inbound_rule {
    action   = "accept"
    port     = 8080
    protocol = "TCP"
    ip_range = "0.0.0.0/0"  # TODO: Restrict to JAFFAR's IP
  }
  
  tags = [
    "jlam-dev",
    "security"
  ]
}

# DNS Record for dev.jlam.nl
# Note: This assumes DNS is managed elsewhere
# Add manual DNS record: dev.jlam.nl A ${scaleway_instance_ip.dev_ip.address}

# Outputs
output "dev_server_ip" {
  description = "Public IP address of development server"
  value       = scaleway_instance_ip.dev_ip.address
}

output "dev_server_id" {
  description = "ID of development server"
  value       = scaleway_instance_server.dev_server.id
}

output "dev_server_name" {
  description = "Name of development server"
  value       = scaleway_instance_server.dev_server.name
}

output "dns_record_needed" {
  description = "DNS record to create manually"
  value       = "Create DNS A record: dev.jlam.nl -> ${scaleway_instance_ip.dev_ip.address}"
}