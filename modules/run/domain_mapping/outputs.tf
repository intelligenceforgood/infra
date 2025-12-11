output "domain_mapping_name" {
  value = google_cloud_run_domain_mapping.this.name
}

output "dns_record_name" {
  value       = length(google_dns_record_set.cname_map) > 0 ? google_dns_record_set.cname_map[0].name : null
  description = "The DNS record name if a managed zone was provided."
}
