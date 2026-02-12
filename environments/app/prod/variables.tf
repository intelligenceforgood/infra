variable "project_id" {
  type        = string
  description = "GCP project ID for the prod environment."
}

variable "pii_vault_project_id" {
  type        = string
  description = "GCP project ID of the companion PII Vault project."
}

variable "i4g_analyst_members" {
  type        = list(string)
  description = "Principals (users, service accounts, or Google Groups) that need Cloud Run access to analyst surfaces."
  default     = []
}

variable "i4g_admin_members" {
  type        = list(string)
  description = "Principals (Google Workspace groups or users) that should receive project Owner for break-glass admin access."
  default     = []
}

variable "region" {
  type        = string
  description = "Primary region for regional resources."
  default     = "us-central1"
}

variable "iap_support_email" {
  type        = string
  description = "Verified Google account email used for the production IAP consent screen."
}

variable "iap_application_title" {
  type        = string
  description = "Display title shown on the production OAuth consent screen."
  default     = "i4g Analyst Surfaces"
}

variable "iap_manage_brand" {
  type        = bool
  description = "Set to true only if Terraform should create the IAP brand (requires an organization-owned project)."
  default     = false
}

variable "iap_existing_brand_name" {
  type        = string
  description = "Optional brand resource name when reusing a manually created brand."
  default     = ""
}

variable "iap_project_level_bindings" {
  type        = bool
  description = "When true, create project-level IAP accessor bindings for `i4g_analyst_members`."
  default     = true
}

variable "iap_enable_allowed_domains" {
  type        = bool
  description = "Enable allowed domains enforcement for the production IAP project settings."
  default     = false
}

variable "iap_allowed_domains" {
  type        = list(string)
  description = "Trusted domains used when allowed domains is enabled."
  default     = []
}

variable "iap_allow_http_options" {
  type        = bool
  description = "Allow unauthenticated HTTP OPTIONS (CORS preflight) requests through IAP."
  default     = true
}

variable "github_repository" {
  type        = string
  description = "GitHub repository (owner/name) allowed to impersonate automation accounts."
  default     = "intelligenceforgood/core"
}

variable "fastapi_image" {
  type        = string
  description = "Container image URI for the FastAPI Cloud Run service."
}

variable "fastapi_env_vars" {
  type        = map(string)
  description = "Environment variables injected into the FastAPI service container."
  default     = {}
}

variable "fastapi_secret_env_vars" {
  description = "Secret-backed environment variables for the FastAPI service."
  type = map(object({
    secret  = string
    version = optional(string)
  }))
  default = {}
}

variable "fastapi_invoker_member" {
  type        = string
  description = "Principal granted Cloud Run invoker on the FastAPI service (leave blank to use defaults)."
  default     = ""
}

variable "fastapi_invoker_members" {
  type        = list(string)
  description = "Additional principals granted Cloud Run invoker on the FastAPI service."
  default     = []
}

variable "console_image" {
  type        = string
  description = "Container image URI for the Next.js console Cloud Run service."
}

variable "console_env_vars" {
  type        = map(string)
  description = "Environment variables injected into the console service container."
  default     = {}
}

variable "console_secret_env_vars" {
  description = "Secret-backed environment variables injected into the console service."
  type = map(object({
    secret  = string
    version = optional(string)
  }))
  default = {}
}

variable "console_invoker_member" {
  type        = string
  description = "Principal granted Cloud Run invoker on the console service (leave blank to use IAM policies)."
  default     = ""
}

variable "console_invoker_members" {
  type        = list(string)
  description = "Additional principals granted Cloud Run invoker on the console service."
  default     = []
}

variable "fastapi_custom_domain" {
  type        = string
  description = "Optional custom domain to map to the FastAPI service (e.g., api.intelligenceforgood.org)."
  default     = ""
}

variable "ui_custom_domain" {
  type        = string
  description = "Optional custom domain to map to the UI service (e.g., app.intelligenceforgood.org)."
  default     = ""
}

variable "dns_managed_zone" {
  type        = string
  description = "Optional Cloud DNS managed zone name to create DNS records in for the custom domains. If empty, DNS changes are external/manual."
  default     = ""
}

variable "dns_managed_zone_project" {
  type        = string
  description = "Optional project ID where the DNS managed zone is located (if different)."
  default     = ""
}

variable "storage_bucket_default_location" {
  type        = string
  description = "Default location/region for storage buckets."
  default     = "US"
}



variable "storage_buckets" {
  description = "Map of storage bucket configurations keyed by logical name."
  type = map(object({
    name                        = string
    location                    = optional(string)
    storage_class               = optional(string)
    labels                      = optional(map(string))
    force_destroy               = optional(bool)
    uniform_bucket_level_access = optional(bool)
    public_access_prevention    = optional(string)
    versioning                  = optional(bool)
    lifecycle_rules = optional(list(object({
      action = object({
        type          = string
        storage_class = optional(string)
      })
      condition = object({
        age                   = optional(number)
        with_state            = optional(string)
        matches_storage_class = optional(list(string))
        matches_prefix        = optional(list(string))
        matches_suffix        = optional(list(string))
        num_newer_versions    = optional(number)
      })
    })))
    retention_policy = optional(object({
      retention_period = number
    }))
    kms_key_name = optional(string)
  }))
  default = {}
}

variable "run_jobs" {
  description = "Definitions for Cloud Run jobs to deploy in the environment."
  type = map(object({
    enabled             = optional(bool)
    name                = string
    image               = string
    service_account_key = string
    location            = optional(string)
    env_vars            = optional(map(string))
    secret_env_vars = optional(map(object({
      secret  = string
      version = optional(string)
    })))
    command                            = optional(list(string))
    args                               = optional(list(string))
    labels                             = optional(map(string))
    annotations                        = optional(map(string))
    parallelism                        = optional(number)
    task_count                         = optional(number)
    max_retries                        = optional(number)
    timeout_seconds                    = optional(number)
    resource_limits                    = optional(map(string))
    vpc_connector                      = optional(string)
    vpc_connector_egress_settings      = optional(string)
    schedule                           = optional(string)
    time_zone                          = optional(string)
    description                        = optional(string)
    scheduler_name                     = optional(string)
    scheduler_service_account_key      = optional(string)
    scheduler_attempt_deadline_seconds = optional(number)
    scheduler_body                     = optional(string)
    scheduler_headers                  = optional(map(string))
    scheduler_audience                 = optional(string)
    scheduler_oauth_scopes             = optional(list(string))
  }))
  default = {}
}

variable "vertex_ai_search" {
  description = "Configuration for Vertex AI Search."
  type = object({
    project_id    = string
    location      = string
    data_store_id = string
    display_name  = string
  })
}

variable "db_admin_group" {
  type        = string
  description = "Google Group email for database administrators."
}

variable "db_analyst_group" {
  type        = string
  description = "Google Group email for database analysts."
}

variable "database_config" {
  description = "Cloud SQL instance configuration."
  type = object({
    instance_name       = string
    tier                = string
    disk_size           = number
    availability_type   = string
    backup_enabled      = bool
    backup_start_time   = optional(string, "02:00")
    deletion_protection = bool
  })
}

variable "iap_clients" {
  description = "Pre-created IAP OAuth client IDs and secrets for each backend. Override in local-overrides.tfvars when ready."
  type = map(object({
    client_id     = string
    client_secret = string
  }))
  default   = {}
  sensitive = true

  validation {
    condition = alltrue([
      for k, v in var.iap_clients :
      v.client_id != "REPLACE_ME" && v.client_secret != "REPLACE_ME"
    ])
    error_message = "iap_clients entries must not use sentinel values. Provide real OAuth credentials or leave the map empty."
  }
}
