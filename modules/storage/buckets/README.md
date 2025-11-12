# storage/buckets Module

Creates one or more Google Cloud Storage buckets with sane defaults for the i4g platform.

## Features
- Uniform bucket-level access and public access prevention enabled by default.
- Optional per-bucket overrides for location, storage class, versioning, lifecycle rules, and retention.
- Optional default KMS key association.
- Returns a map of bucket names keyed by logical identifier for wiring into other modules.

## Inputs
- `project_id` (string): Target GCP project ID.
- `default_location` (string): Fallback location when a bucket omits `location` (default `US`).
- `buckets` (map): Definitions for each bucket. Each entry supports the fields shown below.

### Bucket object
```hcl
buckets = {
  evidence = {
    name          = "i4g-evidence-dev"
    location      = "us"
    force_destroy = true
    labels = {
      env     = "dev"
      service = "storage"
    }
    lifecycle_rules = [
      {
        action = {
          type = "Delete"
        }
        condition = {
          age = 365
        }
      }
    ]
  }
}
```

## Outputs
- `bucket_names` (map): Logical key → bucket name.
