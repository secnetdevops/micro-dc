variable "vrack_network_name" {
  type    = string
  default = "vrack"
}

variable "vrack_ip_range" {
  type    = string
  default = "172.30.0.0/16"
}

variable "public_libvirt_bridge" {
  type    = string
  default = "br0"
}

resource "libvirt_network" "network" {
  name      = "${var.vrack_network_name}"
  mode      = "none"
  domain    = "vrack.local"
  addresses = [ "${var.vrack_ip_range}" ]
  bridge    = "vrack_br0"

  dns {
    enabled = true
    local_only = true
  }

}