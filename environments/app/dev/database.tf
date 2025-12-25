resource "google_sql_database_instance" "default" {
  name             = "i4g-dev-db"
  database_version = "POSTGRES_15"
  region           = var.region
  project          = var.project_id

  settings {
    tier = "db-custom-1-3840"

    disk_type       = "PD_SSD"
    disk_size       = 10
    disk_autoresize = true

    availability_type = "ZONAL"

    ip_configuration {
      ipv4_enabled = true
    }

    backup_configuration {
      enabled = false
    }

    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }
  }

  deletion_protection = false
}

resource "google_sql_database" "i4g_db" {
  name     = "i4g_db"
  instance = google_sql_database_instance.default.name
  project  = var.project_id
}
