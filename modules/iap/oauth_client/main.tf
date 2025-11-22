/*
The IAP OAuth Admin API and the `google_iap_client` resource are deprecated.
This module intentionally does not create OAuth clients. Create IAP OAuth
clients (brands/clients) manually in the Google Cloud Console or via a
non-deprecated automation path, then supply any client IDs/secrets to your
deployment or Secret Manager as appropriate.

Keeping this module present keeps the higher-level modules stable while
avoiding calls to the deprecated API that produced Terraform warnings.
*/

locals {
  noop = true
}
