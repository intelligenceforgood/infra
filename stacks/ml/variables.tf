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
