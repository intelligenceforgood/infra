# Cloud SQL IAM users + project-level bindings — shared module eliminates
# dev/prod copy-paste.  See modules/database/users/main.tf header for
# state migration commands.
module "database_users" {
  source = "../../../modules/database/users"

  project_id    = var.project_id
  instance_name = module.database.instance_name

  iam_groups = {
    admin = {
      email = var.db_admin_group
      roles = ["roles/cloudsql.client", "roles/cloudsql.instanceUser", "roles/cloudsql.viewer"]
    }
    analyst = {
      email = var.db_analyst_group
      roles = ["roles/cloudsql.client", "roles/cloudsql.instanceUser", "roles/cloudsql.viewer"]
    }
  }

  service_accounts = {
    app = {
      email = module.iam_service_accounts.emails["app"]
      roles = ["roles/cloudsql.client", "roles/cloudsql.instanceUser"]
    }
    ingest = {
      email = module.iam_service_accounts.emails["ingest"]
      roles = ["roles/cloudsql.client", "roles/cloudsql.instanceUser"]
    }
    intake = {
      email = module.iam_service_accounts.emails["intake"]
      roles = ["roles/cloudsql.client", "roles/cloudsql.instanceUser"]
    }
    report = {
      email = module.iam_service_accounts.emails["report"]
      roles = ["roles/cloudsql.client", "roles/cloudsql.instanceUser"]
    }
  }
}
