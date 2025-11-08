terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  backend "gcs" {
    # TODO: replace with the bucket created by bootstrap/create_state_bucket.sh
    bucket = "tfstate-i4g-dev"
    prefix = "env/dev"
    # TODO: update to the automation service account email for this project
    impersonate_service_account = "sa-infra@i4g-dev.iam.gserviceaccount.com"
  }
}
