# Creating the centos-7 virtualbox VM
    References:
    - [<https://linoxide.com/linux-how-to/setup-centos-7-vagrant-base-box-virtualbox/>]
    - [<https://nakkaya.com/2012/08/30/create-manage-virtualBox-vms-from-the-command-line/>]
    - [<https://www.centos.org/download/>]
    - [<http://mirrors.ocf.berkeley.edu/centos/7.6.1810/isos/x86_64/CentOS-7-x86_64-Minimal-1810.iso>]

1.  pre-initialization
    ```
    % MEDIA=${MEDIA:-CentOS-7-x86_64-Minimal-1810.iso}
    % VM=${VM:-"centos-7"}
    ```

2.  Download a minimal centos version.

    ```
    % wget http://mirrors.ocf.berkeley.edu/centos/7.6.1810/isos/x86_64/$MEDIA
    ```

3.  For remote desktop functionality, fetch and install VirtualBox
    extensions.
    
    ```
    % VBVERSION=5.2.26-128414
    % wget http://download.virtualbox.org/virtualbox/$VBVERSION/Oracle_VM_VirtualBox_Extension_Pack-4.2.12.vbox-extpack
    % sudo VBoxManage extpack install ./Oracle_VM_VirtualBox_Extension_Pack-4.2.12-84980.vbox-extpack
    % : Verify that the Extension Pack is successfully installed, by using the following command.
    % VBoxManage list extpacks
    ```

4.  Create the VM itself

    ```
    % VBoxManage createvm --name $VM --register
    % VBoxManage modifyvm $VM --memory 2048 --acpi on --boot1 dvd
    % VBoxManage modifyvm $VM --usbxhci on

    % : create the network.  Here, we can create a bridged network as:
    # VBoxManage modifyvm $VM --nic1 bridged --bridgeadapter1 en0
    % : that en0 adaptor is an adaptor on the local host.
    ```

    For vagrant VMs, we need it to be NAT based, else the VM cannot be
    generic and migratable.

    ```
    % VBoxManage modifyvm $VM --nic1 nat
    # VBoxManage modifyvm $VM --macaddress1 XXXXXXXXXXXX
    % VBoxManage modifyvm $VM --natpf1 "inbound-ssh,tcp,,2222,,22"
    % VBoxManage modifyvm $VM --ostype Linux
    ```
5.  Now create the disk and attach it.

    ```
    % VBoxManage createhd --filename ./$VM.vdi --size 1048576 # GiB
    % VBoxManage storagectl $VM --name "SATA Controller" --add sata
    % VBoxManage storageattach $VM --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium ./$VM.vdi
    % VBoxManage storageattach $VM --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium ./$MEDIA
    ```

6.  Start the VM and attach to it
    [<https://xmodulo.com/how-to-create-and-start-virtualbox-vm-without-gui.html>]
    ```
     % VBoxManage modifyvm $VM --vrde on --vrdeproperty "TCP/Ports=33389"
     % VBoxHeadless --startvm $VM
     % rdesktop -f localhost:33389
    ```
    
7.  Install GuestAdditions for ease.
    
    ```
    % VBoxManage storageattach $VM --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium /usr/share/virtualbox/VBoxGuestAdditions.iso
    ```
    
    On the mac, the GuestAdditions are in
    `/Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso`
    so we have

    ```
    % VBoxManage storageattach $VM --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium /Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso
    ```
    On the VM,
     
    ```
    $ yum install -y bzip2 tar
    $ mkdir /mnt/dvd
    $ mount -t iso9660 -o ro /dev/dvd /mnt/dvd
    $ cd /mnt/dvd
    $ ./VBoxLinuxAdditions.run
    $ cd /
    $ umount /mnt/dvd
    $ eject
    ```

    Finally, we detach it on the VBox, as:
    ```
    % VBoxManage storageattach $VM --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium none
    ```

8.  For safety, Take a snapshot, or query

    ```
    % VBoxManage snapshot $VM take <image-name>
    or
    % VBoxManage snapshot $VM restore <image-name>
    % VBoxManage guestproperty enumerate $VM
    ```
# Building a custom Centos-7 box

- **Why did I need to do this?**
    
    I needed to create a centos/7 VM to play with some of our work
    elements.  The catch is that I also need a fair amount of storage
    in a working partition.  The default centos/7 image from
    <https://app.vagrantup.com/centos/boxes/7/> only provides for 40GiB.
    
    Usually, this is plenty.  Moreover, if you need more storage, you
    can always mount it from the host and do your work in that mounted
    space.  There are many ways of mounting it, for instance [nfs].
    You can also, if you are using virtual box as a provider use their
    native mount:  .  The difficulty is that I needed to create/pull
    large number of docker containers.  This meant that I need
    /var/lib/docker to have a lot of space (around 60-80G).  docker
    will not create overlay containers on NFS or vbox mounted file
    systems [references].
    
    So, I would have to find a way to increase the size of my
    centos/7 box's root file system.  Since the default centos/7
    images present as a VMDK, it is not easily extensible.  It is
    possible to convert the first convert the VMDK to a VMI, resize
    the VMI, attach it back to the original image.  This has to be
    done without the vagrant box getting corrupted.  You also need to
    boot the image using a liveCD, resize the partition using gparted,
    and then use the resized box.
    
    It was easier build a new box with the right-sized partition.
    
    [Note to self:  This site:
    <https://github.com/sprotheroe/vagrant-disksize>  looks promising
    and may be worth a shot]
    
    In the previous section, we built
- **How did I go about doing this?**
    This site,
    <https://linoxide.com/linux-how-to/setup-centos-7-vagrant-base-box-virtualbox/>
    gives a good overview of how to create the centos-7 VM image and a
    box from it.  Skip steps 1 and 2, we did the virtual box image of
    centos-7 earlier, and we assume vagrant.
    1.  start the centos-7 we created earlier.
    2.  check that the interface is up.
        ```
        % ifup enp3s0
        ```
    3.  Add your basic tools.
        ```
        % yum install -y openssh-clients wget ntp curl
        % yum install -y net-tools lsof
        % yum install -y kernel-devel kernel-headers
        % yum install -y tcpdump traceroute
        % yum install -y git epel-release
        % yum clean all
        ```
    4.  Fix up the services we need, adjust time.
        ```
        % systemctl enable ntpd.service
        % systemctl stop ntpd
        % ntpdate time.nist.gov
        % systemctl start ntpd
        % systemctl start sshd
        % systemctl stop iptables
        % systemctl stop ip6tables
        ```
    5.  Dork selinux (duh!)
        ```
        % sed -i -e 's/^SELINUX=.\*/SELINUX=permissive/' /etc/selinux/config
        ```
    6.  Fix up for vagrant
        ```
        % useradd vagrant
        % mkdir -m 0700 -p *home/vagrant*.ssh
        % cd *home/vagrant*.ssh
        ```
        - check if you can simply download, else, add --no-check-certificate.
        ```
        % wget [--no-check-certificate] https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub
        % mv vagrant.pub authorized_keys
        % chmod 600 authorized_keys
        % chown -R vagrant:vagrant .
        % echo "vagrant ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vagrant
        ```        
    7.  Now clean up.  We already did a yum clean all.  If you
        downloaded any more packages, remember to do that again.
        ```
        % rm -rf /tmp/\* /var/log/wtmp /var/log/btmp
        % history -c
        ```
    8.  Done.  Shut the VM down and do to the next step, to create the box.
        ```
        % shutdown -h now
        ```
- **Now create the box**
  ```
  % vagrant package --output centos-7.box --base centos-7
  ==> centos-7: Clearing any previously set forwarded ports...
  ==> centos-7: Exporting VM...
  ==> centos-7: Compressing package to: /Users/kvaradhan/centos-7.box
    
  % vagrant box add centos-7 centos-7.box
  ==> box: Box file was not detected as metadata. Adding it directly...
  ==> box: Adding box 'centos-7:' (v0) for provider:
      box: Unpacking necessary files from: /Users/kvaradhan/centos-7.box
  ==> box: Successfully added box 'centos-7:' (v0) for 'virtualbox'!
  ```
# Increasing the size of a vagrant VM storage

[<https://serverfault.com/questions/420070/increasing-disk-size-of-linux-guest-in-vmware>]
[<http://www.systemadmin.me.uk/?p=434>]

1.  Get and install the vagrant-disksize plugin.
    ```
    % vagrant plugin install vagrant-disksize
    ```
2.  Create your vagrant file, as
    ```
    % vagrant init centos-7
    A `Vagrantfile` has been placed in this directory. You are now
    ready to `vagrant up` your first virtual environment! Please read
    the comments in the Vagrantfile as well as documentation on
    `vagrantup.com` for more information on using Vagrant.
    ```
3.  Add the following into your Vagrant file:
    ```
    % diff -c Vagrantfile~ Vagrantfile
    *** Vagrantfile~	2019-03-08 22:08:11.000000000 -0800
    --- Vagrantfile	2019-03-08 22:07:59.000000000 -0800
    ***************
    *** 13,18 ****
    --- 13,19 ----
        # Every Vagrant development environment requires a box. You can search for
        # boxes at https://vagrantcloud.com/search.
        config.vm.box = "centos-7"
    +   config.disksize.size = "2048GB"
    
        # Disable automatic box update checking. If you disable this, then
        # boxes will only be checked for updates when the user runs
    ```

4.  start the VM
    ```
    % vagrant up
    Bringing machine 'default' up with 'virtualbox' provider...
    ==> default: Importing base box 'centos-7'...
    ==> default: Matching MAC address for NAT networking...
    ==> default: Setting the name of the VM: tmp_default_1552111930586_7739
    ==> default: Clearing any previously set network interfaces...
    ==> default: Preparing network interfaces based on configuration...
        default: Adapter 1: nat
    ==> default: Forwarding ports...
        default: 22 (guest) => 2222 (host) (adapter 1)
    ==> default: Resized disk: old 1133952 MB, req 2097152 MB, new 2097152 MB
    ==> default: You may need to resize the filesystem from within the guest.
    ==> default: Booting VM...
    ==> default: Waiting for machine to boot. This may take a few minutes...
        default: SSH address: 127.0.0.1:2222
        default: SSH username: vagrant
        default: SSH auth method: private key
        default:
        default: Vagrant insecure key detected. Vagrant will automatically replace
        default: this with a newly generated keypair for better security.
        default:
        default: Inserting generated public key within guest...
        default: Removing insecure key from the guest if it's present...
        default: Key inserted! Disconnecting and reconnecting using new SSH key...
    ==> default: Machine booted and ready!
    ```
5.  Now login and resize the partition.
    ```
    % vagrant ssh
    vagrant$ exec sudo -s
    vagrant# parted
    GNU Parted 3.1
    Using /dev/sda
    Welcome to GNU Parted! Type 'help' to view a list of commands.
    (parted) print
    Model: ATA VBOX HARDDISK (scsi)
    Disk /dev/sda: 2199GB
    Sector size (logical/physical): 512B/512B
    Partition Table: msdos
    Disk Flags:
    
    Number  Start   End     Size    Type     File system  Flags
     1      1049kB  1075MB  1074MB  primary  xfs          boot
     2      1075MB  1189GB  1188GB  primary               lvm
    
    (parted) mkpart
    Partition type?  primary/extended? primary
    File system type?  [ext2]? ?
    parted: invalid token: ?
    File system type?  [ext2]? 8e
    parted: invalid token: 8e
    File system type?  [ext2]? xfs
    Start? 1189GB                      # end of sda2
    End? 2199GB                        # end of disk, /dev/sda
    (parted) print
    Model: ATA VBOX HARDDISK (scsi)
    Disk /dev/sda: 2199GB
    Sector size (logical/physical): 512B/512B
    Partition Table: msdos
    Disk Flags:
    
    Number  Start   End     Size    Type     File system  Flags
     1      1049kB  1075MB  1074MB  primary  xfs          boot
     2      1075MB  1189GB  1188GB  primary               lvm
     3      1189GB  2199GB  1010GB  primary
    vagrant# pvcreate /dev/sda3
      Physical volume "/dev/sda3" successfully created.
    vagrant# vgdisplay
      -- Volume group --
      VG Name               centos
      System ID
    ...
    vagrant# vgextend centos /dev/sda3
      Volume group "centos" successfully extended
    vagrant# lvextend -l +100%FREE /dev/centos/root
      Size of logical volume centos/root changed from <1.08 TiB (282718 extents) to <2.00 TiB (523518 extents).
      Logical volume centos/root successfully resized.
    vagrant# df -h
    Filesystem               Size  Used Avail Use% Mounted on
    /dev/mapper/centos-root  1.1T  1.5G  1.1T   1% /
    ...
    vagrant# xfs_growfs /dev/mapper/centos-root
    meta-data=/dev/mapper/centos-root isize=512    agcount=4, agsize=72375808 blks
             =                       sectsz=512   attr=2, projid32bit=1
             =                       crc=1        finobt=0 spinodes=0
    data     =                       bsize=4096   blocks=289503232, imaxpct=5
             =                       sunit=0      swidth=0 blks
    naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
    log      =internal               bsize=4096   blocks=141359, version=2
             =                       sectsz=512   sunit=0 blks, lazy-count=1
    realtime =none                   extsz=4096   blocks=0, rtextents=0
    data blocks changed from 289503232 to 536082432
    
    vagrant# df -h
    Filesystem               Size  Used Avail Use% Mounted on
    /dev/mapper/centos-root  2.0T  1.5G  2.0T   1% /
    ...
    ```
6.  Now attach sda3 to the root lvm.
    ```
    vagrant# fdisk -l
    
    Disk /dev/sda: 2199.0 GB, 2199023255552 bytes, 4294967296 sectors
    Units = sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk label type: dos
    Disk identifier: 0x00015905
    
       Device Boot      Start         End      Blocks   Id  System
    /dev/sda1   *        2048     2099199     1048576   83  Linux
    /dev/sda2         2099200  2322333695  1160117248   8e  Linux LVM
    /dev/sda3      2322333696  4294967294   986316799+  8e  Linux LVM
    
    Disk /dev/mapper/centos-root: 1185.8 GB, 1185805238272 bytes, 2316025856 sectors
    Units = sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes

    Disk /dev/mapper/centos-swap: 2147 MB, 2147483648 bytes, 4194304 sectors
    Units = sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes

    vagrant# pvcreate /dev/sda3
      Physical volume "/dev/sda3" successfully created.
    vagrant# vgdisplay
      -- Volume group --
      VG Name               centos
      System ID
    ...

    vagrant# vgextend centos /dev/sda3
      Volume group "centos" successfully extended
    vagrant# lvextend -l +100%FREE /dev/centos/root
      Size of logical volume centos/root changed from <1.08 TiB (282718 extents) to <2.00 TiB (523518 extents).
      Logical volume centos/root successfully resized.
    vagrant# df -h
    Filesystem               Size  Used Avail Use% Mounted on
    /dev/mapper/centos-root  1.1T  1.4G  1.1T   1% /
    ...

    vagrant# : centos uses xfs for its mounts, see below
    vagrant# mount
    ...
    /dev/mapper/centos-root on / type xfs (rw,relatime,seclabel,attr2,inode64,noquota)
    selinuxfs on /sys/fs/selinux type selinuxfs (rw,relatime)
    vagrant# xfs_growfs /dev/mapper/centos-root
    meta-data=/dev/mapper/centos-root isize=512    agcount=4, agsize=72375808 blks
             =                       sectsz=512   attr=2, projid32bit=1
             =                       crc=1        finobt=0 spinodes=0
    data     =                       bsize=4096   blocks=289503232, imaxpct=5
             =                       sunit=0      swidth=0 blks
    naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
    log      =internal               bsize=4096   blocks=141359, version=2
             =                       sectsz=512   sunit=0 blks, lazy-count=1
    realtime =none                   extsz=4096   blocks=0, rtextents=0
    data blocks changed from 289503232 to 536082432

    vagrant# : And now, success?
    vagrant# df -h
    Filesystem               Size  Used Avail Use% Mounted on
    /dev/mapper/centos-root  2.0T  1.4G  2.0T   1% /
    ...
    tmpfs                    496M     0  496M   0% /dev/shm
    tmpfs                    496M  6.7M  489M   2% /run
    tmpfs                    496M     0  496M   0% /sys/fs/cgroup
    /dev/sda1               1014M  162M  853M  16% /boot
    tmpfs                    100M     0  100M   0% /run/user/1000
    ```

# Other notes
```
Hex code (type L to list all codes): L

 0  Empty           24  NEC DOS         81  Minix / old Lin bf  Solaris
 1  FAT12           27  Hidden NTFS Win 82  Linux swap / So c1  DRDOS/sec (FAT-
 2  XENIX root      39  Plan 9          83  Linux           c4  DRDOS/sec (FAT-
 3  XENIX usr       3c  PartitionMagic  84  OS/2 hidden C:  c6  DRDOS/sec (FAT-
 4  FAT16 <32M      40  Venix 80286     85  Linux extended  c7  Syrinx
 5  Extended        41  PPC PReP Boot   86  NTFS volume set da  Non-FS data
 6  FAT16           42  SFS             87  NTFS volume set db  CP/M / CTOS / .
 7  HPFS/NTFS/exFAT 4d  QNX4.x          88  Linux plaintext de  Dell Utility
 8  AIX             4e  QNX4.x 2nd part 8e  Linux LVM       df  BootIt
 9  AIX bootable    4f  QNX4.x 3rd part 93  Amoeba          e1  DOS access
 a  OS/2 Boot Manag 50  OnTrack DM      94  Amoeba BBT      e3  DOS R/O
 b  W95 FAT32       51  OnTrack DM6 Aux 9f  BSD/OS          e4  SpeedStor
 c  W95 FAT32 (LBA) 52  CP/M            a0  IBM Thinkpad hi eb  BeOS fs
 e  W95 FAT16 (LBA) 53  OnTrack DM6 Aux a5  FreeBSD         ee  GPT
 f  W95 Ext'd (LBA) 54  OnTrackDM6      a6  OpenBSD         ef  EFI (FAT-12/16/
10  OPUS            55  EZ-Drive        a7  NeXTSTEP        f0  Linux/PA-RISC b
11  Hidden FAT12    56  Golden Bow      a8  Darwin UFS      f1  SpeedStor
12  Compaq diagnost 5c  Priam Edisk     a9  NetBSD          f4  SpeedStor
14  Hidden FAT16 <3 61  SpeedStor       ab  Darwin boot     f2  DOS secondary
16  Hidden FAT16    63  GNU HURD or Sys af  HFS / HFS+      fb  VMware VMFS
17  Hidden HPFS/NTF 64  Novell Netware  b7  BSDI fs         fc  VMware VMKCORE
18  AST SmartSleep  65  Novell Netware  b8  BSDI swap       fd  Linux raid auto
1b  Hidden W95 FAT3 70  DiskSecure Mult bb  Boot Wizard hid fe  LANstep
1c  Hidden W95 FAT3 75  PC/IX           be  Solaris boot    ff  BBT
1e  Hidden W95 FAT1 80  Old Minix
```
