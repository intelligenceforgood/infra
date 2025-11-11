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

module "run_fastapi" {
  source     = "../../modules/run/service"
  project_id = var.project_id
  location   = var.region

  name            = "fastapi-gateway"
  service_account = module.iam_service_accounts.emails["fastapi"]
  image           = var.fastapi_image
  env_vars        = var.fastapi_env_vars
  labels = {
    service = "fastapi"
    env     = "dev"
  }

  invoker_member = var.fastapi_invoker_member

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
    env     = "dev"
  }

  invoker_member = var.streamlit_invoker_member

  depends_on = [module.iam_service_account_bindings, module.run_fastapi, google_project_service.gemini_cloud_assist]
}
