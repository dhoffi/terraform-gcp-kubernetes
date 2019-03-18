# gcloud compute images list
data "google_compute_image" "jumpbox-image_data" {
  family  = "ubuntu-1604-lts"
  project = "ubuntu-os-cloud"
}

data "google_compute_image" "nodes-image_data" {
  family  = "ubuntu-1604-lts"
  project = "ubuntu-os-cloud"
}
