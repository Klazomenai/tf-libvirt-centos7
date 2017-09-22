resource "libvirt_domain" "domain-centos7-qcow2" {
  name = "domain-centos7-qcow2"
  memory = "512"
  vcpu = 1
  network_interface {
    network_name = "tf"
  }
  disk {
    volume_id = "${libvirt_volume.vol-centos7-qcow2.id}"
  }
  graphics {
    type = "spice"
    listen_type = "address"
    autoport = "yes"
  }
}
