# ---------------------------------------------------------------------------
# App Stack — Outputs
# ---------------------------------------------------------------------------

output "service_account_emails" {
  description = "Map of logical names to service account emails."
  value       = module.iam_service_accounts.emails
}

output "github_workload_identity_pool" {
  description = "Fully qualified name of the GitHub workload identity pool."
  value       = module.github_wif.pool_name
}

output "core_svc_service" {
  description = "Metadata for the Core API Cloud Run service."
  value = {
    name = module.run_core_svc.name
    url  = module.run_core_svc.uri
  }
}

output "vertex_search" {
  description = "Discovery resources backing Vertex AI Search retrieval."
  value = {
    data_store_name = module.vertex_search.data_store_name
  }
}

output "storage_buckets" {
  description = "Map of storage buckets created for the environment."
  value       = module.storage_buckets.bucket_names
}

output "run_jobs" {
  description = "Cloud Run jobs configured for the environment."
  value = {
    for key, job in module.run_jobs :
    key => {
      name     = job.name
      location = job.location
    }
  }
}

output "ssi_service" {
  description = "Metadata for the SSI Cloud Run Service (if enabled)."
  value = var.ssi_service_enabled ? {
    name = module.run_ssi_service[0].name
    url  = module.run_ssi_service[0].uri
  } : null
}

output "serverless_egress_ip" {
  description = "Static egress IP address used by serverless workloads."
  value       = google_compute_address.serverless_egress.address
}

output "iap" {
  description = "IAP brand metadata."
  value = {
    brand_name = module.iap_project.brand_name
  }
}

output "global_lb_ip" {
  description = "Global IP address for the Load Balancer."
  value       = length(module.global_lb) > 0 ? module.global_lb[0].ip_address : null
}
