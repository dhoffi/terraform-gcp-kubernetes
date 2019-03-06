# Terraforming Infrastructure for setting up Kubernetes with kubespray

vaguely based upon: https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform</br>
vaguely based upon: https://github.com/kubernetes-sigs/kubespray/tree/master/contrib/terraform/aws

---

## GCP Prerequisites


### gcloud configuration

Let's create a dedicated local gcloud configuration for our project:

``` bash
gcloud config configurations create kubernetes
gcloud init
```

choose `[1] Re-initialize this configuration [kubernetes] with new settings`<br/>
choose `[x] Create a new project`<br/>
give a project-id

and set your default GCE location and zone

``` bash
gcloud config set compute/region europe-west1
gcloud config set compute/zone europe-west1-c
```

### local environment .envrc (usable with https://direnv.net)
Edit the first line of `./.envrc` activating your profile chosen above.<br/>
Also edit the GCP service-account name in the line `export  TF_VAR_ADMIN_NAME=tu-0815` to a name that pleases you.

Variables in ./.envrc prefixed with `TF_VAR_` will be used in terraform (redundantly defined in `vars.tf` with the same name and caps as in .envrc)<br/>
All variables will as well be used setup and helper shellscripts (see `00_setup` folder).

If you use https://direnv.net the `./.envrc` file will be sourced and unsourced any time you cd into or below its folder or out of it. Otherwise you'd have to `source ./.envrc` it.

---

<center><big> After having done/edited all this you need to `source ./.envrc` or `direnv allow` !!!</big></center>

---

Make sure that the service account file with credentials (which we will create/get in a minute) is ignored by your VCS, e.g. git

``` bash
echo "/${TF_VAR_PROJECT_ID}_${TF_VAR_ADMIN_NAME}.json" >> .gitignore
```

my .gitignore files looks something like this:

```
.DS_Store
.terraform
.vscode/

/.envrc
/myk8spray_tu-k8s.json
/tmp/
```

### enable billing four your project

To enable billing for your project:

- Go to the API Console.
- From the projects list, select a project or create a new one.
- Open the console left side menu and select Billing  Billing
- Click Enable billing. (If billing is already enabled then this option isn't available.)
- If you don't have a billing account, create one.
- Select your location, fill out the form, and click Submit and enable billing.

After you enable billing, any requests to billable APIs beyond their free courtesy usage limits are billed, subject to the - billing terms of each API.

### create a/the GCP service-account and authorization for it

For this we don't want to use our GCP admin or user account.<br/>
Instead we are creating our own project specific service-account and will use that.

In addition to being an identity, a service account is a resource which has IAM policies attached to it. These policies determine who can use the service account. For instance, Alice can have the editor role on a service account and Bob can have viewer role on a service account. This is just like granting roles for any other GCP resource.

see [Service accounts](https://cloud.google.com/iam/docs/service-accounts?hl=en) and [Understanding service accounts](https://cloud.google.com/iam/docs/understanding-service-accounts?hl=en)

There is a helper script `./00_setup/create_service_account.sh CREATE` which does so for you.<br/>
(if uppercased parameter CREATE is given, the script will create the service-account and keys for it
otherwise it will only enable and bind policies)

``` bash
#!/bin/bash

if [ -z "$REPO_ROOT_DIR" ]; then echo 'you have to `source .envrc` in project root dir or consider installing https://direnv.net' ; fi
trap "set +x" INT TERM QUIT EXIT

set -x

if [ ! -z "$0" ] && [ "$0" == CREATE ]; then
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
```

after executing these commands you now should have the service-account credentials file in your local directory.

<center><big>!!! don't forget to git ignore this file as it contains sensitive information !!!**</big></center>


### create terraform backend storage bucket

On first run (and only on first run) you also have to create the terraform state bucket before anything else.</br>
The helper script `./00_setup/create_terraform_state_bucket.sh` does so for you:

``` bash
gsutil mb -p "${TF_VAR_PROJECT_ID}" "gs://terraform-state-${TF_VAR_PROJECT_ID}"
```

This bucket will be used by terraform to store its state.

### terraform init with parameterized backend-config

For being able to use parameterized variables from `./.envrc` in `./backend.tf` you have to pass `-backend-config` parameters to `terraform init`. The helper script `./00_setup/terraform_init.sh` shows how-to:

``` bash
#!/bin/bash

# env variables from (parent/s) .envrc
if [ -z "$REPO_ROOT_DIR ]; then
    echo 'you have to `source .envrc` in project root dir or consider installing https://direnv.net'
fi

trap "set +x" INT TERM QUIT EXIT

set -x
terraform init -backend=true -input=false \
  -backend-config "credentials=${GCP_PROJECT_SERVICE_ACCOUNT_FILE}" \
  -backend-config "bucket=${TF_VAR_TF_STATE_BUCKET}" \
  -backend-config "project=${TF_VAR_PROJECT_ID}"
```

Backend is defined in `./backend.tf`

In case you get an error like this:

```
Error loading state: 2 error(s) occurred:

* writing "gs://terraform-state-mycoolproject/terraform/state/default.tflock" failed: googleapi: Error 403: Access Not Configured. Cloud Storage JSON API has not been used in project 175697319590 before or it is disabled. Enable it by visiting https://console.developers.google.com/apis/api/storage-api.googleapis.com/overview?project=0000000000 then retry. If you enabled this API recently, wait a few minutes for the action to propagate to our systems and retry., accessNotConfigured
* storage: object doesn't exist
```

You have to go to the given URL, enable the "Google Cloud Storage JSON API"</br>
and re-run `./00_setup/terraform_init.sh`

## Terraforming GCP for kubespray

vaguely based upon: https://github.com/kubernetes-sigs/kubespray/tree/master/contrib/terraform/aws

terraform apply will create:

- VPC with Public and Private Subnets in # Availability Zones
- Bastion Hosts and NAT Gateways in the Public Subnet
- A dynamic number of masters, etcd, and worker nodes in the Private Subnet
- even distributed over the # of Availability Zones
- AWS ELB in the Public Subnet for accessing the Kubernetes API from the internet

## 
***TODO***


---

<style type="text/css"> /* automatic heading numbering */ h1 { counter-reset: h2counter; font-size: 24pt; } h2 { counter-reset: h3counter; font-size: 22pt; margin-top: 2em; } h3 { counter-reset: h4counter; font-size: 16pt; } h4 { counter-reset: h5counter; font-size: 14pt; } h5 { counter-reset: h6counter; } h6 { } h2:before { counter-increment: h2counter; content: counter(h2counter) ".\0000a0\0000a0"; } h3:before { counter-increment: h3counter; content: counter(h2counter) "." counter(h3counter) ".\0000a0\0000a0"; } h4:before { counter-increment: h4counter; content: counter(h2counter) "." counter(h3counter) "." counter(h4counter) ".\0000a0\0000a0"; } h5:before { counter-increment: h5counter; content: counter(h2counter) "." counter(h3counter) "." counter(h4counter) "." counter(h5counter) ".\0000a0\0000a0"; } h6:before { counter-increment: h6counter; content: counter(h2counter) "." counter(h3counter) "." counter(h4counter) "." counter(h5counter) "." counter(h6counter) ".\0000a0\0000a0"; } </style>
