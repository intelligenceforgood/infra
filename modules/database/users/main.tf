# modules/database/users
#
# Creates Cloud SQL IAM database users (groups and service accounts) and
# grants the associated project-level IAM roles needed for database access.
#
# State migration (from inline resources in app/dev):
#   terraform state mv 'google_sql_user.iam_admin_group'        'module.database_users.google_sql_user.iam_groups["admin"]'
#   terraform state mv 'google_sql_user.iam_analyst_group'      'module.database_users.google_sql_user.iam_groups["analyst"]'
#   terraform state mv 'google_sql_user.iam_app_sa'             'module.database_users.google_sql_user.service_accounts["app"]'
#   terraform state mv 'google_sql_user.iam_ingest_sa'          'module.database_users.google_sql_user.service_accounts["ingest"]'
#   terraform state mv 'google_sql_user.iam_intake_sa'          'module.database_users.google_sql_user.service_accounts["intake"]'
#   terraform state mv 'google_sql_user.iam_report_sa'          'module.database_users.google_sql_user.service_accounts["report"]'
#   (Repeat for google_project_iam_member resources — see docs/guides/state_migration.md)

terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# ---------------------------------------------------------------------------
# IAM Group database users
# ---------------------------------------------------------------------------

resource "google_sql_user" "iam_groups" {
  for_each = var.iam_groups

  name     = each.value.email
  instance = var.instance_name
  project  = var.project_id
  type     = "CLOUD_IAM_GROUP"
}

locals {
  group_role_bindings = flatten([
    for key, group in var.iam_groups : [
      for role in group.roles : {
        key    = "${key}--${replace(role, "roles/", "")}"
        member = "group:${group.email}"
        role   = startswith(role, "roles/") ? role : "roles/${role}"
      }
    ]
  ])
}

resource "google_project_iam_member" "group_bindings" {
  for_each = { for b in local.group_role_bindings : b.key => b }

  project = var.project_id
  role    = each.value.role
  member  = each.value.member
}

# ---------------------------------------------------------------------------
# Service Account database users
# ---------------------------------------------------------------------------

resource "google_sql_user" "service_accounts" {
  for_each = var.service_accounts

  name     = trimsuffix(each.value.email, ".gserviceaccount.com")
  instance = var.instance_name
  project  = var.project_id
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
}

locals {
  sa_role_bindings = flatten([
    for key, sa in var.service_accounts : [
      for role in sa.roles : {
        key    = "${key}--${replace(role, "roles/", "")}"
        member = "serviceAccount:${sa.email}"
        role   = startswith(role, "roles/") ? role : "roles/${role}"
      }
    ]
  ])
}

resource "google_project_iam_member" "sa_bindings" {
  for_each = { for b in local.sa_role_bindings : b.key => b }

  project = var.project_id
  role    = each.value.role
  member  = each.value.member
}
