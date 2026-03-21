terraform {
  backend "gcs" {
    bucket                      = "tfstate-i4g-ml"
    prefix                      = "env/ml"
    impersonate_service_account = "sa-infra@i4g-ml.iam.gserviceaccount.com"
  }
}
