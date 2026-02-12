variable "project_id" {
  type        = string
  description = "GCP project ID where the load balancer resources will be created."
}

variable "name" {
  type        = string
  description = "Name prefix for all LB resources (IP, certs, NEGs, backends, etc.)."
}

variable "backends" {
  description = "Map of backends. Key is a unique identifier (e.g., 'api', 'console')."
  type = map(object({
    domain            = string
    service_name      = string
    region            = string
    enable_iap        = bool
    iap_client_id     = optional(string)
    iap_client_secret = optional(string)
  }))
}
