variable "nodes_count" {
  type    = number
  default = 3
}

variable "admin_ssh_public_key" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEl9ZynVlYBuXm3j9xxBcC7ap4fn+IZw5qLhSk1b1LizSmnvxgCWjrGu8SmEFirMH3xgEYgoyJroR60I4UfkkPGpbk3hbP89C4yOqEaeC6F10yWyA48sFIbyxFOxOPokPwjsn7I2scsuFesKVEm57oX0vGqGIPqT7+SSC2v+cY6QNUTFofSgzPE1d0EZ/2oVraigMcnwFCNcYY60mxNlx10qk3iGa4hcNFFEg+dOgGTM8PQMoXMSHHH+3zTGptxCRecJBzs0ZqJ5nRIyUrdvo2tNCwXcHPtEe0ZsXt/0GwBrywNad6bS/BjJiTOBDin1D2EGGgiWnT1oJlPEDATElKNevwHLbOgH5MrCvM+Ohfr9uFEjk+BCUHO1yGxo8JibcOE0CkD6sTbF0TniR4qqlfNu0KqjYRbdY2t7E/8ZlySDNfki/JCQ3UPEyHKEWXvKc8Fw260OaEpAkg3iHwUBTB2uAzHUoBUk03ZxKhEIq99yIDMFhiSSQMqrXxAZOTMTum1M8gJ1LhNFwogTAhw3wRqnSyxr5b4sBGMebRptraTxqbjZVe8pqNMODFvWH4IJ1gTWZTXsWgQH7wc8fJYPMH+qTvO2FIKCz4bPyCMNp8FCfmaA2vnwOXm3kj2KVkACrGL+wXI/tSWonDnx4EjcRE5dNtII2W4fbSMFVAlmT+Fw=="
}

resource "libvirt_pool" "storage" {
  name = "elasticsearch-lab"
  type = "dir"
  path = "/opt/libvirt/storage-pools/elasticsearch-lab"
}

resource "libvirt_cloudinit_disk" "cloudinit" {
  name           = "es-${count.index+1}-cloudinit.iso"
  pool           = libvirt_pool.storage.name
  user_data      = <<-EOF
#cloud-config
hostname: es-${count.index+1}
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin
    home: /home/ubuntu
    shell: /bin/bash
    lock_passwd: false
    ssh-authorized-keys:
      - ${var.admin_ssh_public_key}
ssh_pwauth: false
disable_root: true
EOF

  network_config   = <<-EOF
version: 2
ethernets:
    ens3:
      dhcp4: false
      dhcp6: false
      addresses:
      - ${cidrhost(var.es_vrack_subnet, count.index + 11)}/${regex(".*/(.*)", var.es_vrack_subnet)[0]}
      nameservers:
        addresses: [ 8.8.8.8 ]
      routes:
      - to: 0.0.0.0/0
        via: ${cidrhost(var.vrack_ip_range, count.index+1)}
        on-link: true
EOF
  #user_data      = data.template_file.user_data.rendered
  #network_config = data.template_file.network_config.rendered

  count          = var.nodes_count
}

resource "libvirt_volume" "volume" {
  name           = "es-${count.index+1}-volume"
  base_volume_id = "/var/lib/libvirt/images/ubuntu20.04"
  format         = "qcow2"
  pool           = libvirt_pool.storage.name
  count          = var.nodes_count
}

resource "libvirt_domain" "domain" {
  name   = "es-${count.index+1}"
  memory = 4096
  vcpu   = 2

  cloudinit = element(libvirt_cloudinit_disk.cloudinit.*.id, count.index)
  
  disk {
    volume_id = element(libvirt_volume.volume.*.id, count.index)
  }

  # -- connect VPS to internal network
  network_interface {
    network_name   = "${var.vrack_network_name}"
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "virtio"
    source_path = "/dev/pts/4"
  }

#   provisioner "remote-exec" {
#     inline = [
#       "echo TEST?",
#       "echo Done!"
#     ]

#     connection {
#       bastion_host = var.micro_dc_host
#       bastion_user = var.micro_dc_user

#       host        = "${cidrhost(var.es_vrack_subnet, count.index + 11)}"
#       type        = "ssh"
#       user        = "ubuntu"
#       private_key = file("${var.admin_ssh_private_key}")
#       timeout     = "2m"
#     }
#   }

  count = var.nodes_count
}

output "hosts_ip_addresses" {
  value = {
    for index, instance in libvirt_domain.domain:
      instance.name => cidrhost(var.es_vrack_subnet, index+11)
  }
}
