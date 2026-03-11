# ---------------------------------------------------------------------------
# PII-Vault Stack — Outputs
# ---------------------------------------------------------------------------

output "vault_instance_name" {
  description = "Cloud SQL instance name for the vault database."
  value       = google_sql_database_instance.vault.name
}

output "vault_instance_connection_name" {
  description = "Cloud SQL connection name for the vault database."
  value       = google_sql_database_instance.vault.connection_name
}

output "vault_database_name" {
  description = "Database name."
  value       = google_sql_database.vault_db.name
}
