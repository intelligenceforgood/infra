output "data_store_name" {
  description = "Full resource name of the Discovery data store."
  value       = google_discovery_engine_data_store.this.name
}

output "data_store_id" {
  description = "Short ID of the data store."
  value       = google_discovery_engine_data_store.this.data_store_id
}

