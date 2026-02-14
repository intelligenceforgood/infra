output "notification_channel_id" {
  description = "The ID of the email notification channel."
  value       = google_monitoring_notification_channel.email.id
}

output "pii_access_alert_policy_id" {
  description = "Alert policy ID for PII access."
  value       = google_monitoring_alert_policy.pii_access.id
}

output "ingestion_failure_alert_policy_id" {
  description = "Alert policy ID for ingestion failures."
  value       = google_monitoring_alert_policy.ingestion_failure.id
}

output "dossier_alert_policy_id" {
  description = "Alert policy ID for dossier generation."
  value       = google_monitoring_alert_policy.dossier_stuck.id
}
