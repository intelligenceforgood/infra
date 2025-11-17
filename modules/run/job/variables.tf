variable "project_id" {
  type        = string
  description = "GCP project ID hosting the Cloud Run job."
}

variable "location" {
  type        = string
  description = "Region for the Cloud Run job."
}

variable "name" {
  type        = string
  description = "Name of the Cloud Run job."
}

variable "service_account" {
  type        = string
  description = "Service account email used to execute the job."
}

variable "image" {
  type        = string
  description = "Container image URI for the job."
}

variable "env_vars" {
  type        = map(string)
  description = "Environment variables injected into the job container."
  default     = {}
}

variable "secret_env_vars" {
  description = "Secret-backed environment variables injected into the job container."
  type = map(object({
    secret  = string
    version = optional(string)
  }))
  default = {}
}

variable "command" {
  type        = list(string)
  description = "Optional command override for the container."
  default     = []
}

variable "args" {
  type        = list(string)
  description = "Optional arguments passed to the container."
  default     = []
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to the job template."
  default     = {}
}

variable "annotations" {
  type        = map(string)
  description = "Annotations applied to the job template."
  default     = {}
}

variable "parallelism" {
  type        = number
  description = "Number of tasks to run in parallel."
  default     = 1
}

variable "task_count" {
  type        = number
  description = "Total number of tasks to run."
  default     = 1
}

variable "timeout_seconds" {
  type        = number
  description = "Execution timeout per task in seconds."
  default     = 600
}

variable "max_retries" {
  type        = number
  description = "Maximum number of retries for failed tasks."
  default     = 3
}

variable "resource_limits" {
  type        = map(string)
  description = "Resource limits map (e.g. cpu, memory)."
  default     = {}
}

variable "vpc_connector" {
  type        = string
  description = "Optional Serverless VPC connector name."
  default     = null
  nullable    = true
}

variable "vpc_connector_egress_settings" {
  type        = string
  description = "Egress setting when using VPC connector (ALL_TRAFFIC or PRIVATE_RANGES_ONLY)."
  default     = "ALL_TRAFFIC"
}

variable "deletion_protection" {
  type        = bool
  description = "Whether Terraform-managed job resources are deletion protected."
  default     = false
}
