# JLAM Production Infrastructure - Outputs
# Clean deployment information and status

# ===== SERVER INFORMATION =====
output "server_id" {
  description = "Production server instance ID"
  value       = scaleway_instance_server.jlam_production.id
}

output "server_name" {
  description = "Production server name"
  value       = scaleway_instance_server.jlam_production.name
}

output "server_type" {
  description = "Production server instance type"
  value       = scaleway_instance_server.jlam_production.type
}

output "server_image" {
  description = "Production server operating system image"
  value       = scaleway_instance_server.jlam_production.image
}

# ===== NETWORK INFORMATION =====
output "public_ip" {
  description = "Production server public IP address"
  value       = var.use_existing_ip ? var.existing_ip_address : scaleway_instance_server.jlam_production.public_ip
}

output "private_ip" {
  description = "Production server private IP address"
  value       = scaleway_instance_server.jlam_production.private_ip
}

output "ip_id" {
  description = "IP address resource ID (for IP retention)"
  value       = var.use_existing_ip ? data.scaleway_instance_ip.existing_ip[0].id : scaleway_instance_server.jlam_production.ip_id
}

# ===== SECURITY INFORMATION =====
output "security_group_id" {
  description = "Security group ID"
  value       = scaleway_instance_security_group.jlam_production.id
}

output "security_group_name" {
  description = "Security group name"
  value       = scaleway_instance_security_group.jlam_production.name
}

# ===== VOLUME INFORMATION =====
output "data_volume_id" {
  description = "Data volume ID"
  value       = scaleway_instance_volume.jlam_data.id
}

output "data_volume_size" {
  description = "Data volume size in GB"
  value       = scaleway_instance_volume.jlam_data.size_in_gb
}

# ===== DEPLOYMENT INFORMATION =====
output "deployment_timestamp" {
  description = "Deployment timestamp for tracking"
  value       = local.deployment_timestamp
}

output "terraform_workspace" {
  description = "Terraform workspace used for deployment"
  value       = terraform.workspace
}

# ===== APPLICATION URLS =====
output "application_urls" {
  description = "Production application URLs"
  value = {
    main_app          = "https://app.jlam.nl"
    authentication    = "https://auth.jlam.nl"
    monitoring        = "https://monitor.jlam.nl"
    traefik_dashboard = "http://${var.use_existing_ip ? var.existing_ip_address : scaleway_instance_server.jlam_production.public_ip}:8080"
  }
}

# ===== SSH CONNECTION =====
output "ssh_connection" {
  description = "SSH connection command"
  value       = "ssh -i ~/.ssh/jlam_tunnel_key jlam@${var.use_existing_ip ? var.existing_ip_address : scaleway_instance_server.jlam_production.public_ip}"
  sensitive   = false
}

# ===== HEALTH CHECK URLS =====
output "health_check_urls" {
  description = "Health check endpoints"
  value = {
    main_health   = "https://app.jlam.nl/health"
    traefik_ping  = "http://${var.use_existing_ip ? var.existing_ip_address : scaleway_instance_server.jlam_production.public_ip}:8080/ping"
    server_status = "http://${var.use_existing_ip ? var.existing_ip_address : scaleway_instance_server.jlam_production.public_ip}"
  }
}

# ===== DATABASE CONNECTION INFO =====
output "database_connection" {
  description = "JLAM database connection information (host and port only)"
  value = {
    host = var.jlam_database_host
    port = var.jlam_database_port
    name = var.jlam_database_name
    # Note: username and password are not exposed for security
  }
  sensitive = true
}

output "authentik_database_connection" {
  description = "Authentik database connection information"
  value = {
    host = scaleway_rdb_instance.authentik_database.endpoint_ip
    port = scaleway_rdb_instance.authentik_database.endpoint_port
    name = scaleway_rdb_database.authentik.name
    # Note: credentials not exposed in outputs for security
  }
  sensitive = false
}

# ===== RESOURCE TAGS =====
output "resource_tags" {
  description = "Tags applied to all resources"
  value       = local.common_labels
}

# ===== DEPLOYMENT SUMMARY =====
output "deployment_summary" {
  description = "Complete deployment summary"
  value = {
    status           = "deployed"
    server_ready     = "deployment_complete"
    ip_retained      = scaleway_instance_server.jlam_production.public_ip
    deployment_date  = local.deployment_timestamp
    infrastructure   = "clean-enterprise-ready"
    monitoring       = var.enable_monitoring ? "enabled" : "disabled"
    ssl_certificates = var.enable_ssl_certificates ? "enabled" : "disabled"
    docker_swarm     = var.enable_docker_swarm ? "enabled" : "disabled"
  }
}

# ===== COST INFORMATION =====
output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown (EUR)"
  value = {
    server_instance = "~€15/month (DEV1-L)"
    data_volume     = "~€2/month (20GB SSD)"
    ip_address      = "€0/month (included)"
    bandwidth       = "~€0-5/month (depends on traffic)"
    total_estimated = "~€17-22/month"
  }
}

# ===== NEXT STEPS =====
output "next_steps" {
  description = "Post-deployment next steps"
  value = [
    "1. Wait 5-10 minutes for complete service initialization",
    "2. Verify health checks: curl https://app.jlam.nl/health",
    "3. Check Traefik dashboard: http://${var.use_existing_ip ? var.existing_ip_address : scaleway_instance_server.jlam_production.public_ip}:8080",
    "4. Verify SSL certificates are working properly",
    "5. Test authentication flow via https://auth.jlam.nl",
    "6. Monitor resource usage and performance",
    "7. Set up automated backups if not already configured"
  ]
}