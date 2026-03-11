# ---------------------------------------------------------------------------
# App Stack — PII Vault Cross-Project Access
#
# The PII Vault project is storage-only — it holds tokenization secrets and
# KMS keys but has no service accounts or role bindings of its own.  All
# access control is defined here in the App project.
# ---------------------------------------------------------------------------

module "pii_vault_access" {
  source               = "../../modules/iam/pii_vault_access"
  pii_vault_project_id = var.pii_vault_project_id

  accessor_emails = [
    module.iam_service_accounts.emails["app"],
    module.iam_service_accounts.emails["ingest"],
    module.iam_service_accounts.emails["report"],
  ]
}

# Grant the PII Vault service account access to pull images from the app registry.
# Only needed when the pii-vault project runs Cloud Run workloads (e.g. dev).
data "google_project" "pii_vault" {
  count      = var.enable_vault_registry_access ? 1 : 0
  project_id = var.pii_vault_project_id
}

resource "google_artifact_registry_repository_iam_member" "vault_reader" {
  count      = var.enable_vault_registry_access ? 1 : 0
  project    = var.project_id
  location   = google_artifact_registry_repository.applications.location
  repository = google_artifact_registry_repository.applications.repository_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:sa-vault@${var.pii_vault_project_id}.iam.gserviceaccount.com"

  depends_on = [google_artifact_registry_repository.applications]
}

# Grant the PII Vault Cloud Run Service Agent access to pull images.
# Required because the image is in a different project.
resource "google_artifact_registry_repository_iam_member" "vault_service_agent_reader" {
  count      = var.enable_vault_registry_access ? 1 : 0
  project    = var.project_id
  location   = google_artifact_registry_repository.applications.location
  repository = google_artifact_registry_repository.applications.repository_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:service-${data.google_project.pii_vault[0].number}@serverless-robot-prod.iam.gserviceaccount.com"

  depends_on = [google_artifact_registry_repository.applications]
}
