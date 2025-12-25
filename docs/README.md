# Infra docs

This folder contains infrastructure operational notes and short-runbooks for
the `infra` Terraform workspace.

Policy: local overrides

- Keep local environment overrides (for example, `local-overrides.tfvars`) out
  of source control. Use a local file named `local-overrides.tfvars` during
  development and do not commit it. The repo `.gitignore` already excludes
  `infra/environments/dev/local-overrides.tfvars` and `infra/environments/dev/tfplan`.

