variable "project_id" {
  type        = string
  description = "GCP project ID that owns the Vertex AI Search resources."
}

variable "location" {
  type        = string
  description = "Location for Discovery Engine resources (use 'global' for search)."
}

variable "data_store_id" {
  type        = string
  description = "Identifier for the Discovery Engine data store."
}

variable "display_name" {
  type        = string
  description = "Display name for the data store."
}

variable "industry_vertical" {
  type        = string
  description = "Industry vertical hint for ranking configuration."
  default     = "GENERIC"
}

variable "solution_types" {
  type        = list(string)
  description = "Solution types supported by the data store."
  default     = ["SOLUTION_TYPE_SEARCH"]
}

variable "content_config" {
  type        = string
  description = "Content configuration for the data store (NO_CONTENT, CONTENT_REQUIRED, or PUBLIC_WEBSITE)."
  default     = "CONTENT_REQUIRED"
}

