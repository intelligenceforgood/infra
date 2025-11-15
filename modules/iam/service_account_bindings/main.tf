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
        role   = role
        member = binding.member
      }
    ]
  ])

  binding_entries_map = zipmap(
    range(length(local.binding_entries)),
    local.binding_entries,
  )
}

resource "google_project_iam_member" "this" {
  for_each = local.binding_entries_map

  project = var.project_id
  role    = each.value.role
  member  = each.value.member
}
