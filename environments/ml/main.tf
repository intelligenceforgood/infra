# ---------------------------------------------------------------------------
# ML Environment — Thin Wrapper
#
# All infrastructure logic lives in stacks/ml/. This file only calls the
# stack module with environment-specific values passed through from tfvars.
# ---------------------------------------------------------------------------

module "ml" {
  source = "../../stacks/ml"

  providers = {
    google      = google
    google-beta = google-beta
  }

  project_id       = var.project_id
  region           = var.region
  data_bucket_name = var.data_bucket_name
}
