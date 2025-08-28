# Variables for JLAM Development Server
# Configure these via terraform.tfvars or environment variables

variable "scaleway_zone" {
  description = "Scaleway zone for development server"
  type        = string
  default     = "nl-ams-1"
}

variable "scaleway_region" {
  description = "Scaleway region for development server"
  type        = string
  default     = "nl-ams"
}

variable "ssh_public_key" {
  description = "SSH public key for server access"
  type        = string
  # This should be provided via terraform.tfvars or environment variable
  # Example: "ssh-rsa AAAAB3NzaC1yc2E... user@hostname"
}

variable "scaleway_access_key" {
  description = "Scaleway access key"
  type        = string
  sensitive   = true
}

variable "scaleway_secret_key" {
  description = "Scaleway secret key"  
  type        = string
  sensitive   = true
}

variable "scaleway_project_id" {
  description = "Scaleway project ID"
  type        = string
  sensitive   = true
}

# SSL Certificate Variables (for Universal SSL Module)
variable "ssl_certificate" {
  description = "SSL certificate content (*.jlam.nl wildcard cert)"
  type        = string
  sensitive   = true
}

variable "ssl_private_key" {
  description = "SSL private key content"
  type        = string
  sensitive   = true
}

variable "ssl_ca_bundle" {
  description = "SSL CA bundle/chain content (optional)"
  type        = string
  sensitive   = true
  default     = ""
}