output "pool_name" {
  description = "Fully qualified name of the workload identity pool."
  value       = google_iam_workload_identity_pool.pool.name
}

output "provider_name" {
  description = "Fully qualified name of the workload identity pool provider."
  value       = google_iam_workload_identity_pool_provider.github.name
}
