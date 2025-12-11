# i4g PII Vault stack

This directory contains Terraform configs for the PII vault stack (dev/prod). Use the same
workflow as other `environments/` stacks:

1. Bootstrap the state bucket and automation SA:

```bash
./bootstrap/create_state_bucket.sh pii-vault-dev i4g-pii-vault-dev
./bootstrap/create_state_bucket.sh pii-vault-prod i4g-pii-vault-prod
```

2. Initialize and plan in `environments/pii-vault/dev/` (or `prod`).

3. Resources created in the vault project include:
- Secret Manager
- Cloud KMS (key ring + encryption key)
- Storage bucket for raw evidence

4. IAM bindings & cross-project interactions:
- Grant the app runtime SA (in `i4g-dev` / `i4g-prod`) `roles/secretmanager.secretAccessor` and
  access to the encryption `roles/cloudkms.cryptoKeyEncrypterDecrypter` if those keys are used.

If you want to automate granting the permissions from the app project to the vault project during
apply time, pass the app service account emails into the vault stack:

```bash
terraform plan -var 'app_service_accounts=["service-account@app-project.iam.gserviceaccount.com"]'
terraform apply -var 'app_service_accounts=["service-account@app-project.iam.gserviceaccount.com"]'
```

The dev `terraform.tfvars` already includes `sa-app@i4g-dev.iam.gserviceaccount.com`; add the prod runtime account
when you are ready to wire the production gateway to the vault secrets.

## Secrets provisioning (manual step)
Terraform creates the Secret Manager containers only. You must add versions after apply so the
services can read the HMAC pepper and any symmetric key material.

1) Tokenization pepper (HMAC secret for deterministic tokens)

```bash
PEPPER=$(openssl rand -base64 32)
printf '%s' "$PEPPER" | gcloud secrets versions add tokenization-pepper \
  --project i4g-pii-vault-dev \
  --data-file=-
# repeat for prod with the SAME value if you want cross-env deterministic tokens
```

2) pii-tokenization-key (if used for encrypting canonical PII)

```bash
KEY=$(openssl rand -base64 32)
printf '%s' "$KEY" | gcloud secrets versions add pii-tokenization-key \
  --project i4g-pii-vault-dev \
  --data-file=-
# repeat for prod (same value only if cross-env deterministic encryption is required)
```

3) Validate access via WIF impersonation

```bash
cd /Users/jerry/Work/project/i4g/proto
python scripts/infra/verify_vault_secret_access.py \
  --project i4g-pii-vault-dev \
  --service-account sa-infra@i4g-pii-vault-dev.iam.gserviceaccount.com \
  --secret-id tokenization-pepper \
  --version latest
```

Notes:
- Keep secret values out of Terraform/state; seed via secure terminal or CI.
- KMS keys (`i4g-vault-ring/i4g-vault-encrypt`) are provisioned by Terraform; the pepper stays only in Secret Manager.
