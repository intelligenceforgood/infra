variable "project_id" {
  type        = string
  description = "GCP project where service accounts are created."
}

variable "service_accounts" {
  description = "Map of service account definitions keyed by logical name."
  type = map(object({
    account_id   = string
    display_name = string
    description  = optional(string)
  }))
}
