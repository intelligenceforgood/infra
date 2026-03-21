terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

resource "google_bigquery_dataset" "this" {
  project       = var.project_id
  dataset_id    = var.dataset_id
  location      = var.location
  description   = var.description
  labels        = var.labels
  friendly_name = var.friendly_name

  default_table_expiration_ms = var.default_table_expiration_ms

  dynamic "access" {
    for_each = var.access
    content {
      role           = access.value.role
      user_by_email  = try(access.value.user_by_email, null)
      group_by_email = try(access.value.group_by_email, null)
      special_group  = try(access.value.special_group, null)
    }
  }
}

resource "google_bigquery_table" "tables" {
  for_each = var.tables

  project    = var.project_id
  dataset_id = google_bigquery_dataset.this.dataset_id
  table_id   = each.key
  schema     = each.value.schema
  labels     = try(each.value.labels, var.labels)

  deletion_protection = try(each.value.deletion_protection, true)

  dynamic "time_partitioning" {
    for_each = try(each.value.time_partitioning, null) != null ? [each.value.time_partitioning] : []
    content {
      type  = time_partitioning.value.type
      field = try(time_partitioning.value.field, null)
    }
  }

  clustering = try(each.value.clustering, null)
}
