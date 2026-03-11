# ---------------------------------------------------------------------------
# Cloud SQL — PII Vault prod
#
# The instance i4g-vault-prod-db was created out-of-band. Import before
# the first apply:
#
#   terraform import google_sql_database_instance.vault \
#     projects/i4g-pii-vault-prod/instances/i4g-vault-prod-db
#   terraform import google_sql_database.vault_db \
#     projects/i4g-pii-vault-prod/instances/i4g-vault-prod-db/databases/vault_db
# ---------------------------------------------------------------------------

resource "google_sql_database_instance" "vault" {
  name             = "i4g-vault-prod-db"
  database_version = "POSTGRES_15"
  region           = var.region
  project          = var.project_id

  settings {
    tier = "db-custom-2-7680"

    disk_type       = "PD_SSD"
    disk_size       = 20
    disk_autoresize = true

    availability_type = "REGIONAL"

    ip_configuration {
      ipv4_enabled = true
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "02:00"
      point_in_time_recovery_enabled = true
    }

    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }
  }

  deletion_protection = true

  depends_on = [google_project_service.sqladmin]
}

resource "google_sql_database" "vault_db" {
  name     = "vault_db"
  instance = google_sql_database_instance.vault.name
  project  = var.project_id
}

# NOTE: Cloud SQL IAM roles (cloudsql.client, cloudsql.instanceUser) for app
# service accounts are managed in app/prod via the pii_vault_access module.
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
