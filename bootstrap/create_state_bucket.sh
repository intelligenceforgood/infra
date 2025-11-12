#!/usr/bin/env bash
# Bootstrap helper for Terraform state bucket and automation service account.
#
# Usage:
#   ./bootstrap/create_state_bucket.sh <env> [project_id]
#
# Example:
#   ./bootstrap/create_state_bucket.sh dev i4g-dev
#
# Requirements:
#   - gcloud CLI authenticated with permission to create buckets and IAM roles.
#   - gcloud alpha storage component (bundled with recent gcloud releases).

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <env> [project_id]" >&2
  exit 1
fi

ENVIRONMENT="$1"
PROJECT_ID="${2:-$(gcloud config get-value project --quiet)}"
if [[ -z "${PROJECT_ID}" ]]; then
  echo "Project ID not supplied and gcloud config project is unset." >&2
  exit 1
fi

REGION="us"
BUCKET_NAME="tfstate-i4g-${ENVIRONMENT}"
SERVICE_ACCOUNT_ID="sa-infra"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_ID}@${PROJECT_ID}.iam.gserviceaccount.com"

printf "\n🔧 Bootstrapping Terraform state for env='%s' project='%s'\n" "${ENVIRONMENT}" "${PROJECT_ID}"

# Enable core APIs required by Terraform-managed resources.
APIS=(
  cloudresourcemanager.googleapis.com
  compute.googleapis.com
  run.googleapis.com
  artifactregistry.googleapis.com
  iam.googleapis.com
  iamcredentials.googleapis.com
  serviceusage.googleapis.com
  storage.googleapis.com
  cloudfunctions.googleapis.com
  cloudscheduler.googleapis.com
  secretmanager.googleapis.com
  logging.googleapis.com
  monitoring.googleapis.com
)

printf "\n📡 Enabling required services...\n"
for api in "${APIS[@]}"; do
  echo "  → ${api}"
  gcloud services enable "${api}" --project "${PROJECT_ID}" --quiet >/dev/null
done

printf "\n🪣 Ensuring state bucket gs://%s exists...\n" "${BUCKET_NAME}"
if gcloud storage buckets describe "gs://${BUCKET_NAME}" --project "${PROJECT_ID}" >/dev/null 2>&1; then
  echo "  Bucket already exists. Skipping create."
else
  gcloud storage buckets create "gs://${BUCKET_NAME}" \
    --project "${PROJECT_ID}" \
    --location "${REGION}" \
    --uniform-bucket-level-access \
    --quiet
fi

# Enable versioning for backup/rollback of Terraform state.
printf "🌱 Enabling bucket versioning...\n"
gcloud storage buckets update "gs://${BUCKET_NAME}" --versioning --project "${PROJECT_ID}" --quiet

printf "\n👤 Ensuring service account %s exists...\n" "${SERVICE_ACCOUNT_EMAIL}"
if gcloud iam service-accounts describe "${SERVICE_ACCOUNT_EMAIL}" --project "${PROJECT_ID}" >/dev/null 2>&1; then
  echo "  Service account already exists."
else
  gcloud iam service-accounts create "${SERVICE_ACCOUNT_ID}" \
    --project "${PROJECT_ID}" \
    --display-name "Terraform automation"
fi

printf "\n🔐 Granting IAM roles to %s...\n" "${SERVICE_ACCOUNT_EMAIL}"
PROJECT_ROLES=(
  roles/storage.admin
  roles/resourcemanager.projectIamAdmin
  roles/run.admin
  roles/iam.securityReviewer
  roles/serviceusage.serviceUsageAdmin
  roles/secretmanager.admin
  roles/logging.admin
  roles/monitoring.editor
)

for role in "${PROJECT_ROLES[@]}"; do
  echo "  → ${role}"
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member "serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role "${role}" \
    --quiet >/dev/null
done

printf "\n📦 Granting bucket-level access...\n"
gcloud storage buckets add-iam-policy-binding "gs://${BUCKET_NAME}" \
  --member "serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role roles/storage.objectAdmin \
  --quiet

echo "\n✅ Bootstrap complete. Configure Terraform backend with:\n"
cat <<EOF
terraform {
  backend "gcs" {
    bucket                      = "${BUCKET_NAME}"
    prefix                      = "env/${ENVIRONMENT}"
    impersonate_service_account = "${SERVICE_ACCOUNT_EMAIL}"
  }
}
EOF
