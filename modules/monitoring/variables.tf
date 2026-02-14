variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "notification_email" {
  description = "Email address for alert notifications."
  type        = string
}

variable "detokenization_threshold" {
  description = "Max detokenization alert events per hour before firing."
  type        = number
  default     = 5
}

variable "ingestion_alert_threshold" {
  description = "Number of ingestion failure alert events per hour before firing."
  type        = number
  default     = 1
}

variable "dossier_alert_threshold" {
  description = "Number of dossier stuck/failure events per hour before firing."
  type        = number
  default     = 1
}
