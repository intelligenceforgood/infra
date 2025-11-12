variable "project_id" {
  type        = string
  description = "GCP project ID where buckets will be created."
}

variable "buckets" {
  description = "Map of bucket configurations keyed by logical name."
  type = map(object({
    name                       = string
    location                   = optional(string)
    storage_class              = optional(string)
    labels                     = optional(map(string))
    force_destroy              = optional(bool)
    uniform_bucket_level_access = optional(bool)
    public_access_prevention    = optional(string)
    versioning                 = optional(bool)
    lifecycle_rules = optional(list(object({
      action = object({
        type          = string
        storage_class = optional(string)
      })
      condition = object({
        age                   = optional(number)
        with_state            = optional(string)
        matches_storage_class = optional(list(string))
        matches_prefix        = optional(list(string))
        matches_suffix        = optional(list(string))
        num_newer_versions    = optional(number)
      })
    })))
    retention_policy = optional(object({
      retention_period = number
    }))
    kms_key_name = optional(string)
  }))
  default = {}
}

variable "default_location" {
  type        = string
  description = "Default location for buckets when not specified per bucket."
  default     = "US"
}
