locals {
  pre = "${var.dest}-${var.env}"


  # add tags like this: tags = "${merge(var.default_tags, map("tagname", "tagvalue"))}"
  default_labels = {
    dest = "${var.dest}"
    env  = "${var.env}"

    kubernetes-cluster = "${var.cluster_name}"
  }
  default_tags = ["${var.dest}", "${var.env}", "${var.cluster_name}"]
}
