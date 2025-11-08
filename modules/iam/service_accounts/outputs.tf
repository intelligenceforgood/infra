output "emails" {
  description = "Map of logical keys to full service account emails."
  value       = { for key, sa in google_service_account.this : key => sa.email }
}

output "service_account_ids" {
  description = "Map of logical keys to service account unique IDs."
  value       = { for key, sa in google_service_account.this : key => sa.unique_id }
}
