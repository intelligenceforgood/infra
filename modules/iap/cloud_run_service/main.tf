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
  resolved_display_name = trimspace(var.display_name) != "" ? var.display_name : format("%s IAP Client", var.service_name)
  resolved_secret_id    = trimspace(var.secret_id) != "" ? var.secret_id : format("iap-client-%s", replace(var.service_name, "_", "-"))
  secret_locations      = length(var.secret_replication_locations) > 0 ? var.secret_replication_locations : [var.region]
}

module "oauth_client" {
  count  = var.manage_client ? 1 : 0
  source = "../oauth_client"

  project_id                   = var.project_id
  brand_name                   = var.brand_name
  display_name                 = local.resolved_display_name
  secret_id                    = local.resolved_secret_id
  secret_replication_locations = local.secret_locations
}

resource "google_iap_web_cloud_run_service_iam_binding" "access" {
  project                = var.project_id
  location               = var.region
  cloud_run_service_name = var.service_name
  role                   = "roles/iap.httpsResourceAccessor"
  members                = var.access_members
}
