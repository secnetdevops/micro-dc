terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.6.11"
    }
  }
}

provider "libvirt" {
  uri = "qemu+ssh://${var.micro_dc_user}@${var.micro_dc_host}/system?socket=/var/run/libvirt/libvirt-sock"
}
