# ---------------------------------------------------------------------------
# PII-Vault Stack — Database Users
# ---------------------------------------------------------------------------

# Create users for App Service Accounts (e.g. sa-app, sa-ingest).
# NOTE: IAM roles (cloudsql.client, cloudsql.instanceUser) are granted in
# the app stack via the pii_vault_access module. This resource only creates
# the database user entries on the Cloud SQL instance.
resource "google_sql_user" "app_sa_users" {
  for_each = { for email in var.app_service_accounts : email => email }
  name     = trimsuffix(each.value, ".gserviceaccount.com")
  instance = google_sql_database_instance.vault.name
  project  = var.project_id
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
}
