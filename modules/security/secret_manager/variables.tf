variable "project_id" {
  type        = string
  description = "Project ID to create the secrets in."
}

variable "secrets" {
  description = "Map of secrets to create. Each key is a logical name; value contains secret_id and labels."
  type = map(object({
    secret_id = string
    labels    = optional(map(string), {})
  }))
  default = {}
}
