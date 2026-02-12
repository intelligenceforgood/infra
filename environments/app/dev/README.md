# Dev Environment Terraform Notes

This folder composes reusable modules to stand up the core stack in the
`i4g-dev` project. Key components currently wired in:

- Core service accounts plus scoped IAM bindings for the shared application
  runtime service account (`sa-app` powering FastAPI and the analyst console), ingestion jobs, report generation,
  vault, and automation.
- Workload Identity Federation pool/provider granting GitHub Actions access to
  the `sa-infra` automation account.
- Cloud Run service module (`run_fastapi`) deploying the API
  gateway once container images are published to Artifact Registry.
  - Note: For dev projects outside an Organization this repo expects you to
    manage the OAuth consent screen (brand) and OAuth clients manually. The
    Terraform modules do not create brands/clients by default; set
    `iap_manage_brand = true` only after moving the project into an Organization
    and after confirming provider support. Use `iap_project_level_bindings = false`
    to disable project-level IAP IAM entries and prefer per-service bindings.

## Required Variables

Set the following before running `terraform plan`/`apply`:

- `i4g_analyst_members` — principals (`group:analysts@example.com`, `user:analyst@example.com`, etc.) granted
  `roles/iap.httpsResourceAccessor` to reach the analyst-facing Cloud Run services via IAP.
- `i4g_admin_members` — Workspace groups or users that should hold `roles/owner` for the project (e.g., `group:gcp-i4g-admin@intelligenceforgood.org`). Keep this scoped to the break-glass admin group.
- `project_id` — GCP project ID (e.g., `i4g-dev`).
- `iap_support_email` — verified Google account email that owns the OAuth consent screen (IAP brand requirement).
- `iap_application_title` _(optional)_ — overrides the consent screen title (defaults to `i4g Analyst Surfaces`).
- `iap_manage_brand` _(optional)_ — set to `true` only if the project belongs to a Google Cloud organization and you
  want Terraform to create/manage the brand; otherwise leave `false` and manage the brand manually (or skip).
- `iap_existing_brand_name` _(optional)_ — fully qualified brand resource name to reuse when Terraform is not creating
  one.
- `fastapi_image` — Container image URI (Artifact Registry or GCR) for the
  FastAPI service, such as `us-central1-docker.pkg.dev/i4g-dev/applications/fastapi:dev`.
- `fastapi_env_vars` _(optional)_ — Map of environment variables injected into
  the container. Recommended values:
  - `I4G_ENV = dev`
  - `I4G_STORAGE__STRUCTURED_BACKEND = cloudsql`
  - `I4G_RUNTIME__LOG_LEVEL = INFO`
- `fastapi_invoker_member` _(optional)_ — Principal with `roles/run.invoker` on
  the service (the module automatically grants the shared runtime service account
  plus the IAP service agent; provide extra service accounts only when necessary).
- `fastapi_invoker_members` _(optional)_ — Additional principals that should be
  granted the invoker role on FastAPI.
  Example `terraform.tfvars` fragment:

```hcl
i4g_analyst_members = [
  "group:analysts@example.com"
]

i4g_admin_members = [
  "group:admins@example.com"
]

project_id             = "i4g-dev"
fastapi_image          = "us-central1-docker.pkg.dev/i4g-dev/applications/fastapi:dev"
fastapi_env_vars = {
  I4G_ENV                          = "dev"
  I4G_RUNTIME__LOG_LEVEL           = "INFO"
  I4G_STORAGE__STRUCTURED_BACKEND  = "cloudsql"
}
fastapi_invoker_members = [
  "serviceAccount:custom-ui@i4g-dev.iam.gserviceaccount.com"
]
```

## Deployment Flow

1. Build and push the FastAPI container (see `core/docker/fastapi.Dockerfile`).
2. Run `terraform init` (one time) and `terraform plan -var-file=terraform.tfvars`.
3. Apply with `terraform apply -var-file=terraform.tfvars` once the plan looks good.
4. Capture the service URLs from `terraform output fastapi_service`.

Future enhancements will add additional Cloud Run services, jobs, Scheduler
triggers, and Secret Manager wiring—compose them here by instantiating the
appropriate modules.
