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
  default_uniform_bucket_level_access = true
  default_public_access_prevention    = "enforced"
  default_versioning                  = true
  default_storage_class               = "STANDARD"
}

resource "google_storage_bucket" "buckets" {
  for_each = var.buckets

  project       = var.project_id
  name          = each.value.name
  location      = coalesce(try(each.value.location, null), var.default_location)
  storage_class = coalesce(try(each.value.storage_class, null), local.default_storage_class)
  labels        = try(each.value.labels, {})
  force_destroy = try(each.value.force_destroy, false)

  uniform_bucket_level_access = try(each.value.uniform_bucket_level_access, local.default_uniform_bucket_level_access)
  public_access_prevention    = try(each.value.public_access_prevention, local.default_public_access_prevention)

  dynamic "versioning" {
    for_each = [true]
    content {
      enabled = can(each.value.versioning.enabled) ? each.value.versioning.enabled : coalesce(try(each.value.versioning, null), local.default_versioning)
    }
  }

  dynamic "retention_policy" {
    for_each = try(each.value.retention_policy, null) == null ? [] : [each.value.retention_policy]
    content {
      retention_period = retention_policy.value.retention_period
    }
  }

  dynamic "encryption" {
    for_each = try(each.value.kms_key_name, null) == null ? [] : [each.value.kms_key_name]
    content {
      default_kms_key_name = encryption.value
    }
  }

  dynamic "lifecycle_rule" {
    for_each = coalesce(try(each.value.lifecycle_rules, null), [])
    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = try(lifecycle_rule.value.action.storage_class, null)
      }

      condition {
        age                   = try(lifecycle_rule.value.condition.age, null)
        with_state            = try(lifecycle_rule.value.condition.with_state, null)
        matches_storage_class = try(lifecycle_rule.value.condition.matches_storage_class, null)
        matches_prefix        = try(lifecycle_rule.value.condition.matches_prefix, null)
        matches_suffix        = try(lifecycle_rule.value.condition.matches_suffix, null)
        num_newer_versions    = try(lifecycle_rule.value.condition.num_newer_versions, null)
      }
    }
  }
}
