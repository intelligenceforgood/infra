# Intelligence for Good — Infrastructure

This repository manages Terraform modules, environment configuration, and automation for deploying the i4g platform on Google Cloud Platform. The workflow is intentionally Terraform-CLI only—no Terraform Cloud/SaaS dependency—so everything runs from laptops or GitHub Actions with the same source of truth. For application setup and local development details, refer to `proto/docs/dev_guide.md`.

## Structure (proposed)
- `bootstrap/` — one-time helpers for creating the state bucket, service accounts, and enabling required APIs.
- `environments/` — environment-specific configuration (e.g., `dev`, `staging`, `prod`). Each folder contains a root module that stitches reusable modules together.
- `modules/` — reusable Terraform modules (Cloud Run services, Cloud Storage buckets, IAM roles, log sinks, Secret Manager entries, etc.).
- `policy/` — optional OPA/Conftest policies for static checks before apply.
- `scripts/` — helper scripts for linting (`terraform fmt`, `tflint`), drift detection, or CI wrappers.
- `.github/workflows/` — automation for plan/apply, lint, and policy checks using GitHub Actions + Workload Identity Federation.

## Remote State & Locking (No Terraform Cloud)
- **Backend**: Terraform CLI with the native `gcs` backend.
	- Bucket name pattern: `tfstate-i4g-{env}` (per project). Create with uniform bucket-level access, versioning enabled, and `prevent_destroy` in Terraform once bootstrapped.
	- Locking: `gcs` backend already uses object generations for optimistic locking; no separate datastore required.
- **Bootstrap**: run `bootstrap/create_state_bucket.sh` (to be added) once with the `gcloud` CLI. It provisions the bucket, enables required services (`cloudresourcemanager`, `run`, `iam`, `secretmanager`, etc.), and creates the automation service account `sa-infra@{project}` with least-privilege roles (`roles/storage.admin` on the state bucket, `roles/resourcemanager.projectIamAdmin`, `roles/run.admin`, `roles/iam.securityReviewer`, etc.).
- **Authentication**:
	- Locally: `gcloud auth application-default login` or `gcloud auth login` + `gcloud config set project {project}`. Terraform can impersonate `sa-infra@{project}` using `google_client_config` + `impersonate_service_account` in the backend block.
	- CI/CD: GitHub Actions workflow uses Workload Identity Federation (WIF). We create a provider mapped to the repository and grant `sa-infra@{project}` `roles/iam.workloadIdentityUser` for that provider so no JSON keys are stored in GitHub.

Example backend configuration (placed in each environment root module):

```hcl
terraform {
	backend "gcs" {
		bucket                      = "tfstate-i4g-dev"
		prefix                      = "env/dev"
		impersonate_service_account = "sa-infra@i4g-dev.iam.gserviceaccount.com"
	}
	required_version = ">= 1.9.0, < 2.0.0"
}
```

## Workflow Overview
1. **Author changes** in a feature branch under `modules/` or `environments/{env}`.
2. **terraform fmt && tflint** locally; run `terraform plan` from the relevant environment folder. The plan uses the shared GCS backend through impersonation.
3. **Open a PR**; GitHub Actions executes lint + plan jobs (dry-run only) using WIF.
4. **Review the plan output** attached to the PR. Once approved, merge to `main`.
5. **Apply stage**: a separate workflow (manual dispatch or triggered on `main`) runs `terraform apply` with the same backend and service account.
6. **Drift detection**: nightly workflow runs `terraform plan -detailed-exitcode` and alerts if drift is detected.

No SaaS state management is involved; everything relies on GCS + IAM.

## Module Roadmap
To align with the security matrix in `planning/future_architecture.md`, we will introduce modules under `modules/` as follows:

- `iam/service_accounts`: create core service accounts (`sa-fastapi`, `sa-streamlit`, `sa-ingest`, `sa-report`, `sa-vault`, `sa-infra`) with labels and Workload Identity annotations.
- `iam/workload_identity_github`: workload identity pool/provider for GitHub Actions tokens (implemented for dev).
- `iam/roles`: manage custom IAM roles (e.g., narrowed Vertex AI Search access, read-only Firestore roles, signed URL issuers).
- `iam/bindings`: attach roles to service accounts per environment, including conditional bindings for signed URL creation and Secret Manager access.
- `network/vpc`: provision VPC, subnets, and Serverless VPC connectors for Cloud Run → AlloyDB/Cloud SQL connectivity.
- `storage/buckets`: configure evidence/report buckets with lifecycle rules, uniform access, CMEK if required.
- `run/service`: parameterized Cloud Run service module (image, service account, env vars, ingress). Variants for FastAPI, Streamlit, tokenization microservice.
- `run/job`: Cloud Run job module for ingestion/report workers.
- `scheduler/job`: Cloud Scheduler jobs triggering Cloud Run jobs with OIDC tokens.
- `secrets/manager`: define Secret Manager entries, rotation windows, and IAM bindings.
- `observability/logging`: sinks to BigQuery/Storage, uptime checks, alerting policies.

Environment roots (`environments/dev/main.tf`, etc.) compose these modules and pass project-specific values.

## Identity & Access Strategy (Terraform View)
- Service accounts mirror the role-to-capability matrix. Each binding is declared in Terraform, making drift visible during plan.
- Workload Identity Federation resources live in `modules/iam/workload_identity_github`, defining pools/providers for GitHub Actions (extend with additional modules for other issuers if needed).
- OAuth clients for Google Identity Platform can be managed via Terraform’s `google_identity_platform_oauth_idp_config` resources; local development uses mock tokens outside Terraform scope.
- Secrets rotation schedules are represented via Cloud Scheduler jobs + Cloud Run jobs modules, wired to call rotation workflows.

## Getting Started
1. Clone the repo and run `scripts/check_tools.sh` (to be added) to verify `terraform`, `tflint`, and `gcloud` availability.
2. Authenticate with `gcloud`: `gcloud auth login && gcloud auth application-default login`.
3. If you plan to manage Vertex/Discovery Engine resources from your workstation, attach the dev project as the quota project for Application Default Credentials:

	```bash
	gcloud auth application-default set-quota-project i4g-dev
	```

	Replace `i4g-dev` when targeting another environment. Without this, Discovery Engine API calls fail with `SERVICE_DISABLED` even when the API is enabled.
4. Create the state bucket and automation service account: `./bootstrap/create_state_bucket.sh dev` (script will output bucket name and service account email).
5. Navigate to `environments/dev/` and run `terraform init`.
6. Run `terraform plan` to verify backend connectivity (override `-var "github_repository=owner/repo"` if using a fork).

## GitHub Actions Workflow (Dev Terraform)

Workflow file: `.github/workflows/terraform-dev.yml`.

1. **Create repository variables** (`Settings → Variables → Actions`):
	- `TF_GCP_PROJECT_ID` → `i4g-dev`
	- `TF_GCP_WORKLOAD_IDENTITY_PROVIDER` → workload identity provider resource path (e.g., `projects/123456789/locations/global/workloadIdentityPools/github-actions/providers/proto`)
	- `TF_GCP_SERVICE_ACCOUNT` → automation service account email (`sa-infra@i4g-dev.iam.gserviceaccount.com`)
2. The workflow uses `google-github-actions/auth@v2` to exchange GitHub OIDC tokens for short-lived credentials and runs `terraform fmt/plan` on pull requests touching `infra/**`.
3. On merges to `main`, the workflow re-runs plan and `apply -auto-approve` so state stays in sync with the repo. Override `github_repository` via repository variable or by editing the workflow if you run from a fork.

### Later: Move Projects Under the Official Org/Billing
Once the nonprofit has a Google Cloud Organization and billing account:

1. **Link billing:**

		```bash
		gcloud beta billing projects link <project_id> \
			--billing-account=<BILLING_ACCOUNT_ID>
		```

2. **Create org folder (optional):** organize projects under a folder (e.g., `i4g-environments`).

3. **Grant admin roles:** add org administrators as `projectOwner` or custom roles on each project.

4. **Move projects into the org:**

		```bash
		gcloud beta projects move <project_id> \
			--organization=<ORG_ID>
		```

	 (Use `--folder=<FOLDER_ID>` if moving into a specific folder.)

5. **Update Terraform backend impersonation:** ensure `sa-infra@{project}` has `roles/iam.serviceAccountTokenCreator` and `roles/iam.workloadIdentityUser` as needed in the new org.

6. **Audit IAM:** run `terraform plan` to confirm bindings align with the new org context.

## Guidelines
- Keep Terraform versions pinned via `required_version` and modules pinned via `required_providers`.
- Prefer least-privilege IAM roles; document every custom role in module README files.
- Use pull requests for all infrastructure changes; plans must be reviewed before apply.
- Avoid committing credentials—rely on WIF or short-lived impersonation tokens.

## Related Repositories
- `intelligenceforgood/i4g` — application services.
- `intelligenceforgood/docs` — public documentation site.
- `intelligenceforgood/proto` — experimental prototypes.
