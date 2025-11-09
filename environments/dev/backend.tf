terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  backend "gcs" {
    bucket                      = "tfstate-i4g-dev"
    prefix                      = "env/dev"
    impersonate_service_account = "sa-infra@i4g-dev.iam.gserviceaccount.com"
  }
}
