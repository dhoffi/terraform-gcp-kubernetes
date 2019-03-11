#!/bin/bash

if [ -z "$REPO_ROOT_DIR" ]; then echo 'you have to `source .envrc` in project root dir or consider installing https://direnv.net' ; exit -1 ; fi
trap "set +x" INT TERM QUIT EXIT

set -x
gsutil mb -p "${TF_VAR_PROJECT_ID}" -l "${TF_VAR_GCP_REGION}" "gs://${TF_VAR_TF_STATE_BUCKET}"
