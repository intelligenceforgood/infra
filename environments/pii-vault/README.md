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
- Grant the app runtime SA (in `i4g-app-dev` / `i4g-app-prod`) `roles/secretmanager.secretAccessor` and
  access to the encryption `roles/cloudkms.cryptoKeyEncrypterDecrypter` if those keys are used.

If you want to automate granting the permissions from the app project to the vault project during
apply time, pass the app service account emails into the vault stack:

```bash
terraform plan -var 'app_service_accounts=["service-account@app-project.iam.gserviceaccount.com"]'
terraform apply -var 'app_service_accounts=["service-account@app-project.iam.gserviceaccount.com"]'
```
# PII Vault Stack (dev/prod)

This stack is for PII vault related resources (KMS, Secret Manager) that should be isolated from the application project.

Structure:
- `environments/pii-vault/dev/`: Development stack – lightweight KMS + Secret Manager for sandbox
- `environments/pii-vault/prod/`: Production-grade stack – hardened KMS, key rotation, audit logging

Bootstrapping:
- Run: `./bootstrap/create_state_bucket.sh pii-vault-dev i4g-pii-vault-dev` to create the state bucket and `sa-infra` in the project.
- Initialize: `cd environments/pii-vault/dev && terraform init`

Notes:
- This is an initial scaffold demonstrating usage; policies, IAM, and hardened KMS/Secret rotation will be added in later changes.
- Do not store secrets in source control; use the Secret Manager modules and provide versions via the CLI/script or `scripts/infra` helpers.
