terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

resource "google_cloud_scheduler_job" "this" {
  name        = var.name
  project     = var.project_id
  region      = var.region
  schedule    = var.schedule
  time_zone   = var.time_zone
  description = var.description

  attempt_deadline = format("%ss", var.attempt_deadline_seconds)

  http_target {
    http_method = "POST"
    uri         = format(
      "https://%s-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/%s/jobs/%s:run",
      var.run_job_location,
      var.project_id,
      var.run_job_name,
    )
    body    = base64encode(var.body)
    headers = merge({
      "Content-Type" = "application/json"
    }, var.headers)

    oidc_token {
      service_account_email = var.service_account_email
      audience              = var.audience
    }
  }
}
