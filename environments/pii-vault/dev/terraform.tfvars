project_id = "i4g-pii-vault-dev"
region     = "us-central1"

iam_db_groups = [
  "gcp-i4g-admin@intelligenceforgood.org",
  "gcp-i4g-analyst@intelligenceforgood.org",
]

# App SA emails for vault database user creation only.
# IAM roles are managed in app/dev via the pii_vault_access module.
app_service_accounts = [
  "sa-app@i4g-dev.iam.gserviceaccount.com",
  "sa-ingest@i4g-dev.iam.gserviceaccount.com",
  "sa-report@i4g-dev.iam.gserviceaccount.com",
]
