# Copilot Instructions for i4g/infra

**Unified Workspace Context:** This repository is part of the `i4g` multi-root workspace. Shared coding standards, routines, and platform context live in the `copilot/` repo. These instructions contain only repo-specific context.

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

For a full pre-merge review, use the `pre-merge-review` routine and the checklist in `copilot/.github/shared/pre-merge-checklist.instructions.md`.

## Coding Standards

Follow `copilot/.github/shared/general-coding.instructions.md` for all shared language standards.

