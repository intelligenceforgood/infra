# ---------------------------------------------------------------------------
# App Environment — Pass-through Outputs
# ---------------------------------------------------------------------------

output "service_account_emails" {
  description = "Map of logical names to service account emails."
  value       = module.app.service_account_emails
}

output "github_workload_identity_pool" {
  description = "Fully qualified name of the GitHub workload identity pool."
  value       = module.app.github_workload_identity_pool
}

output "core_svc_service" {
  description = "Metadata for the Core API Cloud Run service."
  value       = module.app.core_svc_service
}

output "vertex_search" {
  description = "Discovery resources backing Vertex AI Search retrieval."
  value       = module.app.vertex_search
}

output "storage_buckets" {
  description = "Map of storage buckets created for the environment."
  value       = module.app.storage_buckets
}

output "run_jobs" {
  description = "Cloud Run jobs configured for the environment."
  value       = module.app.run_jobs
}

output "ssi_service" {
  description = "Metadata for the SSI Cloud Run Service (if enabled)."
  value       = module.app.ssi_service
}

output "serverless_egress_ip" {
  description = "Static egress IP address used by serverless workloads."
  value       = module.app.serverless_egress_ip
}

output "iap" {
  description = "IAP brand metadata."
  value       = module.app.iap
}

output "global_lb_ip" {
  description = "Global IP address for the Load Balancer."
  value       = module.app.global_lb_ip
}
