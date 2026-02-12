variable "pii_vault_project_id" {
  type        = string
  description = "GCP project ID of the PII Vault project (e.g. i4g-pii-vault-dev)."
}

variable "accessor_emails" {
  type        = list(string)
  description = "List of service-account emails that need access to vault secrets and KMS keys."
}
