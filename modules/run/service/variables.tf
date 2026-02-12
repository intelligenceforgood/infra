variable "project_id" {
  type        = string
  description = "GCP project ID where the Cloud Run service will be deployed."
}

variable "name" {
  type        = string
  description = "Name of the Cloud Run service."
}

variable "location" {
  type        = string
  description = "Region for the Cloud Run service (e.g., us-central1)."
  default     = "us-central1"
}

variable "service_account" {
  type        = string
  description = "Service account email that the service runs as."
}

variable "image" {
  type        = string
  description = "Container image URI to deploy."
}

variable "args" {
  type        = list(string)
  description = "Container args override."
  default     = []
}

variable "command" {
  type        = list(string)
  description = "Container command override."
  default     = []
}

variable "env_vars" {
  type        = map(string)
  description = "Environment variables to inject into the container."
  default     = {}
}

variable "secret_env_vars" {
  description = "Secret-backed environment variables injected into the container."
  type = map(object({
    secret  = string
    version = optional(string)
  }))
  default = {}
}

variable "container_ports" {
  description = "List of container ports to expose."
  type = list(object({
    name           = optional(string)
    container_port = optional(number)
  }))
  default = [
    {
      name           = "http1"
      container_port = 8080
    }
  ]
}

variable "resource_limits" {
  type        = map(string)
  description = "Resource limits for the container (cpu, memory)."
  default = {
    cpu    = "1"
    memory = "512Mi"
  }
}

variable "container_concurrency" {
  type        = number
  description = "Maximum number of concurrent requests per container instance."
  default     = 80
}

variable "timeout_seconds" {
  type        = number
  description = "Request timeout in seconds."
  default     = 300
}

variable "ingress" {
  type        = string
  description = "Ingress setting for the service. Accepts v2 enum values (INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER) or legacy v1 annotation values. Leave blank for provider default."
  default     = ""

  validation {
    condition = var.ingress == "" || contains([
      "all", "internal", "internal-only", "internal-and-cloud-load-balancing",
      "INGRESS_TRAFFIC_ALL", "INGRESS_TRAFFIC_INTERNAL_ONLY", "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
    ], var.ingress)
    error_message = "ingress must be one of: INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER (or legacy values: all, internal, internal-only, internal-and-cloud-load-balancing), or empty string."
  }
}

variable "min_instances" {
  type        = number
  description = "Minimum number of container instances to keep warm."
  default     = null
}

variable "max_instances" {
  type        = number
  description = "Maximum number of container instances."
  default     = null
}

variable "annotations" {
  type        = map(string)
  description = "Additional template annotations."
  default     = {}
}

variable "labels" {
  type        = map(string)
  description = "Labels to attach to the service."
  default     = {}
}

variable "invoker_member" {
  type        = string
  description = "Principal granted the invoker role (leave blank to skip binding)."
  default     = ""
}

variable "invoker_members" {
  type        = list(string)
  description = "Additional principals granted the invoker role."
  default     = []
}

variable "invoker_role" {
  type        = string
  description = "IAM role granted to invoker principal."
  default     = "roles/run.invoker"
}

variable "vpc_connector" {
  type        = string
  description = "Optional Serverless VPC connector to attach."
  default     = ""
}

variable "vpc_connector_egress_settings" {
  type        = string
  description = "Egress settings when a VPC connector is used."
  default     = "ALL_TRAFFIC"
}
