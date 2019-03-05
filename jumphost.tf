resource "google_compute_instance" "jumphost" {
  name         = "jumphost"
  machine_type = "f1-micro"

  tags = ["jumphost"]

  boot_disk {
    # source      = "${google_compute_disk.jumphost_disk.name}"
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
    auto_delete = true
  }

  network_interface {
    network = "default"

    access_config {
      # ephemeral external ip address
    }
  }

  scheduling {
    preemptible         = false
    on_host_maintenance = "MIGRATE"
    automatic_restart   = true
  }

  metadata {
    sshKeys = "gcpadmin:${file("~/.ssh/gcp_jumphost.pub")}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo \"hello from $$HOST\" > ~/terraform_complete",
    ]

    connection {
      type        = "ssh"
      agent       = false
      user        = "gcpadmin"
      private_key = "${file("~/.ssh/gcp_jumphost")}"
      timeout     = "2m"
    }
  }
}

output "jumphost_ip" {
  value = "${google_compute_instance.jumphost.network_interface.0.access_config.0.nat_ip}"
}
