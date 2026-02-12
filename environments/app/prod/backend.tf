terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "gcs" {
    bucket                      = "tfstate-i4g-prod"
    prefix                      = "env/prod"
    impersonate_service_account = "sa-infra@i4g-prod.iam.gserviceaccount.com"
  }
}
