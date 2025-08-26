# Authentik Database Deployment - Standalone
# Deploy only the Authentik database resources

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.0"
    }
  }
}

# Variables for Authentik database only
variable "authentik_database_password" {
  description = "Authentik PostgreSQL admin password"
  type        = string
  sensitive   = true
}

variable "authentik_app_password" {
  description = "Authentik application user password"  
  type        = string
  sensitive   = true
}

variable "scaleway_region" {
  description = "Scaleway region"
  type        = string
  default     = "nl-ams"
}

# Authentik Database Instance - Dedicated Authentication Database
resource "scaleway_rdb_instance" "authentik_database" {
  name           = "jlam-authentik-db"
  node_type      = "DB-DEV-S"
  engine         = "PostgreSQL-15"
  is_ha_cluster  = false
  disable_backup = false
  volume_type    = "sbs_5k"
  volume_size_in_gb = 20

  # Security and Access
  user_name = "authentik_user"
  password  = var.authentik_database_password

  # Backup Configuration
  backup_schedule_frequency = 24 # Daily backups
  backup_schedule_retention = 7  # Keep 7 days
  
  # Enable public access for initial setup (can be disabled later)
  backup_same_region = true
  
  region = var.scaleway_region

  tags = [
    "jlam",
    "authentik",
    "authentication", 
    "database",
    "production",
    "managed-by-terraform"
  ]
}

# Create authentik database within the instance
resource "scaleway_rdb_database" "authentik" {
  instance_id = scaleway_rdb_instance.authentik_database.id
  name        = "authentik"
}

# Create dedicated user for Authentik with proper permissions
resource "scaleway_rdb_user" "authentik_app" {
  instance_id = scaleway_rdb_instance.authentik_database.id
  name        = "authentik_app"
  password    = var.authentik_app_password
  is_admin    = false
}

# Grant permissions to the app user
resource "scaleway_rdb_privilege" "authentik_app_privileges" {
  instance_id   = scaleway_rdb_instance.authentik_database.id
  user_name     = scaleway_rdb_user.authentik_app.name
  database_name = scaleway_rdb_database.authentik.name
  permission    = "all"
}

# Output the database connection details
output "authentik_database_connection" {
  description = "Authentik database connection information"
  value = {
    host = scaleway_rdb_instance.authentik_database.load_balancer[0].ip
    port = scaleway_rdb_instance.authentik_database.load_balancer[0].port
    name = scaleway_rdb_database.authentik.name
    admin_user = "authentik_user"
    app_user = "authentik_app"
  }
  sensitive = false
}