output "ip_address" {
  description = "Global static IP address allocated for the load balancer."
  value       = google_compute_global_address.default.address
}

output "backend_services" {
  description = "Map of backend key to backend service name (used for per-service IAP bindings)."
  value       = { for k, v in google_compute_backend_service.default : k => v.name }
}

output "backend_service_ids" {
  description = "Map of backend key to numeric backend service ID (used for IAP JWT audience)."
  value       = { for k, v in google_compute_backend_service.default : k => v.generated_id }
}
