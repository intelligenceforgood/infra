i4g_analyst_members = [
  "group:gcp-i4g-analyst@intelligenceforgood.org",
]

i4g_admin_members = [
  "group:gcp-i4g-admin@intelligenceforgood.org",
]

db_admin_group   = "gcp-i4g-admin@intelligenceforgood.org"
db_analyst_group = "gcp-i4g-analyst@intelligenceforgood.org"

project_id            = "i4g-prod"
iap_support_email     = "jerry@intelligenceforgood.org"
iap_application_title = "i4g Analyst Surfaces (Prod)"
fastapi_image         = "us-central1-docker.pkg.dev/i4g-prod/applications/fastapi:prod"

fastapi_env_vars = {
  I4G_ENV                            = "prod"
  I4G_RUNTIME__LOG_LEVEL             = "WARNING"
  I4G_STORAGE__STRUCTURED_BACKEND    = "cloudsql"
  I4G_APP__CLOUDSQL__INSTANCE        = "i4g-prod:us-central1:i4g-prod-db"
  I4G_APP__CLOUDSQL__DATABASE        = "i4g_db"
  I4G_APP__CLOUDSQL__USER            = "sa-app@i4g-prod.iam.gserviceaccount.com"
  I4G_APP__CLOUDSQL__ENABLE_IAM_AUTH = "true"
  I4G_VERTEX_SEARCH_PROJECT          = "i4g-prod"
  I4G_VERTEX_SEARCH_LOCATION         = "global"
  I4G_VERTEX_SEARCH_DATA_STORE       = "retrieval-prod"
  I4G_VERTEX_SEARCH_SERVING_CONFIG   = "default_search"
}

fastapi_secret_env_vars = {
  I4G_PII__PEPPER = {
    secret  = "projects/i4g-pii-vault-prod/secrets/tokenization-pepper"
    version = "latest"
  }
  I4G_CRYPTO__PII_KEY = {
    secret  = "projects/i4g-pii-vault-prod/secrets/pii-tokenization-key"
    version = "latest"
  }
}

console_image   = "us-central1-docker.pkg.dev/i4g-prod/applications/i4g-console:prod"
console_enabled = false

console_env_vars = {
  NEXT_PUBLIC_USE_MOCK_DATA        = "false"
  I4G_API_KIND                     = "core"
  I4G_API_KEY                      = "prod-analyst-token"
  I4G_VERTEX_SEARCH_PROJECT        = "i4g-prod"
  I4G_VERTEX_SEARCH_LOCATION       = "global"
  I4G_VERTEX_SEARCH_DATA_STORE     = "retrieval-prod"
  I4G_VERTEX_SEARCH_SERVING_CONFIG = "default_search"
}

console_invoker_member  = ""
console_invoker_members = []

vertex_search_data_store_id = "retrieval-prod"
vertex_search_display_name  = "Retrieval Production Data Store"

# Custom domains (leave blank if DNS is managed externally and not present in this project)
fastapi_custom_domain    = ""
ui_custom_domain         = ""
dns_managed_zone         = ""
dns_managed_zone_project = ""

# IAP allowed domains
iap_allowed_domains = ["intelligenceforgood.org"]

storage_bucket_default_location = "US"
storage_buckets = {
  evidence = {
    name = "i4g-evidence-prod"
    labels = {
      env     = "prod"
      service = "evidence"
    }
    lifecycle_rules = [
      {
        action = {
          type = "Delete"
        }
        condition = {
          age = 365
        }
      }
    ]
  }
  reports = {
    name = "i4g-reports-prod"
    labels = {
      env     = "prod"
      service = "reports"
    }
    lifecycle_rules = [
      {
        action = {
          type = "Delete"
        }
        condition = {
          age = 730
        }
      }
    ]
    retention_policy = {
      retention_period = 60 * 60 * 24 * 365
    }
  }
}

run_jobs = {
  ingest = {
    enabled             = false
    name                = "ingest-bootstrap"
    image               = "us-central1-docker.pkg.dev/i4g-prod/applications/ingest-job:prod"
    service_account_key = "ingest"
    env_vars = {
      I4G_ENV                            = "prod"
      I4G_APP__CLOUDSQL__INSTANCE        = "i4g-prod:us-central1:i4g-prod-db"
      I4G_APP__CLOUDSQL__DATABASE        = "i4g_db"
      I4G_APP__CLOUDSQL__USER            = "sa-ingest@i4g-prod.iam"
      I4G_APP__CLOUDSQL__ENABLE_IAM_AUTH = "true"
    }
  }

  intake = {
    enabled             = false
    name                = "process-intakes"
    image               = "us-central1-docker.pkg.dev/i4g-prod/applications/intake-job:prod"
    service_account_key = "intake"
    env_vars = {
      I4G_ENV                            = "prod"
      I4G_APP__CLOUDSQL__INSTANCE        = "i4g-prod:us-central1:i4g-prod-db"
      I4G_APP__CLOUDSQL__DATABASE        = "i4g_db"
      I4G_APP__CLOUDSQL__USER            = "sa-intake@i4g-prod.iam"
      I4G_APP__CLOUDSQL__ENABLE_IAM_AUTH = "true"
    }
  }

  report = {
    name                = "generate-reports"
    image               = "us-central1-docker.pkg.dev/i4g-prod/applications/report-job:prod"
    service_account_key = "report"
    env_vars = {
      I4G_ENV                            = "prod"
      I4G_STORAGE__STRUCTURED_BACKEND    = "cloudsql"
      I4G_APP__CLOUDSQL__INSTANCE        = "i4g-prod:us-central1:i4g-prod-db"
      I4G_APP__CLOUDSQL__DATABASE        = "i4g_db"
      I4G_APP__CLOUDSQL__USER            = "sa-report@i4g-prod.iam"
      I4G_APP__CLOUDSQL__ENABLE_IAM_AUTH = "true"
    }
  }
  dossier_queue = {
    enabled             = false
    name                = "dossier-queue"
    image               = "us-central1-docker.pkg.dev/i4g-prod/applications/dossier-job:prod"
    service_account_key = "report"
    env_vars = {
      I4G_ENV = "prod"
    }
  }
}
