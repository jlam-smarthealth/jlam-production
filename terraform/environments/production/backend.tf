# JLAM Production Environment - Terraform Backend
# Workspace: jlam-production
# Created: 2025-08-27

terraform {
  cloud {
    organization = "jlam"
    
    workspaces {
      name = "jlam-production"
    }
  }
}