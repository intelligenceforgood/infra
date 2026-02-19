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
  # Map legacy v1 annotation values to v2 enum values for backward compatibility.
  ingress_map = {
    ""                                       = null
    "all"                                    = "INGRESS_TRAFFIC_ALL"
    "internal"                               = "INGRESS_TRAFFIC_INTERNAL_ONLY"
    "internal-only"                          = "INGRESS_TRAFFIC_INTERNAL_ONLY"
    "internal-and-cloud-load-balancing"      = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
    "INGRESS_TRAFFIC_ALL"                    = "INGRESS_TRAFFIC_ALL"
    "INGRESS_TRAFFIC_INTERNAL_ONLY"          = "INGRESS_TRAFFIC_INTERNAL_ONLY"
    "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER" = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  }

  effective_ingress = var.ingress == "" ? null : lookup(local.ingress_map, var.ingress, var.ingress)

  effective_invokers = distinct([
    for member in concat(
      var.invoker_member == "" ? [] : [var.invoker_member],
      var.invoker_members
    ) : trimspace(member)
    if trimspace(member) != ""
  ])
}

resource "google_cloud_run_v2_service" "this" {
  name     = var.name
  project  = var.project_id
  location = var.location

  deletion_protection = var.deletion_protection

  ingress = local.effective_ingress

  template {
    service_account = var.service_account
    labels          = var.labels
    annotations     = var.annotations

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    max_instance_request_concurrency = var.container_concurrency
    timeout                          = "${var.timeout_seconds}s"

    dynamic "vpc_access" {
      for_each = var.vpc_connector != "" ? [1] : []
      content {
        connector = var.vpc_connector
        egress    = var.vpc_connector_egress_settings
      }
    }

    containers {
      image   = var.image
      args    = var.args
      command = var.command

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.secret_env_vars
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value.secret
              version = coalesce(env.value.version, "latest")
            }
          }
        }
      }

      dynamic "ports" {
        for_each = var.container_ports
        content {
          name           = try(ports.value.name, null)
          container_port = try(ports.value.container_port, 8080)
        }
      }

      resources {
        limits = var.resource_limits
      }
    }
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}

resource "google_cloud_run_v2_service_iam_binding" "invoker" {
  count = length(local.effective_invokers) > 0 ? 1 : 0

  project  = var.project_id
  location = var.location
  name     = google_cloud_run_v2_service.this.name
  role     = var.invoker_role
  members  = local.effective_invokers
}
