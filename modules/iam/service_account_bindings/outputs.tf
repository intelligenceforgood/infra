output "member_resources" {
  description = "Map of IAM member resource identifiers (for dependencies)."
  value       = google_project_iam_member.this
}
