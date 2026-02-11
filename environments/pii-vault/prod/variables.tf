variable "project_id" {
  type        = string
  description = "GCP project ID for the vault prod environment."
}

variable "region" {
  type        = string
  description = "Primary region for regional resources."
  default     = "us-central1"
}
