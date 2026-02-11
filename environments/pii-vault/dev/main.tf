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

resource "google_project_service" "sqladmin" {
  project            = var.project_id
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "run" {
  project            = var.project_id
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_storage_bucket" "vault_objects" {
  project                     = var.project_id
  name                        = "i4g-vault-objects-${var.project_id}"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
  versioning { enabled = true }
  lifecycle_rule {
    action { type = "Delete" }
    condition { age = 365 }
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
  rotation_period = "7776000s" # 90 days
}

module "tokenization_secret" {
  source     = "../../../modules/security/secret_manager"
  project_id = var.project_id
  region     = var.region
  secret_id  = "pii-tokenization-key"
}

module "tokenization_pepper" {
  source     = "../../../modules/security/secret_manager"
  project_id = var.project_id
  region     = var.region
  secret_id  = "tokenization-pepper"
}
