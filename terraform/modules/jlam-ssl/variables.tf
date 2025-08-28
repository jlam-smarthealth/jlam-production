# JLAM Universal SSL Certificate Module
# For all environments: development, staging, production
# Created: 2025-08-28

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
  description = "SSL CA bundle/chain content"
  type        = string
  sensitive   = true
  default     = ""
}

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "ssl_directory" {
  description = "Directory path for SSL certificates on server"
  type        = string
  default     = "/tmp/jlam-ssl"
}