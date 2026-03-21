#!/usr/bin/env bash
# Bootstrap helper for the i4g-ml GCP project.
#
# Creates the Terraform state bucket, automation service account, and enables
# the APIs required by the ML platform stack.  Run once before `terraform init`
# in environments/ml/.
#
# Usage:
#   ./bootstrap/create_ml_project.sh [project_id]
#
# Example:
#   ./bootstrap/create_ml_project.sh i4g-ml
#
# Prerequisites:
#   - gcloud CLI authenticated with Owner or Editor on the target project.
#   - The GCP project must already exist and have billing linked.

set -euo pipefail

PROJECT_ID="${1:-i4g-ml}"
REGION="us"
BUCKET_NAME="tfstate-${PROJECT_ID}"
SERVICE_ACCOUNT_ID="sa-infra"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_ID}@${PROJECT_ID}.iam.gserviceaccount.com"

printf "\n🔧 Bootstrapping ML platform project='%s'\n" "${PROJECT_ID}"

# ── Enable required APIs ─────────────────────────────────────────────────────

APIS=(
  aiplatform.googleapis.com
  artifactregistry.googleapis.com
  bigquery.googleapis.com
  cloudresourcemanager.googleapis.com
  cloudscheduler.googleapis.com
  compute.googleapis.com
  iam.googleapis.com
  iamcredentials.googleapis.com
  logging.googleapis.com
  monitoring.googleapis.com
  run.googleapis.com
  secretmanager.googleapis.com
  serviceusage.googleapis.com
  storage.googleapis.com
)

printf "\n📡 Enabling required services...\n"
for api in "${APIS[@]}"; do
  echo "  → ${api}"
  gcloud services enable "${api}" --project "${PROJECT_ID}" --quiet >/dev/null
done

# ── State bucket ─────────────────────────────────────────────────────────────

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

printf "🌱 Enabling bucket versioning...\n"
gcloud storage buckets update "gs://${BUCKET_NAME}" --versioning --project "${PROJECT_ID}" --quiet

# ── Automation service account ───────────────────────────────────────────────

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
  roles/aiplatform.admin
  roles/artifactregistry.admin
  roles/bigquery.admin
  roles/iam.securityReviewer
  roles/logging.admin
  roles/monitoring.editor
  roles/resourcemanager.projectIamAdmin
  roles/run.admin
  roles/secretmanager.admin
  roles/serviceusage.serviceUsageAdmin
  roles/storage.admin
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

# ── Impersonation grant ──────────────────────────────────────────────────────

CALLER_EMAIL="$(gcloud config get-value account --quiet 2>/dev/null || true)"
if [[ -n "${CALLER_EMAIL}" ]]; then
  printf "\n🔑 Granting Token Creator on sa-infra to %s...\n" "${CALLER_EMAIL}"
  gcloud iam service-accounts add-iam-policy-binding "${SERVICE_ACCOUNT_EMAIL}" \
    --project "${PROJECT_ID}" \
    --member "user:${CALLER_EMAIL}" \
    --role "roles/iam.serviceAccountTokenCreator" \
    --quiet >/dev/null
else
  printf "\n⚠️  Could not detect caller email. Manually grant Token Creator:\n"
  echo "  gcloud iam service-accounts add-iam-policy-binding ${SERVICE_ACCOUNT_EMAIL} \\"
  echo "    --project ${PROJECT_ID} \\"
  echo "    --member 'user:YOUR_EMAIL' \\"
  echo "    --role roles/iam.serviceAccountTokenCreator"
fi

# ── Done ─────────────────────────────────────────────────────────────────────

printf "\n✅ Bootstrap complete. Next steps:\n"
cat <<EOF

  cd infra/environments/ml/
  terraform init
  terraform plan

The backend is already configured in environments/ml/backend.tf:

  terraform {
    backend "gcs" {
      bucket                      = "${BUCKET_NAME}"
      prefix                      = "env/ml"
      impersonate_service_account = "${SERVICE_ACCOUNT_EMAIL}"
    }
  }
EOF
