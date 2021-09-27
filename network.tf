resource "libvirt_network" "vrack" {
  name      = "${var.vrack_network_name}"
  mode      = "none"
  addresses = [ "${var.vrack_ip_range}" ]
  bridge    = "${var.vrack_network_bridge}"
}
