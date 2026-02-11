output "secret_accessor_members" {
  description = "Map of SA email → IAM member resource ID for secret accessor grants."
  value       = { for k, v in google_project_iam_member.secret_accessor : k => v.id }
}

output "kms_user_members" {
  description = "Map of SA email → IAM member resource ID for KMS grants."
  value       = { for k, v in google_project_iam_member.kms_user : k => v.id }
}

output "sql_client_members" {
  description = "Map of SA email → IAM member resource ID for Cloud SQL Client grants."
  value       = { for k, v in google_project_iam_member.sql_client : k => v.id }
}

output "sql_instance_user_members" {
  description = "Map of SA email → IAM member resource ID for Cloud SQL Instance User grants."
  value       = { for k, v in google_project_iam_member.sql_instance_user : k => v.id }
}
