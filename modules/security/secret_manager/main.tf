resource "google_secret_manager_secret" "this" {
  for_each  = var.secrets
  project   = var.project_id
  secret_id = each.value.secret_id

  labels = each.value.labels

  replication {
    auto {}
  }
}

output "secret_ids" {
  description = "Map of logical key → Secret Manager secret ID."
  value = {
    for k, s in google_secret_manager_secret.this : k => s.secret_id
  }
}

output "secret_names" {
  description = "Map of logical key → fully-qualified secret resource name."
  value = {
    for k, s in google_secret_manager_secret.this : k => s.name
  }
}
