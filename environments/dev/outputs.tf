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
