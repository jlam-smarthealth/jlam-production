# JLAM Production Environment - Terraform Configuration
# Target: NEW production server (fresh provision)
# Strategy: Clean enterprise deployment on fresh infrastructure

terraform {
  required_version = ">= 1.7.0"
  
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.0"
    }
  }

  # Terraform Cloud Backend - Production Workspace
  cloud {
    organization = "jlam"
    workspaces {
      name = "jlam-production"
    }
  }
}

# Use main terraform configuration with production settings
module "jlam_infrastructure" {
  source = "../../terraform"
  
  # Production environment configuration
  environment = "production"
  deployment_timestamp = "production-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  # Production database configuration
  jlam_database_host = var.jlam_database_host
  jlam_database_port = var.jlam_database_port
  jlam_database_user = var.jlam_database_user
  jlam_database_password = var.jlam_database_password
  jlam_database_name = var.jlam_database_name
  
  # Application configuration
  secret_key_base = var.secret_key_base
  
  # Production infrastructure settings - NEW server with NEW IP
  server_type = "DEV1-L"        # Enterprise-ready
  data_volume_size = 50         # Larger storage for production
  use_existing_ip = false       # Create new IP for production
  external_ip_id = scaleway_instance_ip.production_ip.id
  
  # Production security (restrictive)
  admin_ips = [
    "127.0.0.1/32",    # Localhost
    "172.16.0.0/12",   # Docker networks  
    "192.168.0.0/16"   # Private networks
  ]
  backup_retention_days = 30
  
  # Feature flags  
  enable_monitoring = true
  enable_ssl_certificates = true
  enable_auto_updates = false      # Stability over convenience
  enable_docker_swarm = true
  
  # Production tags
  additional_tags = {
    environment = "production"
    migration   = "clean-deployment"
    purpose     = "enterprise-production" 
    criticality = "high"
    backup      = "required"
    monitoring  = "24x7"
  }
  cost_center = "jlam-production"
  owner = "jlam-devops-production"
}

# Production gets a NEW IP address (provisioned fresh)
# Note: This will create a new static IP, different from staging
resource "scaleway_instance_ip" "production_ip" {
  tags = ["jlam", "production", "static-ip", "clean-deployment"]
}

# Variables that need to be passed through
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
  sensitive   = true
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

# Production-specific outputs
output "production_summary" {
  description = "Production environment summary"
  value = {
    environment = "production"
    server_ip   = scaleway_instance_ip.production_ip.address
    purpose     = "Clean enterprise production deployment"
    ssl         = "Sectigo wildcard certificates"
    monitoring  = "Enterprise-grade 24x7"
    backup      = "30 days retention"
    security    = "Enterprise hardened"
    next_step   = "DNS cutover after testing"
  }
}

output "production_urls" {
  description = "Production environment URLs (after DNS cutover)"
  value = {
    main_app    = "https://app.jlam.nl"      # After DNS cutover
    auth        = "https://auth.jlam.nl"     # After DNS cutover  
    monitoring  = "https://monitor.jlam.nl"  # After DNS cutover
    dashboard   = "http://${scaleway_instance_ip.production_ip.address}:8080"
  }
}

output "dns_cutover_instructions" {
  description = "DNS cutover instructions for go-live"
  value = [
    "1. Verify production deployment is healthy",
    "2. Update DNS A records:",
    "   • app.jlam.nl → ${scaleway_instance_ip.production_ip.address}",
    "   • auth.jlam.nl → ${scaleway_instance_ip.production_ip.address}",
    "   • monitor.jlam.nl → ${scaleway_instance_ip.production_ip.address}",
    "3. Monitor DNS propagation (up to 24-48 hours)",
    "4. Test all production URLs",
    "5. Keep staging (51.158.190.109) as rollback option"
  ]
}

output "new_production_ip" {
  description = "New production server IP address"
  value       = scaleway_instance_ip.production_ip.address
}