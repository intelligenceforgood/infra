variable "project_id" {
  type        = string
  description = "Project ID to create the KMS key ring in."
}

variable "region" {
  type        = string
  description = "Region for the KMS key ring."
  default     = "us-central1"
}

variable "key_ring_name" {
  type        = string
  description = "Name of the KMS key ring to create."
  default     = "i4g-keyring"
}
