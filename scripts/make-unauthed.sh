#!/usr/bin/env bash
set -euo pipefail
PROJECT="i4g-dev"
REGION="us-central1"
SERVICES=("i4g-console" "fastapi-gateway")

echo "Making services public (allow unauthenticated invoker) in project ${PROJECT} region ${REGION}"
for svc in "${SERVICES[@]}"; do
  echo "Allowing unauthenticated access to ${svc}..."
  gcloud run services add-iam-policy-binding "${svc}" \
    --project="${PROJECT}" \
    --region="${REGION}" \
    --member="allUsers" \
    --role="roles/run.invoker" \
    --quiet
done
echo "Done. Verify each service URL in the browser."