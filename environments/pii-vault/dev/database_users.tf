# Create the Vault Service Account user in the database
resource "google_sql_user" "vault_sa_user" {
  name     = trimsuffix(google_service_account.vault_sa.email, ".gserviceaccount.com")
  instance = google_sql_database_instance.vault.name
  project  = var.project_id
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
}

# Grant the Vault Service Account access to login (Cloud SQL Instance User)
resource "google_project_iam_member" "vault_sa_sql_instance_user" {
  project = var.project_id
  role    = "roles/cloudsql.instanceUser"
  member  = "serviceAccount:${google_service_account.vault_sa.email}"
}
