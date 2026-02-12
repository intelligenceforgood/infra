i4g_analyst_members = [
  "group:gcp-i4g-analyst@intelligenceforgood.org",
]

i4g_admin_members = [
  "group:gcp-i4g-admin@intelligenceforgood.org",
]

db_admin_group   = "gcp-i4g-admin@intelligenceforgood.org"
db_analyst_group = "gcp-i4g-analyst@intelligenceforgood.org"

database_config = {
  instance_name       = "i4g-prod-db"
  tier                = "db-custom-2-7680"
  disk_size           = 50
  availability_type   = "REGIONAL"
  backup_enabled      = true
  backup_start_time   = "02:00"
  deletion_protection = true
}

project_id            = "i4g-prod"
pii_vault_project_id  = "i4g-pii-vault-prod"
iap_support_email     = "jerry@intelligenceforgood.org"
iap_application_title = "i4g Analyst Surfaces (Prod)"
fastapi_image         = "us-central1-docker.pkg.dev/i4g-prod/applications/fastapi:prod"

fastapi_env_vars = {
  I4G_ENV                            = "prod"
  I4G_RUNTIME__LOG_LEVEL             = "WARNING"
  I4G_STORAGE__STRUCTURED_BACKEND    = "cloudsql"
  I4G_STORAGE__EVIDENCE__LOCAL_DIR   = "/tmp/evidence"
  I4G_APP__CLOUDSQL__INSTANCE        = "i4g-prod:us-central1:i4g-prod-db"
  I4G_APP__CLOUDSQL__DATABASE        = "i4g_db"
  I4G_APP__CLOUDSQL__USER            = "sa-app@i4g-prod.iam.gserviceaccount.com"
  I4G_APP__CLOUDSQL__ENABLE_IAM_AUTH = "true"
  I4G_VECTOR__BACKEND                = "vertex_ai"
  I4G_LLM__PROVIDER                  = "vertex_ai"
  I4G_LLM__CHAT_MODEL                = "gemini-2.5-flash"
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

# Console image — set when the image is pushed to the prod registry.
# When empty, the console service and its LB backend are skipped.
console_image = ""

console_env_vars = {
  NEXT_PUBLIC_USE_MOCK_DATA        = "false"
  I4G_API_KIND                     = "core"
  I4G_VERTEX_SEARCH_SERVING_CONFIG = "default_search"
}

console_secret_env_vars = {
  I4G_API_KEY = {
    secret  = "projects/i4g-prod/secrets/api-key"
    version = "latest"
  }
}

console_invoker_member  = ""
console_invoker_members = []

vertex_ai_search = {
  project_id    = "i4g-prod"
  location      = "global"
  data_store_id = "retrieval-prod"
  display_name  = "Retrieval Production Data Store"
}

# Custom domains (enable when prod is ready for custom domain cutover)
fastapi_custom_domain    = ""
ui_custom_domain         = ""
dns_managed_zone         = ""
dns_managed_zone_project = ""

# IAP OAuth clients — override in local-overrides.tfvars when ready.
# Leave empty until IAP clients are created for prod.
# iap_clients = {
#   console = {
#     client_id     = "..."
#     client_secret = "..."
#   }
#   api = {
#     client_id     = "..."
#     client_secret = "..."
#   }
# }

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
      I4G_STORAGE__STRUCTURED_BACKEND    = "cloudsql"
      I4G_APP__CLOUDSQL__INSTANCE        = "i4g-prod:us-central1:i4g-prod-db"
      I4G_APP__CLOUDSQL__DATABASE        = "i4g_db"
      I4G_APP__CLOUDSQL__USER            = "sa-ingest@i4g-prod.iam"
      I4G_APP__CLOUDSQL__ENABLE_IAM_AUTH = "true"
    }
    secret_env_vars = {
      I4G_PII__PEPPER = {
        secret  = "projects/i4g-pii-vault-prod/secrets/tokenization-pepper"
        version = "latest"
      }
      I4G_CRYPTO__PII_KEY = {
        secret  = "projects/i4g-pii-vault-prod/secrets/pii-tokenization-key"
        version = "latest"
      }
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
    secret_env_vars = {
      I4G_PII__PEPPER = {
        secret  = "projects/i4g-pii-vault-prod/secrets/tokenization-pepper"
        version = "latest"
      }
      I4G_CRYPTO__PII_KEY = {
        secret  = "projects/i4g-pii-vault-prod/secrets/pii-tokenization-key"
        version = "latest"
      }
    }
  }
  sweeper = {
    enabled             = false
    name                = "classification-sweeper"
    image               = "us-central1-docker.pkg.dev/i4g-prod/applications/ingest-job:prod"
    service_account_key = "ingest"
    timeout_seconds     = 3600
    parallelism         = 1
    max_retries         = 0
    args                = ["jobs", "sweeper"]
    schedule            = "*/5 * * * *"

    env_vars = {
      I4G_ENV                            = "prod"
      I4G_STORAGE__STRUCTURED_BACKEND    = "cloudsql"
      I4G_APP__CLOUDSQL__INSTANCE        = "i4g-prod:us-central1:i4g-prod-db"
      I4G_APP__CLOUDSQL__DATABASE        = "i4g_db"
      I4G_APP__CLOUDSQL__USER            = "sa-ingest@i4g-prod.iam"
      I4G_APP__CLOUDSQL__ENABLE_IAM_AUTH = "true"
      I4G_VECTOR__BACKEND                = "vertex_ai"
      I4G_LLM__PROVIDER                  = "vertex_ai"
      I4G_LLM__CHAT_MODEL                = "gemini-2.5-flash"
    }
  }

  account_list = {
    enabled             = false
    name                = "account-list"
    image               = "us-central1-docker.pkg.dev/i4g-prod/applications/account-job:prod"
    service_account_key = "report"
    max_retries         = 0
    env_vars = {
      I4G_ENV                          = "prod"
      I4G_ACCOUNT_JOB__WINDOW_DAYS     = "15"
      I4G_ACCOUNT_JOB__CATEGORIES      = "bank,crypto,payments"
      I4G_ACCOUNT_JOB__OUTPUT_FORMATS  = "pdf,xlsx"
      I4G_ACCOUNT_JOB__INCLUDE_SOURCES = "true"
      I4G_RUNTIME__LOG_LEVEL           = "INFO"
      I4G_ACCOUNT_LIST__ENABLE_VECTOR  = "false"
      I4G_LLM__PROVIDER                = "vertex_ai"
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
