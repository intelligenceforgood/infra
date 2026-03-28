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

  model_artifact_uri            = var.model_artifact_uri
  shadow_model_artifact_uri     = var.shadow_model_artifact_uri
  challenger_model_artifact_uri = var.challenger_model_artifact_uri
  challenger_traffic_weight     = var.challenger_traffic_weight
  risk_model_artifact_uri       = var.risk_model_artifact_uri
  ner_model_artifact_uri        = var.ner_model_artifact_uri
  cost_aware_routing            = var.cost_aware_routing
  similarity_enabled            = var.similarity_enabled
}
