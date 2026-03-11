project_id = "i4g-pii-vault-prod"
region     = "us-central1"

iam_db_groups = [
  "gcp-i4g-admin@intelligenceforgood.org",
  "gcp-i4g-analyst@intelligenceforgood.org",
]

# App SA emails for vault database user creation only.
# IAM roles (cloudsql.client, cloudsql.instanceUser) are managed in app/prod
# via the pii_vault_access module.
app_service_accounts = [
  "sa-app@i4g-prod.iam.gserviceaccount.com",
  "sa-ingest@i4g-prod.iam.gserviceaccount.com",
  "sa-report@i4g-prod.iam.gserviceaccount.com",
]
