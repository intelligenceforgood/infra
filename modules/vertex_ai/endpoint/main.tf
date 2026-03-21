terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

resource "google_vertex_ai_endpoint" "this" {
  name         = var.display_name
  display_name = var.display_name
  project      = var.project_id
  location     = var.region
  description  = var.description
  labels       = var.labels
}
