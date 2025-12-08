output "service_account_emails" {
  description = "Map of logical names to service account emails."
  value       = module.iam_service_accounts.emails
}

output "github_workload_identity_pool" {
  description = "Fully qualified name of the GitHub workload identity pool."
  value       = module.github_wif.pool_name
}

output "fastapi_service" {
  description = "Metadata for the FastAPI Cloud Run service."
  value = {
    name = module.run_fastapi.name
    url  = module.run_fastapi.uri
  }
}

output "streamlit_service" {
  description = "Metadata for the Streamlit Cloud Run service."
  value = {
    name = module.run_streamlit.name
    url  = module.run_streamlit.uri
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
  value       = module.global_lb.ip_address
}
