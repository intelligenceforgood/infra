locals {
  service_accounts = {
    app = {
      account_id   = "sa-app"
      display_name = "Application Runtime"
      description  = "Runs FastAPI, Streamlit, and console services"
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
  }

  github_wif = {
    pool_id     = "github-actions"
    provider_id = "proto"
  }
}
