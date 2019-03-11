# Terraforming Infrastructure for setting up Kubernetes with kubespray

vaguely based upon: https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform</br>
vaguely based upon: https://github.com/kubernetes-sigs/kubespray/tree/master/contrib/terraform/aws

This project is highly parameterized to be able to terraform for different GCP accounts, and environments within them.

By sourcing `.envrc` there will be defined several environment variables, which also will be used inside scripts and terraforming.

Environment Variable `DEST` determines the target GCP account which to use.</br>
(This way e.g.: terraformed 'test' and 'dev' environments can be setup in a different GCP account than 'prod')

Each environment should have its own technical admin user (env var `TF_VAR_ADMIN_NAME=${DEST}-tu-k8s`).

GCP Service account credential files (as created by ./00_setup/create_service_account.sh)</br>
should be under ./secrets folder and have the form '${TF_VAR_PROJECT_ID}_${TF_VAR_ADMIN_NAME}.json'</br>e.g.: 'devtest-myk8spray_devtest-tu-k8s.json

gcloud configuration should be the same as '${DEST}-${TF_VAR_PROJECT_ID}' e.g.: 'devtest-myk8spray'.

Naming scheme of **any resource** created should be prefixed with '${DEST}-{env}-' e.g.: 'devtest-dev-' or 'devtest-test2-'.

---

## Terraform naming conventions

- `resource`s named with kebab case
- `resource` names are prefixed with `${dest}-${env}-<resource>_<resourceName>` with resourceName same (kebab case) as name of resource
- `data` section names (kebab cased) are postfixed with `_data`
- `variable`s are named with snake-case
- `output` section names are snake-case and postfixed with `-out` except for self-links which are postfixed with `-out-self-link`

## GCP Prerequisites

`direnv allow` (or `source .envrc`) asks for the value of `DEST` as the scripts cannot guess which env's are on which account.

After having cloned this repo you have to edit .envrc accordingly and create the gcloud configuration as shown next before you `direnv allow` or `source .envrc`, otherwise it will fail.

### gcloud configuration

Let's create a dedicated local gcloud configuration for our project in its GCP account.</br>
As `.envrc` uses glcoud command to activate this and get some information out of it, namely
- PROJECT_ID
- compute/region
- compute/zone

Unfortunately this is a hen-and-egg problem the first time.</br>
So beware to adhere to the naming convention '${DEST}-${PROJECT_ID}'

If you already created the GCP project manually via Google Cloud Platform Web Console, act accordingly.

``` bash
gcloud config configurations create devtest-myk8spray
gcloud init
```

choose `[1] Re-initialize this configuration [kubernetes] with new settings`<br/>
choose `[x] Create a new project`<br/>
give a project-id (BEWARE project-id should be **the same name** as your gcloud configuration above)

After finishing you can check success with:
`gcloud config configurations list`

But you also should set your default GCE location and zone

``` bash
gcloud config set compute/region europe-west1
gcloud config set compute/zone europe-west1-c
```

### local environment .envrc (usable with https://direnv.net)

Edit your project name (after the '${DEST}-')in the line</br>
`gcloud config configurations activate ${DEST}-myk8spray 2> /dev/null`</br>
to whatever you chose your project to be named above.

Also edit the GCP service-account name in the line `export  TF_VAR_ADMIN_NAME=${DEST}-tu-0815` to a name that pleases you.</br>
Beware to keep the prefix '${DEST}-' before the name you choose.

Variables in ./.envrc prefixed with `TF_VAR_` will be used in terraform (redundantly defined in their corresponding `./vars/${env}-vars.tf` with the same name and caps as in .envrc)<br/>
All variables will as well be used in setup and helper shellscripts (see `00_setup` folder).

If you use https://direnv.net the `./.envrc` file will be sourced and unsourced any time you cd into or below its folder or out of it. Otherwise you'd have to `source ./.envrc` it.

---

<center><big> After having done/edited all this you need to `source ./.envrc` or `direnv allow` !!!</big></center>

---

Make sure that the service account file with credentials (which we will create/get in a minute) is ignored by your VCS, e.g. git

``` bash
echo "/${TF_VAR_PROJECT_ID}_${TF_VAR_ADMIN_NAME}.json" >> .gitignore
```

my .gitignore file looks something like this:

```
.DS_Store
.vscode/

.terraform
/secrets/
/tmp/
```

### enable billing for your project

To enable billing for your project:

- Go to the API Console.
- From the projects list, select a project or create a new one.
- Open the console left side menu and select Billing  Billing
- Click Enable billing. (If billing is already enabled then this option isn't available.)
- If you don't have a billing account, create one.
- Select your location, fill out the form, and click Submit and enable billing.

After you enable billing, any requests to billable APIs beyond their free courtesy usage limits are billed, subject to the - billing terms of each API.

### create a/the GCP service-account and authorization for it

If you already have a service-account then you can skip this step in the prerequisites.</br>
But beware that some things in this project only work if the username of the service-account adheres to the convention and is prefixed with '${DEST}-'.

Beware that it is a wise idea NOT to use your GCP admin or user account.<br/>
So instead we are creating our own project specific service-account and will use that.

In addition to being an identity, a service account is a resource which has IAM policies attached to it. These policies determine who can use the service account. For instance, Alice can have the editor role on a service account and Bob can have viewer role on a service account. This is just like granting roles for any other GCP resource.

see [Service accounts](https://cloud.google.com/iam/docs/service-accounts?hl=en) and [Understanding service accounts](https://cloud.google.com/iam/docs/understanding-service-accounts?hl=en)

There is a helper script `./00_setup/create_service_account.sh CREATE` which does so for you.<br/>
(if uppercased parameter CREATE is given, the script will create the service-account and keys for it
otherwise it will only enable and bind policies)

``` bash
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
  --role roles/storage.admin

# Any actions that Terraform performs require that the API be enabled to do so.

gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable cloudbilling.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable compute.googleapis.com
```

after executing these commands you now should have the service-account credentials file in your local directory.

---

<center><big>!!! don't forget to git ignore this file as it contains sensitive information !!!**</big></center></br>
<center><big>!!! at the same time, store this file (contents) in a password safe or somewhere where it can't be accessed illegally and also where it can't be lost</big></center>

---

### create terraform backend storage bucket

On first run (and only on first run) you also have to create the terraform state bucket before anything else.</br>
The helper script `./00_setup/create_terraform_state_bucket.sh` does so for you:

``` bash
gsutil mb -p "${TF_VAR_PROJECT_ID}" -l "${TF_VAR_GCP_REGION}" "gs://${TF_VAR_TF_STATE_BUCKET}"
```

This bucket will be used by terraform to store its state (per environment in this account as we will be using terraform workspaces later on).

### terraform init with parameterized backend-config

<center><big>!!! BEWARE: before 'terraform init' or better before ./00_setup/terraform_init.sh</br>
switch to the right terraform workspace (see above) !!!</big></center></br>


For being able to use parameterized variables from `./.envrc` in `./backend.tf` you have to pass `-backend-config` parameters to `terraform init`. The helper script `./00_setup/terraform_init.sh` shows how-to:

``` bash
#!/bin/bash

if [ -z "$REPO_ROOT_DIR" ]; then echo 'you have to `source .envrc` in project root dir or consider installing https://direnv.net' ; exit -1 ; fi
trap "set +x" INT TERM QUIT EXIT

set -x
terraform init -backend=true -input=false \
  -backend-config "credentials=${TF_VAR_GCP_PROJECT_SERVICE_ACCOUNT_FILE}" \
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

### terraform workspace

We want to use separate terraform state files for each environment within each ${DEST} account.

This way we are able to terraform separately but identically e.g.?
- `dev`  environment in `devtest` ${DEST} account
- `test` environment in `devtest` ${DEST} account
- `prod` environment in `prod`    ${DEST} account

so we create a new terraform workspace for each environment we want to terraform with:

``` bash
terraform workspace new dev
```

again, if you get an error message like:

```
Failed to get configured named states: querying Cloud Storage failed: googleapi: Error 403: Access Not Configured. Cloud Storage JSON API has not been used in project 491825312490 before or it is disabled. Enable it by visiting https://console.developers.google.com/apis/api/storage-api.googleapis.com/overview?project=491825312490 then retry. If you enabled this API recently, wait a few minutes for the action to propagate to our systems and retry., accessNotConfigured
```

Either go to the given URL and enable the "Google Cloud Storage JSON API"</br>
or if you have done so before wait a few seconds and try again.

You can switch between workspaces with:

```
terraform workspace list
terraform workspace select dev
```

Beware that the workspace name will be taken as the 'env' name for all created and referenced terraform resources.

It also has to match e.g. the variable file base names under `./vars/<env>.tfvars`

---
---
---

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
