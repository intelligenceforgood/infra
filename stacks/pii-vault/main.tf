# ---------------------------------------------------------------------------
# PII-Vault Stack — Main
#
# API enablement, storage bucket, KMS, and secret manager resources for the
# PII vault project.
# ---------------------------------------------------------------------------

# ── API Enablement ───────────────────────────────────────────────────────────

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

# ── Storage ──────────────────────────────────────────────────────────────────

resource "google_storage_bucket" "vault_objects" {
  project                     = var.project_id
  name                        = "i4g-vault-objects-${var.project_id}"
  location                    = var.region
  force_destroy               = var.bucket_force_destroy
  uniform_bucket_level_access = true
  versioning { enabled = true }
  lifecycle_rule {
    action { type = "Delete" }
    condition { age = var.bucket_lifecycle_age }
  }

  depends_on = [google_project_service.storage]
}

# ── KMS ──────────────────────────────────────────────────────────────────────

module "kms" {
  source        = "../../modules/security/kms"
  project_id    = var.project_id
  region        = var.region
  key_ring_name = "i4g-vault-ring"
}

resource "google_kms_crypto_key" "vault_key" {
  name            = "i4g-vault-encrypt"
  key_ring        = module.kms.key_ring_self_link
  rotation_period = "7776000s" # 90 days
}

# ── Secrets ──────────────────────────────────────────────────────────────────

module "tokenization_secrets" {
  source     = "../../modules/security/secret_manager"
  project_id = var.project_id

  secrets = {
    pii_key = {
      secret_id = "pii-tokenization-key"
      labels    = { service = "vault", env = var.environment }
    }
    pepper = {
      secret_id = "tokenization-pepper"
      labels    = { service = "vault", env = var.environment }
    }
  }
}
