
resource "google_sql_user" "iam_ingest_sa" {
  name     = trimsuffix(module.iam_service_accounts.emails["ingest"], ".gserviceaccount.com")
  instance = google_sql_database_instance.default.name
  project  = var.project_id
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
}

resource "google_sql_user" "iam_admin_group" {
  name     = var.db_admin_group
  instance = google_sql_database_instance.default.name
  project  = var.project_id
  type     = "CLOUD_IAM_GROUP"
}

resource "google_sql_user" "iam_analyst_group" {
  name     = var.db_analyst_group
  instance = google_sql_database_instance.default.name
  project  = var.project_id
  type     = "CLOUD_IAM_GROUP"
}

resource "google_sql_user" "iam_app_sa" {
  name     = trimsuffix(module.iam_service_accounts.emails["app"], ".gserviceaccount.com")
  instance = google_sql_database_instance.default.name
  project  = var.project_id
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
}

resource "google_project_iam_member" "db_admin_connect" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "group:${var.db_admin_group}"
}

resource "google_project_iam_member" "db_admin_login" {
  project = var.project_id
  role    = "roles/cloudsql.instanceUser"
  member  = "group:${var.db_admin_group}"
}

resource "google_project_iam_member" "db_analyst_connect" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "group:${var.db_analyst_group}"
}

resource "google_project_iam_member" "db_analyst_login" {
  project = var.project_id
  role    = "roles/cloudsql.instanceUser"
  member  = "group:${var.db_analyst_group}"
}

resource "google_project_iam_member" "db_admin_viewer" {
  project = var.project_id
  role    = "roles/cloudsql.viewer"
  member  = "group:${var.db_admin_group}"
}

resource "google_project_iam_member" "db_analyst_viewer" {
  project = var.project_id
  role    = "roles/cloudsql.viewer"
  member  = "group:${var.db_analyst_group}"
}
