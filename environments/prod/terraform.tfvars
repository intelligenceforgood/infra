project_id    = "i4g-prod"
fastapi_image = "us-central1-docker.pkg.dev/i4g-prod/applications/fastapi:prod"

fastapi_env_vars = {
  I4G_ENV                          = "prod"
  I4G_RUNTIME__LOG_LEVEL           = "WARNING"
  I4G_STORAGE__STRUCTURED_BACKEND = "firestore"
}

streamlit_image = "us-central1-docker.pkg.dev/i4g-prod/applications/streamlit:prod"

streamlit_env_vars = {
  I4G_ENV                = "prod"
  STREAMLIT_SERVER_TITLE = "i4g Analyst Dashboard"
}

vertex_search_data_store_id = "retrieval-prod"
vertex_search_display_name  = "Retrieval Production Data Store"

storage_bucket_default_location = "US"
storage_buckets = {
  evidence = {
    name          = "i4g-evidence-prod"
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
    name                = "ingest-azure-snapshot"
  image               = "us-central1-docker.pkg.dev/i4g-prod/applications/ingest-job:prod"
    service_account_key = "ingest"
    env_vars = {
      I4G_ENV = "prod"
    }
    schedule                        = "0 * * * *"
    time_zone                       = "UTC"
    description                     = "Hourly ingestion of Azure exports"
    scheduler_service_account_key   = "ingest"
    scheduler_attempt_deadline_seconds = 300
  }
  report = {
    name                = "generate-reports"
  image               = "us-central1-docker.pkg.dev/i4g-prod/applications/report-job:prod"
    service_account_key = "report"
    env_vars = {
      I4G_ENV = "prod"
    }
    schedule                      = "0 2 * * *"
    time_zone                     = "UTC"
    description                   = "Daily report generation"
    scheduler_service_account_key = "report"
  }
}
