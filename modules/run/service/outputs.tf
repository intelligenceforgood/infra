output "name" {
  description = "Name of the Cloud Run service."
  value       = google_cloud_run_service.this.name
}

output "uri" {
  description = "Public URI of the latest traffic-targeted revision."
  value       = google_cloud_run_service.this.status[0].url
}
