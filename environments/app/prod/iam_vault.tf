# ---------------------------------------------------------------------------
# PII Vault Cross-Project Access
#
# The PII Vault project (i4g-pii-vault-prod) is storage-only — it holds
# tokenization secrets and KMS keys but has no service accounts or role
# bindings of its own.  All access control is defined here in the App project.
#
# Apply order (migration):
#   1. `terraform apply` in app/prod   → creates grants
#   2. `terraform apply` in pii-vault/prod → removes old grants
#
# NOTE: Unlike dev, the prod vault project does not run Cloud Run workloads,
# so there are no artifact registry reader grants here. If vault workloads
# are added later, copy the vault_reader / vault_service_agent_reader
# resources from app/dev/iam_vault.tf.
# ---------------------------------------------------------------------------

module "pii_vault_access" {
  source               = "../../../modules/iam/pii_vault_access"
  pii_vault_project_id = var.pii_vault_project_id

  accessor_emails = [
    module.iam_service_accounts.emails["app"],
    module.iam_service_accounts.emails["ingest"],
    module.iam_service_accounts.emails["report"],
  ]
}
