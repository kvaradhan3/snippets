#! /bin/sh


MEDIA=CentOS-7-x86_64-Minimal-1810.iso
VERSION=`VBoxManage --version | sed 's/r/-/'`
EXTPACK='Oracle VM VirtualBox Extension Pack'

wget http://mirrors.ocf.berkeley.edu/centos/7.6.1810/isos/x86_64/$MEDIA

#  2. For remote desktop functionality, fetch and install VirtualBox extensions.
if VBoxManage list extpacks | grep "$EXTPACK" >/dev/null 2>&1 ; then
    : ok
else
    vERSION=$(echo $VERSION | sed 's/-.*//`)
    EXTPACK=$(echo $EXTPACK | sed 's/ /_/g')
    REPO=download.virtualbox.org/virtualbox
    wget http://$REPO/$vERSION/$EXTPACK-$VERSION.vbox-extpack
    sudo VBoxManage extpack install ./$EXTPACK-$VERSION.vbox-extpack
fi
: Verify that the Extension Pack is successfully installed
VBoxManage list extpacks 

#  3. Create the VM itself
VM="centos-7"
VBoxManage createvm --name $VM --register
VBoxManage modifyvm $VM --memory 2048 --acpi on --boot1 dvd
VBoxManage modifyvm $VM --usbxhci on

: create the network.  Here, we can create a bridged network as:
# VBoxManage modifyvm $VM --nic1 bridged --bridgeadapter1 en0
: that en0 adaptor is an adaptor on the local host.

#     For vagrant VMs, we need it to be NAT based, else the VM cannot be
#     generic and migratable.

VBoxManage modifyvm $VM --nic1 nat
VBoxManage modifyvm $VM --natpf1 "inbound-ssh,tcp,,2222,,22"
VBoxManage modifyvm $VM  --ostype Linux

 # 4. Now create the disk and attach it.
VBoxManage createhd --filename ./$VM.vdi --size 1048576 # GiB
VBoxManage storagectl $VM --name "SATA Controller" --add sata
VBoxManage storageattach $VM --storagectl "SATA Controller" --port 0 \
                             --device 0 --type hdd --medium ./$VM.vdi
VBoxManage storageattach $VM --storagectl "SATA Controller" --port 1 \
                             --device 0 --type dvddrive --medium ./$MEDIA

#  5. Start the VM and attach to it
#     [https://xmodulo.com/how-to-create-and-start-virtualbox-vm-without-gui.html]

VBoxManage modifyvm $VM --vrde on --vrdeproperty "TCP/Ports=33389"
VBoxHeadless --startvm $VM </dev/null >/dev/null 2>&1 &
rdesktop -f localhost:33389
