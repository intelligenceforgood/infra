# run/job Module

Provisions a Google Cloud Run (v2) job with configurable container image, environment variables, retries, and optional VPC connector wiring.

## Features
- Supports custom command/args, environment variables, resource limits.
- Optional Serverless VPC connector configuration.
- Outputs job name, location, and ID for downstream references (e.g., Cloud Scheduler triggers).

## Inputs
- `project_id` (string, required)
- `location` (string, required)
- `name` (string, required)
- `service_account` (string, required)
- `image` (string, required)
- `env_vars` (map(string), optional)
- `command` (list(string), optional)
- `args` (list(string), optional)
- `labels` (map(string), optional)
- `annotations` (map(string), optional)
- `parallelism` (number, optional, default 1)
- `task_count` (number, optional, default 1)
- `timeout_seconds` (number, optional, default 600)
- `max_retries` (number, optional, default 3)
- `resource_limits` (map(string), optional)
- `vpc_connector` (string, optional)
- `vpc_connector_egress_settings` (string, optional, default `ALL_TRAFFIC`)

## Outputs
- `name`
- `location`
- `id`
