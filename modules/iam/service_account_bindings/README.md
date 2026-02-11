# Service Account Binding Module

Applies project-level IAM roles to a set of members (typically service accounts).
Bindings are supplied as a map keyed by logical name, with the module flattening
roles into individual `google_project_iam_member` resources.

## Inputs

- `project_id` – target project ID.
- `bindings` – map where each entry contains:
  - `member` – fully qualified principal string (e.g., `serviceAccount:sa-app@project.iam.gserviceaccount.com`).
  - `roles` – list of IAM roles to grant at the project scope.

## Example

```hcl
module "iam_service_account_bindings" {
  source     = "../../modules/iam/service_account_bindings"
  project_id = var.project_id

  bindings = {
    app = {
      member = "serviceAccount:${module.iam_service_accounts.emails["app"]}"
      roles  = [
        "roles/storage.objectViewer",
        "roles/secretmanager.secretAccessor"
      ]
    }
  }
}
```

Extend the bindings map to include additional service accounts and roles as needed.
