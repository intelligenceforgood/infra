output "service_account_emails" {
  description = "Map of logical names to service account emails."
  value       = module.iam_service_accounts.emails
}
