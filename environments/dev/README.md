# Dev Environment Terraform Notes

This folder composes reusable modules to stand up the prototype stack in the
`i4g-dev` project. Key components currently wired in:

- Core service accounts plus scoped IAM bindings for the shared application
  runtime service account (`sa-app` powering Streamlit/FastAPI/console), ingestion jobs, report generation,
  vault, and automation.
- Workload Identity Federation pool/provider granting GitHub Actions access to
  the `sa-infra` automation account.
- Cloud Run service modules (`run_fastapi`, `run_streamlit`) deploying the API
  gateway and the analyst Streamlit UI once container images are published to
  Artifact Registry.

## Required Variables

Set the following before running `terraform plan`/`apply`:

- `i4g_analyst_members` — list of principals (`group:analysts@example.com`, `user:analyst@example.com`, service
  accounts, etc.) that should reach the analyst-facing Cloud Run services. Specify Google Groups to manage access
  centrally.
- `project_id` — GCP project ID (e.g., `i4g-dev`).
- `fastapi_image` — Container image URI (Artifact Registry or GCR) for the
  FastAPI service, such as `us-central1-docker.pkg.dev/i4g-dev/applications/fastapi:dev`.
- `fastapi_env_vars` *(optional)* — Map of environment variables injected into
  the container. Recommended values:
  - `I4G_ENV = dev`
  - `I4G_STORAGE__STRUCTURED_BACKEND = sqlite`
  - `I4G_RUNTIME__LOG_LEVEL = INFO`
- `fastapi_invoker_member` *(optional)* — Principal with `roles/run.invoker` on
  the service. Leave blank to rely on project-level Cloud Run IAM or provide a
  specific service account if FastAPI must trust another workload directly.
- `fastapi_invoker_members` *(optional)* — Additional principals that should be
  granted the invoker role on FastAPI.
- `streamlit_image` — Container image URI for the Streamlit UI service (e.g.
  `us-central1-docker.pkg.dev/i4g-dev/applications/streamlit:dev`).
- `streamlit_env_vars` *(optional)* — Map of environment variables for
  Streamlit. Recommended values:
  - `I4G_ENV = dev`
  - `I4G_API__KEY = dev-analyst-token`
  - `STREAMLIT_SERVER_TITLE = i4g Analyst Dashboard`
  The FastAPI base URL is injected automatically from the `run_fastapi`
  module output.
- `streamlit_invoker_member` *(optional)* — Principal with `roles/run.invoker`
  on the Streamlit service.
- `streamlit_invoker_members` *(optional)* — Additional invoker principals for
  the Streamlit service (leave empty to rely on IAM policies).

Example `terraform.tfvars` fragment:

```hcl
i4g_analyst_members = [
  "group:analysts@example.com"
]

project_id             = "i4g-dev"
fastapi_image          = "us-central1-docker.pkg.dev/i4g-dev/applications/fastapi:dev"
fastapi_env_vars = {
  I4G_ENV                          = "dev"
  I4G_RUNTIME__LOG_LEVEL           = "INFO"
  I4G_STORAGE__STRUCTURED_BACKEND  = "sqlite"
}
fastapi_invoker_members = [
  "serviceAccount:custom-ui@i4g-dev.iam.gserviceaccount.com"
]

streamlit_image = "us-central1-docker.pkg.dev/i4g-dev/applications/streamlit:dev"
streamlit_env_vars = {
  I4G_ENV                = "dev"
  I4G_API__KEY           = "dev-analyst-token"
  STREAMLIT_SERVER_TITLE = "i4g Analyst Dashboard"
}
streamlit_invoker_member = "group:analysts@example.com"
```

## Deployment Flow

1. Build and push the FastAPI container (see `proto/docker/fastapi.Dockerfile`).
2. Build and push the Streamlit container (`proto/docker/streamlit.Dockerfile`).
3. Run `terraform init` (one time) and `terraform plan -var-file=terraform.tfvars`.
4. Apply with `terraform apply -var-file=terraform.tfvars` once the plan looks good.
5. Capture the service URLs from `terraform output fastapi_service` and
  `terraform output streamlit_service`.

Future enhancements will add additional Cloud Run services, jobs, Scheduler
triggers, and Secret Manager wiring—compose them here by instantiating the
appropriate modules.
