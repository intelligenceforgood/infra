variable "project_id" {
  type        = string
  description = "GCP project ID for the vault dev environment."
}

variable "region" {
  type        = string
  description = "Primary region for regional resources."
  default     = "us-central1"
}

variable "iam_db_groups" {
  type        = list(string)
  description = "List of IAM group emails to grant database access."
  default     = []
}

variable "app_service_accounts" {
  type        = list(string)
  description = "App-project SA emails that need database user entries on the vault Cloud SQL instance. IAM roles (cloudsql.client, cloudsql.instanceUser) are managed in app/dev via the pii_vault_access module."
  default     = []
}

