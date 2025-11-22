# Prod Environment Terraform Notes

This directory provisions the production (`i4g-prod`) stack using the shared Terraform modules. It mirrors the dev configuration but tightens defaults so only the intended principals can reach Cloud Run services.

## Components

- Core service accounts (`sa-app` shared by FastAPI/Streamlit/console, `sa-ingest`, `sa-report`, `sa-vault`, `sa-infra`) plus least-privilege IAM bindings.
- GitHub Actions Workload Identity Federation mapped to `sa-infra` so CI can plan/apply without JSON keys.
- Cloud Run services for FastAPI and Streamlit plus the analyst console. Identity-Aware Proxy (IAP) protects each
	surface (brand, OAuth clients, IAM bindings) so analysts must authenticate via Google.
- Vertex AI Search data store (`retrieval-prod`) for production retrieval workflows.

## Required Variables

Populate these inputs before planning/applying:

- `i4g_analyst_members` — principals (users or Google Groups such as
	`group:analysts@example.com`) that should access the analyst-facing Cloud Run services via IAP. Add Google Groups
	here to avoid editing Terraform when team membership changes.
- `project_id` — GCP project ID (e.g., `i4g-prod`).
- `iap_support_email` — verified Google account email that owns the production OAuth consent screen.
- `iap_application_title` *(optional)* — display title on the consent screen (defaults to `i4g Analyst Surfaces`).
- `iap_manage_brand` *(optional)* — set to `true` only if the project is attached to a Google Cloud organization and
	Terraform should create/manage the brand; otherwise leave `false` and manage the brand manually if needed.
- `iap_existing_brand_name` *(optional)* — fully qualified brand resource name to reuse when Terraform is not managing
	it.
- `iap_manage_clients` *(optional)* — set to `true` to create per-service OAuth clients + Secret Manager secrets; leave
	`false` to manage only IAP IAM bindings.
- `iap_secret_replication_locations` *(optional)* — Secret Manager replica regions for the OAuth client secrets (defaults to the service region).
- `fastapi_image` — Artifact Registry image tag for the FastAPI service (`us-central1-docker.pkg.dev/i4g-prod/applications/fastapi:prod`).
- `fastapi_env_vars` *(optional)* — override or extend the default map (Firestone/Cloud Storage buckets, log level, etc.).
- `streamlit_image` — Artifact Registry image tag for the Streamlit UI (`us-central1-docker.pkg.dev/i4g-prod/applications/streamlit:prod`).
- `streamlit_env_vars` *(optional)* — add branding or feature flags; FastAPI URL is injected automatically.
- `fastapi_invoker_member`, `fastapi_invoker_members`, and `streamlit_invoker_member` *(optional)* — set explicit principals if additional service accounts need direct `roles/run.invoker`. The Terraform module automatically grants the shared runtime service account plus the IAP service agent.

## Usage

```bash
cd infra/environments/prod
terraform init
terraform plan -var-file=terraform.tfvars
```

Ensure the production state bucket (`tfstate-i4g-prod`) and automation account (`sa-infra@i4g-prod.iam.gserviceaccount.com`) exist using the bootstrap helpers before running `terraform init`.

When ready, promote container images to the `:prod` tags and apply changes with:

```bash
terraform apply -var-file=terraform.tfvars
```

Outputs provide the service URLs and Vertex AI Search data store identifier for downstream configuration.
