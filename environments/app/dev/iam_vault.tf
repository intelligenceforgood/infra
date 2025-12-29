# Data source to get the PII Vault project details (specifically the project number)
data "google_project" "pii_vault_dev" {
  project_id = "i4g-pii-vault-dev"
}

# Grant the PII Vault service account access to pull images from the app dev registry
resource "google_artifact_registry_repository_iam_member" "vault_reader" {
  project    = var.project_id
  location   = google_artifact_registry_repository.applications.location
  repository = google_artifact_registry_repository.applications.repository_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:sa-vault@i4g-pii-vault-dev.iam.gserviceaccount.com"

  depends_on = [google_artifact_registry_repository.applications]
}

# Grant the PII Vault Cloud Run Service Agent access to pull images
# This is required because the image is in a different project (i4g-dev)
resource "google_artifact_registry_repository_iam_member" "vault_service_agent_reader" {
  project    = var.project_id
  location   = google_artifact_registry_repository.applications.location
  repository = google_artifact_registry_repository.applications.repository_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:service-${data.google_project.pii_vault_dev.number}@serverless-robot-prod.iam.gserviceaccount.com"

  depends_on = [google_artifact_registry_repository.applications]
}
