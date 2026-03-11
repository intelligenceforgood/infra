# Create users for App Service Accounts (sa-app, sa-ingest, sa-report from i4g-prod).
# NOTE: IAM roles (cloudsql.client, cloudsql.instanceUser) are granted in
# app/prod via the pii_vault_access module. This resource only creates the
# database user entries on the Cloud SQL instance.
#
# Unlike pii-vault/dev, prod has no vault Cloud Run service and therefore no
# vault SA — the app project SAs access the vault DB directly.
resource "google_sql_user" "app_sa_users" {
  for_each = { for email in var.app_service_accounts : email => email }
  name     = trimsuffix(each.value, ".gserviceaccount.com")
  instance = google_sql_database_instance.vault.name
  project  = var.project_id
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
}
