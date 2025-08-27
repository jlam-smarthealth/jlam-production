# JLAM Production Infrastructure - Variables
# Clean, enterprise-grade variable definitions

# ===== DEPLOYMENT CONFIGURATION =====
variable "deployment_timestamp" {
  description = "Timestamp for deployment tracking"
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}$", var.deployment_timestamp)) || var.deployment_timestamp == ""
    error_message = "Deployment timestamp must be in format YYYY-MM-DD-HHMM or empty."
  }
}

variable "environment" {
  description = "Environment name (production, staging, development)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be production, staging, or development."
  }
}

# ===== JLAM DATABASE CONFIGURATION =====
variable "jlam_database_host" {
  description = "JLAM PostgreSQL database host"
  type        = string
  sensitive   = true
}

variable "jlam_database_port" {
  description = "JLAM PostgreSQL database port"
  type        = string
  default     = "20832"

  validation {
    condition     = can(regex("^[0-9]+$", var.jlam_database_port))
    error_message = "Database port must be a valid port number."
  }
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

  validation {
    condition     = length(var.jlam_database_password) >= 12
    error_message = "Database password must be at least 12 characters long."
  }
}

variable "jlam_database_name" {
  description = "JLAM PostgreSQL database name"
  type        = string
  default     = "rdb"
}

# ===== AUTHENTIK DATABASE CONFIGURATION =====
variable "authentik_database_password" {
  description = "Authentik PostgreSQL admin password"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.authentik_database_password) >= 16
    error_message = "Authentik database password must be at least 16 characters long."
  }
}

variable "authentik_app_password" {
  description = "Authentik application user password"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.authentik_app_password) >= 16
    error_message = "Authentik app password must be at least 16 characters long."
  }
}

# ===== APPLICATION CONFIGURATION =====
variable "secret_key_base" {
  description = "Application secret key base for session encryption"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.secret_key_base) >= 64
    error_message = "Secret key base must be at least 64 characters long."
  }
}

# ===== INFRASTRUCTURE CONFIGURATION =====
variable "server_type" {
  description = "Scaleway instance type for production server"
  type        = string
  default     = "DEV1-L"

  validation {
    condition = contains([
      "DEV1-S",  # 1 vCPU, 2GB RAM - development
      "DEV1-M",  # 1 vCPU, 4GB RAM - small production  
      "DEV1-L",  # 2 vCPU, 4GB RAM - recommended production
      "DEV1-XL", # 3 vCPU, 8GB RAM - high traffic
      "GP1-XS",  # 1 vCPU, 1GB RAM - minimal
      "GP1-S",   # 2 vCPU, 4GB RAM - general purpose
      "GP1-M",   # 4 vCPU, 8GB RAM - medium workload
      "GP1-L"    # 8 vCPU, 16GB RAM - large workload
    ], var.server_type)
    error_message = "Server type must be a valid Scaleway instance type."
  }
}

variable "server_image" {
  description = "Server operating system image"
  type        = string
  default     = "ubuntu_jammy"

  validation {
    condition = contains([
      "ubuntu_jammy",
      "ubuntu_focal",
      "debian_bullseye",
      "debian_bookworm"
    ], var.server_image)
    error_message = "Server image must be a supported Linux distribution."
  }
}

variable "data_volume_size" {
  description = "Size of the data volume in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.data_volume_size >= 10 && var.data_volume_size <= 10000
    error_message = "Data volume size must be between 10 and 10000 GB."
  }
}

# ===== NETWORK CONFIGURATION =====
variable "scaleway_zone" {
  description = "Scaleway availability zone"
  type        = string
  default     = "nl-ams-1"

  validation {
    condition = contains([
      "nl-ams-1", "nl-ams-2", "nl-ams-3",
      "fr-par-1", "fr-par-2", "fr-par-3",
      "pl-waw-1", "pl-waw-2", "pl-waw-3"
    ], var.scaleway_zone)
    error_message = "Scaleway zone must be a valid zone."
  }
}

variable "scaleway_region" {
  description = "Scaleway region"
  type        = string
  default     = "nl-ams"

  validation {
    condition = contains([
      "nl-ams", "fr-par", "pl-waw"
    ], var.scaleway_region)
    error_message = "Scaleway region must be a valid region."
  }
}

# ===== SECURITY CONFIGURATION =====
variable "admin_ips" {
  description = "List of IP addresses allowed for administrative access"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Consider restricting in production
}

variable "enable_monitoring" {
  description = "Enable monitoring and alerting"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 365
    error_message = "Backup retention must be between 7 and 365 days."
  }
}

# ===== FEATURE FLAGS =====
variable "enable_ssl_certificates" {
  description = "Enable SSL certificate management"
  type        = bool
  default     = true
}

variable "enable_auto_updates" {
  description = "Enable automatic system updates"
  type        = bool
  default     = false # Disabled for production stability
}

variable "enable_docker_swarm" {
  description = "Enable Docker Swarm mode for clustering"
  type        = bool
  default     = true
}

# ===== TAGS CONFIGURATION =====
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "cost_center" {
  description = "Cost center for billing allocation"
  type        = string
  default     = "jlam-platform"
}

variable "owner" {
  description = "Resource owner for management and contact"
  type        = string
  default     = "jlam-devops"
}