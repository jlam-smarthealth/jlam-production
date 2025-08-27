# JLAM Staging Environment - Terraform Backend
# Workspace: jlam-staging
# Created: 2025-08-27

terraform {
  cloud {
    organization = "jlam"

    workspaces {
      name = "jlam-staging"
    }
  }
}