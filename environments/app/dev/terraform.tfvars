i4g_analyst_members = [
  "group:gcp-i4g-analyst@intelligenceforgood.org",
  "group:i4g-friend@intelligenceforgood.org",
]

i4g_admin_members = [
  "group:gcp-i4g-admin@intelligenceforgood.org",
]

db_admin_group   = "gcp-i4g-admin@intelligenceforgood.org"
db_analyst_group = "gcp-i4g-analyst@intelligenceforgood.org"

project_id            = "i4g-dev"
iap_support_email     = "jerry@intelligenceforgood.org"
iap_application_title = "i4g Analyst Surfaces (Dev)"
fastapi_image         = "us-central1-docker.pkg.dev/i4g-dev/applications/fastapi:dev"

fastapi_env_vars = {
  I4G_ENV                                     = "dev"
  I4G_STORAGE__STRUCTURED_BACKEND             = "cloudsql"
  I4G_STORAGE__CLOUDSQL_INSTANCE              = "i4g-dev:us-central1:i4g-dev-db"
  I4G_STORAGE__CLOUDSQL_DATABASE              = "i4g_db"
  I4G_STORAGE__CLOUDSQL_USER                  = "ingest_user"
  I4G_STORAGE__FIRESTORE__PROJECT             = "i4g-dev"
  I4G_VECTOR__BACKEND                         = "vertex_ai"
  I4G_VECTOR__VERTEX_AI_BRANCH                = "default_branch"
  I4G_API__RATE_LIMIT_PER_MINUTE              = "1000"
  I4G_TOKENIZATION__BACKEND                   = "cloudsql"
  I4G_TOKENIZATION__CLOUDSQL_INSTANCE         = "i4g-dev:us-central1:i4g-dev-db"
  I4G_TOKENIZATION__CLOUDSQL_DATABASE         = "vault_db"
  I4G_TOKENIZATION__CLOUDSQL_USER             = "sa-app@i4g-dev.iam"
  I4G_TOKENIZATION__CLOUDSQL_ENABLE_IAM_AUTH  = "true"
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
  I4G_STORAGE__CLOUDSQL_PASSWORD = {
    secret  = "projects/i4g-dev/secrets/ingest-db-password"
    version = "latest"
  }
}

streamlit_image = "us-central1-docker.pkg.dev/i4g-dev/applications/streamlit:dev"

streamlit_env_vars = {
  I4G_ENV                          = "dev"
  I4G_API__KEY                     = "" # real token lives in local-overrides.tfvars (see infra/docs/README.md)
  STREAMLIT_SERVER_TITLE           = "I4G Analyst Dashboard"
  I4G_VERTEX_SEARCH_SERVING_CONFIG = "default_search"
}

streamlit_invoker_member  = ""
streamlit_invoker_members = []

console_image = "us-central1-docker.pkg.dev/i4g-dev/applications/i4g-console:dev"

console_env_vars = {
  NEXT_PUBLIC_USE_MOCK_DATA        = "false"
  I4G_API_KIND                     = "core"
  I4G_API_KEY                      = "dev-analyst-token"
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
    name          = "i4g-reports-dev"
    force_destroy = true
    labels = {
      env     = "dev"
      service = "reports"
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
  data_bundles = {
    name                        = "i4g-dev-data-bundles"
    force_destroy               = false
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
    name                = "ingest-bootstrap"
    image               = "us-central1-docker.pkg.dev/i4g-dev/applications/ingest-job:dev"
    service_account_key = "ingest"
    timeout_seconds     = 3600
    env_vars = {
      I4G_ENV                          = "dev"
      I4G_STORAGE__STRUCTURED_BACKEND  = "cloudsql"
      I4G_STORAGE__CLOUDSQL_INSTANCE   = "i4g-dev:us-central1:i4g-dev-db"
      I4G_STORAGE__CLOUDSQL_DATABASE   = "i4g_db"
      I4G_STORAGE__CLOUDSQL_USER       = "ingest_user"
      I4G_VECTOR__BACKEND              = "vertex_ai"
    }
    secret_env_vars = {
      I4G_STORAGE__CLOUDSQL_PASSWORD = {
        secret  = "ingest-db-password"
        version = "latest"
      }
    }
  }

  intake = {
    name                = "process-intakes"
    image               = "us-central1-docker.pkg.dev/i4g-dev/applications/intake-job:dev"
    service_account_key = "intake"
    env_vars = {
      I4G_ENV                         = "dev"
      I4G_API__KEY                    = "dev-analyst-token"
      I4G_INGEST__ENABLE_VECTOR       = "false"
      I4G_RUNTIME__FALLBACK_DIR       = "/tmp/i4g"
      I4G_STORAGE__STRUCTURED_BACKEND = "cloudsql"
      I4G_STORAGE__CLOUDSQL_INSTANCE  = "i4g-dev:us-central1:i4g-dev-db"
      I4G_STORAGE__CLOUDSQL_DATABASE  = "i4g_db"
      I4G_STORAGE__CLOUDSQL_USER      = "ingest_user"
    }
    secret_env_vars = {
      I4G_STORAGE__CLOUDSQL_PASSWORD = {
        secret  = "ingest-db-password"
        version = "latest"
      }
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

vertex_ai_search = {
  project_id    = "REPLACE_WITH_PROJECT_ID"
  location      = "global"
  data_store_id = "REPLACE_WITH_DATA_STORE_ID"
  display_name  = "Retrieval PoC Data Store"
}

# Custom domains (leave blank if DNS is managed externally and not present in this project)
fastapi_custom_domain    = "api.intelligenceforgood.org"
ui_custom_domain         = "app.intelligenceforgood.org"
dns_managed_zone         = ""
dns_managed_zone_project = ""

# IAP allowed domains
iap_allowed_domains = ["intelligenceforgood.org"]

iap_clients = {
  api = {
    client_id     = "REPLACE_WITH_CLIENT_ID"
    client_secret = "REPLACE_WITH_CLIENT_SECRET"
  }
  console = {
    client_id     = "REPLACE_WITH_CLIENT_ID"
    client_secret = "REPLACE_WITH_CLIENT_SECRET"
  }
}

