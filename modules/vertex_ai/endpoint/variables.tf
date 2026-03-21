variable "project_id" {
  type        = string
  description = "GCP project ID where the Vertex AI Endpoint will be created."
}

variable "region" {
  type        = string
  description = "Region for the Vertex AI Endpoint (e.g., us-central1)."
  default     = "us-central1"
}

variable "display_name" {
  type        = string
  description = "Display name for the Vertex AI Endpoint."
}

variable "description" {
  type        = string
  description = "Human-readable description of the endpoint."
  default     = ""
}

variable "labels" {
  type        = map(string)
  description = "Labels to attach to the endpoint."
  default     = {}
}
