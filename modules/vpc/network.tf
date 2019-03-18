resource "google_compute_subnetwork" "mgmt-subnet" {
  name        = "${local.pre}-mgmt-net"
  description = "${local.pre}-mgmt-net"

  ip_cidr_range = "${var.mgmt_subnet_cidr}"
  network       = "${google_compute_network.vpc.self_link}"

  private_ip_google_access = true
}

resource "google_compute_subnetwork" "public-subnet" {
  name        = "${local.pre}-pub-net"
  description = "${local.pre}-pub-net"

  ip_cidr_range = "${var.public_subnet_cidr}"
  network       = "${google_compute_network.vpc.self_link}"

  private_ip_google_access = false
}

resource "google_compute_subnetwork" "private-subnet" {
  name        = "${local.pre}-pri-net"
  description = "${local.pre}-pri-net"

  ip_cidr_range = "${var.private_subnet_cidr}"
  network       = "${google_compute_network.vpc.self_link}"

  private_ip_google_access = false
}

# =================================================================================
# ========================   output   =============================================
# =================================================================================
output "subnetwork_mgmt-out-self-link" {
  value = "${google_compute_subnetwork.mgmt-subnet.self_link}"
}

output "subnetwork_mgmt_gateway_address-out" {
  value = "${google_compute_subnetwork.mgmt-subnet.gateway_address}"
}

output "subnetwork_private-out-self-link" {
  value = "${google_compute_subnetwork.private-subnet.self_link}"
}

output "subnetwork_private_gateway_address-out" {
  value = "${google_compute_subnetwork.private-subnet.gateway_address}"
}

output "subnetwork_public-out-self_link" {
  value = "${google_compute_subnetwork.public-subnet.self_link}"
}

output "subnetwork_public_gateway_address-out" {
  value = "${google_compute_subnetwork.public-subnet.gateway_address}"
}
