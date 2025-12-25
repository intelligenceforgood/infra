resource "google_sql_database_instance" "default" {
  name             = "i4g-prod-db"
  database_version = "POSTGRES_15"
  region           = var.region
  project          = var.project_id

  settings {
    tier = "db-custom-2-7680"

    disk_type       = "PD_SSD"
    disk_size       = 50
    disk_autoresize = true

    availability_type = "REGIONAL"

    ip_configuration {
      ipv4_enabled = true
    }

    backup_configuration {
      enabled    = true
      start_time = "02:00"
    }
  }

  deletion_protection = true
}

resource "google_sql_database" "i4g_db" {
  name     = "i4g_db"
  instance = google_sql_database_instance.default.name
  project  = var.project_id
}
