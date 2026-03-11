# ---------------------------------------------------------------------------
# App Stack — Provider Requirements
#
# Child modules must declare the providers they expect so that Terraform
# can pass them through from the root (wrapper) module without warnings.
# ---------------------------------------------------------------------------

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    google-beta = {
      source = "hashicorp/google-beta"
    }
  }
}
