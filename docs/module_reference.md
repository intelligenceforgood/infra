# Terraform Module Reference

> **Last Verified:** March 2026
>
> Quick reference for all reusable Terraform modules in `infra/modules/`.
> Each entry describes the module's purpose, key inputs, and which stacks use it.

---

## Module Directory

| Module Path                            | Purpose                                         | Key Inputs                                                                               |
| -------------------------------------- | ----------------------------------------------- | ---------------------------------------------------------------------------------------- |
| `modules/run/service`                  | Cloud Run v2 service                            | `name`, `image`, `service_account`, `env_vars`, `secret_env_vars`, `invoker_members`     |
| `modules/run/job`                      | Cloud Run v2 job                                | `name`, `image`, `service_account`, `env_vars`, `args`, `timeout_seconds`, `parallelism` |
| `modules/run/domain_mapping`           | Custom domain mapping for Cloud Run             | `service_name`, `domain`                                                                 |
| `modules/scheduler/job`                | Cloud Scheduler → Cloud Run job trigger         | `name`, `schedule`, `run_job_name`, `service_account_email`                              |
| `modules/database/cloudsql`            | Cloud SQL PostgreSQL instance + databases       | `instance_name`, `database_version`, `region`, `tier`                                    |
| `modules/database/users`               | Cloud SQL user provisioning                     | `instance_name`, `users`                                                                 |
| `modules/iam/service_accounts`         | Service account creation map                    | `service_accounts` (map of key → display name)                                           |
| `modules/iam/service_account_bindings` | IAM bindings on service accounts                | `bindings` (map of role → members)                                                       |
| `modules/iam/workload_identity_github` | Workload Identity Federation for GitHub Actions | `project_id`, `github_repository`                                                        |
| `modules/iap/project`                  | IAP project-level configuration                 | `iap_support_email`, `iap_clients`                                                       |
| `modules/iap/cloud_run_service`        | IAP binding for a Cloud Run service             | `service_name`, `members`                                                                |
| `modules/iap/oauth_client`             | IAP OAuth client creation                       | `brand_name`, `application_title`                                                        |
| `modules/lb/iap_https`                 | HTTPS load balancer with IAP                    | `name`, `backends`, `ssl_certificate`                                                    |
| `modules/storage/buckets`              | GCS bucket provisioning                         | `buckets` (map of key → config)                                                          |
| `modules/security/secret_manager`      | Secret Manager secret creation                  | `secrets` (map of key → `{secret_id, labels}`)                                           |
| `modules/security/kms`                 | Cloud KMS keyring and key management            | `keyring_name`, `key_name`, `rotation_period`                                            |
| `modules/monitoring`                   | Cloud Monitoring alerting policies              | `project_id`, `notification_channels`                                                    |
| `modules/vertex_search`                | Vertex AI Search data store + engine            | `project_id`, `data_store_id`, `location`                                                |

---

## Usage Pattern

All modules follow the standard Terraform interface pattern:

- `main.tf` — resource definitions
- `variables.tf` — input variables (all must have `description` and `type`)
- `outputs.tf` — exported values consumed by callers

Sensitive variables use `sensitive = true`. Secrets are **never** stored in `.tfvars`.

### Example: Adding a new Cloud Run service

```hcl
module "run_my_service" {
  source = "../../modules/run/service"

  name            = "my-service"
  service_account = module.iam_service_accounts.emails["app"]
  image           = var.my_service_image
  env_vars        = var.my_service_env_vars
  secret_env_vars = var.my_service_secret_env_vars
  invoker_members = ["allUsers"]  # or restrict to service accounts
}
```

### Example: Adding a scheduled job

```hcl
module "run_my_job" {
  source              = "../../modules/run/job"
  name                = "my-job"
  image               = var.my_job_image
  service_account     = module.iam_service_accounts.emails["ingest"]
  env_vars            = { I4G_ENV = var.environment }
  timeout_seconds     = 600
  parallelism         = 1
  max_retries         = 0
}

module "run_my_job_scheduler" {
  source                = "../../modules/scheduler/job"
  name                  = "my-job-schedule"
  schedule              = "0 6 * * *"  # Daily at 06:00 UTC
  run_job_name          = module.run_my_job.name
  run_job_location      = module.run_my_job.location
  service_account_email = module.iam_service_accounts.emails["scheduler"]
}
```

---

## Stack Structure

```
stacks/
└── app/                        # Single unified stack for dev + prod
    ├── main.tf                 # Module calls and resources
    ├── locals.tf               # Derived values (enabled jobs, scheduled jobs)
    ├── variables.tf            # All inputs
    └── outputs.tf              # Service URIs, etc.

environments/
└── app/
    ├── dev/                    # Dev environment wrapper
    │   ├── main.tf             # module "app" { source = "../../../stacks/app" }
    │   ├── variables.tf        # Variable declarations
    │   └── terraform.tfvars    # Dev-specific values
    └── prod/                   # Prod environment wrapper
        └── ...                 # Same structure as dev
```

Behavior differences between `dev` and `prod` are controlled by `var.environment` and conditional locals in `stacks/app/locals.tf`.

---

## Related Documents

- [service_catalog.md](service_catalog.md) — Deployed services and jobs inventory
- [scheduler_inventory.md](scheduler_inventory.md) — Scheduler job specifications
- [infra/README.md](../README.md) — Infra repo overview and commands
