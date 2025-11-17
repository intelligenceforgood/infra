variable "project_id" {
  type        = string
  description = "GCP project ID containing the Cloud Run job."
}

variable "region" {
  type        = string
  description = "Region for the Cloud Scheduler job."
}

variable "name" {
  type        = string
  description = "Name of the Cloud Scheduler job."
}

variable "schedule" {
  type        = string
  description = "Cron schedule expression."
}

variable "time_zone" {
  type        = string
  description = "Time zone for the schedule."
  default     = "UTC"
}

variable "description" {
  type        = string
  description = "Optional job description."
  default     = ""
}

variable "attempt_deadline_seconds" {
  type        = number
  description = "Attempt deadline in seconds."
  default     = 300
}

variable "run_job_name" {
  type        = string
  description = "Name of the Cloud Run job to trigger."
}

variable "run_job_location" {
  type        = string
  description = "Region of the Cloud Run job to trigger."
}

variable "service_account_email" {
  type        = string
  description = "Service account email used for authenticated requests."
}

variable "audience" {
  type        = string
  description = "Optional audience claim for the OIDC token. Ignored when oauth_scopes is provided."
  default     = ""
}

variable "oauth_scopes" {
  type        = list(string)
  description = "Optional list of OAuth scopes. When provided, Cloud Scheduler will mint an OAuth access token instead of an OIDC token."
  default     = []
}

variable "headers" {
  type        = map(string)
  description = "Additional HTTP headers for the request."
  default     = {}
}

variable "body" {
  type        = string
  description = "JSON payload sent in the POST request body."
  default     = "{}"
}
