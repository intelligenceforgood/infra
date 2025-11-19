project_id    = "i4g-dev"
fastapi_image = "us-central1-docker.pkg.dev/i4g-dev/applications/fastapi:dev"

fastapi_env_vars = {
  I4G_ENV                  = "dev"
  I4G_STORAGE__SQLITE_PATH = "/tmp/i4g_store.db"
}

fastapi_invoker_member = "allUsers"

streamlit_image = "us-central1-docker.pkg.dev/i4g-dev/applications/streamlit:dev"

streamlit_env_vars = {
  I4G_ENV                          = "dev"
  I4G_API__KEY                     = "dev-analyst-token"
  STREAMLIT_SERVER_TITLE           = "i4g Analyst Dashboard"
  I4G_VERTEX_SEARCH_PROJECT        = "i4g-dev"
  I4G_VERTEX_SEARCH_LOCATION       = "global"
  I4G_VERTEX_SEARCH_DATA_STORE     = "retrieval-poc"
  I4G_VERTEX_SEARCH_SERVING_CONFIG = "default_search"
}

streamlit_invoker_member = ""
streamlit_invoker_members = [
  "allUsers",
]

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
      I4G_ENV = "dev"
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
}

vertex_search_data_store_id = "retrieval-poc"
vertex_search_display_name  = "Retrieval PoC Data Store"

