#!/bin/bash

if [ -z "$REPO_ROOT_DIR" ]; then echo 'you have to `source .envrc` in project root dir or consider installing https://direnv.net' ; fi
trap "set +x" INT TERM QUIT EXIT

set -x
terraform init -backend=true -input=false \
  -backend-config "credentials=${GCP_PROJECT_SERVICE_ACCOUNT_FILE}" \
  -backend-config "bucket=${TF_VAR_TF_STATE_BUCKET}" \
  -backend-config "project=${TF_VAR_PROJECT_ID}"