output "dataset_id" {
  description = "The ID of the BigQuery dataset."
  value       = google_bigquery_dataset.this.dataset_id
}

output "self_link" {
  description = "The URI of the BigQuery dataset."
  value       = google_bigquery_dataset.this.self_link
}

output "table_ids" {
  description = "Map of table IDs created in the dataset."
  value       = { for k, v in google_bigquery_table.tables : k => v.table_id }
}
