# Cloud Scheduler Inventory

> **Last Verified:** March 2026
>
> Authoritative list of all Cloud Scheduler jobs that trigger Cloud Run jobs.
> Source of truth: `infra/environments/app/dev/terraform.tfvars` (`run_jobs` map with `schedule` keys).
> Managed via `modules/scheduler/job`.

---

## Scheduled Jobs

| Scheduler Name                    | Cron           | Plain-English      | Target Cloud Run Job     | Image        | Service Account |
| --------------------------------- | -------------- | ------------------ | ------------------------ | ------------ | --------------- |
| `classification-sweeper-schedule` | `*/5 * * * *`  | Every 5 minutes    | `classification-sweeper` | `ingest-job` | `sa-scheduler`  |
| `retention-purge-schedule`        | `0 3 * * *`    | Daily at 03:00 UTC | `retention-purge`        | `ingest-job` | `sa-scheduler`  |
| `analytics-refresh-schedule`      | `0 */4 * * *`  | Every 4 hours      | `analytics-refresh`      | `ingest-job` | `sa-scheduler`  |
| `ssi-ecx-poller-schedule`         | `*/15 * * * *` | Every 15 minutes   | `ssi-ecx-poller`         | `ssi-svc`    | `sa-scheduler`  |

> Note: `ingest-bootstrap`, `process-intakes`, `generate-reports`, and `dossier-queue` are **not scheduled** — they are triggered manually or via CI/CD.

---

## Job Details

### classification-sweeper

- **Purpose:** Sweeps case records that have not yet been classified and applies fraud taxonomy tags using the LLM classification pipeline.
- **Schedule:** `*/5 * * * *` — Every 5 minutes
- **Image:** `ingest-job` (reused; entry point selected via args/env)
- **Timeout:** Default (300s)
- **Max retries:** 0
- **Failure action:** Alert via Cloud Monitoring; cases remain unclassified until next sweep.

### retention-purge

- **Purpose:** Purges intake records and associated artifacts beyond the configured data retention window. Also purges soft-deleted cases.
- **Schedule:** `0 3 * * *` — Daily at 03:00 UTC (chosen to minimize overlap with analyst activity)
- **Image:** `ingest-job` (reused; `args: ["jobs", "retention-purge"]`)
- **Timeout:** 1800s (30 minutes — purge may process large batches)
- **Parallelism:** 1
- **Max retries:** 0
- **Failure action:** Retained data beyond policy; manual run needed.

### analytics-refresh

- **Purpose:** Refreshes aggregated TIFAP analytics: campaign statistics, trend data, entity co-occurrence indices.
- **Schedule:** `0 */4 * * *` — Every 4 hours
- **Image:** `ingest-job` (reused)
- **Timeout:** Default
- **Max retries:** 0
- **Failure action:** Analytics dashboards show stale data; no data loss.

### ssi-ecx-poller

- **Purpose:** Polls eCX (External Crypto Exchange) API for new scam intelligence signals. Fetches and ingests new eCX records into the SSI data store.
- **Schedule:** `*/15 * * * *` — Every 15 minutes
- **Image:** `ssi-svc` (SSI service image, different entry point for polling mode)
- **Timeout:** Default
- **Max retries:** 0
- **Failure action:** 15-minute gap in eCX data; next poll resumes normally.

---

## Scheduler Authentication

All schedulers use `sa-scheduler` (Cloud Scheduler service account) to invoke Cloud Run jobs.

- Auth method: OIDC token with `cloud-platform` OAuth scope
- Audience: automatically derived from the Cloud Run job URI
- Token creator role: `gcp-sa-cloudscheduler.iam.gserviceaccount.com` is granted `serviceAccountTokenCreator` on `sa-scheduler`

---

## Operations Notes

- To pause a scheduler: `gcloud scheduler jobs pause <name> --location=us-central1`
- To manually trigger a job outside of schedule: `gcloud run jobs execute <job-name> --region=us-central1`
- Scheduler jobs are **paused by default in non-prod environments** when `scheduler_paused = true` is set in tfvars

---

## Related Documents

- [service_catalog.md](service_catalog.md) — Full service and job inventory
- [planning/architecture/system_narrative.md](../../../planning/architecture/system_narrative.md) — Platform-level context
