i4g_analyst_members = [
  "group:gcp-i4g-analyst@intelligenceforgood.org",
]

i4g_admin_members = [
  "group:gcp-i4g-admin@intelligenceforgood.org",
]

project_id            = "i4g-dev"
iap_support_email     = "jerry@intelligenceforgood.org"
iap_application_title = "i4g Analyst Surfaces (Dev)"
fastapi_image         = "us-central1-docker.pkg.dev/i4g-dev/applications/fastapi:dev"

fastapi_env_vars = {
  I4G_ENV                          = "dev"
  I4G_STORAGE__SQLITE_PATH         = "/tmp/i4g_store.db"
  I4G_VERTEX_SEARCH_PROJECT        = "i4g-dev"
  I4G_VERTEX_SEARCH_LOCATION       = "global"
  I4G_VERTEX_SEARCH_DATA_STORE     = "retrieval-poc"
  I4G_VERTEX_SEARCH_SERVING_CONFIG = "default_search"
}

fastapi_secret_env_vars = {
  I4G_TOKENIZATION__PEPPER = {
    secret  = "projects/i4g-pii-vault-dev/secrets/tokenization-pepper"
    version = "latest"
  }
  I4G_CRYPTO__PII_KEY = {
    secret  = "projects/i4g-pii-vault-dev/secrets/pii-tokenization-key"
    version = "latest"
  }
}

streamlit_image = "us-central1-docker.pkg.dev/i4g-dev/applications/streamlit:dev"

streamlit_env_vars = {
  I4G_ENV                          = "dev"
  I4G_API__KEY                     = "" # real token lives in local-overrides.tfvars (see infra/docs/README.md)
  STREAMLIT_SERVER_TITLE           = "I4G Analyst Dashboard"
  I4G_VERTEX_SEARCH_PROJECT        = "i4g-dev"
  I4G_VERTEX_SEARCH_LOCATION       = "global"
  I4G_VERTEX_SEARCH_DATA_STORE     = "retrieval-poc"
  I4G_VERTEX_SEARCH_SERVING_CONFIG = "default_search"
}

streamlit_invoker_member  = ""
streamlit_invoker_members = []

console_image = "us-central1-docker.pkg.dev/i4g-dev/applications/i4g-console:dev"

console_env_vars = {
  NEXT_PUBLIC_USE_MOCK_DATA        = "false"
  I4G_API_KIND                     = "core"
  I4G_API_KEY                      = "dev-analyst-token"
  I4G_VERTEX_SEARCH_PROJECT        = "i4g-dev"
  I4G_VERTEX_SEARCH_LOCATION       = "global"
  I4G_VERTEX_SEARCH_DATA_STORE     = "retrieval-poc"
  I4G_VERTEX_SEARCH_SERVING_CONFIG = "default_search"
}

console_invoker_member  = ""
console_invoker_members = []

storage_bucket_default_location = "US"
storage_buckets = {
  evidence = {
    name          = "i4g-evidence-dev"
    force_destroy = true
    labels = {
      env     = "dev"
      service = "evidence"
    }
  }
  reports = {
    name          = "i4g-reports-dev"
    force_destroy = true
    labels = {
      env     = "dev"
      service = "reports"
    }
  }
  data_bundles = {
    name          = "i4g-dev-data-bundles"
    force_destroy = false
    uniform_bucket_level_access = true
    public_access_prevention    = "enforced"
    labels = {
      env     = "dev"
      service = "data-bundles"
    }
    lifecycle_rules = [
      {
        action = {
          type          = "Delete"
          storage_class = null
        }
        condition = {
          with_state         = "ARCHIVED" # delete archived (noncurrent) versions
          num_newer_versions = 5
        }
      }
    ]
  }
}

run_jobs = {
  ingest = {
    enabled             = true
    name                = "ingest-azure-snapshot"
    image               = "us-central1-docker.pkg.dev/i4g-dev/applications/ingest-job:dev"
    service_account_key = "ingest"
    env_vars = {
      I4G_ENV = "dev"
    }
  }
  intake = {
    name                = "process-intakes"
    image               = "us-central1-docker.pkg.dev/i4g-dev/applications/intake-job:dev"
    service_account_key = "intake"
    env_vars = {
      I4G_ENV                   = "dev"
      I4G_API__KEY              = "dev-analyst-token"
      I4G_INGEST__ENABLE_VECTOR = "false"
      I4G_RUNTIME__FALLBACK_DIR = "/tmp/i4g"
      I4G_STORAGE__SQLITE_PATH  = "/tmp/i4g/sqlite/intake.db"
    }
  }
  weekly_refresh = {
    name                = "weekly-azure-refresh"
    image               = "us-central1-docker.pkg.dev/i4g-dev/applications/weekly-refresh-job:dev"
    service_account_key = "ingest"
    env_vars = {
      I4G_ENV               = "dev"
      AZURE_SEARCH_ENDPOINT = "https://ifg-ai-search.search.windows.net"
    }
    secret_env_vars = {
      AZURE_SQL_CONNECTION_STRING = {
        secret  = "azure-sql-connection-string"
        version = "latest"
      }
      AZURE_STORAGE_CONNECTION_STRING = {
        secret  = "azure-storage-connection-string"
        version = "latest"
      }
      AZURE_SEARCH_ADMIN_KEY = {
        secret  = "azure-search-admin-key"
        version = "latest"
      }
    }
    scheduler_service_account_key = "scheduler"
    schedule                      = "0 11 * * MON"
    time_zone                     = "UTC"
    description                   = "Weekly Azure -> GCP incremental refresh (dev)."
    scheduler_audience            = "https://us-central1-run.googleapis.com/"
    scheduler_oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    timeout_seconds = 3600
    resource_limits = {
      cpu    = "1"
      memory = "2Gi"
    }
  }
  report = {
    name                = "generate-reports"
    image               = "us-central1-docker.pkg.dev/i4g-dev/applications/report-job:dev"
    service_account_key = "report"
    env_vars = {
      I4G_ENV = "dev"
    }
  }
  account_list = {
    name                = "account-list"
    image               = "us-central1-docker.pkg.dev/i4g-dev/applications/account-job:dev"
    service_account_key = "report"
    env_vars = {
      I4G_ENV                          = "dev"
      I4G_ACCOUNT_JOB__WINDOW_DAYS     = "15"
      I4G_ACCOUNT_JOB__CATEGORIES      = "bank,crypto,payments"
      I4G_ACCOUNT_JOB__OUTPUT_FORMATS  = "pdf,xlsx"
      I4G_ACCOUNT_JOB__INCLUDE_SOURCES = "true"
      I4G_RUNTIME__LOG_LEVEL           = "INFO"
      I4G_ACCOUNT_LIST__ENABLE_VECTOR  = "false"
      I4G_LLM__PROVIDER                = "mock"
      I4G_STORAGE__FIRESTORE__PROJECT  = "i4g-dev"
    }
  }
  dossier_queue = {
    name                = "dossier-queue"
    image               = "us-central1-docker.pkg.dev/i4g-dev/applications/dossier-job:dev"
    service_account_key = "report"
    env_vars = {
      I4G_ENV = "dev"
    }
  }
}

vertex_search_data_store_id = "retrieval-poc"
vertex_search_display_name  = "Retrieval PoC Data Store"

# Custom domains (leave blank if DNS is managed externally and not present in this project)
fastapi_custom_domain    = "api.intelligenceforgood.org"
ui_custom_domain         = "app.intelligenceforgood.org"
dns_managed_zone         = ""
dns_managed_zone_project = ""

# IAP allowed domains
iap_allowed_domains = ["intelligenceforgood.org"]

