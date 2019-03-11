terraform {
  required_version = ">= v0.11.0"
}

provider "google" {
  credentials = "${file("${var.GCP_PROJECT_SERVICE_ACCOUNT_FILE}")}"
  project     = "${var.PROJECT_ID}"
  region      = "${var.GCP_REGION}"
  zone        = "${var.GCP_ZONE}"
}

data "google_compute_zones" "available-zones_data" {}

module "vpc" {
  source = "./modules/vpc"

  # parameters
  dest                  = "${var.dest}"
  env                   = "${var.env}"
  gcp_region            = "${var.GCP_REGION}"
  cluster_name          = "${var.cluster_name}"
  how_many_master_nodes = "${var.how_many_master_nodes}"
  how_many_worker_nodes = "${var.how_many_worker_nodes}"
  mgmt_subnet_cidr      = "${var.mgmt_subnet_cidr}"
  private_subnet_cidr   = "${var.private_subnet_cidr}"
  public_subnet_cidr    = "${var.public_subnet_cidr}"
}

module "mgmt" {
  source = "./modules/mgmt"

  # parameters
  dest       = "${var.dest}"
  env        = "${var.env}"
  gcp_region = "${var.GCP_REGION}"

  network_self_link   = "${module.vpc.network-out-self-link}"
  cluster_name        = "${var.cluster_name}"
  how_many_jumpboxes  = "${var.how_many_jumpboxes}"
  mgmt_subnet_cidr    = "${var.mgmt_subnet_cidr}"
  private_subnet_cidr = "${var.private_subnet_cidr}"
  public_subnet_cidr  = "${var.public_subnet_cidr}"
}
