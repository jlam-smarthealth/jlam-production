# Authentik Database Instance - Dedicated Authentication Database
# This creates a separate PostgreSQL instance for Authentik SSO
# Keeps authentication data completely isolated from JLAM application data

resource "scaleway_rdb_instance" "authentik_database" {
  name           = "jlam-authentik-db"
  node_type      = "DB-DEV-S"
  engine         = "PostgreSQL-15"
  is_ha_cluster  = false
  disable_backup = false
  volume_type    = "bssd"
  volume_size_in_gb = 20

  # Security and Access
  user_name = "authentik_user"
  password  = var.authentik_database_password

  # Backup Configuration
  backup_schedule_frequency = 24 # Daily backups
  backup_schedule_retention = 7  # Keep 7 days
  
  # Network Security
  private_network {
    pn_id = scaleway_vpc_private_network.jlam_network.id
  }

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

# Private network for secure database communication
resource "scaleway_vpc_private_network" "jlam_network" {
  name   = "jlam-private-network"
  region = var.scaleway_region
  
  tags = [
    "jlam",
    "production", 
    "private-network",
    "managed-by-terraform"
  ]
}