#!/bin/bash

if [ -z "$REPO_ROOT_DIR" ]; then echo 'you have to `source .envrc` in project root dir or consider installing https://direnv.net' ; fi
trap "set +x" INT TERM QUIT EXIT

set -x
gsutil mb -p "${TF_VAR_PROJECT_ID}" "gs://terraform-state-${TF_VAR_PROJECT_ID}"
