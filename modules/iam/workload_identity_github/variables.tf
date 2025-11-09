variable "project_id" {
  type        = string
  description = "Project ID where the workload identity pool resides."
}

variable "pool_id" {
  type        = string
  description = "ID of the workload identity pool (must be unique within the project)."
}

variable "pool_display_name" {
  type        = string
  description = "Display name for the workload identity pool."
  default     = "GitHub Actions"
}

variable "pool_description" {
  type        = string
  description = "Description for the workload identity pool."
  default     = "Federates GitHub Actions OIDC tokens"
}

variable "provider_id" {
  type        = string
  description = "ID for the workload identity pool provider (e.g., github-actions)."
}

variable "provider_display_name" {
  type        = string
  description = "Display name for the provider."
  default     = "GitHub"
}

variable "provider_description" {
  type        = string
  description = "Description for the provider."
  default     = "Trusts GitHub Actions OIDC tokens"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository in owner/name format (e.g., intelligenceforgood/proto)."
}

variable "attribute_condition" {
  type        = string
  description = "CEL expression filtering acceptable GitHub tokens."
  default     = "attribute.repository == \"intelligenceforgood/proto\""
}

variable "attribute_mapping" {
  description = "Mapping of OIDC token attributes to Google attributes."
  type = map(string)
  default = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.workflow"   = "assertion.workflow"
    "attribute.ref"        = "assertion.ref"
  }
}
