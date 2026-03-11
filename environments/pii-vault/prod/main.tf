# ---------------------------------------------------------------------------
# PII-Vault / Prod - Thin Wrapper
#
# All infrastructure logic lives in stacks/pii-vault/. This file only calls
# the stack module with environment-specific values passed through from tfvars.
# ---------------------------------------------------------------------------

module "pii_vault" {
  source      = "../../../stacks/pii-vault"
  environment = "prod"

  project_id = var.project_id
  region     = var.region

  # -- IAM groups & app SAs ------------------------------------------------
  iam_db_groups        = var.iam_db_groups
  app_service_accounts = var.app_service_accounts

  # -- Database (hardcoded values from the original inline config) ----------
  database_instance_name       = "i4g-vault-prod-db"
  database_tier                = "db-custom-2-7680"
  database_disk_size           = 20
  database_availability_type   = "REGIONAL"
  database_backup_enabled      = true
  database_backup_start_time   = "02:00"
  database_pitr_enabled        = true
  database_deletion_protection = true

  # -- Storage -------------------------------------------------------------
  bucket_force_destroy = false
  bucket_lifecycle_age = 365

  # -- Vault Service -------------------------------------------------------
  deploy_vault_service = false
}
