variable "project_id" {
  type        = string
  description = "GCP project ID hosting the Secret Manager secret."
}

variable "brand_name" {
  type        = string
  description = "Fully qualified IAP brand resource name."

  validation {
    condition     = trimspace(var.brand_name) != ""
    error_message = "brand_name must not be empty."
  }
}

variable "display_name" {
  type        = string
  description = "Display name assigned to the OAuth client."
}

variable "secret_id" {
  type        = string
  description = "Secret Manager identifier used to store the client secret."
}

variable "secret_replication_locations" {
  type        = list(string)
  description = "Replica locations for the Secret Manager secret."

  validation {
    condition     = length(var.secret_replication_locations) > 0
    error_message = "Provide at least one location for secret replication."
  }
}
