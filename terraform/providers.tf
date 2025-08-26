# JLAM Production Infrastructure - Provider Configuration
# Clean, enterprise-ready provider setup

# Note: terraform{} block is defined in main.tf to avoid duplication

# Scaleway Provider Configuration
provider "scaleway" {
  # Credentials via environment variables:
  # SCW_ACCESS_KEY, SCW_SECRET_KEY, SCW_DEFAULT_PROJECT_ID, SCW_DEFAULT_ORGANIZATION_ID

  zone   = var.scaleway_zone
  region = var.scaleway_region

  # Note: Scaleway provider does not support default_tags
  # Tags are applied individually to resources in main.tf
}