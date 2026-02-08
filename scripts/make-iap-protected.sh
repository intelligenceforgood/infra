#!/usr/bin/env bash
set -euo pipefail
PROJECT="i4g-dev"
REGION="us-central1"
SERVICES=("i4g-console" "fastapi-gateway")
IAP_PRINCIPAL="user:jerry@intelligenceforgood.org"

echo "Securing services behind IAP and removing allUsers invoker in project ${PROJECT}"
for svc in "${SERVICES[@]}"; do
  echo "Removing allUsers invoker from ${svc}..."
  # remove allUsers binding (ignore errors if not present)
  gcloud run services remove-iam-policy-binding "${svc}" \
    --project="${PROJECT}" \
    --region="${REGION}" \
    --member="allUsers" \
    --role="roles/run.invoker" \
    --quiet || true

  echo "Ensure IAP binding exists for ${svc} (project-level IAP accessor may also work)..."
  # For IAP you need to grant roles/iap.httpsResourceAccessor at the project level or per-service via terraform.
  # Here we add the project-level binding as a quick temporary measure:
  gcloud projects add-iam-policy-binding "${PROJECT}" \
    --member="${IAP_PRINCIPAL}" \
    --role="roles/iap.httpsResourceAccessor" \
    --quiet || true
done

echo "If browser still returns 403, ensure an OAuth consent screen exists and your user is a test user (or the brand is created in an Org)."
echo "Done."