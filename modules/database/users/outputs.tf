output "group_user_names" {
  description = "Map of group keys to their Cloud SQL user names."
  value       = { for k, v in google_sql_user.iam_groups : k => v.name }
}

output "service_account_user_names" {
  description = "Map of service account keys to their Cloud SQL user names."
  value       = { for k, v in google_sql_user.service_accounts : k => v.name }
}
