resource "google_sql_database_instance" "vault" {
  name             = "i4g-vault-dev-db"
  database_version = "POSTGRES_15"
  region           = var.region
  project          = var.project_id

  settings {
    # Minimal tier for dev/vault
    tier = "db-f1-micro"

    disk_type       = "PD_SSD"
    disk_size       = 10
    disk_autoresize = true

    availability_type = "ZONAL"

    ip_configuration {
      ipv4_enabled = true
      # In a real setup, we'd use private_network here.
      # For dev prototype, public IP with IAM auth is acceptable if restricted.
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

  depends_on = [google_project_service.sqladmin]
}

resource "google_sql_database" "vault_db" {
  name     = "vault_db"
  instance = google_sql_database_instance.vault.name
  project  = var.project_id
}

# NOTE: Cloud SQL IAM roles (cloudsql.client, cloudsql.instanceUser) for app
# service accounts are managed in app/dev via the pii_vault_access module.
# Only database-local resources (instance, DB, users, groups) remain here.

# Create IAM groups in the database
resource "google_sql_user" "iam_groups" {
  for_each = toset(var.iam_db_groups)
  name     = each.value
  instance = google_sql_database_instance.vault.name
  project  = var.project_id
  type     = "CLOUD_IAM_GROUP"
}

# Grant groups access to connect (Cloud SQL Client)
resource "google_project_iam_member" "iam_group_sql_client" {
  for_each = toset(var.iam_db_groups)
  project  = var.project_id
  role     = "roles/cloudsql.client"
  member   = format("group:%s", each.value)
}

# Grant groups access to login (Cloud SQL Instance User)
resource "google_project_iam_member" "iam_group_sql_instance_user" {
  for_each = toset(var.iam_db_groups)
  project  = var.project_id
  role     = "roles/cloudsql.instanceUser"
  member   = format("group:%s", each.value)
}
