variable "project_id" {
  type        = string
  description = "GCP project ID for the prod environment."
}

variable "i4g_analyst_members" {
  type        = list(string)
  description = "Principals (users, service accounts, or Google Groups) that need Cloud Run access to analyst surfaces."
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

variable "iap_manage_clients" {
  type        = bool
  description = "Set to true to create per-service OAuth clients and store their secrets."
  default     = false
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

variable "iap_secret_replication_locations" {
  type        = list(string)
  description = "Secret Manager replica regions storing production OAuth client secrets."
  default     = []
}

variable "github_repository" {
  type        = string
  description = "GitHub repository (owner/name) allowed to impersonate automation accounts."
  default     = "intelligenceforgood/proto"
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

variable "streamlit_image" {
  type        = string
  description = "Container image URI for the Streamlit Cloud Run service."
}

variable "streamlit_env_vars" {
  type        = map(string)
  description = "Environment variables injected into the Streamlit service container."
  default     = {}
}

variable "streamlit_invoker_members" {
  type        = list(string)
  description = "Principals granted Cloud Run invoker on the Streamlit service."
  default     = []
}

variable "streamlit_invoker_member" {
  type        = string
  description = "Principal granted Cloud Run invoker on the Streamlit service (leave blank to use defaults)."
  default     = ""
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

variable "vertex_search_location" {
  type        = string
  description = "Discovery Engine location for Vertex AI Search resources."
  default     = "global"
}

variable "storage_bucket_default_location" {
  type        = string
  description = "Default location/region for storage buckets."
  default     = "US"
}

variable "firestore_location" {
  type        = string
  description = "Location/region for the default Firestore database."
  default     = "us-central1"
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

variable "vertex_search_data_store_id" {
  type        = string
  description = "Identifier for the Vertex AI Search data store."
  default     = "retrieval-prod"
}

variable "vertex_search_display_name" {
  type        = string
  description = "Display name for the Vertex AI Search data store."
  default     = "Retrieval Production Data Store"
}
