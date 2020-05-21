locals {
  pre = "${var.dest}-${var.env}"

  # add tags like this: tags = merge(var.default_tags, {tagname = "tagvalue"})
  default_labels = {
    dest = var.dest
    env  = var.env
  }
  default_tags = [var.dest, var.env]
}
