output "name" {
  description = "Name of the Cloud Run job."
  value       = google_cloud_run_v2_job.this.name
}

output "location" {
  description = "Region where the Cloud Run job is deployed."
  value       = google_cloud_run_v2_job.this.location
}

output "id" {
  description = "Fully qualified identifier of the Cloud Run job."
  value       = google_cloud_run_v2_job.this.id
}
