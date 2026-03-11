# ---------------------------------------------------------------------------
# PII-Vault Stack — Variables
# ---------------------------------------------------------------------------

variable "environment" {
  type        = string
  description = "Deployment environment label (dev or prod)."

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be 'dev' or 'prod'."
  }
}

variable "project_id" {
  type        = string
  description = "GCP project ID for the vault environment."
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
  description = "App-project SA emails that need database user entries on the vault Cloud SQL instance. IAM roles are managed in the app stack via the pii_vault_access module."
  default     = []
}

# ── Database ─────────────────────────────────────────────────────────────────

variable "database_instance_name" {
  type        = string
  description = "Cloud SQL instance name for the vault database."
}

variable "database_tier" {
  type        = string
  description = "Cloud SQL machine tier."
  default     = "db-f1-micro"
}

variable "database_disk_size" {
  type        = number
  description = "Initial disk size in GB."
  default     = 10
}

variable "database_availability_type" {
  type        = string
  description = "Cloud SQL availability type (ZONAL or REGIONAL)."
  default     = "ZONAL"
}

variable "database_backup_enabled" {
  type        = bool
  description = "Whether to enable automated backups."
  default     = false
}

variable "database_backup_start_time" {
  type        = string
  description = "Preferred backup start time (HH:MM)."
  default     = "02:00"
}

variable "database_pitr_enabled" {
  type        = bool
  description = "Whether to enable point-in-time recovery."
  default     = false
}

variable "database_deletion_protection" {
  type        = bool
  description = "Whether deletion protection is enabled on the Cloud SQL instance."
  default     = false
}

# ── Storage ──────────────────────────────────────────────────────────────────

variable "bucket_force_destroy" {
  type        = bool
  description = "Whether the vault objects bucket can be force-destroyed."
  default     = true
}

variable "bucket_lifecycle_age" {
  type        = number
  description = "Days after which objects in the vault bucket are deleted."
  default     = 365
}

# ── Vault Cloud Run Service ─────────────────────────────────────────────────

variable "deploy_vault_service" {
  type        = bool
  description = "Whether to deploy the vault Cloud Run service. Enable for environments that need the vault API."
  default     = false
}

variable "vault_service_image" {
  type        = string
  description = "Container image URI for the vault Cloud Run service."
  default     = ""
}

variable "vault_service_cloudsql_instance_override" {
  type        = string
  description = "Override for the Cloud SQL instance connection name used by the vault service. If empty, uses the instance created by this stack."
  default     = ""
}
