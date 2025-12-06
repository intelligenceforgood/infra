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
