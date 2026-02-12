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

  validation {
    condition     = can(regex("^db-(f1-micro|g1-small|custom-[0-9]+-[0-9]+)$", var.config.tier))
    error_message = "config.tier must be a valid Cloud SQL tier (e.g., db-f1-micro, db-g1-small, db-custom-1-3840)."
  }

  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.config.availability_type)
    error_message = "config.availability_type must be either ZONAL or REGIONAL."
  }
}

variable "database_name" {
  type        = string
  description = "Name of the database to create on the instance."
}

variable "database_version" {
  type        = string
  description = "Cloud SQL database version (e.g., POSTGRES_15)."
  default     = "POSTGRES_15"

  validation {
    condition     = can(regex("^POSTGRES_[0-9]+$", var.database_version))
    error_message = "database_version must match the pattern POSTGRES_<major> (e.g., POSTGRES_15, POSTGRES_16)."
  }
}

variable "enable_iam_auth" {
  type        = bool
  description = "Whether to enable Cloud SQL IAM authentication via database flags."
  default     = true
}
