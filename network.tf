resource "libvirt_network" "tf" {
   name = "tf"
   domain = "tf.local"
   mode = "nat"
   addresses = ["10.0.100.0/24"]
}
