# IAP Cloud Run Service Module

Creates a service-specific OAuth client, stores its secret in Secret Manager,
and configures Identity-Aware Proxy (IAP) access for a Cloud Run service.

## Inputs

| Name | Description | Type | Default |
| --- | --- | --- | --- |
| `project_id` | Target GCP project ID. | `string` | n/a |
| `region` | Cloud Run region. | `string` | n/a |
| `service_name` | Cloud Run service name. | `string` | n/a |
| `manage_client` | Create/manage an OAuth client + Secret Manager entry. | `bool` | `false` |
| `brand_name` | Fully qualified IAP brand name (required when `manage_client=true`). | `string` | `""` |
| `display_name` | OAuth client display name. | `string` | `""` (derives from service) |
| `access_members` | Principals granted `roles/iap.httpsResourceAccessor`. | `list(string)` | `[]` (must contain at least one) |
| `secret_replication_locations` | Secret Manager replica regions. | `list(string)` | `[]` (defaults to service region) |
| `secret_id` | Override for the Secret Manager secret ID. | `string` | `""` |

## Outputs

| Name | Description |
| --- | --- |
| `client_id` | OAuth client ID for IAP (null when `manage_client=false`). |
| `secret_id` | Secret ID holding the client secret (null when `manage_client=false`). |
| `secret_resource` | Fully qualified Secret Manager resource path (null when `manage_client=false`). |
| `iap_binding_id` | Identifier for the IAM binding associating principals with IAP. |

## Notes

- Remember to grant `roles/run.invoker` on the underlying Cloud Run service to
  `service-${project_number}@gcp-sa-iap.iam.gserviceaccount.com` so IAP can
  reach the backend. The Terraform `run/service` module should manage this
  alongside runtime service accounts.
