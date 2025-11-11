resource "google_discovery_engine_data_store" "this" {
  provider = google-beta

  project       = var.project_id
  location      = var.location
  data_store_id = var.data_store_id
  display_name  = var.display_name

  industry_vertical           = var.industry_vertical
  solution_types              = var.solution_types
  content_config              = var.content_config
  create_advanced_site_search = false
}
