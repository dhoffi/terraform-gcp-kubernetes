variable "dest" {}
variable "env" {}

variable "JUMPBOXUSER" {}
variable "JUMPBOXSSHFILENAME" {}
variable "JUMPBOXSSHFILE" {}
variable "JUMPBOXSSHPUB" {}
variable "NODEUSER" {}
variable "NODESSHFILENAME" {}
variable "NODESSHFILE" {}
variable "NODESSHPUB" {}

# from $REPO_ROOT_DIR/.envrc
# redundant definition to fail-fast
variable "ADMIN_NAME" {}
variable "GCP_PROJECT_SERVICE_ACCOUNT_FILE" {}

variable "PROJECT_ID" {}
variable "GCP_REGION" {}
variable "GCP_ZONE" {}
variable "TF_STATE_BUCKET" {}

# VPC variables
variable how_many_jumpboxs {}

variable cluster_name {}

variable how_many_master_nodes {}

variable how_many_worker_nodes {}

variable "mgmt_subnet_cidr" {}
variable "private_subnet_cidr" {}

variable "public_subnet_cidr" {}
