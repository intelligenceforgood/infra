variable "project_id" {
  type        = string
  description = "GCP project ID for the ML platform."
}

variable "region" {
  type        = string
  description = "Primary region for regional resources."
  default     = "us-central1"
}

variable "data_bucket_name" {
  type        = string
  description = "Name of the GCS bucket for ML data (datasets, models, artifacts)."
  default     = "i4g-ml-data"
}

variable "core_dev_project_id" {
  type        = string
  description = "GCP project ID for i4g-dev (core platform) — used for cross-project IAM."
  default     = "i4g-dev"
}

variable "core_prod_project_id" {
  type        = string
  description = "GCP project ID for i4g-prod (core platform) — used for cross-project IAM."
  default     = "i4g-prod"
}

variable "serve_image_tag" {
  type        = string
  description = "Tag for the ML serving container image."
  default     = "dev"
}

variable "model_artifact_uri" {
  type        = string
  description = "GCS URI of the model artifacts for the serving container."
  default     = ""
}

variable "shadow_model_artifact_uri" {
  type        = string
  description = "GCS URI of the shadow (candidate) model artifacts for A/B comparison on dev."
  default     = ""
}

variable "ner_model_artifact_uri" {
  type        = string
  description = "GCS URI of the NER model artifacts for named-entity extraction on dev."
  default     = ""
}

variable "alert_email" {
  type        = string
  description = "Email address for ML platform monitoring alerts."
  default     = "ml-alerts@i4g.dev"
}

variable "prod_serve_image_tag" {
  type        = string
  description = "Tag for the production ML serving container image."
  default     = "prod"
}

variable "prod_model_artifact_uri" {
  type        = string
  description = "GCS URI of the model artifacts for the production serving container."
  default     = ""
}

variable "prod_shadow_model_artifact_uri" {
  type        = string
  description = "GCS URI of the shadow (candidate) model artifacts for A/B comparison on prod."
  default     = ""
}

variable "prod_ner_model_artifact_uri" {
  type        = string
  description = "GCS URI of the NER model artifacts for named-entity extraction on prod."
  default     = ""
}

variable "drift_model_id" {
  type        = string
  description = "Model ID to monitor for drift (used by daily drift Cloud Run Job)."
  default     = "classification-xgboost-v1"
}

# ── Phase 3: Champion/Challenger ─────────────────────────────────────────────

variable "challenger_model_artifact_uri" {
  type        = string
  description = "GCS URI of the challenger model artifacts for A/B routing on dev."
  default     = ""
}

variable "challenger_traffic_weight" {
  type        = string
  description = "Traffic weight for the challenger model (0.0–1.0)."
  default     = "0.0"
}

variable "prod_challenger_model_artifact_uri" {
  type        = string
  description = "GCS URI of the challenger model artifacts for A/B routing on prod."
  default     = ""
}

variable "prod_challenger_traffic_weight" {
  type        = string
  description = "Traffic weight for the challenger model on prod (0.0–1.0)."
  default     = "0.0"
}

# ── Phase 3: Risk Scoring ────────────────────────────────────────────────────

variable "risk_model_artifact_uri" {
  type        = string
  description = "GCS URI of the risk scoring XGBoost model artifacts on dev."
  default     = ""
}

variable "prod_risk_model_artifact_uri" {
  type        = string
  description = "GCS URI of the risk scoring XGBoost model artifacts on prod."
  default     = ""
}

# ── Phase 3: Feature Store ───────────────────────────────────────────────────

variable "feature_store_id" {
  type        = string
  description = "Vertex AI Feature Store ID for online feature serving."
  default     = ""
}

# ── Phase 3: Embeddings / Similarity ─────────────────────────────────────────

variable "embedding_model_name" {
  type        = string
  description = "Name of the sentence-transformer model for document similarity."
  default     = "all-MiniLM-L6-v2"
}

variable "similarity_enabled" {
  type        = string
  description = "Enable FAISS similarity index at startup ('true' or 'false')."
  default     = "false"
}

# ── Phase 3: Cost-Aware Routing ──────────────────────────────────────────────

variable "cost_aware_routing" {
  type        = string
  description = "Enable cost-aware model routing ('true' or 'false')."
  default     = "false"
}
