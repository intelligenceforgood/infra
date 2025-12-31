variable "project_id" {
  type        = string
  description = "GCP project ID for the vault dev environment."
}

variable "region" {
  type        = string
  description = "Primary region for regional resources."
  default     = "us-central1"
}

variable "app_service_accounts" {
  type        = list(string)
  description = "List of app service account emails to grant cross-project access (optional)."
  default     = []
}

variable "iam_db_groups" {
  type        = list(string)
  description = "List of IAM group emails to grant database access."
  default     = []
}

