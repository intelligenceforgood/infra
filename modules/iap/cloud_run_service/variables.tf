variable "project_id" {
  type        = string
  description = "GCP project ID hosting the Cloud Run service."
}

variable "region" {
  type        = string
  description = "Region where the Cloud Run service is deployed."
}

variable "service_name" {
  type        = string
  description = "Name of the Cloud Run service protected by IAP."
}

variable "manage_client" {
  type        = bool
  description = "Whether to create a dedicated OAuth client + Secret Manager entry for this service."
  default     = false
}

variable "brand_name" {
  type        = string
  description = "Fully qualified brand resource name (required when manage_client is true)."
  default     = ""
}

variable "display_name" {
  type        = string
  description = "Human-readable name for the OAuth client created for this service."
  default     = ""
}

variable "access_members" {
  type        = list(string)
  description = "Principals granted IAP HTTPS resource access for this service."
  default     = []

  validation {
    condition     = length(var.access_members) > 0
    error_message = "Provide at least one principal for IAP access."
  }
}

variable "secret_replication_locations" {
  type        = list(string)
  description = "Locations used when storing the OAuth client secret in Secret Manager."
  default     = []
}

variable "secret_id" {
  type        = string
  description = "Optional override for the Secret Manager secret ID."
  default     = ""
}
