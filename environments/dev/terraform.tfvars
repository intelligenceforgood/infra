project_id    = "i4g-dev"
fastapi_image = "us-central1-docker.pkg.dev/i4g-dev/applications/fastapi:dev"

fastapi_env_vars = {
  I4G_ENV                  = "dev"
  I4G_STORAGE__SQLITE_PATH = "/tmp/i4g_store.db"
}

fastapi_invoker_member = "allUsers"

streamlit_image = "us-central1-docker.pkg.dev/i4g-dev/applications/streamlit:dev"

streamlit_env_vars = {
  I4G_ENV                = "dev"
  I4G_API__KEY           = "dev-analyst-token"
  STREAMLIT_SERVER_TITLE = "i4g Analyst Dashboard"
  I4G_VERTEX_SEARCH_PROJECT        = "i4g-dev"
  I4G_VERTEX_SEARCH_LOCATION       = "global"
  I4G_VERTEX_SEARCH_DATA_STORE     = "retrieval-poc"
  I4G_VERTEX_SEARCH_SERVING_CONFIG = "default_search"
}

streamlit_invoker_member = "allUsers"

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
    enabled            = false
    name                = "ingest-azure-snapshot"
  image               = "us-central1-docker.pkg.dev/i4g-dev/applications/ingest-job:dev"
    service_account_key = "ingest"
    env_vars = {
      I4G_ENV = "dev"
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

