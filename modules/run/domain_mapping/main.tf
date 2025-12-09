resource "google_cloud_run_domain_mapping" "this" {
  project  = var.project_id
  location = var.region
  name     = var.domain
  spec {
    route_name = var.service_name
  }
}

output "domain" {
  value = google_cloud_run_domain_mapping.this.name
}

# Optional: Create a CNAME record in a managed zone if provided
resource "google_dns_record_set" "cname_map" {
  count = trimspace(var.dns_managed_zone) == "" ? 0 : 1

  project      = var.dns_project == "" ? var.project_id : var.dns_project
  managed_zone = var.dns_managed_zone
  name         = "${var.domain}."
  type         = "CNAME"
  ttl          = 300
  rrdatas      = ["ghs.googlehosted.com."]

  depends_on = [google_cloud_run_domain_mapping.this]
}
