# gcloud compute images list
data "google_compute_image" "nodes-image_data" {
  family  = "ubuntu-1604-lts"
  project = "ubuntu-os-cloud"
}

# Using templates with Instance Group Manager
# Instance Templates cannot be updated after creation with the Google Cloud Platform API.
# In order to update an Instance Template, Terraform will destroy the existing resource and create a replacement.
# In order to effectively use an Instance Template resource with an Instance Group Manager resource,
# it's recommended to specify create_before_destroy in a lifecycle block.
# Either omit the Instance Template name attribute, or specify a partial name with name_prefix.
resource "google_compute_instance_template" "masters-template" {
  #name        = "${local.pre}-master-template"
  name_prefix          = "${local.pre}-master-template-"
  description          = "This template is used to create kubernetes master node instances."
  instance_description = "generated from google_compute_instance_template master"

  machine_type   = "n1-standard-1"
  can_ip_forward = true

  disk {
    source_image = "${data.google_compute_image.nodes-image_data.self_link}"
    boot         = true
    auto_delete  = true
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.private-subnet.self_link}"

    # if ommited --> no public ip
    # access_config = {
    #   # if empty, gets a public ephemeral ip
    # }
  }

  lifecycle {
    create_before_destroy = true
  }

  metadata = "${merge(local.master_labels, map("sshKeys", "${var.nodeuser}:${var.nodesshpub}"))}"
  # metadata = "${local.master_labels}"

  labels = "${local.master_labels}"
  tags   = "${local.master_tags}"
}

resource "google_compute_instance_template" "workers-template" {
  #name        = "${local.pre}-worker-template"
  name_prefix          = "${local.pre}-worker-template-"
  description          = "This template is used to create kubernetes worker node instances."
  instance_description = "generated from google_compute_instance_template worker"

  machine_type   = "n1-standard-1"
  can_ip_forward = true

  disk {
    source_image = "${data.google_compute_image.nodes-image_data.self_link}"
    boot         = true
    auto_delete  = true
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.private-subnet.self_link}"

    # if ommited --> no public ip
    # access_config = {
    #   # if empty, gets a public ephemeral ip

    # }
  }

  lifecycle {
    create_before_destroy = true
  }

  metadata = "${merge(local.worker_labels, map("sshKeys", "${var.nodeuser}:${var.nodesshpub}"))}"
  # metadata = "${local.worker_labels}"

  labels   = "${local.worker_labels}"
  tags     = "${local.worker_tags}"
}

resource "google_compute_region_instance_group_manager" "masters-group-manager" {
  name = "${local.pre}-masters-group-manager"

  base_instance_name = "${local.pre}-master"
  instance_template  = "${google_compute_instance_template.masters-template.self_link}"
  region             = "${var.gcp_region}"

  wait_for_instances = false

  # unless this resource is attached to an autoscaler, in which case it should never be set
  target_size = "${var.how_many_master_nodes}"

  # # only for EXTERNAL lb google_compute_target_pool
  # target_pools = ["${google_compute_target_pool.masters-target-pool.self_link}"]
  # for INTERNAL lb referenced by backend_service.backend { }

  # distribution_policy_zones  = ["europe-west1-b", "europe-west1-c"]

  # auto_healing_policies {
  #   health_check      = "${google_compute_health_check.masters-health-check.self_link}"
  #   initial_delay_sec = 60
  # }
}

resource "google_compute_region_instance_group_manager" "workers-group-manager" {
  name = "${local.pre}-workers-group-manager"

  base_instance_name = "${local.pre}-worker"
  instance_template  = "${google_compute_instance_template.workers-template.self_link}"
  region             = "${var.gcp_region}"

  wait_for_instances = false

  # unless this resource is attached to an autoscaler, in which case it should never be set
  target_size = "${var.how_many_worker_nodes}"

  # # only for EXTERNAL lb google_compute_target_pool
  # target_pools = ["${google_compute_target_pool.workers-target-pool.self_link}"]
  # for INTERNAL lb referenced by backend_service.backend { }

  #distribution_policy_zones  = ["europe-west1-b", "europe-west1-c"]

  # auto_healing_policies {
  #   health_check      = "${google_compute_health_check.workers-health-check.self_link}"
  #   initial_delay_sec = 60
  # }
}

# # for EXTERNAL lb targets
# resource "google_compute_target_pool" "masters-target-pool" {
# for INTERNAL lb backend-services
resource "google_compute_region_backend_service" "masters-backend-service" {
  name             = "${local.pre}-masters-backend-service"
  session_affinity = "NONE"

  # protocol = "HTTP"

  # only for INTERNAL lb, otherwise google_compute_target_pool references ...
  backend {
    description = "backend vms for masters-backend-service"
    group       = "${google_compute_region_instance_group_manager.masters-group-manager.instance_group}"
  }
  health_checks = [
    # "${google_compute_http_health_check.masters-health-check.self_link}",
    "${google_compute_health_check.masters-health-check.self_link}",
  ]
}

# # for EXTERNAL lb targets
# resource "google_compute_target_pool" "workers-target-pool" {
# for INTERNAL lb backend-services
resource "google_compute_region_backend_service" "workers-backend-service" {
  name             = "${local.pre}-workers-backend-service"
  session_affinity = "NONE"

  # protocol = "HTTP"

  # only for INTERNAL lb, otherwise google_compute_target_pool references ...
  backend {
    description = "backend vms for workers-backend-service"
    group       = "${google_compute_region_instance_group_manager.workers-group-manager.instance_group}"
  }
  health_checks = [
    # "${google_compute_http_health_check.workers-health-check.self_link}",
    "${google_compute_health_check.workers-health-check.self_link}",
  ]
}

# resource "google_compute_http_health_check" "masters-health-check" {
resource "google_compute_health_check" "masters-health-check" {
  name = "${local.pre}-masters-health-check"

  check_interval_sec  = 5
  timeout_sec         = 2  # less than check_interval_sec
  healthy_threshold   = 2  # healty after this many consecutive calls succeeded
  unhealthy_threshold = 10 # unhealthy after this many consecutive calls failed

  # # only for EXTERNAL lb targets
  # request_path = "/healthz"
  # port         = "8080"
  # for INTERNAL lb service-backends
  http_health_check {
    request_path = "/healthz"
    port         = "8080"
  }
}

# resource "google_compute_http_health_check" "workers-health-check" {
resource "google_compute_health_check" "workers-health-check" {
  name = "${local.pre}-workers-health-check"

  check_interval_sec  = 10
  timeout_sec         = 5  # less than check_interval_sec
  healthy_threshold   = 2  # healty after this many consecutive calls succeeded
  unhealthy_threshold = 5  # unhealthy after this many consecutive calls failed

  # # only for EXTERNAL lb targets
  # request_path = "/healthz"
  # port         = "8080"
  # for INTERNAL lb service-backends
  http_health_check {
    request_path = "/healthz"
    port         = "8080"
  }
}

data "google_compute_region_instance_group" "masters-group_data" {
  self_link = "${google_compute_region_instance_group_manager.masters-group-manager.instance_group}"
}

data "google_compute_region_instance_group" "workers-group_data" {
  self_link = "${google_compute_region_instance_group_manager.workers-group-manager.instance_group}"
}
