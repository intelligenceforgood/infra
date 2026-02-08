# Intelligence for Good — Infrastructure

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Terraform](https://img.shields.io/badge/Terraform-1.9.x-blueviolet.svg)](https://www.terraform.io/)
[![Cloud](https://img.shields.io/badge/Cloud-GCP-informational.svg)](https://cloud.google.com/)

This Terraform package defines all shared infrastructure for the i4g platform on Google Cloud. It is designed for the Terraform CLI (local laptops and GitHub Actions) with state stored in Google Cloud Storage. Application-specific runbooks live in `core/docs/development/dev_guide.md`.

---

## Repository Layout
- `bootstrap/` – one-time helpers (state bucket creation, API enablement).
- `environments/app/` – root modules for the application stack (`dev`, `prod`).
	Additional stacks (e.g., `pii-vault`) can live alongside `app/` using the same layout.

## Additional stacks

- To add a new stack (for example, a PII vault), create `environments/<stack>/<env>` entries such as:
	- `environments/pii-vault/dev`
	- `environments/pii-vault/prod`

	Each folder should include a `backend.tf`, `providers.tf`, `variables.tf`, and `main.tf` or module
	references that compose the required platform resources. The `bootstrap/create_state_bucket.sh`
	helper accepts arbitrary environment strings (e.g., `pii-vault-dev`) so state buckets like `tfstate-i4g-pii-vault-dev`
	are automatically created when bootstrapping a new stack.

	Example commands for the vault stack:

	```bash
	# Initialize and plan vault dev
	cd infra/environments/pii-vault/dev
	terraform init
	terraform plan -var "project_id=i4g-pii-vault-dev" -var "github_repository=intelligenceforgood/core"

	# Initialize and plan vault prod
	cd ../prod
	terraform init
	terraform plan -var "project_id=i4g-pii-vault-prod" -var "github_repository=intelligenceforgood/core"
	```

### Naming conventions

- Stack/project naming example: `i4g-app-dev`, `i4g-app-prod`, `i4g-pii-vault-dev`, `i4g-pii-vault-prod`.
- The bootstrap helper uses the `ENVIRONMENT` parameter to generate a state bucket name: `tfstate-i4g-<ENVIRONMENT>`.
- Keep the `i4g` prefix to group state buckets under a single project umbrella while separating stacks by the rest of the suffix.
	If you prefer a different naming pattern, update the bootstrap script and backend prefixes accordingly.
- `modules/` – reusable building blocks (Cloud Run services/jobs, IAM, buckets, scheduler, etc.).
- `.github/workflows/` – Terraform plan/apply automation that authenticates via Workload Identity Federation.

---

## Prerequisites
- Terraform `>= 1.9.0 < 2.0.0`.
- Google Cloud SDK (`gcloud`) with the alpha storage component.
- Access to the target project with permissions to enable services, create storage buckets, and manage IAM.

Authenticate before touching Terraform:

```bash
gcloud auth login
gcloud auth application-default login
```

If you manage Vertex/Discovery resources locally, scope Application Default Credentials to the project to avoid `SERVICE_DISABLED` errors:

```bash
gcloud auth application-default set-quota-project i4g-dev
```

Replace `i4g-dev` with the project you are targeting.

---

## Bootstrapping a New Environment
Run these steps once per GCP project before Terraform `init`.

1. **Create state bucket and automation service account.**

	 ```bash
	 ./bootstrap/create_state_bucket.sh dev i4g-dev
	 ```

	 The script enables the core APIs (including Artifact Registry), creates `tfstate-i4g-dev`, and provisions `sa-infra@i4g-dev.iam.gserviceaccount.com` with required roles.

2. **Configure Terraform backend.** Add the emitted snippet to `environments/app/<env>/backend.tf` if it differs from the checked-in example:

	 ```hcl
	 terraform {
		 backend "gcs" {
			 bucket                      = "tfstate-i4g-dev"
			 prefix                      = "env/dev"
			 impersonate_service_account = "sa-infra@i4g-dev.iam.gserviceaccount.com"
		 }
	 }
	 ```

3. **Initialize Terraform.** From `environments/app/dev/` (or `prod/`):

	 ```bash
	 terraform init
	 ```

	 Initialization uses your local ADC credentials but impersonates `sa-infra` for all state operations and plans.

---

## Day-to-Day Workflow
1. Work from a feature branch and edit files under `modules/` or `environments/app/<env>/`.
2. Format and lint locally: `terraform fmt -recursive` (tflint optional but recommended).
3. Run `terraform plan` inside the relevant environment directory. Provide overrides such as `-var "github_repository=owner/repo"` if you are testing from a fork.
   > **Note:** If you have local overrides (e.g., for IAP secrets), you must explicitly include them:
   > `terraform plan -var-file="local-overrides.tfvars"`
   > `terraform apply -var-file="local-overrides.tfvars"`

4. Open a pull request. GitHub Actions (`.github/workflows/terraform-dev.yml`) re-runs `fmt` and `plan` using Workload Identity Federation.
5. After review merge into `main`. Dev applies run automatically; prod applies remain manual for now.

---

## Promoting to Production
1. Build and publish container images to Artifact Registry (`applications/<service>:dev`).
2. When ready to promote, retag the tested digests to `:prod` or update the prod `terraform.tfvars` image references explicitly.
3. Import any pre-existing service accounts into Terraform state (see Troubleshooting) to avoid recreation conflicts.
4. From `environments/app/prod/` run:

	 ```bash
	 terraform plan
	 terraform apply
	 ```

5. Smoke test FastAPI endpoints, confirm Cloud Run jobs, and update `planning/change_log.md` with noteworthy outcomes.

---

## Container Images & Artifact Registry
- Terraform now manages the regional `applications` repository in Artifact Registry and grants runtime read access plus writer access to `sa-infra`.
- Docker build/push commands should target `us-central1-docker.pkg.dev/<project>/applications/<name>:<tag>`.
- For local pushes make sure `gcloud auth configure-docker us-central1-docker.pkg.dev` has been run once; CI uses Workload Identity Federation automatically.
- `scripts/infra/add_azure_secrets.py` adds Secret Manager versions for the Azure connection strings and admin key.

---

## Troubleshooting
- **`failed to fetch oauth token: Repository "applications" not found`**
	- Ensure the Artifact Registry API is enabled. `./bootstrap/create_state_bucket.sh` covers this; if you skipped it run `gcloud services enable artifactregistry.googleapis.com --project <project>`.
	- Apply Terraform in `environments/app/<env>/` to create the `applications` repository before pushing images.

- **`alreadyExists: Service account ...` during apply**
	- Import the resource instead of recreating it:

		```bash
		terraform import \
			'module.iam_service_accounts.google_service_account.this["infra"]' \
			projects/<project>/serviceAccounts/sa-infra@<project>.iam.gserviceaccount.com
		```

	- Repeat for any other pre-existing accounts (`fastapi`, etc.).

- **`permission denied for impersonating sa-infra`**
	- Grant the operator account (or GitHub Actions WIF principal) `roles/iam.serviceAccountTokenCreator` on `sa-infra`.
	- Verify your backend block includes `impersonate_service_account` and you re-ran `terraform init` after edits.

- **Cloud Scheduler failures ~~calling~~ jobs**
	- Schedulers are only created when a job definition includes a non-empty `schedule`. Keep `schedule` omitted while iterating to avoid premature triggers.
	- Confirm the Cloud Scheduler service account (`service-<project-number>@gcp-sa-cloudscheduler.iam.gserviceaccount.com`) has `roles/iam.serviceAccountTokenCreator`. Terraform now manages this binding automatically; re-apply if missing.

- **Discovery (Vertex AI Search) requests fail with `SERVICE_DISABLED`**
	- Run `gcloud auth application-default set-quota-project <project>` so ADC requests bill against the project with the API enabled.
- **Weekly refresh job fails with `Secret version not found`**
	- Terraform only creates the Secret Manager placeholders; add versions with the helper:
		```bash
		python scripts/infra/add_azure_secrets.py --project <project>
		```
	- Add `--use-env` to read `AZURE_SQL_CONNECTION_STRING`, `AZURE_STORAGE_CONNECTION_STRING`, and `AZURE_SEARCH_ADMIN_KEY` from the environment if you are automating rotations.
	- Re-run the Cloud Run job or wait for the next scheduled trigger once versions exist.

---

## GitHub Actions Configuration
The dev workflow lives at `.github/workflows/terraform-dev.yml`.

Set the following repository variables under `Settings → Variables → Actions`:
- `TF_GCP_PROJECT_ID` – e.g., `i4g-dev`.
- `TF_GCP_PII_VAULT_PROJECT_ID` – e.g., `i4g-pii-vault-dev`.
- `TF_GCP_WORKLOAD_IDENTITY_PROVIDER` – resource path like `projects/123456789/locations/global/workloadIdentityPools/github-actions/providers/core`.
- `TF_GCP_SERVICE_ACCOUNT` – `sa-infra@i4g-dev.iam.gserviceaccount.com`.

The workflow uses `google-github-actions/auth@v2` to exchange the GitHub OIDC token for Google credentials, then runs `terraform fmt` and `terraform plan`. Apply automation for prod can be added later following the same pattern.

---

## Guidelines
- Keep Terraform version pins in sync across modules and environments.
- Prefer least-privilege IAM policies and document exceptions inline.
- Use pull requests for every change; never apply directly from a local `main`.
- Store no long-lived credentials—use impersonation or Workload Identity Federation.

Related repositories:
- `intelligenceforgood/core` – prototype and shared utilities.
- `intelligenceforgood/i4g` – production application services.
- `intelligenceforgood/docs` – public documentation site.
