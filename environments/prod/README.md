# Prod Environment Terraform Notes

This directory provisions the production (`i4g-prod`) stack using the shared Terraform modules. It mirrors the dev configuration but tightens defaults so only the intended principals can reach Cloud Run services.

## Components

- Core service accounts (`sa-fastapi`, `sa-streamlit`, `sa-ingest`, `sa-report`, `sa-vault`, `sa-infra`) plus least-privilege IAM bindings.
- GitHub Actions Workload Identity Federation mapped to `sa-infra` so CI can plan/apply without JSON keys.
- Cloud Run services for FastAPI and Streamlit; no public invokers are granted by default. Streamlit receives the FastAPI URL automatically.
- Vertex AI Search data store (`retrieval-prod`) for production retrieval workflows.

## Required Variables

Populate these inputs before planning/applying:

- `project_id` — GCP project ID (e.g., `i4g-prod`).
- `fastapi_image` — Artifact Registry image tag for the FastAPI service (`us-central1-docker.pkg.dev/i4g-prod/applications/fastapi:prod`).
- `fastapi_env_vars` *(optional)* — override or extend the default map (Firestone/Cloud Storage buckets, log level, etc.).
- `streamlit_image` — Artifact Registry image tag for the Streamlit UI (`us-central1-docker.pkg.dev/i4g-prod/applications/streamlit:prod`).
- `streamlit_env_vars` *(optional)* — add branding or feature flags; FastAPI URL is injected automatically.
- `fastapi_invoker_member` / `streamlit_invoker_member` *(optional)* — set explicit principals if needed (for example, IAP service accounts). Leave blank to rely on IAP policies and the automatic Streamlit→FastAPI binding.

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
