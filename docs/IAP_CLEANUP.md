<!-- Moved from environments/dev to infra/docs for central infra documentation -->

```markdown
# IAP Cleanup & Terraform state guidance

This file documents safe steps to clean up any Terraform-managed IAP brand/client
artifacts that may have been created during earlier experiments, and how to
prepare your environment before migrating the project into an Organization.

Important safety notes
- Always back up your Terraform state before removing resources from state.
- These steps only update local Terraform state. They do not call Google APIs or
  delete any live resources unless you run the commands shown below.

Quick checklist (recommended)
1. Confirm Terraform backend and working directory. This repo uses per-environment
   working dirs. Run the commands from `infra/environments/dev` (or the env you
   are working in).

2. Inspect the Terraform state for IAP-related resources:

```bash
cd infra/environments/dev
terraform init
terraform state list | grep -i iap || true
```

3. If the above `state list` prints nothing, Terraform is not currently tracking
   IAP brand/client resources and you can skip the state-removal steps.

4. If the state lists resources such as `google_iap_brand` or `google_iap_client`
   (or any `iap`-named resources), back up the state and then remove those
   resources from state so Terraform stops managing them:

```bash
# Backup local state (or snapshot your remote backend according to your backend)
cp terraform.tfstate terraform.tfstate.backup

# Example removals (replace with exact names from `terraform state list`):
terraform state rm 'module.iap_project.google_iap_brand.brand'
terraform state rm 'module.iap_fastapi.module.oauth_client[0].google_iap_client.client'
terraform state rm 'module.iap_fastapi.module.oauth_client[0].google_secret_manager_secret.secret'
```

5. Disable project-level IAP bindings in Terraform so they are not applied during
   future `apply` runs (this repo already exposes `iap_project_level_bindings`):

Add to your env tfvars (e.g., `infra/environments/dev/terraform.tfvars`):

```hcl
iap_project_level_bindings = false
```

Then run `terraform plan` to confirm there are no pending destroys you didn't
expect.

6. If you manually created an OAuth brand/client in the Console for dev use,
   you can leave it until you migrate the project into the Organization. To
   remove the client and secret now (optional):

 - Delete the OAuth client in the Cloud Console: APIs & Services → Credentials
 - Delete any related Secret Manager secrets you created for the client
   (e.g., `gcloud secrets delete <secret-name> --project=<project>`)

7. If you temporarily added a project-level IAP accessor IAM binding with
   `gcloud projects add-iam-policy-binding`, you can remove it with:

```bash
gcloud projects remove-iam-policy-binding <PROJECT_ID> \
  --member='user:you@example.org' --role='roles/iap.httpsResourceAccessor' --quiet
```

When to delete the OAuth brand
- You do not need to delete the OAuth brand now. If you plan to migrate the
  project into an Organization and create an org-level brand, you can keep the
  existing brand until migration, then remove or recreate under the Org as
  appropriate. Deleting brands can be irreversible in some cases; only delete
  if you are certain.

Questions? Paste the output of `terraform state list | grep -i iap` and I will
produce the exact `terraform state rm` commands for the entries shown.

```
