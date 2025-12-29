resource "google_service_account" "vault_sa" {
  project      = var.project_id
  account_id   = "sa-vault"
  display_name = "Vault Service Account"
}

# Grant Cloud SQL Client
resource "google_project_iam_member" "vault_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.vault_sa.email}"
}

# Grant Secret Access
resource "google_secret_manager_secret_iam_member" "vault_secret_access" {
  project   = var.project_id
  secret_id = module.tokenization_secret.secret_name
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.vault_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "vault_pepper_access" {
  project   = var.project_id
  secret_id = module.tokenization_pepper.secret_name
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.vault_sa.email}"
}

# Grant KMS Access
resource "google_kms_crypto_key_iam_member" "vault_kms_access" {
  crypto_key_id = google_kms_crypto_key.vault_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.vault_sa.email}"
}

module "vault_service" {
  source = "../../../modules/run/service"

  depends_on = [google_project_service.run]

  project_id      = var.project_id
  name            = "i4g-vault"
  location        = var.region
  service_account = google_service_account.vault_sa.email
  image           = "us-central1-docker.pkg.dev/i4g-dev/applications/fastapi:dev"

  env_vars = {
    "I4G_ENV"                                    = "dev"
    "I4G_STORAGE__STRUCTURED_BACKEND"            = "cloudsql"
    "I4G_STORAGE__CLOUDSQL_INSTANCE"             = google_sql_database_instance.vault.connection_name
    "I4G_STORAGE__CLOUDSQL_DATABASE"             = google_sql_database.vault_db.name
    "I4G_STORAGE__CLOUDSQL_USER"                 = trimsuffix(google_service_account.vault_sa.email, ".gserviceaccount.com")
    "I4G_STORAGE__CLOUDSQL_ENABLE_IAM_AUTH"      = "true"
    "I4G_TOKENIZATION__BACKEND"                  = "cloudsql"
    "I4G_TOKENIZATION__CLOUDSQL_INSTANCE"        = google_sql_database_instance.vault.connection_name
    "I4G_TOKENIZATION__CLOUDSQL_DATABASE"        = google_sql_database.vault_db.name
    "I4G_TOKENIZATION__CLOUDSQL_USER"            = trimsuffix(google_service_account.vault_sa.email, ".gserviceaccount.com")
    "I4G_TOKENIZATION__CLOUDSQL_ENABLE_IAM_AUTH" = "true"
  }

  secret_env_vars = {
    "I4G_TOKENIZATION__PEPPER" = {
      secret  = module.tokenization_pepper.secret_name
      version = "latest"
    }
    "I4G_CRYPTO__PII_KEY" = {
      secret  = module.tokenization_secret.secret_name
      version = "latest"
    }
  }
}
