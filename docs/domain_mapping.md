# Cloud Run Domain Mapping & IAP Guide

This doc captures the steps to map custom domains to Cloud Run services and align Identity-Aware Proxy (IAP) settings.

## Overview
- Custom domains:
  - `api.intelligenceforgood.org` -> FastAPI gateway
  - `app.intelligenceforgood.org` -> Streamlit/Console UI
- Terraform will create Cloud Run domain mappings when `fastapi_custom_domain` or `ui_custom_domain` variables are set.
- DNS records (CNAME) must map the hostnames to `ghs.googlehosted.com` for subdomains. Verify the DNS change with domain owner.
- IAP brand & OAuth clients cannot be created by Terraform (deprecated API). Create the brand and OAuth client manually or via an alternative automation approach.

## Requirements
- Domain ownership for `intelligenceforgood.org` and access to the DNS provider (or Cloud DNS in Google Cloud).
- A Cloud Run service to map the domain to (e.g., `fastapi-gateway`).
- Appropriate IAM permissions to update the Cloud Run service and Cloud DNS records.

## Terraform-managed domain mapping
- In `environments/app/dev/terraform.tfvars` and `environments/app/prod/terraform.tfvars`, set:
  - `fastapi_custom_domain = "api.intelligenceforgood.org"`
  - `ui_custom_domain = "app.intelligenceforgood.org"`
  - Optionally set `dns_managed_zone` and `dns_managed_zone_project` if you manage DNS via Cloud DNS.

- Run `terraform plan` and `terraform apply` in the relevant environment (`environments/app/dev` or `environments/app/prod`).
- Terraform will create a `google_cloud_run_domain_mapping` resource and (optionally) a `google_dns_record_set` if `dns_managed_zone` is set.

## Manual DNS steps (if DNS is not managed via Cloud DNS)
- Create a CNAME record for `api.intelligenceforgood.org` -> `ghs.googlehosted.com`.
- Create a CNAME record for `app.intelligenceforgood.org` -> `ghs.googlehosted.com`.
- Wait for DNS propagation, then run terrraform apply to create the domain mapping.

## IAP & OAuth
- If using IAP, create an OAuth brand + OAuth client manually via Google Cloud Console.
- Add authorized redirect URIs and allowed origins for the custom domains (https://api.intelligenceforgood.org/_gcpgtoken or application-specific callback endpoints).
- Store client secrets in Secret Manager and update `iap_manage_clients` or set the `iap_client_id` and `iap_client_secret` in your run-time config accordingly.

## Verification
- Once mapped and DNS updated, confirm:
  - Visit `https://api.intelligenceforgood.org` (should present IAP authorization if enabled).
  - Run `gcloud run domain-mappings describe api.intelligenceforgood.org --region us-central1 --project i4g-dev` to verify mapping.

## Troubleshooting
- If managed certs are stuck, ensure the domain verification is finished and there are no conflicting DNS CNAME records.
- If IAP is not allowing access, check `iap_allowed_domains` and ensure `IAP` brand is configured with corresponding `support_email` and domains.

## Notes
- For apex domains (example.com), Cloud Run requires A records with synthetic IPv4 addresses. Avoid apex mappings for Cloud Run when possible.
- Terraform does not create OAuth clients for IAP due to the deprecation of the Admin API; manual steps are required.
