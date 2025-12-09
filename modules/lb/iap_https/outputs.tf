output "ip_address" {
  value = google_compute_global_address.default.address
}

output "backend_services" {
  value = { for k, v in google_compute_backend_service.default : k => v.name }
}
