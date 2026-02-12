variable "project_id" {
  type        = string
  description = "GCP project ID where IAM bindings are applied."
}

variable "instance_name" {
  type        = string
  description = "Cloud SQL instance name to create database users on."
}

variable "iam_groups" {
  description = "IAM groups to register as Cloud SQL users with project-level role bindings."
  type = map(object({
    email = string
    roles = list(string)
  }))
  default = {}
}

variable "service_accounts" {
  description = "Service accounts to register as Cloud SQL users with optional project-level role bindings."
  type = map(object({
    email = string
    roles = optional(list(string), [])
  }))
  default = {}
}
