module "iam_service_accounts" {
  source     = "../../modules/iam/service_accounts"
  project_id = var.project_id

  service_accounts = local.service_accounts
}
