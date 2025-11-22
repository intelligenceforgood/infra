# IAP Project Module

Provision the project-wide Identity-Aware Proxy (IAP) brand plus optional
access-level defaults.

## Inputs

| Name | Description | Type | Default |
| --- | --- | --- | --- |
| `project_id` | Target GCP project ID. | `string` | n/a |
| `support_email` | Verified email used for the OAuth consent screen (required when Terraform manages the brand). | `string` | `""` |
| `application_title` | Consent-screen title. | `string` | `"i4g Analyst Surfaces"` |
| `manage_brand` | Create/manage the IAP brand via Terraform (project must belong to an org). | `bool` | `false` |
| `existing_brand_name` | Reuse an existing brand when Terraform is not managing it. | `string` | `""` |
| `enable_allowed_domains` | Turn on allowed-domains enforcement. | `bool` | `false` |
| `allowed_domains` | Domains permitted when allowed-domains is enabled. | `list(string)` | `[]` |
| `allow_http_options` | Allow unauthenticated HTTP OPTIONS (CORS preflight). | `bool` | `true` |

## Outputs

| Name | Description |
| --- | --- |
| `brand_name` | Fully-qualified resource name for the managed brand, or the provided brand when unmanaged. |
| `project_settings_name` | IAP settings resource path if access settings are managed. |

## Notes

- `google_iap_brand` resources cannot be destroyed without Google support when `manage_brand=true`, so the module sets
  `prevent_destroy` to guard against accidental deletion.
- The module only provisions `google_iap_settings` when either allowed domains
  or the HTTP OPTIONS toggle is enabled.
