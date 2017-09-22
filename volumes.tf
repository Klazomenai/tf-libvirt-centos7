resource "libvirt_volume" "centos7-qcow2" {
  name = "centos7-qcow2"
  source = "/tmp/CentOS-7-x86_64-GenericCloud-1707.qcow2"
}

resource "libvirt_volume" "vol-centos7-qcow2" {
  name = "vol-centos7-qcow2"
  base_volume_id = "${libvirt_volume.centos7-qcow2.id}"
}
