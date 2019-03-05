#!/bin/bash

if [ -z "$REPO_ROOT_DIR" ]; then echo 'you have to `source .envrc` in project root dir or consider installing https://direnv.net' ; fi
trap "set +x" INT TERM QUIT EXIT

set -x

if [ ! -z "$1" ] && [ "$1" == CREATE ]; then
    # create service-account
    gcloud iam service-accounts create ${TF_VAR_ADMIN_NAME} \
    --display-name "admin service-account for ${TF_VAR_PROJECT_ID}"

    # create keys for service-account and store in ${GCP_PROJECT_SERVICE_ACCOUNT_FILE} (!!! beware to .gitignore this!!!)
    gcloud iam service-accounts keys create ${GCP_PROJECT_SERVICE_ACCOUNT_FILE} \
    --iam-account ${TF_VAR_ADMIN_NAME}@${TF_VAR_PROJECT_ID}.iam.gserviceaccount.com

    export GOOGLE_APPLICATION_CREDENTIALS=${GCP_PROJECT_SERVICE_ACCOUNT_FILE}
fi

# Grant the service account permission to view the Admin Project and manage Cloud Storage
gcloud projects add-iam-policy-binding ${TF_VAR_PROJECT_ID} \
  --member serviceAccount:${TF_VAR_ADMIN_NAME}@${TF_VAR_PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/viewer

gcloud projects add-iam-policy-binding ${TF_VAR_PROJECT_ID} \
  --member serviceAccount:${TF_VAR_ADMIN_NAME}@${TF_VAR_PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/storage.admin

# Any actions that Terraform performs require that the API be enabled to do so.

gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable cloudbilling.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable compute.googleapis.com
