# ---------------------------------------------------------------------------
# ML Stack — Main
#
# Unified Terraform for the ML platform (i4g-ml project). Provisions all
# resources needed for data ingestion, feature engineering, model training,
# and serving. Values come from the thin environment wrapper via tfvars.
# ---------------------------------------------------------------------------

# ── API Enablement ───────────────────────────────────────────────────────────

locals {
  apis = toset([
    "aiplatform.googleapis.com",
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "run.googleapis.com",
    "cloudscheduler.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "iam.googleapis.com",
    "sqladmin.googleapis.com",
    "dataflow.googleapis.com",
  ])
}

resource "google_project_service" "apis" {
  for_each           = local.apis
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# ── Service Account ──────────────────────────────────────────────────────────

resource "google_service_account" "sa_ml" {
  project      = var.project_id
  account_id   = "sa-ml-platform"
  display_name = "ML Platform Service Account"
}

locals {
  sa_ml_roles = [
    "roles/aiplatform.user",
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
    "roles/storage.objectAdmin",
    "roles/run.invoker",
    "roles/artifactregistry.reader",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ]
}

resource "google_project_iam_member" "sa_ml_roles" {
  for_each = toset(local.sa_ml_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.sa_ml.email}"
}

# ── Storage ──────────────────────────────────────────────────────────────────

module "ml_storage" {
  source     = "../../modules/storage/buckets"
  project_id = var.project_id

  buckets = {
    data = {
      name     = var.data_bucket_name
      location = var.region

      versioning = true

      lifecycle_rules = [
        {
          action    = { type = "SetStorageClass", storage_class = "NEARLINE" }
          condition = { age = 90 }
        },
        {
          action    = { type = "SetStorageClass", storage_class = "COLDLINE" }
          condition = { age = 365 }
        },
      ]

      labels = { component = "ml", managed_by = "terraform" }
    }
  }
}

# ── Artifact Registry ────────────────────────────────────────────────────────

resource "google_artifact_registry_repository" "ml_containers" {
  project       = var.project_id
  location      = var.region
  repository_id = "containers"
  format        = "DOCKER"

  labels = { component = "ml", managed_by = "terraform" }

  depends_on = [google_project_service.apis]
}

# ── BigQuery ─────────────────────────────────────────────────────────────────

module "ml_bigquery" {
  source     = "../../modules/bigquery/dataset"
  project_id = var.project_id

  dataset_id  = "i4g_ml"
  location    = var.region
  description = "ML platform dataset — raw data, features, predictions, training, analytics."

  labels = { component = "ml", managed_by = "terraform" }

  access = [
    {
      role          = "OWNER"
      special_group = "projectOwners"
    },
    {
      role          = "WRITER"
      special_group = "projectWriters"
    },
    {
      role          = "READER"
      special_group = "projectReaders"
    },
    {
      role          = "OWNER"
      user_by_email = google_service_account.sa_ml.email
    },
  ]

  tables = {
    # ── Raw layer ──────────────────────────────────────────────────────────
    raw_cases = {
      schema = jsonencode([
        { name = "case_id", type = "STRING", mode = "REQUIRED" },
        { name = "classification_result", type = "STRING", mode = "NULLABLE" },
        { name = "status", type = "STRING", mode = "NULLABLE" },
        { name = "risk_score", type = "FLOAT64", mode = "NULLABLE" },
        { name = "taxonomy_version", type = "STRING", mode = "NULLABLE" },
        { name = "created_at", type = "TIMESTAMP", mode = "NULLABLE" },
        { name = "updated_at", type = "TIMESTAMP", mode = "NULLABLE" },
        { name = "_ingested_at", type = "TIMESTAMP", mode = "REQUIRED" },
      ])
      time_partitioning   = { type = "DAY", field = "_ingested_at" }
      clustering          = ["case_id"]
      deletion_protection = false
    }

    raw_entities = {
      schema = jsonencode([
        { name = "entity_id", type = "STRING", mode = "REQUIRED" },
        { name = "case_id", type = "STRING", mode = "REQUIRED" },
        { name = "entity_type", type = "STRING", mode = "REQUIRED" },
        { name = "canonical_value", type = "STRING", mode = "NULLABLE" },
        { name = "confidence", type = "FLOAT64", mode = "NULLABLE" },
        { name = "created_at", type = "TIMESTAMP", mode = "NULLABLE" },
        { name = "_ingested_at", type = "TIMESTAMP", mode = "REQUIRED" },
      ])
      time_partitioning   = { type = "DAY", field = "_ingested_at" }
      clustering          = ["case_id", "entity_type"]
      deletion_protection = false
    }

    raw_analyst_labels = {
      schema = jsonencode([
        { name = "id", type = "STRING", mode = "REQUIRED" },
        { name = "case_id", type = "STRING", mode = "REQUIRED" },
        { name = "axis", type = "STRING", mode = "REQUIRED" },
        { name = "label_code", type = "STRING", mode = "REQUIRED" },
        { name = "analyst_id", type = "STRING", mode = "NULLABLE" },
        { name = "confidence", type = "FLOAT64", mode = "NULLABLE" },
        { name = "notes", type = "STRING", mode = "NULLABLE" },
        { name = "created_at", type = "TIMESTAMP", mode = "NULLABLE" },
        { name = "_ingested_at", type = "TIMESTAMP", mode = "REQUIRED" },
      ])
      time_partitioning   = { type = "DAY", field = "_ingested_at" }
      clustering          = ["case_id", "axis"]
      deletion_protection = false
    }

    # ── Feature layer ──────────────────────────────────────────────────────
    features_case_features = {
      schema = jsonencode([
        { name = "case_id", type = "STRING", mode = "REQUIRED" },
        # Text features
        { name = "text_length", type = "INT64", mode = "NULLABLE" },
        { name = "word_count", type = "INT64", mode = "NULLABLE" },
        { name = "avg_sentence_length", type = "FLOAT64", mode = "NULLABLE" },
        # Entity features
        { name = "entity_count", type = "INT64", mode = "NULLABLE" },
        { name = "unique_entity_types", type = "INT64", mode = "NULLABLE" },
        { name = "has_crypto_wallet", type = "BOOL", mode = "NULLABLE" },
        { name = "has_bank_account", type = "BOOL", mode = "NULLABLE" },
        { name = "has_phone", type = "BOOL", mode = "NULLABLE" },
        { name = "has_email", type = "BOOL", mode = "NULLABLE" },
        # Indicator features
        { name = "indicator_count", type = "INT64", mode = "NULLABLE" },
        { name = "indicator_diversity", type = "INT64", mode = "NULLABLE" },
        { name = "max_indicator_confidence", type = "FLOAT64", mode = "NULLABLE" },
        # Classification features
        { name = "current_classification_axis", type = "STRING", mode = "NULLABLE" },
        { name = "current_classification_conf", type = "FLOAT64", mode = "NULLABLE" },
        { name = "classification_axis_count", type = "INT64", mode = "NULLABLE" },
        # Structural features
        { name = "document_count", type = "INT64", mode = "NULLABLE" },
        { name = "evidence_file_count", type = "INT64", mode = "NULLABLE" },
        { name = "case_age_days", type = "INT64", mode = "NULLABLE" },
        { name = "has_attachments", type = "BOOL", mode = "NULLABLE" },
        # Metadata
        { name = "_computed_at", type = "TIMESTAMP", mode = "REQUIRED" },
        { name = "_feature_version", type = "INT64", mode = "NULLABLE" },
      ])
      time_partitioning   = { type = "DAY", field = "_computed_at" }
      clustering          = ["case_id"]
      deletion_protection = false
    }

    # ── Prediction layer ───────────────────────────────────────────────────
    predictions_prediction_log = {
      schema = jsonencode([
        { name = "prediction_id", type = "STRING", mode = "REQUIRED" },
        { name = "case_id", type = "STRING", mode = "REQUIRED" },
        { name = "model_id", type = "STRING", mode = "REQUIRED" },
        { name = "model_version", type = "INT64", mode = "REQUIRED" },
        { name = "endpoint", type = "STRING", mode = "REQUIRED" },
        { name = "request_payload", type = "JSON", mode = "NULLABLE" },
        { name = "prediction", type = "JSON", mode = "NULLABLE" },
        { name = "latency_ms", type = "INT64", mode = "NULLABLE" },
        { name = "timestamp", type = "TIMESTAMP", mode = "REQUIRED" },
      ])
      time_partitioning   = { type = "DAY", field = "timestamp" }
      clustering          = ["model_id"]
      deletion_protection = false
    }

    predictions_outcome_log = {
      schema = jsonencode([
        { name = "outcome_id", type = "STRING", mode = "REQUIRED" },
        { name = "prediction_id", type = "STRING", mode = "REQUIRED" },
        { name = "case_id", type = "STRING", mode = "REQUIRED" },
        { name = "correction", type = "JSON", mode = "NULLABLE" },
        { name = "analyst_id", type = "STRING", mode = "REQUIRED" },
        { name = "timestamp", type = "TIMESTAMP", mode = "REQUIRED" },
      ])
      time_partitioning   = { type = "DAY", field = "timestamp" }
      clustering          = ["case_id"]
      deletion_protection = false
    }

    # ── Training layer ─────────────────────────────────────────────────────
    training_dataset_registry = {
      schema = jsonencode([
        { name = "dataset_id", type = "STRING", mode = "REQUIRED" },
        { name = "version", type = "INT64", mode = "REQUIRED" },
        { name = "capability", type = "STRING", mode = "REQUIRED" },
        { name = "gcs_path", type = "STRING", mode = "REQUIRED" },
        { name = "train_count", type = "INT64", mode = "NULLABLE" },
        { name = "eval_count", type = "INT64", mode = "NULLABLE" },
        { name = "test_count", type = "INT64", mode = "NULLABLE" },
        { name = "redacted", type = "BOOL", mode = "NULLABLE" },
        { name = "label_distribution", type = "JSON", mode = "NULLABLE" },
        { name = "config", type = "JSON", mode = "NULLABLE" },
        { name = "created_at", type = "TIMESTAMP", mode = "REQUIRED" },
        { name = "created_by", type = "STRING", mode = "NULLABLE" },
      ])
      deletion_protection = false
    }

    # ── Analytics layer ────────────────────────────────────────────────────
    analytics_model_performance = {
      schema = jsonencode([
        { name = "model_id", type = "STRING", mode = "REQUIRED" },
        { name = "model_version", type = "INT64", mode = "REQUIRED" },
        { name = "capability", type = "STRING", mode = "REQUIRED" },
        { name = "week", type = "DATE", mode = "REQUIRED" },
        { name = "total_predictions", type = "INT64", mode = "NULLABLE" },
        { name = "outcomes_received", type = "INT64", mode = "NULLABLE" },
        { name = "correct_predictions", type = "INT64", mode = "NULLABLE" },
        { name = "accuracy", type = "FLOAT64", mode = "NULLABLE" },
        { name = "correction_rate", type = "FLOAT64", mode = "NULLABLE" },
        { name = "per_axis_metrics", type = "JSON", mode = "NULLABLE" },
        { name = "f1", type = "FLOAT64", mode = "NULLABLE" },
      ])
      deletion_protection = false
    }

    analytics_drift_metrics = {
      schema = jsonencode([
        { name = "report_id", type = "STRING", mode = "REQUIRED" },
        { name = "model_id", type = "STRING", mode = "REQUIRED" },
        { name = "report_type", type = "STRING", mode = "REQUIRED" },
        { name = "axis_or_feature", type = "STRING", mode = "REQUIRED" },
        { name = "baseline_rate", type = "FLOAT64", mode = "NULLABLE" },
        { name = "current_rate", type = "FLOAT64", mode = "NULLABLE" },
        { name = "psi", type = "FLOAT64", mode = "REQUIRED" },
        { name = "is_drifted", type = "BOOL", mode = "REQUIRED" },
        { name = "window_start", type = "TIMESTAMP", mode = "REQUIRED" },
        { name = "window_end", type = "TIMESTAMP", mode = "REQUIRED" },
        { name = "computed_at", type = "TIMESTAMP", mode = "REQUIRED" },
      ])
      deletion_protection = false
    }

    analytics_trigger_log = {
      schema = jsonencode([
        { name = "event_id", type = "STRING", mode = "REQUIRED" },
        { name = "capability", type = "STRING", mode = "REQUIRED" },
        { name = "should_retrain", type = "BOOL", mode = "REQUIRED" },
        { name = "reasons", type = "STRING", mode = "NULLABLE" },
        { name = "new_label_count", type = "INT64", mode = "NULLABLE" },
        { name = "max_drift_psi", type = "FLOAT64", mode = "NULLABLE" },
        { name = "pipeline_job_name", type = "STRING", mode = "NULLABLE" },
        { name = "triggered_at", type = "TIMESTAMP", mode = "REQUIRED" },
      ])
      deletion_protection = false
    }

    analytics_cost_summary = {
      schema = jsonencode([
        { name = "summary_id", type = "STRING", mode = "REQUIRED" },
        { name = "model_id", type = "STRING", mode = "NULLABLE" },
        { name = "capability", type = "STRING", mode = "REQUIRED" },
        { name = "prediction_count", type = "INT64", mode = "REQUIRED" },
        { name = "ml_cost_per_prediction", type = "FLOAT64", mode = "REQUIRED" },
        { name = "llm_cost_per_prediction", type = "FLOAT64", mode = "REQUIRED" },
        { name = "ml_total", type = "FLOAT64", mode = "REQUIRED" },
        { name = "llm_total", type = "FLOAT64", mode = "REQUIRED" },
        { name = "savings_pct", type = "FLOAT64", mode = "REQUIRED" },
        { name = "period_start", type = "TIMESTAMP", mode = "REQUIRED" },
        { name = "period_end", type = "TIMESTAMP", mode = "REQUIRED" },
        { name = "computed_at", type = "TIMESTAMP", mode = "REQUIRED" },
      ])
      deletion_protection = false
    }
  }

  depends_on = [google_project_service.apis]
}

# ── Vertex AI Endpoints ──────────────────────────────────────────────────────

module "serving_dev" {
  source = "../../modules/vertex_ai/endpoint"

  project_id   = var.project_id
  region       = var.region
  display_name = "serving-dev"
  labels       = { env = "dev", component = "serving" }

  depends_on = [google_project_service.apis]
}

module "serving_prod" {
  source = "../../modules/vertex_ai/endpoint"

  project_id   = var.project_id
  region       = var.region
  display_name = "serving-prod"
  labels       = { env = "prod", component = "serving" }

  depends_on = [google_project_service.apis]
}

# ── Cloud Run — ML Serving Service ────────────────────────────────────────────
# Exposes /predict/classify, /feedback, /health directly via HTTP.
# Vertex AI Endpoints only proxy /predict; the Cloud Run service provides
# full API access to all serving routes.

module "ml_serving" {
  source = "../../modules/run/service"

  name            = "ml-serving"
  project_id      = var.project_id
  location        = var.region
  service_account = google_service_account.sa_ml.email
  image           = "${var.region}-docker.pkg.dev/${var.project_id}/containers/serve:${var.serve_image_tag}"

  env_vars = {
    MODEL_ARTIFACT_URI                    = var.model_artifact_uri
    SHADOW_MODEL_ARTIFACT_URI             = var.shadow_model_artifact_uri
    NER_MODEL_ARTIFACT_URI                = var.ner_model_artifact_uri
    GOOGLE_CLOUD_PROJECT                  = var.project_id
    I4G_ML_BIGQUERY__DATASET_ID           = "i4g_ml"
    I4G_ML_BIGQUERY__PREDICTION_LOG_TABLE = "predictions_prediction_log"
    I4G_ML_BIGQUERY__OUTCOME_LOG_TABLE    = "predictions_outcome_log"
  }

  resource_limits = {
    cpu    = "2"
    memory = "2Gi"
  }
  min_instances = 0
  max_instances = 2

  invoker_members = [
    "serviceAccount:sa-app@${var.core_dev_project_id}.iam.gserviceaccount.com",
    "serviceAccount:sa-app@${var.core_prod_project_id}.iam.gserviceaccount.com",
  ]

  labels = { component = "serving", managed_by = "terraform" }

  depends_on = [
    google_project_service.apis,
    google_artifact_registry_repository.ml_containers,
  ]
}

# ── Cross-Project IAM ────────────────────────────────────────────────────────
# Allow Core service accounts (dev + prod) to invoke Vertex AI endpoints in
# this project, so they can call the ML serving layer.

resource "google_project_iam_member" "core_dev_vertex_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:sa-app@${var.core_dev_project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "core_prod_vertex_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:sa-app@${var.core_prod_project_id}.iam.gserviceaccount.com"
}

# ── Cloud Scheduler — Weekly Dataset Refresh ─────────────────────────────────
# Triggers the data-refresh Cloud Run Job every Sunday at 4 AM UTC.
# The job runs: ETL ingest → dataset export (with PII redaction + label priority).

resource "google_cloud_run_v2_job" "data_refresh" {
  name     = "data-refresh"
  project  = var.project_id
  location = var.region

  template {
    template {
      service_account = google_service_account.sa_ml.email

      containers {
        image   = "${var.region}-docker.pkg.dev/${var.project_id}/containers/etl:${var.serve_image_tag}"
        command = ["python", "-m", "ml.data.refresh"]

        env {
          name  = "GOOGLE_CLOUD_PROJECT"
          value = var.project_id
        }
        env {
          name  = "I4G_ML_BIGQUERY__DATASET_ID"
          value = "i4g_ml"
        }
        env {
          name  = "I4G_ML_ETL__SOURCE_INSTANCE"
          value = "${var.core_dev_project_id}:${var.region}:i4g-dev-db"
        }
        env {
          name  = "I4G_ML_ETL__SOURCE_DB_NAME"
          value = "i4g_db"
        }
        env {
          name  = "I4G_ML_ETL__SOURCE_DB_USER"
          value = google_service_account.sa_ml.email
        }

        resources {
          limits = {
            cpu    = "2"
            memory = "2Gi"
          }
        }
      }

      max_retries = 1
      timeout     = "1800s"
    }
  }

  depends_on = [
    google_project_service.apis,
    google_artifact_registry_repository.ml_containers,
  ]
}

resource "google_cloud_scheduler_job" "weekly_data_refresh" {
  project   = var.project_id
  region    = var.region
  name      = "weekly-data-refresh"
  schedule  = "0 4 * * 0" # Sunday 4 AM UTC
  time_zone = "UTC"

  http_target {
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${google_cloud_run_v2_job.data_refresh.name}:run"
    http_method = "POST"

    oauth_token {
      service_account_email = google_service_account.sa_ml.email
    }
  }

  depends_on = [google_project_service.apis]
}

# ── Dataflow IAM ─────────────────────────────────────────────────────────────
# Allow sa-ml-platform to run Dataflow jobs for graph feature computation.

resource "google_project_iam_member" "sa_ml_dataflow_worker" {
  project = var.project_id
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${google_service_account.sa_ml.email}"
}

resource "google_project_iam_member" "sa_ml_dataflow_developer" {
  project = var.project_id
  role    = "roles/dataflow.developer"
  member  = "serviceAccount:${google_service_account.sa_ml.email}"
}

# ── Cloud Run Job — Graph Features ───────────────────────────────────────────
# Submits the Dataflow/Beam pipeline for entity co-occurrence graph features.
# Writes to features_graph_features BigQuery table (WRITE_TRUNCATE).

resource "google_cloud_run_v2_job" "graph_features" {
  name                = "graph-features"
  project             = var.project_id
  location            = var.region
  deletion_protection = false

  template {
    template {
      service_account = google_service_account.sa_ml.email

      containers {
        image   = "${var.region}-docker.pkg.dev/${var.project_id}/containers/graph-features:${var.serve_image_tag}"
        command = ["python", "-m", "ml.data.graph_features"]
        args = [
          "--project", var.project_id,
          "--dataset", "i4g_ml",
          "--runner", "DataflowRunner",
          "--temp-location", "gs://${var.data_bucket_name}/dataflow/temp",
          "--staging-location", "gs://${var.data_bucket_name}/dataflow/staging",
          "--region", var.region,
        ]

        env {
          name  = "GOOGLE_CLOUD_PROJECT"
          value = var.project_id
        }

        resources {
          limits = {
            cpu    = "1"
            memory = "1Gi"
          }
        }
      }

      max_retries = 1
      timeout     = "3600s"
    }
  }

  depends_on = [
    google_project_service.apis,
    google_artifact_registry_repository.ml_containers,
  ]
}

resource "google_cloud_scheduler_job" "weekly_graph_features" {
  project   = var.project_id
  region    = var.region
  name      = "weekly-graph-features"
  schedule  = "0 4 * * 0" # Sunday 4 AM UTC
  time_zone = "UTC"

  http_target {
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${google_cloud_run_v2_job.graph_features.name}:run"
    http_method = "POST"

    oauth_token {
      service_account_email = google_service_account.sa_ml.email
    }
  }

  depends_on = [google_project_service.apis]
}

# ── BigQuery — Graph Features Table ──────────────────────────────────────────

resource "google_bigquery_table" "features_graph_features" {
  project    = var.project_id
  dataset_id = module.ml_bigquery.dataset_id
  table_id   = "features_graph_features"

  deletion_protection = false

  schema = jsonencode([
    { name = "case_id", type = "STRING", mode = "REQUIRED" },
    { name = "shared_entity_count", type = "INT64", mode = "REQUIRED" },
    { name = "entity_reuse_frequency", type = "FLOAT64", mode = "REQUIRED" },
    { name = "cluster_size", type = "INT64", mode = "REQUIRED" },
    { name = "_computed_at", type = "TIMESTAMP", mode = "REQUIRED" },
  ])

  labels = {
    component  = "ml"
    managed_by = "terraform"
  }

  depends_on = [module.ml_bigquery]
}

# ── Cloud Monitoring — Outcome Logging Alert ─────────────────────────────────
# Alert when the outcome (feedback) logging failure rate exceeds 5%.
# The serving container emits structured logs; this alert queries the
# dead-letter logger for failed BigQuery writes.

resource "google_monitoring_notification_channel" "ml_email" {
  project      = var.project_id
  display_name = "ML Platform Alerts"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }
}

resource "google_monitoring_alert_policy" "outcome_logging_failures" {
  project      = var.project_id
  display_name = "ML Outcome Logging Failure Rate > 5%"
  combiner     = "OR"

  conditions {
    display_name = "Outcome log dead-letter rate"

    condition_matched_log {
      filter = <<-EOT
        resource.type="cloud_run_revision"
        resource.labels.service_name="ml-serving"
        jsonPayload.logger="ml.serving.logging.dead_letter"
        jsonPayload.message=~"Dead-letter outcome:"
      EOT

      label_extractors = {
        "prediction_id" = "EXTRACT(jsonPayload.message)"
      }
    }
  }

  alert_strategy {
    notification_rate_limit {
      period = "300s"
    }
  }

  notification_channels = [google_monitoring_notification_channel.ml_email.id]

  documentation {
    content   = "Outcome logging to BigQuery is failing at a rate that exceeds the threshold. Check the ml-serving Cloud Run logs for dead_letter entries and BigQuery streaming insert errors."
    mime_type = "text/markdown"
  }

  depends_on = [google_project_service.apis]
}

# ── Cloud Run Job — Daily Accuracy Materialization ───────────────────────────
# Runs the accuracy monitoring module daily at 5 AM UTC to compute
# per-model per-axis accuracy and materialize to analytics_model_performance.

resource "google_cloud_run_v2_job" "accuracy_materialization" {
  name     = "accuracy-materialization"
  project  = var.project_id
  location = var.region

  template {
    template {
      service_account = google_service_account.sa_ml.email

      containers {
        image   = "${var.region}-docker.pkg.dev/${var.project_id}/containers/serve:${var.serve_image_tag}"
        command = ["python", "-m", "ml.monitoring.accuracy"]

        env {
          name  = "GOOGLE_CLOUD_PROJECT"
          value = var.project_id
        }
        env {
          name  = "I4G_ML_BIGQUERY__DATASET_ID"
          value = "i4g_ml"
        }

        resources {
          limits = {
            cpu    = "1"
            memory = "1Gi"
          }
        }
      }

      max_retries = 1
      timeout     = "600s"
    }
  }

  depends_on = [
    google_project_service.apis,
    google_artifact_registry_repository.ml_containers,
  ]
}

resource "google_cloud_scheduler_job" "daily_accuracy" {
  project   = var.project_id
  region    = var.region
  name      = "daily-accuracy-materialization"
  schedule  = "0 5 * * *" # Every day at 5 AM UTC
  time_zone = "UTC"

  http_target {
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${google_cloud_run_v2_job.accuracy_materialization.name}:run"
    http_method = "POST"

    oauth_token {
      service_account_email = google_service_account.sa_ml.email
    }
  }

  depends_on = [google_project_service.apis]
}

# ── Cloud Run Job — Daily Drift Materialization ──────────────────────────────
# Runs the drift monitoring module daily at 6 AM UTC to compute PSI-based
# prediction and feature drift metrics.

resource "google_cloud_run_v2_job" "drift_materialization" {
  name     = "drift-materialization"
  project  = var.project_id
  location = var.region

  template {
    template {
      service_account = google_service_account.sa_ml.email

      containers {
        image   = "${var.region}-docker.pkg.dev/${var.project_id}/containers/serve:${var.serve_image_tag}"
        command = ["python", "-m", "ml.monitoring.drift"]
        args    = ["--model-id", var.drift_model_id, "--window-days", "7"]

        env {
          name  = "GOOGLE_CLOUD_PROJECT"
          value = var.project_id
        }
        env {
          name  = "I4G_ML_BIGQUERY__DATASET_ID"
          value = "i4g_ml"
        }

        resources {
          limits = {
            cpu    = "1"
            memory = "1Gi"
          }
        }
      }

      max_retries = 1
      timeout     = "600s"
    }
  }

  depends_on = [
    google_project_service.apis,
    google_artifact_registry_repository.ml_containers,
  ]
}

resource "google_cloud_scheduler_job" "daily_drift" {
  project   = var.project_id
  region    = var.region
  name      = "daily-drift-materialization"
  schedule  = "0 6 * * *" # Every day at 6 AM UTC
  time_zone = "UTC"

  http_target {
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${google_cloud_run_v2_job.drift_materialization.name}:run"
    http_method = "POST"

    oauth_token {
      service_account_email = google_service_account.sa_ml.email
    }
  }

  depends_on = [google_project_service.apis]
}

# ── Cloud Run Job — Daily Cost Materialization ───────────────────────────────
# Runs cost monitoring at 5:30 AM UTC to compute ML vs LLM cost comparison.

resource "google_cloud_run_v2_job" "cost_materialization" {
  name     = "cost-materialization"
  project  = var.project_id
  location = var.region

  template {
    template {
      service_account = google_service_account.sa_ml.email

      containers {
        image   = "${var.region}-docker.pkg.dev/${var.project_id}/containers/serve:${var.serve_image_tag}"
        command = ["python", "-m", "ml.monitoring.cost"]

        env {
          name  = "GOOGLE_CLOUD_PROJECT"
          value = var.project_id
        }
        env {
          name  = "I4G_ML_BIGQUERY__DATASET_ID"
          value = "i4g_ml"
        }

        resources {
          limits = {
            cpu    = "1"
            memory = "1Gi"
          }
        }
      }

      max_retries = 1
      timeout     = "600s"
    }
  }

  depends_on = [
    google_project_service.apis,
    google_artifact_registry_repository.ml_containers,
  ]
}

resource "google_cloud_scheduler_job" "daily_cost" {
  project   = var.project_id
  region    = var.region
  name      = "daily-cost-materialization"
  schedule  = "30 5 * * *" # Every day at 5:30 AM UTC
  time_zone = "UTC"

  http_target {
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${google_cloud_run_v2_job.cost_materialization.name}:run"
    http_method = "POST"

    oauth_token {
      service_account_email = google_service_account.sa_ml.email
    }
  }

  depends_on = [google_project_service.apis]
}

# ── Cloud Run Job — Retrain Trigger ──────────────────────────────────────────
# Evaluates retraining conditions (data volume, drift, time) and submits
# the training pipeline if warranted. Always exits 0; uses structured
# logging for alerting.

resource "google_cloud_run_v2_job" "retrain_trigger" {
  name     = "retrain-trigger"
  project  = var.project_id
  location = var.region

  template {
    template {
      service_account = google_service_account.sa_ml.email

      containers {
        image   = "${var.region}-docker.pkg.dev/${var.project_id}/containers/serve:${var.serve_image_tag}"
        command = ["python", "scripts/trigger_retraining.py"]
        args    = ["--capability", "classification"]

        env {
          name  = "GOOGLE_CLOUD_PROJECT"
          value = var.project_id
        }
        env {
          name  = "I4G_ML_BIGQUERY__DATASET_ID"
          value = "i4g_ml"
        }

        resources {
          limits = {
            cpu    = "1"
            memory = "1Gi"
          }
        }
      }

      max_retries = 1
      timeout     = "900s"
    }
  }

  depends_on = [
    google_project_service.apis,
    google_artifact_registry_repository.ml_containers,
  ]
}

resource "google_cloud_scheduler_job" "daily_retrain_trigger" {
  project   = var.project_id
  region    = var.region
  name      = "daily-retrain-trigger"
  schedule  = "0 6 * * *" # Every day at 6 AM UTC
  time_zone = "UTC"

  http_target {
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${google_cloud_run_v2_job.retrain_trigger.name}:run"
    http_method = "POST"

    oauth_token {
      service_account_email = google_service_account.sa_ml.email
    }
  }

  depends_on = [google_project_service.apis]
}

resource "google_cloud_scheduler_job" "monthly_force_retrain" {
  project   = var.project_id
  region    = var.region
  name      = "monthly-force-retrain"
  schedule  = "0 7 1 * *" # 1st of month at 7 AM UTC
  time_zone = "UTC"

  http_target {
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${google_cloud_run_v2_job.retrain_trigger.name}:run"
    http_method = "POST"
    body        = base64encode("{\"overrides\":{\"containerOverrides\":[{\"args\":[\"--capability\",\"classification\",\"--force\"]}]}}")

    oauth_token {
      service_account_email = google_service_account.sa_ml.email
    }
  }

  depends_on = [google_project_service.apis]
}

# ── Cloud Monitoring — Retrain Submitted Alert ───────────────────────────────
# Notify when a retraining pipeline is automatically submitted.

resource "google_monitoring_alert_policy" "retrain_submitted" {
  project      = var.project_id
  display_name = "ML Retraining Pipeline Submitted"
  combiner     = "OR"

  conditions {
    display_name = "Retrain submitted"

    condition_matched_log {
      filter = <<-EOT
        resource.type="cloud_run_job"
        resource.labels.job_name="retrain-trigger"
        jsonPayload.action="retrain_submitted"
      EOT
    }
  }

  alert_strategy {
    notification_rate_limit {
      period = "86400s" # Once per day
    }
  }

  notification_channels = [google_monitoring_notification_channel.ml_email.id]

  documentation {
    content   = "The automated retraining trigger evaluated conditions and submitted a Vertex AI training pipeline. Check the Vertex AI Pipelines console for the new run. Review analytics_trigger_log in BigQuery for trigger reasons."
    mime_type = "text/markdown"
  }

  depends_on = [google_project_service.apis]
}

# ── Cloud Monitoring — Override Rate Alerts ──────────────────────────────────
# Alert when the analyst override rate exceeds thresholds, computed from
# the analytics_model_performance table via log-based metric.

resource "google_monitoring_alert_policy" "override_rate_warning" {
  project      = var.project_id
  display_name = "ML Override Rate > 20% (Warning)"
  combiner     = "OR"

  conditions {
    display_name = "Override rate warning"

    condition_matched_log {
      filter = <<-EOT
        resource.type="cloud_run_job"
        resource.labels.job_name="accuracy-materialization"
        textPayload=~"override_rate.*0\\.[2-9]|override_rate.*1\\.0"
      EOT
    }
  }

  alert_strategy {
    notification_rate_limit {
      period = "86400s" # Once per day
    }
  }

  notification_channels = [google_monitoring_notification_channel.ml_email.id]

  documentation {
    content   = "The analyst override rate has exceeded 20% over the last 7 days. This may indicate model accuracy degradation or data drift. Investigate recent prediction quality and consider retraining."
    mime_type = "text/markdown"
  }

  depends_on = [google_project_service.apis]
}

resource "google_monitoring_alert_policy" "override_rate_critical" {
  project      = var.project_id
  display_name = "ML Override Rate > 30% (Critical)"
  combiner     = "OR"

  conditions {
    display_name = "Override rate critical"

    condition_matched_log {
      filter = <<-EOT
        resource.type="cloud_run_job"
        resource.labels.job_name="accuracy-materialization"
        textPayload=~"override_rate.*0\\.[3-9]|override_rate.*1\\.0"
      EOT
    }
  }

  alert_strategy {
    notification_rate_limit {
      period = "3600s" # Once per hour
    }
  }

  notification_channels = [google_monitoring_notification_channel.ml_email.id]

  documentation {
    content   = "CRITICAL: The analyst override rate has exceeded 30% over the last 7 days. Model accuracy is significantly degraded. Immediate action required: check for data drift, input distribution shift, or labeling changes. Trigger retraining pipeline."
    mime_type = "text/markdown"
  }

  depends_on = [google_project_service.apis]
}

# ── Cloud Run — ML Serving (Production) ──────────────────────────────────────
# Separate Cloud Run service for prod serving. Uses the prod image tag,
# prod model artifact URI, and min_instances=1 to avoid cold starts.

module "ml_serving_prod" {
  source = "../../modules/run/service"

  name            = "ml-serving-prod"
  project_id      = var.project_id
  location        = var.region
  service_account = google_service_account.sa_ml.email
  image           = "${var.region}-docker.pkg.dev/${var.project_id}/containers/serve:${var.prod_serve_image_tag}"

  env_vars = {
    MODEL_ARTIFACT_URI                    = var.prod_model_artifact_uri
    SHADOW_MODEL_ARTIFACT_URI             = var.prod_shadow_model_artifact_uri
    NER_MODEL_ARTIFACT_URI                = var.prod_ner_model_artifact_uri
    GOOGLE_CLOUD_PROJECT                  = var.project_id
    I4G_ML_BIGQUERY__DATASET_ID           = "i4g_ml"
    I4G_ML_BIGQUERY__PREDICTION_LOG_TABLE = "predictions_prediction_log"
    I4G_ML_BIGQUERY__OUTCOME_LOG_TABLE    = "predictions_outcome_log"
  }

  resource_limits = {
    cpu    = "2"
    memory = "2Gi"
  }
  min_instances = 1 # Avoid cold starts in production
  max_instances = 4

  invoker_members = [
    "serviceAccount:sa-app@${var.core_prod_project_id}.iam.gserviceaccount.com",
  ]

  labels = { component = "serving", env = "prod", managed_by = "terraform" }

  depends_on = [
    google_project_service.apis,
    google_artifact_registry_repository.ml_containers,
  ]
}

# ── Cloud Monitoring — Prod Endpoint Alerts ──────────────────────────────────

resource "google_monitoring_alert_policy" "prod_latency" {
  project      = var.project_id
  display_name = "ML Prod Serving Latency p90 > 2s"
  combiner     = "OR"

  conditions {
    display_name = "Prod serving latency"

    condition_threshold {
      filter          = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"ml-serving-prod\" AND metric.type = \"run.googleapis.com/request_latencies\""
      comparison      = "COMPARISON_GT"
      threshold_value = 2000 # ms
      duration        = "300s"

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_PERCENTILE_95"
        cross_series_reducer = "REDUCE_MAX"
      }
    }
  }

  alert_strategy {
    auto_close = "1800s"
  }

  notification_channels = [google_monitoring_notification_channel.ml_email.id]

  documentation {
    content   = "Production ML serving latency (p95) has exceeded 2 seconds. Check Cloud Run scaling, model size, and consider increasing min_instances."
    mime_type = "text/markdown"
  }

  depends_on = [google_project_service.apis]
}

resource "google_monitoring_alert_policy" "prod_error_rate" {
  project      = var.project_id
  display_name = "ML Prod Serving Error Rate > 5%"
  combiner     = "OR"

  conditions {
    display_name = "Prod serving error rate"

    condition_threshold {
      filter          = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"ml-serving-prod\" AND metric.type = \"run.googleapis.com/request_count\" AND metric.labels.response_code_class != \"2xx\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.05
      duration        = "300s"

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }

  alert_strategy {
    auto_close = "1800s"
  }

  notification_channels = [google_monitoring_notification_channel.ml_email.id]

  documentation {
    content   = "Production ML serving error rate has exceeded 5%. Check model load status, container logs, and Cloud Run service health."
    mime_type = "text/markdown"
  }

  depends_on = [google_project_service.apis]
}
