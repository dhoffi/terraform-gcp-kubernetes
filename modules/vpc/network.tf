resource "google_compute_subnetwork" "public-subnet" {
  name          = "${local.pre}-pub-net"
  ip_cidr_range = "${var.public_subnet_cidr}"
  network       = "${google_compute_network.vpc.self_link}"


  private_ip_google_access = false
}

resource "google_compute_subnetwork" "private-subnet" {
  name          = "${local.pre}-pri-net"
  ip_cidr_range = "${var.private_subnet_cidr}"
  network       = "${google_compute_network.vpc.self_link}"

  private_ip_google_access = false
}


output "private_subnet-out-self-link" {
  value = "${google_compute_subnetwork.private-subnet.self_link}"
}
output "subnetwork_private_cidr_range-out" {
  value = "${google_compute_subnetwork.private-subnet.ip_cidr_range}"

}
output "subnetwork_private_gateway_address-out" {
  value = "${google_compute_subnetwork.private-subnet.gateway_address}"

}

output "public-subnet_self_link-out-self-link" {
  value = "${google_compute_subnetwork.public-subnet.self_link}"
}
output "subnetwork_public_cidr_range-out" {
  value = "${google_compute_subnetwork.public-subnet.ip_cidr_range}"

}
output "subnetwork_public_gateway_address-out" {
  value = "${google_compute_subnetwork.public-subnet.gateway_address}"

}