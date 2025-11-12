output "name" {
  description = "Name of the Cloud Scheduler job."
  value       = google_cloud_scheduler_job.this.name
}
