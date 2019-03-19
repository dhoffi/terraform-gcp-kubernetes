# Using templates with Instance Group Manager
# Instance Templates cannot be updated after creation with the Google Cloud Platform API.
# In order to update an Instance Template, Terraform will destroy the existing resource and create a replacement.
# In order to effectively use an Instance Template resource with an Instance Group Manager resource,
# it's recommended to specify create_before_destroy in a lifecycle block.
# Either omit the Instance Template name attribute, or specify a partial name with name_prefix.
resource "google_compute_instance_template" "jumpboxs-template" {
  name_prefix          = "${local.pre}-jumpbox-template-"
  description          = "This template is used to create jumpbox instances."
  instance_description = "generated from google_compute_instance_template jumpbox-template"

  machine_type   = "n1-standard-1"
  can_ip_forward = true

  disk {
    source_image = "${data.google_compute_image.jumpbox-image_data.self_link}"
    boot         = true
    auto_delete  = true
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.mgmt-subnet.self_link}"

    # if omited --> no public ip
    access_config = {
      # if empty, gets a public ephemeral ip
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  metadata = "${merge(local.default_labels, map(
      "jumpbox", "true",
      "sshKeys", "${var.jumpboxuser}:${var.jumpboxsshpub}",
    ))}"

  labels = "${merge(local.default_labels, map(
      "jumpbox", "true",
    ))}"

  tags = ["jumpbox", "${local.default_tags}"]
}

resource "google_compute_region_instance_group_manager" "jumpboxs-group-manager" {
  name        = "${local.pre}-jumpboxs-group-manager"
  description = "${local.pre}-jumpboxs-group-manager"

  base_instance_name = "${local.pre}-jumpbox"
  instance_template  = "${google_compute_instance_template.jumpboxs-template.self_link}"
  region             = "${var.gcp_region}"

  wait_for_instances = false

  # unless this resource is attached to an autoscaler, in which case it should never be set
  target_size = "${var.how_many_jumpboxs}"

  # only for EXTERNAL lbs
  target_pools = ["${google_compute_target_pool.jumpboxs-target-pool.self_link}"]

  #distribution_policy_zones  = ["europe-west1-b", "europe-west1-c"]

  # auto_healing_policies {
  #   health_check      = "${google_compute_health_check.jumpboxs-health-check.self_link}"
  #   initial_delay_sec = 60
  # }
}

# only for EXTERNAL lbs
resource "google_compute_target_pool" "jumpboxs-target-pool" {
  name        = "${local.pre}-jumpboxs-target-pool"
  description = "${local.pre}-jumpboxs-target-pool"

  session_affinity = "CLIENT_IP"

  # health_checks = [
  #   # "${google_compute_http_health_check.jumpboxs-health-check.self_link}",
  #   "${google_compute_health_check.jumpboxs-health-check.self_link}",
  # ]
}

# =================================================================================
# ========================    data    =============================================
# =================================================================================
data "google_compute_region_instance_group" "jumpboxs-group_data" {
  self_link = "${google_compute_region_instance_group_manager.jumpboxs-group-manager.instance_group}"
}

# =================================================================================
# ========================   output   =============================================
# =================================================================================

