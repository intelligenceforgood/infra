variable "project_id" {
  type        = string
  description = "GCP project where IAM bindings should be applied."
}

variable "bindings" {
  description = "Map of binding definitions keyed by logical name."
  type = map(object({
    member = string
    roles  = list(string)
  }))
}
