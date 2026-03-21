variable "project_id" {
  type        = string
  description = "GCP project ID where the BigQuery dataset will be created."
}

variable "dataset_id" {
  type        = string
  description = "BigQuery dataset ID (e.g., i4g_ml)."
}

variable "location" {
  type        = string
  description = "Geographic location for the dataset (e.g., us-central1, US)."
  default     = "US"
}

variable "description" {
  type        = string
  description = "Human-readable description of the dataset."
  default     = ""
}

variable "friendly_name" {
  type        = string
  description = "Friendly display name for the dataset."
  default     = null
}

variable "labels" {
  type        = map(string)
  description = "Labels to attach to the dataset and its tables."
  default     = {}
}

variable "default_table_expiration_ms" {
  type        = number
  description = "Default expiration time for tables in the dataset, in milliseconds. Null means tables do not expire."
  default     = null
}

variable "access" {
  description = "Access control entries for the dataset."
  type = list(object({
    role           = string
    user_by_email  = optional(string)
    group_by_email = optional(string)
    special_group  = optional(string)
  }))
  default = []
}

variable "tables" {
  description = "Map of table_id to table configuration. Each entry creates a BigQuery table in the dataset."
  type = map(object({
    schema              = string
    labels              = optional(map(string))
    deletion_protection = optional(bool)
    time_partitioning = optional(object({
      type  = string
      field = optional(string)
    }))
    clustering = optional(list(string))
  }))
  default = {}
}
