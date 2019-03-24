resource "google_compute_network" "vpc" {
  name        = "${local.pre}-vpc"
  description = "${local.pre}-vpc"

  auto_create_subnetworks = "false"
  routing_mode            = "REGIONAL"
}

resource "google_compute_router" "vpc-router" {
  name        = "${local.pre}-vpc-router"
  description = "${local.pre}-vpc-router"

  network = "${google_compute_network.vpc.self_link}"

  bgp {
    asn            = 65022
    advertise_mode = "DEFAULT"
  }
}

resource "google_compute_router_nat" "vpc-router-nat" {
  name = "${local.pre}-vpc-router-nat"

  router                             = "${google_compute_router.vpc-router.name}"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name = "${google_compute_subnetwork.mgmt-subnet.self_link}"

    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  subnetwork {
    name = "${google_compute_subnetwork.private-subnet.self_link}"

    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  subnetwork {
    name = "${google_compute_subnetwork.public-subnet.self_link}"

    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_compute_route" "route_vpc_to_internet" {
  name        = "${local.pre}-route-vpc-to-internet"
  description = "${local.pre}-route-vpc-to-internet"

  network          = "${google_compute_network.vpc.self_link}"
  dest_range       = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"

  priority = 999
  
  # the tags that this route applies to
  tags = ["node"]
}

# resource "google_compute_route" "route_back_kubespray_services" {
#   name        = "${local.pre}-route-vpc-to-internet"
#   description = "${local.pre}-route-vpc-to-internet"

#   network          = "${google_compute_network.vpc.self_link}"
#   dest_range       = "10.233.0.0/18"
#   next_hop_instance =
#   priority = 999

#   # the tags that this route applies to
#   tags = ["node"]
# }

# resource "google_compute_route" "route_back_kubespray_pods" {
#   name        = "${local.pre}-route-vpc-to-internet"
#   description = "${local.pre}-route-vpc-to-internet"

#   network          = "${google_compute_network.vpc.self_link}"
#   dest_range       = "10.233.64.0/18"
#   next_hop_gateway = 

#   priority = 999

#   # the tags that this route applies to
#   tags = ["node"]
# }

# =================================================================================
# ========================   output   =============================================
# =================================================================================
output "network-out-self-link" {
  value = "${google_compute_network.vpc.self_link}"
}

output "network_gateway_ipv4-out" {
  value = "${google_compute_network.vpc.gateway_ipv4}"
}
