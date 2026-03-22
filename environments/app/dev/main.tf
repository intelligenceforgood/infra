# ---------------------------------------------------------------------------
# App / Dev - Thin Wrapper
#
# All infrastructure logic lives in stacks/app/. This file only calls the
# stack module with environment-specific values passed through from tfvars.
# ---------------------------------------------------------------------------

module "app" {
  source      = "../../../stacks/app"
  environment = "dev"

  providers = {
    google      = google
    google-beta = google-beta
  }

  # -- Core ---------------------------------------------------------------
  project_id = var.project_id
  region     = var.region

  # -- People -------------------------------------------------------------
  i4g_analyst_members = var.i4g_analyst_members
  i4g_admin_members   = var.i4g_admin_members

  # -- IAP -----------------------------------------------------------------
  iap_support_email          = var.iap_support_email
  iap_application_title      = var.iap_application_title
  iap_manage_brand           = var.iap_manage_brand
  iap_existing_brand_name    = var.iap_existing_brand_name
  iap_project_level_bindings = var.iap_project_level_bindings
  iap_enable_allowed_domains = var.iap_enable_allowed_domains
  iap_allowed_domains        = var.iap_allowed_domains
  iap_allow_http_options     = var.iap_allow_http_options
  iap_clients                = var.iap_clients

  # -- GitHub --------------------------------------------------------------
  github_repository = var.github_repository

  # -- Database ------------------------------------------------------------
  db_admin_group   = var.db_admin_group
  db_analyst_group = var.db_analyst_group
  database_config  = var.database_config

  # -- Core API ------------------------------------------------------------
  core_svc_image           = var.core_svc_image
  core_svc_env_vars        = var.core_svc_env_vars
  core_svc_secret_env_vars = var.core_svc_secret_env_vars
  core_svc_invoker_member  = var.core_svc_invoker_member
  core_svc_invoker_members = var.core_svc_invoker_members
  core_svc_custom_domain   = var.core_svc_custom_domain
  core_svc_events_url      = var.core_svc_events_url

  # -- SSI -----------------------------------------------------------------
  ssi_service_image           = var.ssi_service_image
  ssi_service_env_vars        = var.ssi_service_env_vars
  ssi_service_secret_env_vars = var.ssi_service_secret_env_vars
  ssi_service_enabled         = var.ssi_service_enabled

  # -- Console -------------------------------------------------------------
  console_image           = var.console_image
  console_env_vars        = var.console_env_vars
  console_secret_env_vars = var.console_secret_env_vars
  console_invoker_member  = var.console_invoker_member
  console_invoker_members = var.console_invoker_members
  ui_custom_domain        = var.ui_custom_domain

  # -- DNS -----------------------------------------------------------------
  dns_managed_zone         = var.dns_managed_zone
  dns_managed_zone_project = var.dns_managed_zone_project

  # -- Storage -------------------------------------------------------------
  storage_bucket_default_location = var.storage_bucket_default_location
  storage_buckets                 = var.storage_buckets

  # -- Jobs ----------------------------------------------------------------
  run_jobs = var.run_jobs

  # -- Vertex AI -----------------------------------------------------------
  vertex_ai_search = var.vertex_ai_search

  # -- ML Platform ---------------------------------------------------------
  ml_project_id            = var.ml_project_id
  ml_service_account_email = var.ml_service_account_email
}
