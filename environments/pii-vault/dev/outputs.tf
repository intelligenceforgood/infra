# ---------------------------------------------------------------------------
# PII-Vault Environment — Pass-through Outputs
# ---------------------------------------------------------------------------

output "vault_instance_name" {
  description = "Cloud SQL instance name for the vault database."
  value       = module.pii_vault.vault_instance_name
}

output "vault_instance_connection_name" {
  description = "Cloud SQL connection name for the vault database."
  value       = module.pii_vault.vault_instance_connection_name
}

output "vault_database_name" {
  description = "Database name."
  value       = module.pii_vault.vault_database_name
}
