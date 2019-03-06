provider "google" {
  credentials = "${file("GCP_PROJECT_SERVICE_ACCOUNT_FILE")}"
  project = "${var.PROJECT_ID}"
  region  = "${var.GCP_LOCATION}"
  zone    = "${var.GCP_ZONE}"
}
