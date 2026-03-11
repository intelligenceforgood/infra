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

# ── Dev-specific: simple moves ────────────────────────────────────────────

moved {
  from = google_project_service.run
  to   = module.pii_vault.google_project_service.run
}

# ── Dev-specific: count index changes (no-count → count[0]) ───────────────

moved {
  from = google_service_account.vault_sa
  to   = module.pii_vault.google_service_account.vault_sa[0]
}

moved {
  from = google_project_iam_member.vault_sql_client
  to   = module.pii_vault.google_project_iam_member.vault_sql_client[0]
}

moved {
  from = google_secret_manager_secret_iam_member.vault_secret_access
  to   = module.pii_vault.google_secret_manager_secret_iam_member.vault_secret_access[0]
}

moved {
  from = google_secret_manager_secret_iam_member.vault_pepper_access
  to   = module.pii_vault.google_secret_manager_secret_iam_member.vault_pepper_access[0]
}

moved {
  from = google_kms_crypto_key_iam_member.vault_kms_access
  to   = module.pii_vault.google_kms_crypto_key_iam_member.vault_kms_access[0]
}

moved {
  from = module.vault_service
  to   = module.pii_vault.module.vault_service[0]
}

moved {
  from = google_sql_user.vault_sa_user
  to   = module.pii_vault.google_sql_user.vault_sa_user[0]
}

moved {
  from = google_project_iam_member.vault_sa_sql_instance_user
  to   = module.pii_vault.google_project_iam_member.vault_sa_sql_instance_user[0]
}

