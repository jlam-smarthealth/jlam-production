# JLAM Universal SSL Certificate Module
# Generates cloud-init configuration for SSL certificate deployment
# Works across all environments: dev/staging/production

locals {
  # Generate cloud-init write_files configuration
  ssl_files = [
    {
      path        = "${var.ssl_directory}/cert.pem"
      content     = var.ssl_certificate
      permissions = "0600"
      owner       = "root:root"
    },
    {
      path        = "${var.ssl_directory}/key.pem"  
      content     = var.ssl_private_key
      permissions = "0600"
      owner       = "root:root"
    }
  ]

  # Add CA bundle only if provided
  ssl_files_with_ca = var.ssl_ca_bundle != "" ? concat(local.ssl_files, [
    {
      path        = "${var.ssl_directory}/ca-bundle.pem"
      content     = var.ssl_ca_bundle
      permissions = "0644"
      owner       = "root:root"
    }
  ]) : local.ssl_files

  # Generate cloud-init write_files entries
  cloud_init_ssl_files = [
    for file in local.ssl_files_with_ca : {
      path        = file.path
      content     = file.content
      permissions = file.permissions
      owner       = file.owner
    }
  ]

  # Generate runcmd to create directory and set permissions
  cloud_init_runcmds = [
    "mkdir -p ${var.ssl_directory}",
    "chown -R root:root ${var.ssl_directory}",
    "chmod 755 ${var.ssl_directory}"
  ]
}

# Output for use in cloud-init templates
output "cloud_init_write_files" {
  description = "SSL certificate files for cloud-init write_files section"
  value       = local.cloud_init_ssl_files
  sensitive   = true
}

output "cloud_init_runcmds" {
  description = "Commands to run for SSL directory setup"
  value       = local.cloud_init_runcmds
}

output "ssl_directory" {
  description = "SSL certificate directory path"
  value       = var.ssl_directory
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}