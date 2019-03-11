resource "google_compute_network" "vpc" {
  name                    = "${local.pre}-vpc"
  auto_create_subnetworks = "false"
  routing_mode            = "REGIONAL"
}

output "network-out-self-link" {
  value = "${google_compute_network.vpc.self_link}"
}
output "network_gateway_ipv4-out" {
  value = "${google_compute_network.vpc.gateway_ipv4}"

}