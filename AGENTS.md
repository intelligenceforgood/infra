# Infra — Repo Context

> **For the Antigravity Agent:** Auto-read this file when working in the `infra/` repo. For platform-wide architecture and service topology, read `antigravity/knowledge/architecture/architecture.md`.

## Environment

- **Language:** Terraform (HCL)
- **Auth:** `gcloud auth application-default login` (impersonate `sa-infra`)
- **Always target:** `i4g-dev` before `i4g-prod`

## Terraform Conventions

- `snake_case` for all resource names, variables, and outputs.
- Run `terraform fmt` before every commit.
- Every variable must have `description` and `type`.
- Secrets: mark `sensitive = true` and store in Secret Manager — **never** in `.tfvars`.
- Module file layout: `main.tf`, `variables.tf`, `outputs.tf` per module.

## Module Structure

Key modules in `modules/`:

- `iam/workload_identity_github` — Workload Identity Federation for GitHub Actions
- `run/` — Cloud Run services and jobs
- `database/` — Cloud SQL
- `lb/` — Load balancer
- `scheduler/` — Cloud Scheduler jobs

Environments live in `environments/app/` (per-environment stacks).

## Quality Gate

```bash
terraform fmt -check -recursive   # must pass before merge
```

## Coding Standards

- For Terraform conventions, read `antigravity/knowledge/standards/terraform.md`
