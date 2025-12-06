resource "google_kms_key_ring" "this" {
  project  = var.project_id
  location = var.region
  name     = var.key_ring_name
}

output "key_ring_self_link" {
  value = google_kms_key_ring.this.self_link
}
