locals {
  service_accounts = {
    fastapi = {
      account_id   = "sa-fastapi"
      display_name = "FastAPI Cloud Run"
      description  = "Runs the FastAPI API gateway"
    }
    streamlit = {
      account_id   = "sa-streamlit"
      display_name = "Streamlit Analyst Portal"
      description  = "Serves the analyst-facing UI"
    }
    ingest = {
      account_id   = "sa-ingest"
      display_name = "Ingestion Jobs"
      description  = "Executes scheduled ingestion Cloud Run jobs"
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
