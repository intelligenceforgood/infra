terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

variable "project_id" {
  type = string
}

variable "name" {
  description = "Name prefix for LB resources"
  type        = string
}

variable "backends" {
  description = "Map of backends. Key is a unique identifier."
  type = map(object({
    domain       = string
    service_name = string
    region       = string
    enable_iap   = bool
    iap_client_id     = optional(string)
    iap_client_secret = optional(string)
  }))
}

# 1. Global IP
resource "google_compute_global_address" "default" {
  project = var.project_id
  name    = "${var.name}-ip"
}

# 2. Managed SSL Certificates
resource "google_compute_managed_ssl_certificate" "default" {
  for_each = var.backends

  project = var.project_id
  name    = "${var.name}-cert-${each.key}"

  managed {
    domains = [each.value.domain]
  }
}

# 3. Serverless NEGs
resource "google_compute_region_network_endpoint_group" "default" {
  for_each = var.backends

  project               = var.project_id
  name                  = "${var.name}-neg-${each.key}"
  network_endpoint_type = "SERVERLESS"
  region                = each.value.region
  cloud_run {
    service = each.value.service_name
  }
}

# 4. Backend Services
resource "google_compute_backend_service" "default" {
  for_each = var.backends

  project = var.project_id
  name    = "${var.name}-backend-${each.key}"
  protocol = "HTTPS"
  port_name = "http"
  timeout_sec = 30

  backend {
    group = google_compute_region_network_endpoint_group.default[each.key].id
  }

  dynamic "iap" {
    for_each = each.value.enable_iap ? [1] : []
    content {
      enabled              = true
      oauth2_client_id     = each.value.iap_client_id
      oauth2_client_secret = each.value.iap_client_secret
    }
  }
}

# 5. URL Map
resource "google_compute_url_map" "default" {
  project = var.project_id
  name    = "${var.name}-lb"

  # Default fallback (required) - just pick the first one
  default_service = values(google_compute_backend_service.default)[0].id

  dynamic "host_rule" {
    for_each = var.backends
    content {
      hosts        = [host_rule.value.domain]
      path_matcher = "matcher-${host_rule.key}"
    }
  }

  dynamic "path_matcher" {
    for_each = var.backends
    content {
      name            = "matcher-${path_matcher.key}"
      default_service = google_compute_backend_service.default[path_matcher.key].id
    }
  }
}

# 6. Target HTTPS Proxy
resource "google_compute_target_https_proxy" "default" {
  project = var.project_id
  name    = "${var.name}-proxy"
  url_map = google_compute_url_map.default.id
  ssl_certificates = [for cert in google_compute_managed_ssl_certificate.default : cert.id]
}

# 7. Forwarding Rule
resource "google_compute_global_forwarding_rule" "default" {
  project    = var.project_id
  name       = "${var.name}-forwarding-rule"
  target     = google_compute_target_https_proxy.default.id
  port_range = "443"
  ip_address = google_compute_global_address.default.address
}

# 8. HTTP Redirect (Port 80)
resource "google_compute_url_map" "https_redirect" {
  project = var.project_id
  name    = "${var.name}-https-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "https_redirect" {
  project = var.project_id
  name    = "${var.name}-http-proxy"
  url_map = google_compute_url_map.https_redirect.id
}

resource "google_compute_global_forwarding_rule" "https_redirect" {
  project    = var.project_id
  name       = "${var.name}-forwarding-rule-http"
  target     = google_compute_target_http_proxy.https_redirect.id
  port_range = "80"
  ip_address = google_compute_global_address.default.address
}

output "ip_address" {
  value = google_compute_global_address.default.address
}

output "backend_services" {
  value = { for k, v in google_compute_backend_service.default : k => v.name }
}
