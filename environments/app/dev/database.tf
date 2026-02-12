# Cloud SQL instance + database — shared module eliminates dev/prod copy-paste.
#
# State migration:
#   terraform state mv google_sql_database_instance.default module.database.google_sql_database_instance.this
#   terraform state mv google_sql_database.i4g_db            module.database.google_sql_database.this
module "database" {
  source = "../../../modules/database/cloudsql"

  project_id    = var.project_id
  region        = var.region
  config        = var.database_config
  database_name = "i4g_db"
}
