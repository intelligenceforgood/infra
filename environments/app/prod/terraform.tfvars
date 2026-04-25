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
iap_support_email     = "jerry@intelligenceforgood.org"
iap_application_title = "i4g Analyst Surfaces (Prod)"
core_svc_image        = "us-central1-docker.pkg.dev/i4g-prod/applications/core-svc:prod"

core_svc_env_vars = {
  I4G_ENV                            = "prod"
  I4G_RUNTIME__LOG_LEVEL             = "WARNING"
  I4G_STORAGE__STRUCTURED_BACKEND    = "cloudsql"
  I4G_STORAGE__EVIDENCE__LOCAL_DIR   = "/tmp/evidence"
  I4G_APP__CLOUDSQL__INSTANCE        = "i4g-prod:us-central1:i4g-prod-db"
  I4G_APP__CLOUDSQL__DATABASE        = "i4g_db"
  I4G_APP__CLOUDSQL__USER            = "sa-app@i4g-prod.iam"
  I4G_APP__CLOUDSQL__ENABLE_IAM_AUTH = "true"
  I4G_VECTOR__BACKEND                = "vertex_ai"
  I4G_LLM__PROVIDER                  = "gemini"
  I4G_LLM__CHAT_MODEL                = "gemini-3-flash-preview"
  I4G_VERTEX_SEARCH_SERVING_CONFIG   = "default_search"
  I4G_FEEDBACK__SHEET_ID             = "1o8iSyLtFbSxdqEtT-L7OQvSqKTealP1H8f0VZzZKTw8"
  I4G_EMAIL__PROVIDER                = "smtp"
  I4G_EMAIL__SMTP_HOST               = "smtp-relay.gmail.com"
  I4G_EMAIL__FROM_ADDRESS            = "report@intelligenceforgood.org"
}

core_svc_secret_env_vars = {
  I4G_API__KEY = {
    secret  = "projects/i4g-prod/secrets/api-key"
    version = "latest"
  }
  I4G_CRYPTO__PII_KEY = {
    secret  = "projects/i4g-prod/secrets/pii-encryption-key"
    version = "latest"
  }
  I4G_LLM__GEMINI_API_KEY = {
    secret  = "projects/i4g-prod/secrets/gemini-api-key"
    version = "latest"
  }
}

# Console image — set when the image is pushed to the prod registry.
# When empty, the console service and its LB backend are skipped.
console_image = "us-central1-docker.pkg.dev/i4g-prod/applications/i4g-console:prod"

console_env_vars = {
  NEXT_PUBLIC_USE_MOCK_DATA        = "false"
  NEXT_PUBLIC_FEEDBACK_ENABLED     = "true"
  I4G_API_KIND                     = "core"
  I4G_API_URL                      = "https://api.intelligenceforgood.org"
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
core_svc_custom_domain = "api.intelligenceforgood.org"
# Direct Cloud Run URL — bypasses IAP for service-to-service event push (Phase 3B).
# sa-ssi already holds roles/run.invoker on core-svc (granted 2025-03-04).
core_svc_events_url      = "https://core-svc-5wtm4m22da-uc.a.run.app"
ui_custom_domain         = "app.intelligenceforgood.org"
dns_managed_zone         = ""
dns_managed_zone_project = ""

# IAP OAuth clients — override in local-overrides.tfvars when ready.
# Leave empty until IAP clients are created for prod.
iap_clients = {
  console = {
    client_id     = "..."
    client_secret = "..."
  }
  api = {
    client_id     = "..."
    client_secret = "..."
  }
}

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
  ssi_evidence = {
    name                        = "i4g-prod-ssi-evidence"
    uniform_bucket_level_access = true
    public_access_prevention    = "enforced"
    labels = {
      env     = "prod"
      service = "ssi"
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
}

run_jobs = {
  ingest = {
    enabled             = true
    name                = "ingest-bootstrap"
    image               = "us-central1-docker.pkg.dev/i4g-prod/applications/ingest-job:prod"
    service_account_key = "ingest"
    timeout_seconds     = 3600
    max_retries         = 0
    env_vars = {
      I4G_ENV                            = "prod"
      I4G_STORAGE__STRUCTURED_BACKEND    = "cloudsql"
      I4G_APP__CLOUDSQL__INSTANCE        = "i4g-prod:us-central1:i4g-prod-db"
      I4G_APP__CLOUDSQL__DATABASE        = "i4g_db"
      I4G_APP__CLOUDSQL__USER            = "sa-ingest@i4g-prod.iam"
      I4G_APP__CLOUDSQL__ENABLE_IAM_AUTH = "true"
      I4G_VECTOR__BACKEND                = "vertex_ai"
    }
    secret_env_vars = {
      I4G_CRYPTO__PII_KEY = {
        secret  = "projects/i4g-prod/secrets/pii-encryption-key"
        version = "latest"
      }
    }
  }

  intake = {
    enabled             = true
    name                = "process-intakes"
    image               = "us-central1-docker.pkg.dev/i4g-prod/applications/intake-job:prod"
    service_account_key = "intake"
    max_retries         = 0
    env_vars = {
      I4G_ENV                            = "prod"
      I4G_INGEST__ENABLE_VECTOR          = "false"
      I4G_RUNTIME__FALLBACK_DIR          = "/tmp/i4g"
      I4G_STORAGE__STRUCTURED_BACKEND    = "cloudsql"
      I4G_APP__CLOUDSQL__INSTANCE        = "i4g-prod:us-central1:i4g-prod-db"
      I4G_APP__CLOUDSQL__DATABASE        = "i4g_db"
      I4G_APP__CLOUDSQL__USER            = "sa-intake@i4g-prod.iam"
      I4G_APP__CLOUDSQL__ENABLE_IAM_AUTH = "true"
    }
    secret_env_vars = {
      I4G_API__KEY = {
        secret  = "projects/i4g-prod/secrets/api-key"
        version = "latest"
      }
      I4G_CRYPTO__PII_KEY = {
        secret  = "projects/i4g-prod/secrets/pii-encryption-key"
        version = "latest"
      }
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
      I4G_CRYPTO__PII_KEY = {
        secret  = "projects/i4g-prod/secrets/pii-encryption-key"
        version = "latest"
      }
    }
  }
  sweeper = {
    enabled             = true
    name                = "classification-sweeper"
    image               = "us-central1-docker.pkg.dev/i4g-prod/applications/ingest-job:prod"
    service_account_key = "ingest"
    timeout_seconds     = 3600
    parallelism         = 1
    max_retries         = 0
    args                = ["jobs", "sweeper"]
    schedule            = "*/5 * * * *"
    scheduler_paused    = true

    env_vars = {
      I4G_ENV                            = "prod"
      I4G_STORAGE__STRUCTURED_BACKEND    = "cloudsql"
      I4G_APP__CLOUDSQL__INSTANCE        = "i4g-prod:us-central1:i4g-prod-db"
      I4G_APP__CLOUDSQL__DATABASE        = "i4g_db"
      I4G_APP__CLOUDSQL__USER            = "sa-ingest@i4g-prod.iam"
      I4G_APP__CLOUDSQL__ENABLE_IAM_AUTH = "true"
      I4G_VECTOR__BACKEND                = "vertex_ai"
      I4G_LLM__PROVIDER                  = "gemini"
      I4G_LLM__CHAT_MODEL                = "gemini-3-flash-preview"
    }
    secret_env_vars = {
      I4G_LLM__GEMINI_API_KEY = {
        secret  = "projects/i4g-prod/secrets/gemini-api-key"
        version = "latest"
      }
    }
  }

  dossier_queue = {
    enabled             = true
    name                = "dossier-queue"
    image               = "us-central1-docker.pkg.dev/i4g-prod/applications/dossier-job:prod"
    service_account_key = "report"
    env_vars = {
      I4G_ENV = "prod"
    }
  }

  retention_purge = {
    enabled             = true
    name                = "retention-purge"
    image               = "us-central1-docker.pkg.dev/i4g-prod/applications/ingest-job:prod"
    service_account_key = "ingest"
    timeout_seconds     = 1800
    parallelism         = 1
    max_retries         = 0
    args                = ["jobs", "retention-purge"]
    schedule            = "0 3 * * *" # Daily at 03:00 UTC
    scheduler_paused    = true

    env_vars = {
      I4G_ENV                            = "prod"
      I4G_STORAGE__STRUCTURED_BACKEND    = "cloudsql"
      I4G_APP__CLOUDSQL__INSTANCE        = "i4g-prod:us-central1:i4g-prod-db"
      I4G_APP__CLOUDSQL__DATABASE        = "i4g_db"
      I4G_APP__CLOUDSQL__USER            = "sa-ingest@i4g-prod.iam"
      I4G_APP__CLOUDSQL__ENABLE_IAM_AUTH = "true"
      I4G_STORAGE__RETENTION_DAYS        = "90"
      I4G_STORAGE__RETENTION_GRACE_DAYS  = "30"
      I4G_LLM__PROVIDER                  = "gemini"
    }
  }

  analytics = {
    enabled             = true
    name                = "analytics-refresh"
    image               = "us-central1-docker.pkg.dev/i4g-prod/applications/ingest-job:prod"
    service_account_key = "ingest"
    timeout_seconds     = 3600
    parallelism         = 1
    max_retries         = 1
    args                = ["jobs", "analytics"]
    schedule            = "0 */4 * * *" # Every 4 hours
    scheduler_paused    = true

    env_vars = {
      I4G_ENV                            = "prod"
      I4G_STORAGE__STRUCTURED_BACKEND    = "cloudsql"
      I4G_APP__CLOUDSQL__INSTANCE        = "i4g-prod:us-central1:i4g-prod-db"
      I4G_APP__CLOUDSQL__DATABASE        = "i4g_db"
      I4G_APP__CLOUDSQL__USER            = "sa-ingest@i4g-prod.iam"
      I4G_APP__CLOUDSQL__ENABLE_IAM_AUTH = "true"
      I4G_LLM__PROVIDER                  = "gemini"
    }
  }

  ecx_poller = {
    enabled             = true # SSI enabled in prod
    name                = "ssi-ecx-poller"
    image               = "us-central1-docker.pkg.dev/i4g-prod/applications/ssi-svc:prod"
    service_account_key = "ssi"
    timeout_seconds     = 300
    parallelism         = 1
    max_retries         = 1
    command             = ["ssi"]
    args                = ["ecx", "poll"]
    schedule            = "*/15 * * * *"
    scheduler_paused    = true

    env_vars = {
      SSI_ENV                               = "prod"
      SSI_ECX__ENABLED                      = "true"
      SSI_ECX__POLLING_ENABLED              = "true"
      SSI_ECX__POLLING_MODULES              = "[\"phish\"]"
      SSI_ECX__POLLING_CONFIDENCE_THRESHOLD = "50"
      SSI_ECX__POLLING_AUTO_INVESTIGATE     = "false"
      SSI_ECX__BASE_URL                     = "https://api.ecrimex.net/api/v1"
      SSI_STORAGE__BACKEND                  = "cloudsql"
      SSI_STORAGE__CLOUDSQL_INSTANCE        = "i4g-prod:us-central1:i4g-prod-db"
      SSI_STORAGE__CLOUDSQL_DATABASE        = "i4g_db"
      SSI_STORAGE__CLOUDSQL_USER            = "sa-ssi@i4g-prod.iam"
      SSI_STORAGE__CLOUDSQL_ENABLE_IAM_AUTH = "true"
      SSI_LLM__PROVIDER                     = "mock"
    }

    secret_env_vars = {
      SSI_ECX__API_KEY = {
        secret  = "projects/i4g-prod/secrets/ssi-ecx-api-key"
        version = "latest"
      }
    }
  }

  merklemap_tail = {
    enabled = false
    name    = "merklemap-tail"
    # Reuses the ingest-job image — the core CLI `i4g jobs merklemap-tail`
    # is registered there (Phase C). Sprint 4 will enable this in prod after SLO sign-off.
    image               = "us-central1-docker.pkg.dev/i4g-prod/applications/ingest-job:prod"
    service_account_key = "ingest"
    timeout_seconds     = 2100 # 35 min — buffer over --max-runtime-seconds=1800
    parallelism         = 1
    max_retries         = 0
    args                = ["jobs", "merklemap-tail", "--max-runtime-seconds=1800"]

    env_vars = {
      I4G_ENV                               = "prod"
      I4G_STORAGE__STRUCTURED_BACKEND       = "cloudsql"
      I4G_APP__CLOUDSQL__INSTANCE           = "i4g-prod:us-central1:i4g-prod-db"
      I4G_APP__CLOUDSQL__DATABASE           = "i4g_db"
      I4G_APP__CLOUDSQL__USER               = "sa-ingest@i4g-prod.iam"
      I4G_APP__CLOUDSQL__ENABLE_IAM_AUTH    = "true"
      I4G_LLM__PROVIDER                     = "mock"
      PHISHDESTROY__MERKLEMAP_TAIL__ENABLED = "true"
      # Placeholder — enabled=false keeps this inert until Sprint 4.
      # Phase D2 / Sprint 4 will substitute the live prod URL before apply.
      I4G_SSI__SERVICE_URL = "https://ssi-svc-PROD-PLACEHOLDER-uc.a.run.app"
    }

    secret_env_vars = {
      PHISHDESTROY__MERKLEMAP_TAIL__API_KEY = {
        secret  = "projects/i4g-prod/secrets/merklemap-api-key"
        version = "latest"
      }
      I4G_CRYPTO__PII_KEY = {
        secret  = "projects/i4g-prod/secrets/pii-encryption-key"
        version = "latest"
      }
    }
  }

  backup_db = {
    enabled             = true
    name                = "backup-db"
    image               = "us-central1-docker.pkg.dev/i4g-prod/applications/backup-job:prod"
    service_account_key = "ingest"
    timeout_seconds     = 1800
    parallelism         = 1
    max_retries         = 0
    schedule            = "0 2 * * 0" # Weekly: Sunday at 02:00 UTC
    scheduler_paused    = true

    env_vars = {
      I4G_ENV                            = "prod"
      I4G_STORAGE__STRUCTURED_BACKEND    = "cloudsql"
      I4G_APP__CLOUDSQL__INSTANCE        = "i4g-prod:us-central1:i4g-prod-db"
      I4G_APP__CLOUDSQL__DATABASE        = "i4g_db"
      I4G_APP__CLOUDSQL__USER            = "sa-ingest@i4g-prod.iam"
      I4G_APP__CLOUDSQL__ENABLE_IAM_AUTH = "true"
      I4G_LLM__PROVIDER                  = "gemini"
    }
  }

  # ssi_investigate Cloud Run Job removed in 3.0.12 — SSI is now service-only.
  # See ssi_service_* variables and module.run_ssi_service for the replacement.
}

# ── SSI Cloud Run Service ───────────────────────────────────────────────────────
ssi_service_enabled = true
ssi_service_image   = "us-central1-docker.pkg.dev/i4g-prod/applications/ssi-svc:prod"

ssi_service_env_vars = {
  SSI_ENV                                = "prod"
  SSI_LLM__PROVIDER                      = "gemini"
  SSI_LLM__MODEL                         = "gemini-3-flash-preview"
  SSI_LLM__GCP_PROJECT                   = "i4g-prod"
  SSI_LLM__GCP_LOCATION                  = "us-central1"
  SSI_EVIDENCE__STORAGE_BACKEND          = "gcs"
  SSI_EVIDENCE__GCS_PREFIX               = "investigations"
  SSI_BROWSER__SANDBOX                   = "false"
  SSI_ZEN_BROWSER__CHROME_BINARY         = "/usr/bin/chromium"
  SSI_PROXY__ENABLED                     = "true"
  SSI_PROXY__USERNAME                    = "spoeevz5nw"
  SSI_COST__BUDGET_PER_INVESTIGATION_USD = "2.0"
  SSI_INTEGRATION__PUSH_TO_CORE          = "true"
  SSI_STORAGE__BACKEND                   = "cloudsql"
  SSI_STORAGE__CLOUDSQL_INSTANCE         = "i4g-prod:us-central1:i4g-prod-db"
  SSI_STORAGE__CLOUDSQL_DATABASE         = "i4g_db"
  SSI_STORAGE__CLOUDSQL_USER             = "sa-ssi@i4g-prod.iam"
  SSI_STORAGE__CLOUDSQL_ENABLE_IAM_AUTH  = "true"
}

ssi_service_secret_env_vars = {
  SSI_INTEGRATION__CORE_API_KEY = {
    secret  = "projects/i4g-prod/secrets/api-key"
    version = "latest"
  }
  SSI_PROXY__PASSWORD = {
    secret  = "projects/i4g-prod/secrets/ssi-proxy-credentials"
    version = "latest"
  }
  SSI_OSINT__VIRUSTOTAL_API_KEY = {
    secret  = "projects/i4g-prod/secrets/ssi-virustotal-api-key"
    version = "latest"
  }
  SSI_OSINT__URLSCAN_API_KEY = {
    secret  = "projects/i4g-prod/secrets/ssi-urlscan-api-key"
    version = "latest"
  }
  SSI_OSINT__IPINFO_TOKEN = {
    secret  = "projects/i4g-prod/secrets/ssi-ipinfo-token"
    version = "latest"
  }
  SSI_ECX__API_KEY = {
    secret  = "projects/i4g-prod/secrets/ssi-ecx-api-key"
    version = "latest"
  }
  SSI_LLM__GEMINI_API_KEY = {
    secret  = "projects/i4g-prod/secrets/gemini-api-key"
    version = "latest"
  }
}
