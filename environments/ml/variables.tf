variable "project_id" {
  type        = string
  description = "GCP project ID for the ML platform."
}

variable "region" {
  type        = string
  description = "Primary region for regional resources."
  default     = "us-central1"
}

variable "data_bucket_name" {
  type        = string
  description = "Name of the GCS bucket for ML data."
  default     = "i4g-ml-data"
}

variable "model_artifact_uri" {
  type        = string
  description = "GCS URI of the champion model artifacts."
  default     = ""
}

variable "shadow_model_artifact_uri" {
  type        = string
  description = "GCS URI of the shadow model artifacts."
  default     = ""
}

variable "challenger_model_artifact_uri" {
  type        = string
  description = "GCS URI of the challenger model artifacts for A/B routing."
  default     = ""
}

variable "challenger_traffic_weight" {
  type        = string
  description = "Traffic weight for the challenger model (0.0–1.0)."
  default     = "0.0"
}

variable "risk_model_artifact_uri" {
  type        = string
  description = "GCS URI of the risk scoring model artifacts."
  default     = ""
}

variable "ner_model_artifact_uri" {
  type        = string
  description = "GCS URI of the NER model artifacts."
  default     = ""
}

variable "cost_aware_routing" {
  type        = string
  description = "Enable cost-aware model routing."
  default     = "false"
}

variable "similarity_enabled" {
  type        = string
  description = "Enable FAISS similarity index at startup."
  default     = "false"
}
