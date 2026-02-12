output "instance_name" {
  description = "Name of the Cloud SQL instance."
  value       = google_sql_database_instance.this.name
}

output "connection_name" {
  description = "Connection name in the format project:region:instance."
  value       = google_sql_database_instance.this.connection_name
}

output "database_name" {
  description = "Name of the database created on the instance."
  value       = google_sql_database.this.name
}
