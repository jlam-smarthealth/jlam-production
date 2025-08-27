# JLAM Terraform Backend Configuration
# Remote state management via Terraform Cloud
# Created: 2025-08-27
# Security: State encryption, locking, versioning

terraform {
  # Backend configuration for Terraform Cloud
  cloud {
    organization = "jlam"

    workspaces {
      tags = ["jlam", "healthcare", "production"]
    }
  }
}

# Note: Workspace-specific configuration
# For production: workspace name = "jlam-production"
# For staging: workspace name = "jlam-staging"
# For dev: workspace name = "jlam-development"

# The actual workspace name is set via:
# 1. CLI: terraform workspace select <name>
# 2. Environment variable: TF_WORKSPACE=<name>
# 3. Terraform Cloud UI configuration