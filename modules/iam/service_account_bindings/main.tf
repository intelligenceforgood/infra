terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

locals {
  binding_entries = flatten([
    for binding_key, binding in var.bindings : [
      for role in binding.roles : {
        key    = "${binding_key}-${role}"
        role   = role
        member = binding.member
      }
    ]
  ])
}

resource "google_project_iam_member" "this" {
  for_each = { for entry in local.binding_entries : entry.key => entry }

  project = var.project_id
  role    = each.value.role
  member  = each.value.member
}
