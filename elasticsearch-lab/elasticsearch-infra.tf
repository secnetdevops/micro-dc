variable "ssh_public_key" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDKQtDa2i34Tbi5bxNZS1Q82Fee6kosqQiYs3Nv9X1qQSC0nUm8E07UFJDl37b2Bf/MY5Qe0itSvxgTn7DhSx7qbMzM2yRi15Yxn0Qn5MfGPRiJp1v/GE1vMg01vbyN/6yK+7ki6ef3vVzi1p97IVpgAe9F8ayQWD93bLWmCwiOtGcm4Ab4REwc69uxm78CyUwxg4q4O3AiUOfyqi9b7DlofPAfalmzIdW7yFKgqPux40uui636Eq5S1QsZ4+nUqdZyM9vKnOjcUCObcaWtCeMVvQT+3eMTDtDpTK6z0IiHjWfWuqBTo8waF6toPbdkawpwGKzEOw+8IrdPHRV+FM40a+ndMPE5Bu66P/wcw9Z/yuJ8ucHRe6SleLdiS95FUe3H9qHco1s4BamSQJnjuvFb7XwLXnZtXn8ObRVlOKcKNKe53Z7v2vBJGGkw3rSkNN1eTGj8daEx8a8A+y9o2TOabZjKnjSm7em+RJ3gZwczJWfQl71vXzALdkUkgV3l7R+4ullKSZbZk9igmVJt/Wle1fY3tO/rgt5prWknLZ7KkGlSUIg6rvs7H6oHE879MNY/eCB5xUdC3wbxANQGIWe/kr1qaLrKmoYDNzosiS/aaceWoUF2lhtA0t+nbb3hKBCSFRgMa/ZIe2RRHcRNFQJL1dvUyYR4J+k4JDOOqnjDvw=="
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
      - ${var.ssh_public_key}
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
        - 172.30.80.${count.index+1}/16
      nameservers:
        addresses: [ 8.8.8.8 ]
EOF
  #user_data      = data.template_file.user_data.rendered
  #network_config = data.template_file.network_config.rendered

  count          = 3
}

resource "libvirt_volume" "volume" {
  name           = "es-${count.index+1}-volume"
  base_volume_id = "/var/lib/libvirt/images/ubuntu20.04"
  format         = "qcow2"
  pool           = libvirt_pool.storage.name
  count          = 3
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

  count         = 3
}


