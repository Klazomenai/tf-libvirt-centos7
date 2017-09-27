# Overview
Proof of Concept for Terraform working with Libvirt. Host and guest both Centos 7. The only config of the guest is to generte some ssh keys and jump on the host to prove POC.

 - Example based on https://github.com/dmacvicar/terraform-provider-libvirt. 
 - `terraform-provider-libvirt` module built with go1.9.
 - Host built with CentOS-7-x86_64-DVD-1708.iso
 - Guest built with CentOS-7-x86_64-GenericCloud-1707.qcow2

# Known issues/todos
## SELinux
 - Sort out proper security conexts and avoid needing to turn off SELinux. Without setting enforce to zero, you will get permission issues when with libvirt and sockets. For now, sad panda says:
```sh
sudo setenforce 0
```

# Pre-requisites
These pre-requisites are based on the below downloaded images. I have tried to start everything from ground zero (i.e. ISO install).

 - Spin up a fresh local install of [CentOS-7-x86_64-DVD-1708.iso](http://mirrors.coreix.net/centos/7.4.1708/isos/x86_64/CentOS-7-x86_64-DVD-1708.iso) from a [pen drive](https://wiki.centos.org/HowTos/InstallFromUSBkey).

```sh
sudo yum -y update
sudo yum -y install git gcc # Required for 'go get'
sudo yum -y install virt-manager # Cheating GUI for libvirt 
```
For other GUI based managers https://libvirt.org/apps.html#desktop

 - Download and install [golang](https://golang.org/dl/)

# Install
 - Fetch, build and install the libvirt Terraform module
```sh
go get github.com/dmacvicar/terraform-provider-libvirt
```

 - Confirm installation worked
```sh
ls $GOPATH/bin
```

 - Define terraform-provider-libvirt as an available provider in `~/.terraformrc`:
```sh
providers {
 libvirt = "$GOPATH/bin/terraform-provider-libvirt"
}
```

 - Configure libvirtd virtualisation daemon and check it is working
``` sh
sudo yum -y install libvirt-daemon-system
```

 - Add libvirt user access to the socket under: /etc/libvirt/libvirtd.conf
```sh
unix_sock_group = "libvirt"
systemctl restart libvirtd
# Check libvirtd is happy and running
systemctl status libvirtd
```

 - The desired $USER should be added to libvirt under /etc/group. Log out and back in again for $USER to take new permissions, otherwise you will see: `Message='Failed to connect socket to '/var/run/libvirt/libvirt-sock': Permission denied')`

- Storage pool is required, instructions from [here](https://github.com/simon3z/virt-deploy/issues/8#issuecomment-73111541)
```sh
sudo virsh pool-define /dev/stdin <<EOF
<pool type='dir'>
  <name>default</name>
  <target>
    <path>/var/lib/libvirt/images</path>
  </target>
</pool>
EOF
sudo virsh pool-start default
sudo virsh pool-autostart default
```

- Pull [qcow2](https://cloud.centos.org/centos/7/images/) image to /tmp
```sh
curl -o /tmp/CentOS-7-x86_64-GenericCloud-1707.qcow2 https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-1707.qcow2
```

- [Inject some basics](http://ask.xmodulo.com/mount-qcow2-disk-image-linux.html) into the qcow2 image to allow ssh-ing to our guest. This is the time for packer, but for now, lets fudge a hack. I had no luck with the libguestfs (guestmount) method, however, once I installed the [kernel requirements and packages](http://lampros.chaidas.com/index.php?controller=post&action=view&id_post=96), I was able to get the qemu-nbd method to work.
```sh
sudo rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
sudo yum -y --enablerepo=elrepo-kernel list available kernel-lt
sudo yum -y --enablerepo=elrepo-kernel install kernel-lt
# Reboot and pick new kernel
```

 - Mount our qcow2 image for injection of ssh keys
```sh
sudo yum -y install qemu-img 
sudo modprobe nbd max_part=8
sudo qemu-nbd --connect=/dev/nbd0 /home/tudorg/Downloads/CentOS-7-x86_64-GenericCloud-1707.qcow2
sudo fdisk /dev/nbd0 -l # Check
sudo mount /dev/nbd0p1 /mnt
sudo mkdir /mnt/root/.ssh/
sudo chmod 600 /mnt/root/.ssh/
```

 - Generate some keys
```sh
ssh-keygen # Pick the defaults
```

 - Dump the new keys on the guest. Cat into the mounted filesystem only works as root. Needs investigation, for now drop into root.
```sh
sudo -i
cat /home/<<Insert your user here>>/.ssh/id_rsa.pub >> /mnt/root/.ssh/authorized_keys
exit
```
 - Allow root login for sshd
For now allow root, in the future there should be another bootstrap/deploy user
```sh
sudo sed -i 's/^#PermitRootLogin yes/PermitRootLogin yes/' /mnt/etc/ssh/sshd_config
```

 - Keys only
```sh
sudo sed -i 's///' /mnt/etc/ssh/sshd_config
PasswordAuthentication yes
```

 - Unmount and disconnect
```sh
sudo umount /mnt
sudo qemu-nbd --disconnect /dev/nbd0 
```

# Start the guest
 - Prep is done, let Terraform take over
```sh
sudo setenforce 0 # Only until security contexts are resolved
terraform init
terraform plan
terraform apply
```

At the end of `terraform apply` the output should be the IP address of the new guest. Ssh to confirm the host has come up and is sane.
