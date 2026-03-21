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
  repository_id = "ml-containers"
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
      user_by_email = google_service_account.sa_ml.email
    },
  ]

  tables = {
    # ── Raw layer ──────────────────────────────────────────────────────────
    raw_cases = {
      schema = jsonencode([
        { name = "case_id", type = "STRING", mode = "REQUIRED" },
        { name = "narrative", type = "STRING", mode = "NULLABLE" },
        { name = "case_type", type = "STRING", mode = "NULLABLE" },
        { name = "status", type = "STRING", mode = "NULLABLE" },
        { name = "created_at", type = "TIMESTAMP", mode = "NULLABLE" },
        { name = "updated_at", type = "TIMESTAMP", mode = "NULLABLE" },
        { name = "tags", type = "STRING", mode = "REPEATED" },
        { name = "_ingested_at", type = "TIMESTAMP", mode = "REQUIRED" },
        { name = "_source_updated", type = "TIMESTAMP", mode = "NULLABLE" },
      ])
      time_partitioning   = { type = "DAY", field = "_ingested_at" }
      clustering          = ["case_id"]
      deletion_protection = false
    }

    raw_classification_results = {
      schema = jsonencode([
        { name = "case_id", type = "STRING", mode = "REQUIRED" },
        { name = "axis", type = "STRING", mode = "REQUIRED" },
        { name = "label_code", type = "STRING", mode = "REQUIRED" },
        { name = "confidence", type = "FLOAT64", mode = "NULLABLE" },
        { name = "model_used", type = "STRING", mode = "NULLABLE" },
        { name = "prompt_version", type = "STRING", mode = "NULLABLE" },
        { name = "created_at", type = "TIMESTAMP", mode = "NULLABLE" },
        { name = "_ingested_at", type = "TIMESTAMP", mode = "REQUIRED" },
      ])
      time_partitioning   = { type = "DAY", field = "_ingested_at" }
      clustering          = ["case_id", "axis"]
      deletion_protection = false
    }

    raw_entities = {
      schema = jsonencode([
        { name = "case_id", type = "STRING", mode = "REQUIRED" },
        { name = "entity_id", type = "STRING", mode = "REQUIRED" },
        { name = "entity_type", type = "STRING", mode = "REQUIRED" },
        { name = "entity_value", type = "STRING", mode = "NULLABLE" },
        { name = "confidence", type = "FLOAT64", mode = "NULLABLE" },
        { name = "source", type = "STRING", mode = "NULLABLE" },
        { name = "created_at", type = "TIMESTAMP", mode = "NULLABLE" },
        { name = "_ingested_at", type = "TIMESTAMP", mode = "REQUIRED" },
      ])
      time_partitioning   = { type = "DAY", field = "_ingested_at" }
      clustering          = ["case_id", "entity_type"]
      deletion_protection = false
    }

    raw_analyst_labels = {
      schema = jsonencode([
        { name = "label_id", type = "STRING", mode = "REQUIRED" },
        { name = "case_id", type = "STRING", mode = "REQUIRED" },
        { name = "axis", type = "STRING", mode = "REQUIRED" },
        { name = "label_code", type = "STRING", mode = "REQUIRED" },
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
