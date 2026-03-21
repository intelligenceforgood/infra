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
  description = "Name of the GCS bucket for ML data."
  default     = "i4g-ml-data"
}
