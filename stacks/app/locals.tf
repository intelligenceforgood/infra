# ---------------------------------------------------------------------------
# App Stack — Locals
# ---------------------------------------------------------------------------

locals {
  service_accounts = {
    app = {
      account_id   = "sa-app"
      display_name = "Application Runtime"
      description  = "Runs core-svc and console services"
    }
    ingest = {
      account_id   = "sa-ingest"
      display_name = "Ingestion Jobs"
      description  = "Executes scheduled ingestion Cloud Run jobs"
    }
    intake = {
      account_id   = "sa-intake"
      display_name = "Intake Processor"
      description  = "Processes intake submissions via Cloud Run jobs"
    }
    scheduler = {
      account_id   = "sa-scheduler"
      display_name = "Scheduler Job Runner"
      description  = "Triggers Cloud Run jobs from Cloud Scheduler"
    }
    report = {
      account_id   = "sa-report"
      display_name = "Report Generator"
      description  = "Produces case reports via Cloud Run jobs"
    }
    vault = {
      account_id   = "sa-vault"
      display_name = "PII Vault Service"
      description  = "Handles tokenization and KMS operations"
    }
    infra = {
      account_id   = "sa-infra"
      display_name = "Terraform Automation"
      description  = "Applies infrastructure as code changes"
    }
    ssi = {
      account_id   = "sa-ssi"
      display_name = "Scam Site Investigator"
      description  = "Runs SSI investigations"
    }
  }

  github_wif = {
    pool_id     = "github-actions"
    provider_id = "core"
  }
}

locals {
  deploy_console    = trimspace(var.console_image) != ""
  deploy_lb         = trimspace(var.core_svc_custom_domain) != ""
  deploy_console_lb = local.deploy_console && trimspace(var.ui_custom_domain) != ""

  i4g_analyst_invokers = [
    for member in var.i4g_analyst_members : trimspace(member)
    if trimspace(member) != ""
  ]

  report_service_account_member = format("serviceAccount:%s", module.iam_service_accounts.emails["report"])
  app_service_account_member    = format("serviceAccount:%s", module.iam_service_accounts.emails["app"])

  # sa-ssi removed from IAP access — SSI Service uses direct internal API
  # calls or SA auth to the task-update endpoint.
  core_svc_iap_access_members = distinct(concat(
    local.i4g_analyst_invokers,
    [local.report_service_account_member],
    [local.app_service_account_member],
  ))

  core_svc_requested_invokers = [
    for member in concat(
      var.core_svc_invoker_member == "" ? [] : [var.core_svc_invoker_member],
      var.core_svc_invoker_members
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

  # SSI needs to call core directly (bypassing IAP) for service-to-service auth
  ssi_service_account_member = format("serviceAccount:%s", module.iam_service_accounts.emails["ssi"])

  core_svc_invoker_members = distinct(concat(
    local.default_runtime_invokers,
    local.core_svc_requested_invokers,
    # Phase 3B: ssi-svc pushes investigation events directly to core-svc
    # (bypassing IAP), so sa-ssi needs roles/run.invoker on core-svc.
    [local.ssi_service_account_member],
  ))

  console_invoker_members = distinct(concat(
    local.default_runtime_invokers,
    local.console_requested_invokers
  ))
}

locals {
  run_job_vpc_connector_overrides = {
    ecx_poller = google_vpc_access_connector.serverless.id
  }

  enabled_run_jobs = {
    for job_key, job in var.run_jobs :
    job_key => job
    if coalesce(try(job.enabled, null), true)
  }

  run_job_dynamic_env_vars = {
    ingest = {
      I4G_VECTOR__VERTEX_AI_PROJECT    = var.vertex_ai_search.project_id
      I4G_VECTOR__VERTEX_AI_LOCATION   = var.vertex_ai_search.location
      I4G_VECTOR__VERTEX_AI_DATA_STORE = var.vertex_ai_search.data_store_id
    }
    sweeper = {
      I4G_VECTOR__VERTEX_AI_PROJECT  = var.vertex_ai_search.project_id
      I4G_VECTOR__VERTEX_AI_LOCATION = var.vertex_ai_search.location
      I4G_LLM__VERTEX_AI_PROJECT     = var.vertex_ai_search.project_id
      I4G_LLM__VERTEX_AI_LOCATION    = var.vertex_ai_search.location
    }
    intake = {
      I4G_INTAKE__API_BASE = format("%s/intakes", trimsuffix(module.run_core_svc.uri, "/"))
    }
    account_list = {
      I4G_STORAGE__REPORT_BUCKET = lookup(module.storage_buckets.bucket_names, "reports", "")
    }
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
      vpc_connector = (
        can(trimspace(job.vpc_connector)) && trimspace(job.vpc_connector) != ""
        ? job.vpc_connector
        : lookup(local.run_job_vpc_connector_overrides, job_key, null)
      )
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
