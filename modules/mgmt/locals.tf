locals {
  pre = "${var.dest}-${var.env}"


  # add lables like this: labels = merge(var.default_labels, {labelname = "labelvalue"})
  default_labels = {
    dest = var.dest
    env  = var.env
  }
  default_tags = [var.dest, var.env]
}
