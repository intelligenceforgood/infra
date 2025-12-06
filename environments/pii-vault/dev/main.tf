resource "google_project_service" "secret_manager" {
  project            = var.project_id
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudkms" {
  project            = var.project_id
  service            = "cloudkms.googleapis.com"
  disable_on_destroy = false
}

module "kms" {
  source     = "../../../modules/security/kms"
  project_id = var.project_id
  region     = var.region
  key_ring_name = "pii-keyring"
}

    # Consider adding a KMS crypto key here later when the provider resource attributes are finalized.
module "secret_manager" {
  source     = "../../../modules/security/secret_manager"
  project_id = var.project_id
  region     = var.region
  secret_id  = "pii-sample-secret"
}

# Grant app service accounts access to the secret manager secret
resource "google_secret_manager_secret_iam_member" "authorized_access" {
  for_each = toset(var.authorized_service_accounts)

  secret_id = module.secret_manager.secret_name
  project   = var.project_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${each.value}"
}

output "pii_kms_key_ring" {
  value = module.kms.key_ring_self_link
}

# Grant app SAs permission to use keys in the ring
resource "google_kms_key_ring_iam_member" "authorized_key_users" {
  for_each = toset(var.authorized_service_accounts)

  key_ring_id = module.kms.key_ring_self_link
  role        = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member      = "serviceAccount:${each.value}"
}

## TODO: Add KMS crypto key resource when schema is pinched to match provider.

output "pii_sample_secret_name" {
  value = module.secret_manager.secret_name
}
