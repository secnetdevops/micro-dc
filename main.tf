variable "micro_dc_host" {
  type    = string
  default = "micro.dc.host"
}

variable "micro_dc_user" {
  type    = string
  default = "ubuntu"
}

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
