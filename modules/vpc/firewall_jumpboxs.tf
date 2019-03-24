resource "google_compute_firewall" "jumpboxs-firewall" {
  name        = "${local.pre}-jumpboxs-firewall"
  description = "${local.pre}-jumpboxs-firewall"

  network = "${google_compute_network.vpc.self_link}"

  allow {
    # enable_logging = true

    protocol = "tcp"
  
    ports = [
      "1-65535"
      # "22",   # ssh
      # "80",   # http
      # "443",  # https
      # "8080", # http-proxy
    ]
  }

  # allow {
  #   protocol = "icmp"
  # }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["jumpbox"]
}
