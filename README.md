# Virtual Micro DC
Create a Virtual Data Center using KVM, QEMU, Libvirt, Terraform and SoYouStart Dedicated Server.

## Order SoYouStart Dedicated Server

> Are you looking for an affordable yet powerful machine? So you Start has designed a rental line of dedicated servers perfect for startups and small businesses looking for power and flexibility. The reliability of the So you Start dedicated servers would be an undeniable asset to your busines.  
https://www.soyoustart.com/en/essential-servers/

## Initialize Micro DC

### Public bridge configuration (ubuntu20.04)

    $ /etc/netplan/networking.yaml
    # This file describes the network interfaces available on your system
    # For more information, see netplan(5).

    network:
    version: 2
    renderer: networkd

    ethernets:
        eno1:
        dhcp4: false
        dhcp6: false

    bridges:
        br0:
        interfaces: [eno1]
        addresses: [<public_IP>/24]
        gateway4: <public_gateway_IP>
        mtu: 1500
        nameservers:
            addresses: [213.186.33.99]
        parameters:
            stp: true
            forward-delay: 4
        dhcp4: no
        dhcp6: no

### Create env file with DC setup

    $ cat my-dc.env
    ### Required variables
    export TF_VAR_micro_dc_host="1.1.1.1"
    export TF_VAR_micro_dc_user="ubuntu"
    export TF_VAR_micro_dc_gateway="1.1.1.254"
    export TF_VAR_micro_dc_public_bridge="br0"
    export TF_VAR_admin_ssh_private_key="/private/ssh/key/id_rsa"

    ### Optional variables
    export TF_VAR_vrack_network_name="vrack"
    export TF_VAR_vrack_ip_range="172.30.0.0/16"
    export TF_VAR_vrack_network_bridge="vrack_br0"

### Run terraform commands
    $ source my-dc.env
    $ terraform init
    $ terraform plan
    $ terraform apply

## Build infrastructure for Elasticsearch LAB

### Run terraform commands

    $ cd elasticsearch-lab
    $ terraform init 
    $ terraform plan
    $ terraform apply

## Connecting to hosts in vrack network through a Bastion Host with SSH

    $ cat ~/.ssh/config
    Host 172.30.*
      User ubuntu
      TCPKeepAlive yes
      StrictHostKeyChecking no
      ProxyCommand ssh -W %h:%p ${TF_VAR_micro_dc_user}@${TF_VAR_micro_dc_host}
