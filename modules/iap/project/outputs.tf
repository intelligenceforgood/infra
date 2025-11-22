output "brand_name" {
  description = "Fully qualified resource name for the project IAP brand."
  value       = local.effective_brand_name
}

output "project_settings_name" {
  description = "Name of the project-level IAP settings resource (if configured)."
  value       = try(google_iap_settings.project[0].name, null)
}
