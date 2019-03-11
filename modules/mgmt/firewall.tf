resource "google_compute_firewall" "jumpboxes-firewall" {
  name = "${local.pre}-jumpboxes-firewall"
  network = "${var.network_self_link}"

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
  target_tags   = ["jumpbox"]
}
# resource "google_compute_firewall" "allow_ssh_hoffi" {
#   name    = "allow-ssh-hoffi"
#   network = "default"

#   allow {
#     protocol = "tcp"
#     ports    = ["22"]
#   }

# #   source_ranges = ["138.68.103.147/32"]
#   source_ranges = ["0.0.0.0/0"]
#   target_tags   = ["ssh"]
# }

# resource "google_compute_firewall" "allow_http" {
#   name    = "allow-http"
#   network = "default"

#   allow {
#     protocol = "tcp"
#     ports    = ["80", "443"]
#   }

#   source_ranges = ["0.0.0.0/0"]
#   target_tags   = ["http"]
# }
