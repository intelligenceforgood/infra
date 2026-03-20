# Infra docs

This folder contains infrastructure operational notes and short-runbooks for
the `infra` Terraform workspace.

## Document Index

| Document                                         | Description                                                                            |
| ------------------------------------------------ | -------------------------------------------------------------------------------------- |
| [service_catalog.md](service_catalog.md)         | Authoritative inventory of all Cloud Run services, jobs, buckets, and service accounts |
| [scheduler_inventory.md](scheduler_inventory.md) | Cloud Scheduler jobs: cron schedules, targets, and operational notes                   |
| [module_reference.md](module_reference.md)       | Terraform module interface reference and usage examples                                |
| [domain_mapping.md](domain_mapping.md)           | Custom domain setup procedures                                                         |
| [iap_manual.md](iap_manual.md)                   | IAP OAuth client manual setup steps                                                    |

## Policy: local overrides

- Keep local environment overrides (for example, `local-overrides.tfvars`) out
  of source control. Use a local file named `local-overrides.tfvars` during
  development and do not commit it. The repo `.gitignore` already excludes
  `infra/environments/app/dev/local-overrides.tfvars` and `infra/environments/app/dev/tfplan`.
