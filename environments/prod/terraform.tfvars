i4g_analyst_members = [
  "group:gcp-i4g-analyst@intelligenceforgood.org",
]

i4g_admin_members = [
  "group:gcp-i4g-admin@intelligenceforgood.org",
]

project_id            = "i4g-prod"
iap_support_email     = "jerry@intelligenceforgood.org"
iap_application_title = "i4g Analyst Surfaces (Prod)"
fastapi_image         = "us-central1-docker.pkg.dev/i4g-prod/applications/fastapi:prod"

fastapi_env_vars = {
  I4G_ENV                          = "prod"
  I4G_RUNTIME__LOG_LEVEL           = "WARNING"
  I4G_STORAGE__STRUCTURED_BACKEND  = "firestore"
  I4G_VERTEX_SEARCH_PROJECT        = "i4g-prod"
  I4G_VERTEX_SEARCH_LOCATION       = "global"
  I4G_VERTEX_SEARCH_DATA_STORE     = "retrieval-prod"
  I4G_VERTEX_SEARCH_SERVING_CONFIG = "default_search"
}

streamlit_image = "us-central1-docker.pkg.dev/i4g-prod/applications/streamlit:prod"

streamlit_env_vars = {
  I4G_ENV                          = "prod"
  STREAMLIT_SERVER_TITLE           = "i4g Analyst Dashboard"
  I4G_VERTEX_SEARCH_PROJECT        = "i4g-prod"
  I4G_VERTEX_SEARCH_LOCATION       = "global"
  I4G_VERTEX_SEARCH_DATA_STORE     = "retrieval-prod"
  I4G_VERTEX_SEARCH_SERVING_CONFIG = "default_search"
}

streamlit_invoker_member  = ""
streamlit_invoker_members = []

console_image = "us-central1-docker.pkg.dev/i4g-prod/applications/analyst-console:prod"

console_env_vars = {
  NEXT_PUBLIC_USE_MOCK_DATA        = "false"
  I4G_API_KIND                     = "proto"
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
    name                = "ingest-azure-snapshot"
    image               = "us-central1-docker.pkg.dev/i4g-prod/applications/ingest-job:prod"
    service_account_key = "ingest"
    env_vars = {
      I4G_ENV = "prod"
    }
  }
  intake = {
    name                = "process-intakes"
    image               = "us-central1-docker.pkg.dev/i4g-prod/applications/intake-job:prod"
    service_account_key = "intake"
    env_vars = {
      I4G_ENV = "prod"
    }
  }
  weekly_refresh = {
    enabled             = false
    name                = "weekly-azure-refresh"
    image               = "us-central1-docker.pkg.dev/i4g-prod/applications/weekly-refresh-job:prod"
    service_account_key = "ingest"
    env_vars = {
      I4G_ENV = "prod"
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
    schedule        = "0 11 * * MON"
    time_zone       = "UTC"
    description     = "Weekly Azure -> GCP incremental refresh (prod)."
    timeout_seconds = 3600
    resource_limits = {
      cpu    = "1"
      memory = "2Gi"
    }
  }
  report = {
    name                = "generate-reports"
    image               = "us-central1-docker.pkg.dev/i4g-prod/applications/report-job:prod"
    service_account_key = "report"
    env_vars = {
      I4G_ENV = "prod"
    }
  }
}
