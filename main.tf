provider "google" {
  credentials = "${file("${path.module}/${var.PROJECT_ID}_${var.ADMIN_NAME}.json")}"
  project = "${var.PROJECT_ID}"
  region  = "${var.GCP_LOCATION}"
  zone    = "${var.GCP_ZONE}"
}
