terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

resource "google_cloud_run_v2_job" "this" {
  name     = var.name
  location = var.location
  project  = var.project_id
  deletion_protection = var.deletion_protection

  template {
    labels      = var.labels
    annotations = var.annotations
    parallelism = coalesce(var.parallelism, 1)
    task_count  = coalesce(var.task_count, 1)

    template {
  service_account = var.service_account
  timeout         = format("%ss", coalesce(var.timeout_seconds, 600))
  max_retries     = coalesce(var.max_retries, 3)

      dynamic "vpc_access" {
        for_each = var.vpc_connector == null || var.vpc_connector == "" ? [] : [var.vpc_connector]
        content {
          connector = vpc_access.value
          egress    = var.vpc_connector_egress_settings
        }
      }

      containers {
        image   = var.image
        command = var.command
        args    = var.args

        dynamic "env" {
          for_each = var.env_vars
          content {
            name  = env.key
            value = env.value
          }
        }

        dynamic "resources" {
          for_each = var.resource_limits == null || length(var.resource_limits) == 0 ? [] : [var.resource_limits]
          content {
            limits = resources.value
          }
        }
      }
    }
  }
}
