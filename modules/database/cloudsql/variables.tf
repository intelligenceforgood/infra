variable "project_id" {
  type        = string
  description = "GCP project ID where the Cloud SQL instance is created."
}

variable "region" {
  type        = string
  description = "Region for the Cloud SQL instance."
}

variable "config" {
  description = "Cloud SQL instance configuration."
  type = object({
    instance_name       = string
    tier                = string
    disk_size           = number
    availability_type   = string
    backup_enabled      = bool
    backup_start_time   = optional(string, "02:00")
    deletion_protection = bool
  })
}

variable "database_name" {
  type        = string
  description = "Name of the database to create on the instance."
}

variable "database_version" {
  type        = string
  description = "Cloud SQL database version (e.g., POSTGRES_15)."
  default     = "POSTGRES_15"
}

variable "enable_iam_auth" {
  type        = bool
  description = "Whether to enable Cloud SQL IAM authentication via database flags."
  default     = true
}
