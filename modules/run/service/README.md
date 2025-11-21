# Cloud Run Service Module

Reusable module for provisioning a Cloud Run service with optional autoscaling,
VPC connector, environment variables, and invoker bindings. Intended for
application services like the FastAPI API gateway or Streamlit UI.

## Inputs

- `project_id` – target project ID.
- `name` – Cloud Run service name.
- `location` – region (`us-central1` default).
- `service_account` – execution service account email.
- `image` – container image URI.
- `args`, `command` – optional overrides for container args/entrypoint.
- `env_vars` – map of environment variables.
- `container_ports` – list of `{ name, container_port }` objects (defaults to single HTTP port 8080).
- `resource_limits` – map of CPU/memory limits.
- `container_concurrency`, `timeout_seconds` – runtime tuning.
- `ingress` – optional ingress annotation (`INGRESS_TRAFFIC_ALL`, etc.); leave blank for provider default.
- `min_instances`, `max_instances` – autoscaling hints.
- `annotations`, `labels` – extra metadata for the revision template.
- `vpc_connector`, `vpc_connector_egress_settings` – optional Serverless VPC connector wiring.
- `invoker_member`, `invoker_role` – optional single principal appended to the invoker list.
- `invoker_members` – authoritative list of principals granted `roles/run.invoker`; include every caller that should
  reach the service. The module rewrites the IAM binding, so members not listed here lose access.
- `autogenerate_revision_name` – bool controlling revision naming (default true).

## Outputs

- `name` – the service name.
- `uri` – service URL of the latest revision with 100% traffic.

## Example

```hcl
module "fastapi_service" {
  source            = "../../modules/run/service"
  project_id        = var.project_id
  name              = "fastapi-dev"
  location          = "us-central1"
  service_account   = module.iam_service_accounts.emails["app"]
  image             = "us-docker.pkg.dev/cloudrun/container/hello"
  env_vars          = { ENV = "dev" }
  invoker_members   = ["user:analyst@example.com", "serviceAccount:${module.iam_service_accounts.emails["app"]}"]
}
```

```
terraform output fastapi_service
```

Once ready for private access, set `invoker_member` to an authenticated principal (e.g., `serviceAccount:sa-app@...`) or manage access through IAP.

You can mix users, service accounts, and Google Groups (`group:analysts@example.com`) in `invoker_members`; Terraform rewrites the binding each apply so only the listed principals retain access.
