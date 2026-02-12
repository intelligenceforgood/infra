# modules/database/cloudsql
#
# Creates a Cloud SQL PostgreSQL instance and a database.
# Shared by app/dev–prod (and vault environments when ready).
#
# State migration (from inline resources):
#   terraform state mv google_sql_database_instance.default module.database.google_sql_database_instance.this
#   terraform state mv google_sql_database.i4g_db            module.database.google_sql_database.this

terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

resource "google_sql_database_instance" "this" {
  name             = var.config.instance_name
  database_version = var.database_version
  region           = var.region
  project          = var.project_id

  settings {
    tier            = var.config.tier
    disk_type       = "PD_SSD"
    disk_size       = var.config.disk_size
    disk_autoresize = true

    availability_type = var.config.availability_type

    ip_configuration {
      ipv4_enabled = true
    }

    backup_configuration {
      enabled    = var.config.backup_enabled
      start_time = var.config.backup_enabled ? var.config.backup_start_time : null
    }

    dynamic "database_flags" {
      for_each = var.enable_iam_auth ? [1] : []
      content {
        name  = "cloudsql.iam_authentication"
        value = "on"
      }
    }
  }

  deletion_protection = var.config.deletion_protection
}

resource "google_sql_database" "this" {
  name     = var.database_name
  instance = google_sql_database_instance.this.name
  project  = var.project_id
}
