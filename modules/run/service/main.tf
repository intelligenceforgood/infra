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
  autoscaling_annotations = merge(
    var.min_instances == null ? {} : { "autoscaling.knative.dev/minScale" = tostring(var.min_instances) },
    var.max_instances == null ? {} : { "autoscaling.knative.dev/maxScale" = tostring(var.max_instances) }
  )

  ingress_annotation = var.ingress == "" ? {} : { "run.googleapis.com/ingress" = var.ingress }

  vpc_annotations = var.vpc_connector == "" ? {} : {
    "run.googleapis.com/vpc-access-connector" = var.vpc_connector,
    "run.googleapis.com/vpc-egress"           = var.vpc_connector_egress_settings
  }

  secret_annotations = length(var.secret_env_vars) == 0 ? {} : {
    "run.googleapis.com/secrets" = join(",", [
      for env_key, env_val in var.secret_env_vars :
      format("%s:%s", env_key, env_val.secret)
    ])
  }

  template_annotations = merge(
    var.annotations,
    local.autoscaling_annotations,
    local.ingress_annotation,
    local.vpc_annotations,
    local.secret_annotations
  )
  effective_invokers = distinct([
    for member in concat(
      var.invoker_member == "" ? [] : [var.invoker_member],
      var.invoker_members
    ) : trimspace(member)
    if trimspace(member) != ""
  ])
}

resource "google_cloud_run_service" "this" {
  name     = var.name
  project  = var.project_id
  location = var.location

  autogenerate_revision_name = var.autogenerate_revision_name

  template {
    metadata {
      annotations = local.template_annotations
      labels      = var.labels
    }

    spec {
      service_account_name = var.service_account

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
            value_from {
              secret_key_ref {
                name = env.key
                key  = coalesce(lookup(env.value, "version", null), "latest")
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

      container_concurrency = var.container_concurrency
      timeout_seconds       = var.timeout_seconds
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

}

resource "google_cloud_run_service_iam_binding" "invoker" {
  count = length(local.effective_invokers) > 0 ? 1 : 0

  project  = var.project_id
  location = var.location
  service  = google_cloud_run_service.this.name
  role     = var.invoker_role
  members  = local.effective_invokers
}
