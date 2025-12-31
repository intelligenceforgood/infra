project_id = "i4g-pii-vault-dev"
region     = "us-central1"

app_service_accounts = [
  "sa-app@i4g-dev.iam.gserviceaccount.com",
  "sa-ingest@i4g-dev.iam.gserviceaccount.com",
]

iam_db_groups = [
  "gcp-i4g-admin@intelligenceforgood.org",
  "gcp-i4g-analyst@intelligenceforgood.org",
]
