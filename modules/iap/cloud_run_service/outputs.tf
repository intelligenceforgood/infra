output "client_id" {
  description = "OAuth client ID issued for the Cloud Run service."
  value       = var.manage_client ? module.oauth_client[0].client_id : null
}

output "secret_id" {
  description = "Secret Manager secret ID storing the OAuth client secret."
  value       = var.manage_client ? module.oauth_client[0].secret_id : null
}

output "secret_resource" {
  description = "Fully qualified Secret Manager resource path."
  value       = var.manage_client ? module.oauth_client[0].secret_resource : null
}

output "iap_binding_id" {
  description = "Identifier for the IAP IAM binding."
  value       = google_iap_web_cloud_run_service_iam_binding.access.id
}
