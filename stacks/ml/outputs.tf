output "service_account_email" {
  description = "Email of the ML platform service account."
  value       = google_service_account.sa_ml.email
}

output "data_bucket_name" {
  description = "Name of the ML data GCS bucket."
  value       = module.ml_storage.bucket_names["data"]
}

output "bigquery_dataset_id" {
  description = "BigQuery dataset ID."
  value       = module.ml_bigquery.dataset_id
}

output "bigquery_table_ids" {
  description = "Map of BigQuery table IDs."
  value       = module.ml_bigquery.table_ids
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository ID for ML containers."
  value       = google_artifact_registry_repository.ml_containers.repository_id
}

output "serving_dev_endpoint_id" {
  description = "Vertex AI serving-dev endpoint ID."
  value       = module.serving_dev.endpoint_id
}

output "serving_prod_endpoint_id" {
  description = "Vertex AI serving-prod endpoint ID."
  value       = module.serving_prod.endpoint_id
}

output "ml_serving_url" {
  description = "URL of the Cloud Run ML serving service."
  value       = module.ml_serving.uri
}

output "ml_serving_name" {
  description = "Name of the Cloud Run ML serving service."
  value       = module.ml_serving.name
}

output "ml_serving_prod_url" {
  description = "URL of the production Cloud Run ML serving service."
  value       = module.ml_serving_prod.uri
}

output "ml_serving_prod_name" {
  description = "Name of the production Cloud Run ML serving service."
  value       = module.ml_serving_prod.name
}
