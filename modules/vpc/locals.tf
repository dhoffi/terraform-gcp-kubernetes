locals {
  pre = "${var.dest}-${var.env}"


  # add labels like this: labels = "${merge(var.default_labels, map("labelname", "labelvalue"))}"
  default_labels = {
    dest = "${var.dest}"
    env  = "${var.env}"

    kubernetes-cluster = "${var.cluster_name}"
  }
  default_tags = ["${var.dest}", "${var.env}", "${var.cluster_name}"]
}
