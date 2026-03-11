# ---------------------------------------------------------------------------
# App Stack — Database
# ---------------------------------------------------------------------------

module "database" {
  source = "../../modules/database/cloudsql"

  project_id    = var.project_id
  region        = var.region
  config        = var.database_config
  database_name = "i4g_db"
}
