resource "google_project_service" "gemini_cloud_assist" {
  project            = var.project_id
  service            = "cloudaicompanion.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "vertex_ai_search" {
  project            = var.project_id
  service            = "discoveryengine.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_scheduler" {
  project            = var.project_id
  service            = "cloudscheduler.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "compute" {
  project            = var.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "vpc_access" {
  project            = var.project_id
  service            = "vpcaccess.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifact_registry" {
  project            = var.project_id
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secret_manager" {
  project            = var.project_id
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "firestore" {
  project            = var.project_id
  service            = "firestore.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iap" {
  project            = var.project_id
  service            = "iap.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service_identity" "iap" {
  provider = google-beta

  project = var.project_id
  service = "iap.googleapis.com"

  depends_on = [google_project_service.iap]
}

resource "google_firestore_database" "default" {
  project          = var.project_id
  name             = "(default)"
  location_id      = var.firestore_location
  type             = "FIRESTORE_NATIVE"
  concurrency_mode = "OPTIMISTIC"

  depends_on = [google_project_service.firestore]
}

resource "google_secret_manager_secret" "azure_sql_connection_string" {
  project   = var.project_id
  secret_id = "azure-sql-connection-string"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  depends_on = [google_project_service.secret_manager]
}

resource "google_secret_manager_secret" "azure_storage_connection_string" {
  project   = var.project_id
  secret_id = "azure-storage-connection-string"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  depends_on = [google_project_service.secret_manager]
}

resource "google_secret_manager_secret" "azure_search_admin_key" {
  project   = var.project_id
  secret_id = "azure-search-admin-key"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  depends_on = [google_project_service.secret_manager]
}

data "google_project" "current" {
  project_id = var.project_id
}

resource "google_artifact_registry_repository" "applications" {
  project       = var.project_id
  location      = var.region
  repository_id = "applications"
  description   = "Container images for application workloads"
  format        = "DOCKER"
  labels = {
    env        = "prod"
    managed_by = "terraform"
  }

  depends_on = [google_project_service.artifact_registry]
}

resource "google_artifact_registry_repository_iam_member" "serverless_runtime" {
  project    = var.project_id
  location   = google_artifact_registry_repository.applications.location
  repository = google_artifact_registry_repository.applications.repository_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:service-${data.google_project.current.number}@serverless-robot-prod.iam.gserviceaccount.com"

  depends_on = [google_artifact_registry_repository.applications]
}

module "iam_service_accounts" {
  source     = "../../../modules/iam/service_accounts"
  project_id = var.project_id

  service_accounts = local.service_accounts
}

module "github_wif" {
  source              = "../../../modules/iam/workload_identity_github"
  project_id          = var.project_id
  pool_id             = local.github_wif.pool_id
  provider_id         = local.github_wif.provider_id
  github_repository   = var.github_repository
  attribute_condition = "attribute.repository == \"${var.github_repository}\""
}

module "iap_project" {
  source = "../../../modules/iap/project"

  project_id             = var.project_id
  support_email          = var.iap_support_email
  application_title      = var.iap_application_title
  manage_brand           = var.iap_manage_brand
  existing_brand_name    = var.iap_existing_brand_name
  enable_allowed_domains = var.iap_enable_allowed_domains
  allowed_domains        = var.iap_allowed_domains
  allow_http_options     = var.iap_allow_http_options

  depends_on = [google_project_service.iap]
}

resource "google_service_account_iam_binding" "infra_wif" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${module.iam_service_accounts.emails["infra"]}"
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "principalSet://iam.googleapis.com/${module.github_wif.pool_name}/attribute.repository/${var.github_repository}"
  ]
}

resource "google_project_iam_member" "iap_analyst" {
  project = var.project_id
  role    = "roles/iap.httpsResourceAccessor"

  for_each = toset(var.i4g_analyst_members)

  member = each.value
}

resource "google_project_iam_member" "project_admins" {
  project = var.project_id
  role    = "roles/owner"

  for_each = toset(var.i4g_admin_members)

  member = each.value
}

resource "google_service_account_iam_member" "report_token_creators" {
  for_each = toset(var.i4g_admin_members)

  service_account_id = "projects/${var.project_id}/serviceAccounts/${module.iam_service_accounts.emails["report"]}"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = each.value
}

resource "google_service_account_iam_member" "app_token_creators" {
  for_each = toset(var.i4g_admin_members)

  service_account_id = "projects/${var.project_id}/serviceAccounts/${module.iam_service_accounts.emails["app"]}"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = each.value
}

resource "google_project_iam_member" "iap_report_service_account" {
  count   = var.iap_project_level_bindings ? 1 : 0
  project = var.project_id
  role    = "roles/iap.httpsResourceAccessor"
  member  = format("serviceAccount:%s", module.iam_service_accounts.emails["report"])
}


module "iam_service_account_bindings" {
  source     = "../../../modules/iam/service_account_bindings"
  project_id = var.project_id

  bindings = {
    app = {
      member = "serviceAccount:${module.iam_service_accounts.emails["app"]}"
      roles = [
        "roles/datastore.user",
        "roles/datastore.viewer",
        "roles/storage.objectViewer",
        "roles/artifactregistry.reader",
        "roles/secretmanager.secretAccessor",
        "roles/discoveryengine.viewer",
        "roles/logging.logWriter",
        "roles/monitoring.metricWriter"
      ]
    }

    ingest = {
      member = "serviceAccount:${module.iam_service_accounts.emails["ingest"]}"
      roles = [
        "roles/datastore.user",
        "roles/storage.objectAdmin",
        "roles/run.invoker",
        "roles/artifactregistry.reader",
        "roles/secretmanager.secretAccessor",
        "roles/pubsub.publisher",
        "roles/logging.logWriter",
        "roles/monitoring.metricWriter"
      ]
    }

    intake = {
      member = "serviceAccount:${module.iam_service_accounts.emails["intake"]}"
      roles = [
        "roles/datastore.user",
        "roles/storage.objectAdmin",
        "roles/artifactregistry.reader",
        "roles/secretmanager.secretAccessor",
        "roles/logging.logWriter",
        "roles/monitoring.metricWriter"
      ]
    }

    report = {
      member = "serviceAccount:${module.iam_service_accounts.emails["report"]}"
      roles = [
        "roles/datastore.user",
        "roles/storage.objectAdmin",
        "roles/artifactregistry.reader",
        "roles/secretmanager.secretAccessor",
        "roles/logging.logWriter",
        "roles/monitoring.metricWriter"
      ]
    }

    vault = {
      member = "serviceAccount:${module.iam_service_accounts.emails["vault"]}"
      roles = [
        "roles/datastore.user",
        "roles/cloudkms.cryptoKeyEncrypterDecrypter"
      ]
    }

    infra = {
      member = "serviceAccount:${module.iam_service_accounts.emails["infra"]}"
      roles = [
        "roles/artifactregistry.writer"
      ]
    }

    scheduler = {
      member = "serviceAccount:${module.iam_service_accounts.emails["scheduler"]}"
      roles = [
        "roles/run.developer"
      ]
    }
  }
}

resource "google_project_iam_member" "ingest_discoveryengine_editor" {
  project = var.project_id
  role    = "roles/discoveryengine.editor"
  member  = "serviceAccount:${module.iam_service_accounts.emails["ingest"]}"
}

module "vertex_search" {
  source = "../../../modules/vertex_search"

  providers = {
    google-beta = google-beta
  }

  project_id    = var.project_id
  location      = var.vertex_search_location
  data_store_id = var.vertex_search_data_store_id
  display_name  = var.vertex_search_display_name

  depends_on = [google_project_service.vertex_ai_search]
}

module "storage_buckets" {
  source           = "../../../modules/storage/buckets"
  project_id       = var.project_id
  default_location = var.storage_bucket_default_location
  buckets          = var.storage_buckets
}

locals {
  i4g_analyst_invokers = [
    for member in var.i4g_analyst_members : trimspace(member)
    if trimspace(member) != ""
  ]

  report_service_account_member = format("serviceAccount:%s", module.iam_service_accounts.emails["report"])

  fastapi_iap_access_members = distinct(concat(
    local.i4g_analyst_invokers,
    [local.report_service_account_member]
  ))

  fastapi_requested_invokers = [
    for member in concat(
      var.fastapi_invoker_member == "" ? [] : [var.fastapi_invoker_member],
      var.fastapi_invoker_members
    ) : trimspace(member)
    if trimspace(member) != ""
  ]

  streamlit_requested_invokers = [
    for member in concat(
      var.streamlit_invoker_member == "" ? [] : [var.streamlit_invoker_member],
      var.streamlit_invoker_members
    ) : trimspace(member)
    if trimspace(member) != ""
  ]

  console_requested_invokers = [
    for member in concat(
      var.console_invoker_member == "" ? [] : [var.console_invoker_member],
      var.console_invoker_members
    ) : trimspace(member)
    if trimspace(member) != ""
  ]

  iap_service_agent_member = format(
    "serviceAccount:service-%s@gcp-sa-iap.iam.gserviceaccount.com",
    data.google_project.current.number
  )

  default_runtime_invokers = [
    format("serviceAccount:%s", module.iam_service_accounts.emails["app"]),
    format("serviceAccount:%s", module.iam_service_accounts.emails["intake"]),
    local.iap_service_agent_member
  ]

  fastapi_invoker_members = distinct(concat(
    local.default_runtime_invokers,
    local.fastapi_requested_invokers
  ))

  streamlit_invoker_members = distinct(concat(
    local.default_runtime_invokers,
    local.streamlit_requested_invokers
  ))

  console_invoker_members = distinct(concat(
    local.default_runtime_invokers,
    local.console_requested_invokers
  ))
}

locals {
  enabled_run_jobs = {
    for job_key, job in var.run_jobs :
    job_key => job
    if coalesce(try(job.enabled, null), true)
  }

  run_job_configs = {
    for job_key, job in local.enabled_run_jobs :
    job_key => merge(job, {
      runtime_service_account_email = module.iam_service_accounts.emails[job.service_account_key]
      scheduler_service_account_email = module.iam_service_accounts.emails[
        coalesce(
          try(job.scheduler_service_account_key, null),
          job.service_account_key
        )
      ]
      location = coalesce(try(job.location, null), var.region)
    })
  }

  scheduled_run_jobs = {
    for job_key, job in local.run_job_configs :
    job_key => job
    if contains(keys(job), "schedule") && job.schedule != null && trimspace(job.schedule) != ""
  }

  scheduler_service_account_emails = toset([
    for job in local.scheduled_run_jobs : job.scheduler_service_account_email
  ])
}

module "run_fastapi" {
  source     = "../../../modules/run/service"
  project_id = var.project_id
  location   = var.region

  name            = "fastapi-gateway"
  service_account = module.iam_service_accounts.emails["app"]
  image           = var.fastapi_image
  env_vars = merge(
    var.fastapi_env_vars,
    {
      I4G_STORAGE__EVIDENCE_BUCKET    = lookup(module.storage_buckets.bucket_names, "evidence", "")
      I4G_STORAGE__REPORT_BUCKET      = lookup(module.storage_buckets.bucket_names, "reports", "")
    }
  )
  secret_env_vars = var.fastapi_secret_env_vars
  labels = {
    service = "fastapi"
    env     = "prod"
  }

  ingress = "all"

  invoker_member  = ""
  invoker_members = local.fastapi_invoker_members

  depends_on = [module.iam_service_account_bindings, google_project_service.gemini_cloud_assist, google_project_service_identity.iap]
}

module "iap_fastapi" {
  source = "../../../modules/iap/cloud_run_service"

  project_id                   = var.project_id
  region                       = var.region
  service_name                 = module.run_fastapi.name
  manage_client                = var.iap_manage_clients
  brand_name                   = module.iap_project.brand_name
  display_name                 = "FastAPI Gateway"
  access_members               = local.fastapi_iap_access_members
  secret_replication_locations = var.iap_secret_replication_locations
  secret_id                    = "iap-client-fastapi"

  depends_on = [module.run_fastapi]
}

module "run_streamlit" {
  source     = "../../../modules/run/service"
  project_id = var.project_id
  location   = var.region

  name            = "streamlit-analyst-ui"
  service_account = module.iam_service_accounts.emails["app"]
  image           = var.streamlit_image
  env_vars = merge(
    var.streamlit_env_vars,
    {
      I4G_API__BASE_URL = trimspace(var.fastapi_custom_domain) != "" ? format("https://%s", var.fastapi_custom_domain) : module.run_fastapi.uri
      I4G_API_URL       = trimspace(var.fastapi_custom_domain) != "" ? format("https://%s", var.fastapi_custom_domain) : module.run_fastapi.uri
    }
  )
  labels = {
    service = "streamlit"
    env     = "prod"
  }

  ingress = "all"

  invoker_member  = ""
  invoker_members = local.streamlit_invoker_members

  depends_on = [module.iam_service_account_bindings, module.run_fastapi, google_project_service.gemini_cloud_assist, google_project_service_identity.iap]
}

module "iap_streamlit" {
  source = "../../../modules/iap/cloud_run_service"

  project_id                   = var.project_id
  region                       = var.region
  service_name                 = module.run_streamlit.name
  manage_client                = var.iap_manage_clients
  brand_name                   = module.iap_project.brand_name
  display_name                 = "Streamlit Analyst UI"
  access_members               = local.i4g_analyst_invokers
  secret_replication_locations = var.iap_secret_replication_locations
  secret_id                    = "iap-client-streamlit"

  depends_on = [module.run_streamlit]
}

module "run_console" {
  source     = "../../../modules/run/service"
  project_id = var.project_id
  location   = var.region

  count = var.console_enabled ? 1 : 0

  name            = "i4g-console"
  service_account = module.iam_service_accounts.emails["app"]
  image           = var.console_image
  env_vars = merge(
    {
      NEXT_PUBLIC_API_BASE_URL = trimspace(var.fastapi_custom_domain) != "" ? format("https://%s", var.fastapi_custom_domain) : module.run_fastapi.uri
      I4G_API_URL              = trimspace(var.fastapi_custom_domain) != "" ? format("https://%s", var.fastapi_custom_domain) : module.run_fastapi.uri
      HOSTNAME                 = "0.0.0.0"
    },
    var.console_env_vars
  )
  labels = {
    service = "console"
    env     = "prod"
  }

  container_ports = [{ name = "http1", container_port = 8080 }]

  ingress = ""

  invoker_member  = ""
  invoker_members = local.console_invoker_members

  depends_on = [module.iam_service_account_bindings, module.run_fastapi, google_project_service_identity.iap]
}

module "domain_mapping_fastapi" {
  source           = "../../../modules/run/domain_mapping"
  project_id       = var.project_id
  region           = var.region
  service_name     = module.run_fastapi.name
  domain           = var.fastapi_custom_domain
  dns_managed_zone = var.dns_managed_zone
  dns_project      = var.dns_managed_zone_project

  count = trimspace(var.fastapi_custom_domain) == "" ? 0 : 1
}

module "domain_mapping_ui" {
  source           = "../../../modules/run/domain_mapping"
  project_id       = var.project_id
  region           = var.region
  service_name     = module.run_console[0].name
  domain           = var.ui_custom_domain
  dns_managed_zone = var.dns_managed_zone
  dns_project      = var.dns_managed_zone_project

  count = var.console_enabled && trimspace(var.ui_custom_domain) != "" ? 1 : 0
}

module "iap_console" {
  source = "../../../modules/iap/cloud_run_service"

  project_id                   = var.project_id
  region                       = var.region
  service_name                 = module.run_console[0].name
  manage_client                = var.iap_manage_clients
  brand_name                   = module.iap_project.brand_name
  display_name                 = "Analyst Console"
  access_members               = local.i4g_analyst_invokers
  secret_replication_locations = var.iap_secret_replication_locations
  secret_id                    = "iap-client-console"

  count = var.console_enabled ? 1 : 0

  depends_on = [module.run_console]
}

module "run_jobs" {
  for_each = local.run_job_configs

  source     = "../../../modules/run/job"
  project_id = var.project_id
  location   = each.value.location

  name            = each.value.name
  service_account = each.value.runtime_service_account_email
  image           = each.value.image
  env_vars = merge(
    coalesce(try(each.value.env_vars, null), {}),
    {
      I4G_ENV                         = "prod"
      I4G_STORAGE__EVIDENCE_BUCKET    = lookup(module.storage_buckets.bucket_names, "evidence", "")
      I4G_STORAGE__REPORT_BUCKET      = lookup(module.storage_buckets.bucket_names, "reports", "")
    }
  )
  secret_env_vars = coalesce(try(each.value.secret_env_vars, null), {})
  command         = coalesce(try(each.value.command, null), [])
  args            = coalesce(try(each.value.args, null), [])
  labels = merge({
    env = "prod"
    job = each.key
  }, coalesce(try(each.value.labels, null), {}))
  annotations                   = coalesce(try(each.value.annotations, null), {})
  parallelism                   = coalesce(try(each.value.parallelism, null), 1)
  task_count                    = coalesce(try(each.value.task_count, null), 1)
  max_retries                   = coalesce(try(each.value.max_retries, null), 3)
  timeout_seconds               = coalesce(try(each.value.timeout_seconds, null), 600)
  resource_limits               = coalesce(try(each.value.resource_limits, null), {})
  vpc_connector                 = try(each.value.vpc_connector, null)
  vpc_connector_egress_settings = coalesce(try(each.value.vpc_connector_egress_settings, null), "ALL_TRAFFIC")

  depends_on = [module.iam_service_account_bindings]
}

module "run_job_schedulers" {
  for_each = local.scheduled_run_jobs

  source     = "../../../modules/scheduler/job"
  project_id = var.project_id
  region     = var.region

  name                     = coalesce(try(each.value.scheduler_name, null), "${each.value.name}-schedule")
  schedule                 = each.value.schedule
  time_zone                = coalesce(try(each.value.time_zone, null), "UTC")
  description              = try(each.value.description, null)
  attempt_deadline_seconds = coalesce(try(each.value.scheduler_attempt_deadline_seconds, null), 300)
  run_job_name             = module.run_jobs[each.key].name
  run_job_location         = module.run_jobs[each.key].location
  service_account_email    = each.value.scheduler_service_account_email
  audience                 = each.value.scheduler_audience != null ? each.value.scheduler_audience : ""
  headers                  = coalesce(try(each.value.scheduler_headers, null), {})
  body                     = coalesce(try(each.value.scheduler_body, null), "{}")

  depends_on = [module.run_jobs]
}

resource "google_service_account_iam_member" "cloud_scheduler_token_creator" {
  for_each = { for email in local.scheduler_service_account_emails : email => email }

  service_account_id = "projects/${var.project_id}/serviceAccounts/${each.value}"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-cloudscheduler.iam.gserviceaccount.com"

  depends_on = [google_project_service.cloud_scheduler]
}

resource "google_cloud_run_v2_job_iam_member" "scheduled_invokers" {
  for_each = local.scheduled_run_jobs

  project  = var.project_id
  location = module.run_jobs[each.key].location
  name     = module.run_jobs[each.key].name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${each.value.scheduler_service_account_email}"

  depends_on = [module.run_jobs]
}
