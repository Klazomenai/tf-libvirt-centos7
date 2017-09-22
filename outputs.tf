output "Net_0_Address" {
    value = "${libvirt_domain.domain-centos7-qcow2.network_interface.0.addresses.0}"
}
