# ---------------------------------------------------------------------------
# PII-Vault / Dev - Thin Wrapper
#
# All infrastructure logic lives in stacks/pii-vault/. This file only calls
# the stack module with environment-specific values passed through from tfvars.
# ---------------------------------------------------------------------------

module "pii_vault" {
  source      = "../../../stacks/pii-vault"
  environment = "dev"

  project_id = var.project_id
  region     = var.region

  # -- IAM groups & app SAs ------------------------------------------------
  iam_db_groups        = var.iam_db_groups
  app_service_accounts = var.app_service_accounts

  # -- Database (hardcoded values from the original inline config) ----------
  database_instance_name       = "i4g-vault-dev-db"
  database_tier                = "db-f1-micro"
  database_disk_size           = 10
  database_availability_type   = "ZONAL"
  database_backup_enabled      = false
  database_deletion_protection = false

  # -- Storage -------------------------------------------------------------
  bucket_force_destroy = true
  bucket_lifecycle_age = 365

  # -- Vault Service -------------------------------------------------------
  deploy_vault_service = true
  vault_service_image  = "us-central1-docker.pkg.dev/i4g-dev/applications/core-svc:dev"
}
