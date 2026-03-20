# I4G Service Catalog

> **Last Verified:** March 2026
>
> This document is the authoritative inventory of every deployed component in the I4G platform.
> Source of truth: `infra/environments/app/dev/terraform.tfvars` and `infra/stacks/app/main.tf`.

---

## Cloud Run Services

| Service Name  | Terraform Module  | Container Image (dev)             | Service Account | Description                                                               |
| ------------- | ----------------- | --------------------------------- | --------------- | ------------------------------------------------------------------------- |
| `core-svc`    | `run_core_svc`    | `ingest-job:dev` → `core-svc:dev` | `sa-app`        | FastAPI backend — all API routes, ingestion orchestration, TIFAP, reports |
| `i4g-console` | `run_console`     | `i4g-console:dev`                 | `sa-app`        | Next.js analyst console — UI for analysts, victims, and LEO               |
| `ssi-svc`     | `run_ssi_service` | `ssi-svc:dev`                     | `sa-ssi`        | SSI investigation service — Playwright browser automation, eCX polling    |

All services deploy to `us-central1` via the `modules/run/service` module.

### Service Configuration Notes

- **core-svc** receives `I4G_SSI__SERVICE_URL` injected at deploy time from the SSI service URI (when `ssi_service_enabled = true`).
- **i4g-console** receives both `I4G_API_URL` (server-side proxy) and `NEXT_PUBLIC_API_BASE_URL` (client-side).
- **ssi-svc** is conditionally deployed (`ssi_service_enabled` flag). When disabled, SSI features in core-svc are unavailable.
- IAP (Identity-Aware Proxy) fronts `core-svc` and `i4g-console` in production via `modules/iap/`.

---

## Cloud Run Jobs

| Job Name                 | Container Image   | Service Account | Trigger                          | Description                                                               |
| ------------------------ | ----------------- | --------------- | -------------------------------- | ------------------------------------------------------------------------- |
| `ingest-bootstrap`       | `ingest-job:dev`  | `sa-ingest`     | Manual / CI                      | One-time or reset-time ingestion bootstrap — seeds initial case data      |
| `process-intakes`        | `intake-job:dev`  | `sa-intake`     | Manual / scheduler               | Processes pending intake submissions through the intake pipeline          |
| `generate-reports`       | `report-job:dev`  | `sa-report`     | Manual / on-demand               | Generates LEA reports and dossiers for accepted reviews                   |
| `classification-sweeper` | `ingest-job:dev`  | `sa-ingest`     | Cloud Scheduler (`*/5 * * * *`)  | Sweeps unclassified cases and applies fraud taxonomy tags                 |
| `dossier-queue`          | `dossier-job:dev` | `sa-report`     | Manual / on-demand               | Processes dossier assembly queue — BundleBuilder, LangChain tools, export |
| `retention-purge`        | `ingest-job:dev`  | `sa-ingest`     | Cloud Scheduler (`0 3 * * *`)    | Purges data beyond retention windows per policy                           |
| `analytics-refresh`      | `ingest-job:dev`  | `sa-ingest`     | Cloud Scheduler (`0 */4 * * *`)  | Refreshes TIFAP analytics aggregations (campaign stats, trend data)       |
| `ssi-ecx-poller`         | `ssi-svc:dev`     | `sa-ssi`        | Cloud Scheduler (`*/15 * * * *`) | Polls eCX (external exchange) for new scam intelligence                   |

All jobs deploy via the `modules/run/job` module. Scheduled jobs use `modules/scheduler/job`.

---

## GCS Storage Buckets

| Bucket Name (dev)      | Purpose                                        | Access                                            |
| ---------------------- | ---------------------------------------------- | ------------------------------------------------- |
| `i4g-evidence-dev`     | Evidence files uploaded during case submission | `sa-app` (read/write), `sa-ingest` (write)        |
| `i4g-reports-dev`      | Generated LEA reports and dossier packages     | `sa-report` (write), `sa-app` (read, signed URLs) |
| `i4g-dev-data-bundles` | Raw data bundle inputs for ingestion jobs      | `sa-ingest` (read/write)                          |
| `i4g-dev-ssi-evidence` | SSI investigation screenshots and artifacts    | `sa-ssi` (write), `sa-app` (read)                 |

---

## Service Accounts

| Account Key    | Description                          | Primary Roles                                                                |
| -------------- | ------------------------------------ | ---------------------------------------------------------------------------- |
| `sa-app`       | Core API + Console shared runtime SA | Cloud SQL client, Storage object admin, Secret Manager accessor, Run invoker |
| `sa-ingest`    | Ingestion job SA                     | Cloud SQL writer, Storage object admin, Vertex AI Search writer              |
| `sa-intake`    | Intake processing job SA             | Cloud SQL writer, Storage object admin                                       |
| `sa-report`    | Report generation job SA             | Cloud SQL reader, Storage object admin, Secret Manager accessor              |
| `sa-ssi`       | SSI service and scheduler SA         | Storage object admin (SSI evidence), Secret Manager accessor                 |
| `sa-scheduler` | Cloud Scheduler invoker SA           | Cloud Run job invoker                                                        |
| `sa-infra`     | Terraform / CI deployment SA         | Project IAM admin, Run admin, Storage admin                                  |

---

## Vertex AI Search

| Resource                   | Description                                                                  |
| -------------------------- | ---------------------------------------------------------------------------- |
| `retrieval-poc` data store | Vertex AI Search data store for semantic case retrieval (cloud environments) |

Managed via `modules/vertex_search`. Local environments use Chroma instead.

---

## Related Documents

- [scheduler_inventory.md](scheduler_inventory.md) — Detailed scheduler job specifications
- [module_reference.md](module_reference.md) — Terraform module interface reference
- [planning/architecture/system_narrative.md](../../../planning/architecture/system_narrative.md) — Platform-level component inventory
- [planning/architecture/integration_contracts.md](../../../planning/architecture/integration_contracts.md) — Cross-service integration contracts
