variable "project_id" {
  type        = string
  description = "Project ID to create the secret in."
}

variable "region" {
  type        = string
  description = "Replication region for user-managed replicas."
  default     = "us-central1"
}

variable "secret_id" {
  type        = string
  description = "Secret id (e.g., 'pii-sample-secret')"
}
