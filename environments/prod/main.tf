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

resource "google_project_service" "artifact_registry" {
  project            = var.project_id
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "firestore" {
  project            = var.project_id
  service            = "firestore.googleapis.com"
  disable_on_destroy = false
}

resource "google_firestore_database" "default" {
  project         = var.project_id
  name            = "(default)"
  location_id     = var.firestore_location
  type            = "FIRESTORE_NATIVE"
  concurrency_mode = "OPTIMISTIC"

  depends_on = [google_project_service.firestore]
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
  source     = "../../modules/iam/service_accounts"
  project_id = var.project_id

  service_accounts = local.service_accounts
}

module "github_wif" {
  source              = "../../modules/iam/workload_identity_github"
  project_id          = var.project_id
  pool_id             = local.github_wif.pool_id
  provider_id         = local.github_wif.provider_id
  github_repository   = var.github_repository
  attribute_condition = "attribute.repository == \"${var.github_repository}\""
}

resource "google_service_account_iam_binding" "infra_wif" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${module.iam_service_accounts.emails["infra"]}"
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "principalSet://iam.googleapis.com/${module.github_wif.pool_name}/attribute.repository/${var.github_repository}"
  ]
}

module "iam_service_account_bindings" {
  source     = "../../modules/iam/service_account_bindings"
  project_id = var.project_id

  bindings = {
    fastapi = {
      member = "serviceAccount:${module.iam_service_accounts.emails["fastapi"]}"
      roles = [
        "roles/datastore.user",
        "roles/storage.objectViewer",
        "roles/artifactregistry.reader",
        "roles/secretmanager.secretAccessor",
        "roles/logging.logWriter",
        "roles/monitoring.metricWriter"
      ]
    }

    streamlit = {
      member = "serviceAccount:${module.iam_service_accounts.emails["streamlit"]}"
      roles = [
        "roles/datastore.viewer",
        "roles/storage.objectViewer",
        "roles/artifactregistry.reader",
        "roles/secretmanager.secretAccessor",
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
  }
}

module "vertex_search" {
  source = "../../modules/vertex_search"

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
  source           = "../../modules/storage/buckets"
  project_id       = var.project_id
  default_location = var.storage_bucket_default_location
  buckets          = var.storage_buckets
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
      runtime_service_account_email   = module.iam_service_accounts.emails[job.service_account_key]
      scheduler_service_account_email = module.iam_service_accounts.emails[
        coalesce(
          try(job.scheduler_service_account_key, null),
          job.service_account_key
        )
      ]
  location                        = coalesce(try(job.location, null), var.region)
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
  source     = "../../modules/run/service"
  project_id = var.project_id
  location   = var.region

  name            = "fastapi-gateway"
  service_account = module.iam_service_accounts.emails["fastapi"]
  image           = var.fastapi_image
  env_vars = merge(
    var.fastapi_env_vars,
    {
      I4G_STORAGE__EVIDENCE_BUCKET = lookup(module.storage_buckets.bucket_names, "evidence", "")
      I4G_STORAGE__REPORT_BUCKET   = lookup(module.storage_buckets.bucket_names, "reports", "")
    }
  )
  labels = {
    service = "fastapi"
    env     = "prod"
  }

  invoker_member = var.fastapi_invoker_member != "" ? var.fastapi_invoker_member : format("serviceAccount:%s", module.iam_service_accounts.emails["streamlit"])

  depends_on = [module.iam_service_account_bindings, google_project_service.gemini_cloud_assist]
}

module "run_streamlit" {
  source     = "../../modules/run/service"
  project_id = var.project_id
  location   = var.region

  name            = "streamlit-analyst-ui"
  service_account = module.iam_service_accounts.emails["streamlit"]
  image           = var.streamlit_image
  env_vars = merge(
    var.streamlit_env_vars,
    {
      I4G_API__BASE_URL = module.run_fastapi.uri
      I4G_API_URL       = module.run_fastapi.uri
    }
  )
  labels = {
    service = "streamlit"
    env     = "prod"
  }

  invoker_member = var.streamlit_invoker_member

  depends_on = [module.iam_service_account_bindings, module.run_fastapi, google_project_service.gemini_cloud_assist]
}

module "run_jobs" {
  for_each = local.run_job_configs

  source     = "../../modules/run/job"
  project_id = var.project_id
  location   = each.value.location

  name            = each.value.name
  service_account = each.value.runtime_service_account_email
  image           = each.value.image
  env_vars = merge(
    coalesce(try(each.value.env_vars, null), {}),
    {
      I4G_ENV                = "prod"
      I4G_STORAGE__EVIDENCE_BUCKET = lookup(module.storage_buckets.bucket_names, "evidence", "")
      I4G_STORAGE__REPORT_BUCKET   = lookup(module.storage_buckets.bucket_names, "reports", "")
    }
  )
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

  source     = "../../modules/scheduler/job"
  project_id = var.project_id
  region     = var.region

  name                      = coalesce(try(each.value.scheduler_name, null), "${each.value.name}-schedule")
  schedule                  = each.value.schedule
  time_zone                 = coalesce(try(each.value.time_zone, null), "UTC")
  description               = try(each.value.description, null)
  attempt_deadline_seconds  = coalesce(try(each.value.scheduler_attempt_deadline_seconds, null), 300)
  run_job_name              = module.run_jobs[each.key].name
  run_job_location          = module.run_jobs[each.key].location
  service_account_email     = each.value.scheduler_service_account_email
  audience                  = try(each.value.scheduler_audience, null)
  headers                   = coalesce(try(each.value.scheduler_headers, null), {})
  body                      = coalesce(try(each.value.scheduler_body, null), "{}")

  depends_on = [module.run_jobs]
}

resource "google_service_account_iam_member" "cloud_scheduler_token_creator" {
  for_each = { for email in local.scheduler_service_account_emails : email => email }

  service_account_id = "projects/${var.project_id}/serviceAccounts/${each.value}"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-cloudscheduler.iam.gserviceaccount.com"

  depends_on = [google_project_service.cloud_scheduler]
}
