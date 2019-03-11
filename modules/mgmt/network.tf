resource "google_compute_subnetwork" "mgmt-subnet" {
  name          = "${local.pre}-mgmt-net"
  ip_cidr_range = "${var.mgmt_subnet_cidr}"
  network       = "${var.network_self_link}"


  private_ip_google_access = true
}

output "subnetwork_mgmt_cidr_range-out" {
  value = "${google_compute_subnetwork.mgmt-subnet.ip_cidr_range}"

}

output "subnetwork_mgmt_gateway_address-out" {
  value = "${google_compute_subnetwork.mgmt-subnet.gateway_address}"

}

