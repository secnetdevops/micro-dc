# Micro DC setup
# --------------
variable "micro_dc_host" {
  type    = string
}

variable "micro_dc_user" {
  type    = string
}

variable "micro_dc_gateway" {
  type    = string
}

variable "micro_dc_public_bridge" {
  type    = string
}

# Private network setup (vrack)
# -----------------------------
variable "vrack_network_name" {
  type    = string
  default = "vrack"
}

variable "vrack_network_bridge" {
  type    = string
  default = "vrack"
}

variable "vrack_ip_range" {
  type    = string
  default = "172.30.0.0/16"
}


# # DC storage pool setup
# # ---------------------
# variable "micro_dc_pool_name" {
#   type    = string
#   default = "micro_dc_pool"
# }

# variable "micro_dc_pool_path" {
#   type = string
#   default = "/opt/libvirt/storage-pools/micro_dc_pool"
# }
