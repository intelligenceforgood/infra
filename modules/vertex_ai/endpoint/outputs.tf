output "endpoint_id" {
  description = "The ID of the Vertex AI Endpoint."
  value       = google_vertex_ai_endpoint.this.id
}

output "name" {
  description = "The resource name of the Vertex AI Endpoint."
  value       = google_vertex_ai_endpoint.this.name
}

output "display_name" {
  description = "Display name of the Vertex AI Endpoint."
  value       = google_vertex_ai_endpoint.this.display_name
}
