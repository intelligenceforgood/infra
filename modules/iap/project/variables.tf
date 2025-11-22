variable "project_id" {
  type        = string
  description = "GCP project ID where the IAP brand + project settings should live."
}

variable "support_email" {
  type        = string
  description = "Verified Google account email that owns the OAuth consent screen (required when Terraform manages the brand)."
  default     = ""
}

variable "application_title" {
  type        = string
  description = "Human-readable label shown on the OAuth consent screen."
  default     = "i4g Analyst Surfaces"
}

variable "manage_brand" {
  type        = bool
  description = "Whether Terraform should create/manage the IAP brand (project must belong to an organization)."
  default     = false
}

variable "existing_brand_name" {
  type        = string
  description = "Optional fully qualified brand resource name to reuse when Terraform is not managing the brand."
  default     = ""
}

variable "enable_allowed_domains" {
  type        = bool
  description = "Toggle the allowed-domains feature for the project-wide IAP policy."
  default     = false
}

variable "allowed_domains" {
  type        = list(string)
  description = "List of trusted domains used when allowed-domains is enabled."
  default     = []

  validation {
    condition     = var.enable_allowed_domains == false || length(var.allowed_domains) > 0
    error_message = "At least one domain must be provided when enable_allowed_domains is true."
  }
}

variable "allow_http_options" {
  type        = bool
  description = "Allow HTTP OPTIONS requests (CORS preflight) to skip authorization checks."
  default     = true
}
