# modules/iam/pii_vault_access
#
# Grants service accounts in the main App project cross-project access to
# PII Vault resources (Secret Manager secrets, Cloud KMS keys, and Cloud SQL).
#
# The PII Vault projects (i4g-pii-vault-dev / i4g-pii-vault-prod) are
# storage-only — they hold secrets, encryption keys, and databases but
# contain no logic, service accounts, or role bindings of their own.  All
# access control for PII Vault resources is defined here, in the App project.

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

variable "pii_vault_project_id" {
  description = "GCP project ID of the PII Vault project (e.g. i4g-pii-vault-dev)."
  type        = string
}

variable "accessor_emails" {
  description = "List of service-account emails that need access to vault secrets and KMS keys."
  type        = list(string)
}

# ---------------------------------------------------------------------------
# Secret Manager – read-only access to tokenization secrets
# ---------------------------------------------------------------------------
resource "google_project_iam_member" "secret_accessor" {
  for_each = toset(var.accessor_emails)

  project = var.pii_vault_project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${each.value}"
}

# ---------------------------------------------------------------------------
# Cloud KMS – encrypt / decrypt using vault keys
# ---------------------------------------------------------------------------
resource "google_project_iam_member" "kms_user" {
  for_each = toset(var.accessor_emails)

  project = var.pii_vault_project_id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member  = "serviceAccount:${each.value}"
}

# ---------------------------------------------------------------------------
# Cloud SQL – connect to the vault database
# ---------------------------------------------------------------------------
resource "google_project_iam_member" "sql_client" {
  for_each = toset(var.accessor_emails)

  project = var.pii_vault_project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${each.value}"
}

resource "google_project_iam_member" "sql_instance_user" {
  for_each = toset(var.accessor_emails)

  project = var.pii_vault_project_id
  role    = "roles/cloudsql.instanceUser"
  member  = "serviceAccount:${each.value}"
}
