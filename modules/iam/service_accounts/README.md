# Service Account Module

Creates a set of Google Cloud service accounts based on a simple map input. The module keeps
metadata centralized and returns the resulting emails and unique IDs for downstream bindings.

## Inputs

- `project_id` – target project for the accounts.
- `service_accounts` – map keyed by logical name; each entry must supply:
  - `account_id` (<= 30 characters, lowercase, underscores allowed)
  - `display_name`
  - optional `description`

Example usage:

```hcl
module "iam_service_accounts" {
  source     = "../../modules/iam/service_accounts"
  project_id = var.project_id

  service_accounts = {
    app = {
      account_id   = "sa-app"
      display_name = "Application Runtime"
      description  = "Runs FastAPI and console services"
    }
    ingest = {
      account_id   = "sa-ingest"
      display_name = "Ingestion Jobs"
      description  = "Executes scheduled ingestion Cloud Run jobs"
    }
  }
}
```

The module exposes the `emails` and `service_account_ids` outputs for referencing in
IAM bindings or workload identity configurations.
