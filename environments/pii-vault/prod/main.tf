resource "google_project_service" "storage" {
  project            = var.project_id
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secretmanager" {
  project            = var.project_id
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudkms" {
  project            = var.project_id
  service            = "cloudkms.googleapis.com"
  disable_on_destroy = false
}

resource "google_storage_bucket" "vault_objects" {
  project                     = var.project_id
  name                        = "i4g-vault-objects-${var.project_id}"
  location                    = var.region
  force_destroy               = false
  uniform_bucket_level_access = true
  versioning { enabled = true }
  lifecycle_rule {
    action { type = "Delete" }
    condition { age = 1825 }
  }
  depends_on = [google_project_service.storage]
}

module "kms" {
  source        = "../../../modules/security/kms"
  project_id    = var.project_id
  region        = var.region
  key_ring_name = "i4g-vault-ring"
}

resource "google_kms_crypto_key" "vault_key" {
  name            = "i4g-vault-encrypt"
  key_ring        = module.kms.key_ring_self_link
  rotation_period = "7776000s"
}

module "tokenization_secret" {
  source     = "../../../modules/security/secret_manager"
  project_id = var.project_id
  region     = var.region
  secret_id  = "pii-tokenization-key"
}

resource "google_project_iam_member" "app_secret_accessor" {
  for_each = { for email in var.app_service_accounts : email => email }
  project  = var.project_id
  role     = "roles/secretmanager.secretAccessor"
  member   = format("serviceAccount:%s", each.value)
}

resource "google_kms_crypto_key_iam_member" "app_key_access" {
  for_each      = { for email in var.app_service_accounts : email => email }
  crypto_key_id = google_kms_crypto_key.vault_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = format("serviceAccount:%s", each.value)
}
