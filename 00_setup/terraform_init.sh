#!/bin/bash

if [ -z "$REPO_ROOT_DIR" ]; then echo 'you have to `source .envrc` in project root dir or consider installing https://direnv.net' ; exit -1 ; fi
trap "set +x" INT TERM QUIT EXIT

set -x
terraform init -backend=true -input=false \
  -backend-config "credentials=${TF_VAR_GCP_PROJECT_SERVICE_ACCOUNT_FILE}" \
  -backend-config "bucket=${TF_VAR_TF_STATE_BUCKET}"
