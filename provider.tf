terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.3"
    }
  }
}
provider "libvirt" {
  uri = "qemu:///system"
}
#provider "libvirt" {
#  alias = "server2"
#  uri   = "qemu+ssh://root@192.168.100.10/system"
#}
resource "libvirt_network" "my_learning_network" {
  name      = "learning"
  autostart = true
  mode      = "nat"
  bridge    = "learningbr"
  domain    = "edu.local"
  addresses = ["192.168.10.0/24"]
  dns {
    enabled = true
    forwarders {
      address = "192.168.122.1"
    }
  }
}

resource "libvirt_volume" "server1-qcow2" {
  name = "server1.qcow2"
  pool = "default"
  #source = "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
  #source = "/mnt/MyFiles/ISO/Cloud-images/CentOS-8-GenericCloud-8.4.2105-20210603.0.x86_64.qcow2"
  source = var.ubuntu18
  format = "qcow2"
}
resource "libvirt_volume" "server2-qcow2" {
  name = "server2.qcow2"
  pool = "default"
  #source = "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
  #source = "/mnt/MyFiles/ISO/Cloud-images/CentOS-8-GenericCloud-8.4.2105-20210603.0.x86_64.qcow2"
  source = var.centOS8
  format = "qcow2"
}

resource "libvirt_volume" "server3-qcow2" {
  name = "server3.qcow2"
  pool = "default"
  #source = "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
  #source = "/mnt/MyFiles/ISO/Cloud-images/CentOS-8-GenericCloud-8.4.2105-20210603.0.x86_64.qcow2"
  source = var.centOS8
  format = "qcow2"
}
data "template_file" "user_data" {
  #template = "${file("${path.module}/cloud_init.cfg")}"
  template = file("./cloud_init.cfg")
}
data "template_file" "network_config" {
  #template = "${file("${path.module}/cloud_init.cfg")}"
  template = file("./server1_network_init.cfg")
}

# Use CloudInit to add the instance
resource "libvirt_cloudinit_disk" "commoninit-server1" {
  name           = "commoninit-server1.iso"
  user_data      = data.template_file.user_data.rendered
  #network_config = data.template_file.network_config.rendered
}
resource "libvirt_cloudinit_disk" "commoninit-server2" {
  name           = "commoninit-server2.iso"
  user_data      = data.template_file.user_data.rendered
}

resource "libvirt_cloudinit_disk" "commoninit-server3" {
  name           = "commoninit-server3.iso"
  user_data      = data.template_file.user_data.rendered
}

# Define KVM domain to create
resource "libvirt_domain" "server1" {
  name   = "server1"
  memory = "2048"
  vcpu   = 2
  #network_interface {
    #network_name = "default"
    #addresses = ["192.168.122.5"]
  #}

  #network_interface {
    #network_name = "practice"
    #addresses=["192.168.0.10"]
  #}

  network_interface {
    network_id     = libvirt_network.my_learning_network.id
    addresses      = ["192.168.10.5"]
    hostname       = "server1"
  }

  disk {
    volume_id = libvirt_volume.server1-qcow2.id
  }
  cloudinit = libvirt_cloudinit_disk.commoninit-server1.id

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}

# Define KVM domain to create
resource "libvirt_domain" "server2" {
  name   = "server2"
  memory = "2048"
  vcpu   = 2

  network_interface {
    network_id     = libvirt_network.my_learning_network.id
    addresses      = ["192.168.10.10"]
    hostname       = "server2"
  }

  disk {
    volume_id = libvirt_volume.server2-qcow2.id
  }
  cloudinit = libvirt_cloudinit_disk.commoninit-server2.id

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }
  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}
//creating KVM domain - server3
resource "libvirt_domain" "server3" {
  name   = "server3"
  memory = "2048"
  vcpu   = 2

  disk {
    volume_id = libvirt_volume.server3-qcow2.id
  }

  network_interface {
    network_id     = libvirt_network.my_learning_network.id
    addresses      = ["192.168.10.15"]
    hostname       = "server3"
  }
  cloudinit = libvirt_cloudinit_disk.commoninit-server3.id

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }
  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
  provisioner "local-exec" {
    command = "echo third"
  }
}

output "ip1" {
  value = libvirt_domain.server1.network_interface.0.addresses.0
}
output "ip2" {
  value = libvirt_domain.server2.network_interface.0.addresses.0
}
output "ip3" {
  value = libvirt_domain.server3.network_interface.0.addresses.0
}



