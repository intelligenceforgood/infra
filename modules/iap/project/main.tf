terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

locals {
  manage_access_settings = var.enable_allowed_domains || var.allow_http_options
}

/*
The IAP OAuth Admin API (brands/clients) is deprecated. This module
does not create `google_iap_brand` resources. If you need an OAuth brand
for IAP, create it manually or via an alternative automation path and set
`existing_brand_name` to the brand resource name.
*/

locals {
  provided_brand_name  = trimspace(var.existing_brand_name) != "" ? var.existing_brand_name : null
  effective_brand_name = local.provided_brand_name
}

resource "google_iap_settings" "project" {
  count = local.manage_access_settings ? 1 : 0

  name = format("projects/%s/iap_web", var.project_id)

  dynamic "access_settings" {
    for_each = [1]
    content {
      dynamic "allowed_domains_settings" {
        for_each = var.enable_allowed_domains ? [1] : []
        content {
          enable  = true
          domains = var.allowed_domains
        }
      }

      dynamic "cors_settings" {
        for_each = var.allow_http_options ? [1] : []
        content {
          allow_http_options = true
        }
      }
    }
  }

  # No explicit depends_on: brand management is handled outside Terraform.
}
