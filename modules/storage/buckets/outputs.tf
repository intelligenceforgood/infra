output "bucket_names" {
  description = "Map of logical bucket keys to final bucket names."
  value       = { for key, bucket in google_storage_bucket.buckets : key => bucket.name }
}
