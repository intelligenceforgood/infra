# GitHub Workload Identity Federation Module

Creates a workload identity pool and provider that trusts GitHub Actions OIDC tokens for a
single repository. Use the exported pool name to grant `roles/iam.workloadIdentityUser`
to service accounts that GitHub workflows should impersonate.

## Inputs

- `project_id` – target project.
- `pool_id` – identifier for the workload identity pool (e.g., `github-actions`).
- `provider_id` – identifier for the provider (e.g., `core`).
- `github_repository` – repository in `owner/name` format.
- Optional overrides for display names, descriptions, attribute mapping, and CEL condition.

## Outputs

- `pool_name` – fully qualified pool resource path (`projects/<number>/locations/global/workloadIdentityPools/<id>`).
- `provider_name` – fully qualified provider resource path.

## Example

```hcl
module "github_wif" {
	source            = "../../modules/iam/workload_identity_github"
	project_id        = var.project_id
	pool_id           = "github-actions"
	provider_id       = "core"
	github_repository = "intelligenceforgood/core"
}

resource "google_service_account_iam_binding" "infra_wif" {
	service_account_id = "projects/${var.project_id}/serviceAccounts/${module.iam_service_accounts.emails["infra"]}"
	role               = "roles/iam.workloadIdentityUser"
	members = [
		"principalSet://iam.googleapis.com/${module.github_wif.pool_name}/attribute.repository/intelligenceforgood/core"
	]
}
```
