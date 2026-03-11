# ---------------------------------------------------------------------------
# State Migration — moved blocks
#
# Maps old root-level resource addresses into the stack module namespace.
# Terraform uses these to update state without destroy/create.
# Remove this file after a successful apply + state verification.
# ---------------------------------------------------------------------------

# ── Common resources ─────────────────────────────────────────────────────

moved {
  from = google_project_service.storage
  to   = module.pii_vault.google_project_service.storage
}

moved {
  from = google_project_service.secretmanager
  to   = module.pii_vault.google_project_service.secretmanager
}

moved {
  from = google_project_service.cloudkms
  to   = module.pii_vault.google_project_service.cloudkms
}

moved {
  from = google_project_service.sqladmin
  to   = module.pii_vault.google_project_service.sqladmin
}

moved {
  from = google_storage_bucket.vault_objects
  to   = module.pii_vault.google_storage_bucket.vault_objects
}

moved {
  from = module.kms
  to   = module.pii_vault.module.kms
}

moved {
  from = google_kms_crypto_key.vault_key
  to   = module.pii_vault.google_kms_crypto_key.vault_key
}

moved {
  from = module.tokenization_secrets
  to   = module.pii_vault.module.tokenization_secrets
}

moved {
  from = google_sql_database_instance.vault
  to   = module.pii_vault.google_sql_database_instance.vault
}

moved {
  from = google_sql_database.vault_db
  to   = module.pii_vault.google_sql_database.vault_db
}

moved {
  from = google_sql_user.iam_groups
  to   = module.pii_vault.google_sql_user.iam_groups
}

moved {
  from = google_project_iam_member.iam_group_sql_client
  to   = module.pii_vault.google_project_iam_member.iam_group_sql_client
}

moved {
  from = google_project_iam_member.iam_group_sql_instance_user
  to   = module.pii_vault.google_project_iam_member.iam_group_sql_instance_user
}

moved {
  from = google_sql_user.app_sa_users
  to   = module.pii_vault.google_sql_user.app_sa_users
}

