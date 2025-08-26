# JLAM Staging Environment - Terraform Configuration
# Target: Current production server (51.158.190.109) becomes staging
# Strategy: Deploy clean config to existing server for testing

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

# Use main terraform configuration with staging overrides
module "jlam_infrastructure" {
  source = "../../terraform"
  
  # Override variables for staging environment
  environment = "staging"
  deployment_timestamp = "staging-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  # Staging-specific database configuration
  jlam_database_host = var.jlam_database_host
  jlam_database_port = var.jlam_database_port  
  jlam_database_user = var.jlam_database_user
  jlam_database_password = var.jlam_database_password
  jlam_database_name = var.jlam_database_name
  
  # Application configuration
  secret_key_base = var.secret_key_base
  
  # Staging infrastructure settings
  server_type = "DEV1-L"
  data_volume_size = 20
  
  # Staging security (more permissive)
  admin_ips = ["0.0.0.0/0"]
  backup_retention_days = 7
  
  # Feature flags
  enable_monitoring = true
  enable_ssl_certificates = true
  enable_auto_updates = false
  enable_docker_swarm = true
  
  # Tags
  additional_tags = {
    environment = "staging"
    migration   = "production-to-staging"
    purpose     = "testing-clean-config"
  }
  cost_center = "jlam-staging"
  owner = "jlam-devops-staging"
}

# Override to use EXISTING IP for staging (critical!)
data "scaleway_instance_ip" "staging_ip" {
  address = "51.158.190.109"  # Keep existing production IP
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

# Staging-specific outputs
output "staging_summary" {
  description = "Staging environment summary"
  value = {
    environment = "staging"
    server_ip   = "51.158.190.109"  # Existing IP retained
    purpose     = "Testing clean configuration before production"
    ssl         = "Let's Encrypt (automatic)"
    monitoring  = "Enabled"
    backup      = "7 days retention"
    next_step   = "Test thoroughly, then deploy to production"
  }
}

output "staging_urls" {
  description = "Staging environment URLs"
  value = {
    main_app    = "https://staging.jlam.nl"  # Or could use IP
    health      = "https://staging.jlam.nl/health"
    dashboard   = "http://51.158.190.109:8080"
  }
}