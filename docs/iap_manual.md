# IAP OAuth Brand & Client Manual Guide

Terraform config does not create IAP OAuth brands/clients due to the deprecation of the OAuth Admin API. Follow this guide to manually configure IAP OAuth.

## Steps
1. Open Google Cloud Console for the target project (e.g., `i4g-dev`).
2. Navigate to **Security** → **Identity-Aware Proxy** → **OAuth consent screen** and ensure a brand exists. If not, create one selecting `External` or `Internal` as appropriate.
3. Under **Credentials**, create an OAuth client (Web application) and note the `Client ID` and `Client secret`.
4. For each application, add authorized redirect URIs and JavaScript origins:
   - For FastAPI (server-to-server): ensure the token exchange endpoints are allowed. If your app expects callbacks, add `https://api.intelligenceforgood.org/_gcpgtoken` (or your callback path).
   - For UI (Streamlit/Console): add `https://app.intelligenceforgood.org` as an authorized origin and `https://app.intelligenceforgood.org/oauth2/callback` if a callback is required.
5. Save the `Client ID` and `Client secret` securely. Use the `sa-infra` or an automation pipeline to write the secret to Secret Manager under the project using the `iap-client-*` secret IDs used in Terraform (e.g., `iap-client-fastapi`).

## Secret Manager
- Use the helper script `scripts/infra/add_azure_secrets.py` as a pattern or use `gcloud`:

```bash
# Example: write a secret version
printf "${IAP_CLIENT_SECRET}" | gcloud secrets versions add iap-client-fastapi --data-file=- --project i4g-dev
```

- Ensure the service account running Cloud Run has `roles/secretmanager.secretAccessor` on the project where the secret lives.

## Verification
- After setting up the OAuth client and secrets, open a private browser session and visit `https://app.intelligenceforgood.org`.
- IAP consent screen should appear (or the app may handle the authentication flow). If not, verify that `IAP` is enabled and the allowed domains include `intelligenceforgood.org`.

## Notes
- Enable `IAP` only after verifying domain mappings are fully operational and DNS records propagated.
- Keep `iap_manage_clients` set to `false` in Terraform when you intend to manage OAuth clients manually.
- Consider using a more robust automation path for OAuth clients if your organization requires programmatic creation and rotation.
