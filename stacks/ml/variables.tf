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
