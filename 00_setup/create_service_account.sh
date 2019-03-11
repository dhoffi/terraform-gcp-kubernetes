#!/bin/bash

if [ -z "$REPO_ROOT_DIR" ]; then echo 'you have to `source .envrc` in project root dir or consider installing https://direnv.net' ; exit -1 ; fi
trap "set +x" INT TERM QUIT EXIT

set -x

if [ -z "$2" ]; then
    # create service-account
    gcloud iam service-accounts create ${TF_VAR_ADMIN_NAME} \
    --display-name "admin service-account for ${TF_VAR_PROJECT_ID}"

    # create keys for service-account and store into ./secrets/... (!!! beware to .gitignore this!!!)
    gcpProjectServiceAccountFilename="${REPO_ROOT_DIR}/secrets/${TF_VAR_PROJECT_ID}_${TF_VAR_ADMIN_NAME}.json"
    gcloud iam service-accounts keys create "$gcpProjectServiceAccountFilename" \
    --iam-account ${TF_VAR_ADMIN_NAME}@${TF_VAR_PROJECT_ID}.iam.gserviceaccount.com

    export GOOGLE_APPLICATION_CREDENTIALS=${gcpProjectServiceAccountFilename}
fi

# Grant the service account permission to view the Admin Project and manage Cloud Storage
gcloud projects add-iam-policy-binding ${TF_VAR_PROJECT_ID} \
  --member serviceAccount:${TF_VAR_ADMIN_NAME}@${TF_VAR_PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/viewer

gcloud projects add-iam-policy-binding ${TF_VAR_PROJECT_ID} \
  --member serviceAccount:${TF_VAR_ADMIN_NAME}@${TF_VAR_PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/iam.serviceAccountUser

gcloud projects add-iam-policy-binding ${TF_VAR_PROJECT_ID} \
  --member serviceAccount:${TF_VAR_ADMIN_NAME}@${TF_VAR_PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/storage.admin

gcloud projects add-iam-policy-binding ${TF_VAR_PROJECT_ID} \
  --member serviceAccount:${TF_VAR_ADMIN_NAME}@${TF_VAR_PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/compute.admin

gcloud projects add-iam-policy-binding ${TF_VAR_PROJECT_ID} \
  --member serviceAccount:${TF_VAR_ADMIN_NAME}@${TF_VAR_PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/compute.instanceAdmin.v1

gcloud projects add-iam-policy-binding ${TF_VAR_PROJECT_ID} \
  --member serviceAccount:${TF_VAR_ADMIN_NAME}@${TF_VAR_PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/compute.networkAdmin

gcloud projects add-iam-policy-binding ${TF_VAR_PROJECT_ID} \
  --member serviceAccount:${TF_VAR_ADMIN_NAME}@${TF_VAR_PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/compute.loadBalancerAdmin

gcloud projects add-iam-policy-binding ${TF_VAR_PROJECT_ID} \
  --member serviceAccount:${TF_VAR_ADMIN_NAME}@${TF_VAR_PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/dns.admin

# Any actions that Terraform performs require that the API be enabled to do so.

gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable cloudbilling.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable compute.googleapis.com
