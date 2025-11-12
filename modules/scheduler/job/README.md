# scheduler/job Module

Creates a Cloud Scheduler job that triggers a Cloud Run job using an authenticated HTTP POST call with an OIDC token.

## Features
- Configurable cron schedule and time zone.
- Automatically builds the Cloud Run `jobs.run` endpoint URL.
- Supports custom headers/body payloads and OIDC audience overrides.

## Inputs
- `project_id` (string, required)
- `region` (string, required)
- `name` (string, required)
- `schedule` (string, required)
- `time_zone` (string, optional, default `UTC`)
- `description` (string, optional)
- `attempt_deadline_seconds` (number, optional, default `300`)
- `run_job_name` (string, required)
- `run_job_location` (string, required)
- `service_account_email` (string, required)
- `audience` (string, optional)
- `headers` (map(string), optional)
- `body` (string, optional, default `{}`)

## Outputs
- `name`
