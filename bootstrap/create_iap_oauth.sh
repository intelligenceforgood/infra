#!/usr/bin/env bash
# Helper script to bootstrap an OAuth client for IAP manually.
# This script requires the gcloud CLI and the user must have Project Owner or Security Admin.
# Usage:
#  ./bootstrap/create_iap_oauth.sh <project> <client-name> <redirect-uri> <secret-id>
# Example:
#  ./bootstrap/create_iap_oauth.sh i4g-dev iap-fastapi "https://api.intelligenceforgood.org/_gcpgtoken" iap-client-fastapi

set -euo pipefail

if [[ $# -lt 4 ]]; then
  echo "Usage: $0 <project> <client-name> <redirect-uri> <secret-id>"
  exit 1
fi

PROJECT="$1"
CLIENT_NAME="$2"
REDIRECT_URI="$3"
SECRET_ID="$4"

# The command below uses gcloud to create an OAuth client.
# NOTE: The creation API may still be restricted in some orgs, and this flow may need manual steps.

# Create OAuth client via Web UI (recommended):
cat <<EOF
Manual steps to create an OAuth client for IAP:
1. Open https://console.cloud.google.com/apis/credentials?project=${PROJECT}
2. Click Create Credentials → OAuth client ID → Web application.
3. Set the name: ${CLIENT_NAME}
4. For authorized redirect URIs, add: ${REDIRECT_URI}
5. Click Create and note the Client ID and Client Secret.
6. Store the client secret in Secret Manager:
   echo "${IAP_CLIENT_SECRET}" | gcloud secrets versions add ${SECRET_ID} --data-file=- --project ${PROJECT}

If you can automate the client creation via gcloud 'beta' or 'oauth' CLI, consider replacing manual steps.
EOF

# Attempt to hint how to store the secret (actual secret requires interactive input).

exit 0
