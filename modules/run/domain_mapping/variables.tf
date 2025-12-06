variable "project_id" {
  type        = string
  description = "Project ID where the Cloud Run service lives (for domain mapping)."
}

variable "region" {
  type        = string
  description = "Region of the Cloud Run service (e.g., us-central1)."
  default     = "us-central1"
}

variable "service_name" {
  type        = string
  description = "Cloud Run service name (the service to map the domain to)."
}

variable "domain" {
  type        = string
  description = "Fully-qualified domain name to map to the Cloud Run service (e.g., api.example.org)."
}

variable "dns_managed_zone" {
  type        = string
  description = "Optional Cloud DNS Managed Zone name to create the DNS record in (repo must have permission)."
  default     = ""
}

variable "dns_project" {
  type        = string
  description = "Optional project where the DNS managed zone lives (if different from project_id)."
  default     = ""
}
