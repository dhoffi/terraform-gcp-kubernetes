# # frontend of a gcp load-balancer is a forwarding rule
# resource "google_compute_forwarding_rule" "lb-external-forwarding-rule" {
#   description           = "load-balancer for external internet traffic"
#   name                  = "${local.pre}-lb-external-forwarding-rule"
#   target                = "${google_compute_target_pool.workers-target-pool.self_link}"
#   load_balancing_scheme = "EXTERNAL"
#   port_range            = "${var.service_port}"
# }

# # external facing load-balancer always goes with a firewall-rule
# resource "google_compute_firewall" "lb-external-firewall" {
#   name = "${local.pre}-lb-external-firewall"

#   allow {
#     protocol = "tcp"
#     ports    = [
#       "80", "8080"
#     ]
#   }

#   source_ranges = ["0.0.0.0/0"]
#   target_tags   = ["${var.dest}-${var.env}-worker"]
# }

# frontend of a gcp load-balancer is a forwarding rule
resource "google_compute_forwarding_rule" "lb-internal-masters-forwarding-rule" {
  description           = "load-balancer for gcp region internal traffic"
  name                  = "${local.pre}-lb-internal-masters-forwarding-rule"

  # only for INTERNAL lbs
  # if changing, also check matching firewall ports!
    ports = [
      "22",   # ssh
      "80",   # http
      "443",  # https
      "8080", # http-proxy
    ]

  # # for EXTERNAL lb target is used
  # target                = "${google_compute_target_pool.masters-target-pool.self_link}"
  # for INTERNAL lb backend_service is used
  backend_service       = "${google_compute_region_backend_service.masters-backend-service.self_link}"
  load_balancing_scheme = "INTERNAL"

  # only for INTERNAL lbs
  subnetwork = "${google_compute_subnetwork.private-subnet.self_link}"

  # port_range            = "64430-64439", # Kkubernetes API server
}

# it's wise to also give internal load-balancers firewall-rules
resource "google_compute_firewall" "lb-internal-basics-firewall" {
  name = "${local.pre}-lb-internal-basics-firewall"
  network = "${google_compute_network.vpc.self_link}"

  allow {
    protocol = "tcp"

    ports = [
      "22",   # ssh
      "80",   # http
      "443",  # https
      "8080", # http-proxy
    ]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.dest}-${var.env}-master", "${var.dest}-${var.env}-worker"]
}

resource "google_compute_firewall" "lb-internal-masters-firewall" {
  name = "${local.pre}-lb-internal-masters-firewall"
  network = "${google_compute_network.vpc.self_link}"

  allow {
    protocol = "tcp"

    ports = [
      "64430-64439", # kubernetes API server
      "2379-2380",   # etcd server client API
      "10250",       # Kubelet API
      "10251",       # kube-scheduler
      "10252",       # kube-controler-manager
    ]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.dest}-${var.env}-master"]
}

resource "google_compute_firewall" "lb-internal-workers-firewall" {
  name = "${local.pre}-lb-internal-workers-firewall"
  network = "${google_compute_network.vpc.self_link}"

  allow {
    protocol = "tcp"

    ports = [
      "10250",       # Kubelet API
      "30000-32767", # NodePort Services Default range
    ]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.dest}-${var.env}-worker"]
}
