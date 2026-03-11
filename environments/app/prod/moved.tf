# ---------------------------------------------------------------------------
# State Migration — moved blocks
#
# Maps old root-level resource addresses into the stack module namespace.
# Terraform uses these to update state without destroy/create.
# Remove this file after a successful apply + state verification.
# ---------------------------------------------------------------------------

# ── Common resources ─────────────────────────────────────────────────────

moved {
  from = google_project_service.gemini_cloud_assist
  to   = module.app.google_project_service.gemini_cloud_assist
}

moved {
  from = google_project_service.vertex_ai_search
  to   = module.app.google_project_service.vertex_ai_search
}

moved {
  from = google_project_service.vertex_ai
  to   = module.app.google_project_service.vertex_ai
}

moved {
  from = google_project_service.cloud_scheduler
  to   = module.app.google_project_service.cloud_scheduler
}

moved {
  from = google_project_service.compute
  to   = module.app.google_project_service.compute
}

moved {
  from = google_project_service.vpc_access
  to   = module.app.google_project_service.vpc_access
}

moved {
  from = google_project_service.artifact_registry
  to   = module.app.google_project_service.artifact_registry
}

moved {
  from = google_project_service.secret_manager
  to   = module.app.google_project_service.secret_manager
}

moved {
  from = google_project_service.sheets
  to   = module.app.google_project_service.sheets
}

moved {
  from = google_project_service.iap
  to   = module.app.google_project_service.iap
}

moved {
  from = google_project_service_identity.iap
  to   = module.app.google_project_service_identity.iap
}

moved {
  from = data.google_project.current
  to   = module.app.data.google_project.current
}

moved {
  from = google_compute_address.serverless_egress
  to   = module.app.google_compute_address.serverless_egress
}

moved {
  from = google_compute_router.serverless
  to   = module.app.google_compute_router.serverless
}

moved {
  from = google_compute_router_nat.serverless
  to   = module.app.google_compute_router_nat.serverless
}

moved {
  from = google_vpc_access_connector.serverless
  to   = module.app.google_vpc_access_connector.serverless
}

moved {
  from = google_artifact_registry_repository.applications
  to   = module.app.google_artifact_registry_repository.applications
}

moved {
  from = google_artifact_registry_repository_iam_member.serverless_runtime
  to   = module.app.google_artifact_registry_repository_iam_member.serverless_runtime
}

moved {
  from = module.ssi_secrets
  to   = module.app.module.ssi_secrets
}

moved {
  from = module.iam_service_accounts
  to   = module.app.module.iam_service_accounts
}

moved {
  from = module.github_wif
  to   = module.app.module.github_wif
}

moved {
  from = module.iap_project
  to   = module.app.module.iap_project
}

moved {
  from = module.iam_service_account_bindings
  to   = module.app.module.iam_service_account_bindings
}

moved {
  from = module.vertex_search
  to   = module.app.module.vertex_search
}

moved {
  from = module.storage_buckets
  to   = module.app.module.storage_buckets
}

moved {
  from = module.run_core_svc
  to   = module.app.module.run_core_svc
}

moved {
  from = module.run_ssi_service
  to   = module.app.module.run_ssi_service
}

moved {
  from = module.run_jobs
  to   = module.app.module.run_jobs
}

moved {
  from = module.run_job_schedulers
  to   = module.app.module.run_job_schedulers
}

moved {
  from = module.database
  to   = module.app.module.database
}

moved {
  from = module.database_users
  to   = module.app.module.database_users
}

moved {
  from = module.pii_vault_access
  to   = module.app.module.pii_vault_access
}

moved {
  from = google_service_account_iam_binding.infra_wif
  to   = module.app.google_service_account_iam_binding.infra_wif
}

moved {
  from = google_project_iam_member.iap_analyst
  to   = module.app.google_project_iam_member.iap_analyst
}

moved {
  from = google_project_iam_member.project_admins
  to   = module.app.google_project_iam_member.project_admins
}

moved {
  from = google_project_iam_member.iap_report_service_account
  to   = module.app.google_project_iam_member.iap_report_service_account
}

moved {
  from = google_project_iam_member.ingest_discoveryengine_editor
  to   = module.app.google_project_iam_member.ingest_discoveryengine_editor
}

moved {
  from = google_service_account_iam_member.report_token_creators
  to   = module.app.google_service_account_iam_member.report_token_creators
}

moved {
  from = google_service_account_iam_member.app_token_creators
  to   = module.app.google_service_account_iam_member.app_token_creators
}

moved {
  from = google_service_account_iam_member.app_self_token_creator
  to   = module.app.google_service_account_iam_member.app_self_token_creator
}

moved {
  from = google_service_account_iam_member.cloud_scheduler_token_creator
  to   = module.app.google_service_account_iam_member.cloud_scheduler_token_creator
}

moved {
  from = google_cloud_run_v2_job_iam_member.scheduled_invokers
  to   = module.app.google_cloud_run_v2_job_iam_member.scheduled_invokers
}

moved {
  from = google_project_organization_policy.allow_public_invokers
  to   = module.app.google_project_organization_policy.allow_public_invokers
}

# ── Prod-specific (already had count / prod-only modules) ─────────────────

moved {
  from = module.monitoring
  to   = module.app.module.monitoring
}

moved {
  from = module.run_console
  to   = module.app.module.run_console
}

moved {
  from = module.global_lb
  to   = module.app.module.global_lb
}

moved {
  from = google_iap_web_backend_service_iam_binding.console
  to   = module.app.google_iap_web_backend_service_iam_binding.console
}

moved {
  from = google_iap_web_backend_service_iam_binding.api
  to   = module.app.google_iap_web_backend_service_iam_binding.api
}

