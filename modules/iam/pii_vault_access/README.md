# pii\_vault\_access

Grants App-project service accounts cross-project access to PII Vault
resources (Secret Manager, Cloud KMS, and Cloud SQL).

## Usage

```hcl
module "pii_vault_access" {
  source               = "../../../modules/iam/pii_vault_access"
  pii_vault_project_id = "i4g-pii-vault-dev"

  accessor_emails = [
    module.iam_service_accounts.emails["app"],
    module.iam_service_accounts.emails["ingest"],
    module.iam_service_accounts.emails["report"],
  ]
}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `pii_vault_project_id` | GCP project ID of the PII Vault project | `string` | yes |
| `accessor_emails` | Service-account emails needing vault access | `list(string)` | yes |

## Outputs

| Name | Description |
|------|-------------|
| `secret_accessor_members` | Map of SA email → IAM member resource ID |
| `kms_user_members` | Map of SA email → IAM member resource ID |
| `sql_client_members` | Map of SA email → IAM member resource ID |
| `sql_instance_user_members` | Map of SA email → IAM member resource ID |
