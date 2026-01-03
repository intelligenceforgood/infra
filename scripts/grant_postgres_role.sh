#!/bin/bash
set -e

# Usage: ./grant_postgres_role.sh [dev|prod]

ENV=${1:-dev}

if [ "$ENV" == "dev" ]; then
    PROJECT="i4g-dev"
    INSTANCE="i4g-dev-db"
    SA_SUFFIX="@i4g-dev.iam"
elif [ "$ENV" == "prod" ]; then
    PROJECT="i4g-prod"
    INSTANCE="i4g-prod-db"
    SA_SUFFIX="@i4g-prod.iam"
else
    echo "Usage: $0 [dev|prod]"
    exit 1
fi

echo "Granting 'postgres' role to service accounts in $ENV..."
echo "You will be prompted for the 'postgres' user password."

# Service accounts that need to create tables
SAS=("sa-app" "sa-ingest" "sa-intake")

SQL_COMMANDS=""
for SA in "${SAS[@]}"; do
    USER="${SA}${SA_SUFFIX}"
    echo "Preparing grant for $USER..."
    SQL_COMMANDS+="GRANT postgres TO \"$USER\"; "
done

echo "Executing: $SQL_COMMANDS"

# Use gcloud beta sql connect
# We use --quiet to suppress prompts, but it will still ask for password if not provided via env var
# We assume the user running this has 'postgres' password.

gcloud beta sql connect "$INSTANCE" --user=postgres --project="$PROJECT" --quiet <<EOF
$SQL_COMMANDS
EOF

echo "Done."
