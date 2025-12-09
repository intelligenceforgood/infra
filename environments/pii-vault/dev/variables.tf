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
variable "project_id" {
  type        = string
  description = "GCP project ID for the pii-vault dev environment."
}

variable "region" {
  type        = string
  description = "Primary region for KMS and Secret Manager resources."
  default     = "us-central1"
}

variable "pii_admin_members" {
  type        = list(string)
  description = "Principals that should receive admin access to the pii vault project."
  default     = []
}

variable "authorized_service_accounts" {
  type        = list(string)
  description = "List of service account emails (from application projects) granted access to secrets/KMS resources."
  default     = []
}
