variable "project_id" {
  type        = string
  description = "GCP project ID for the dev environment."
}

variable "region" {
  type        = string
  description = "Primary region for regional resources."
  default     = "us-central1"
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
  description = "Principal granted Cloud Run invoker on the FastAPI service (leave blank to skip)."
  default     = ""
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

variable "streamlit_invoker_member" {
  type        = string
  description = "Principal granted Cloud Run invoker on the Streamlit service (leave blank to skip)."
  default     = ""
}

variable "vertex_search_location" {
  type        = string
  description = "Discovery Engine location for Vertex AI Search resources."
  default     = "global"
}

variable "vertex_search_data_store_id" {
  type        = string
  description = "Identifier for the Vertex AI Search data store."
  default     = "retrieval-poc"
}

variable "vertex_search_display_name" {
  type        = string
  description = "Display name for the Vertex AI Search data store."
  default     = "Retrieval PoC Data Store"
}
