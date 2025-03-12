1) Go to OpenWRT [release page](https://downloads.openwrt.org/releases/), select the latest release stable release, then ```targets``` -> ```x86``` -> ```64```. Right-click ```generic-ext4-combined.img.gz``` (not the "efi"!) and copy the link.

2) On the Proxmox host, download the archive and unpack it:

```
wget *paste link here*
gunzip openwrt-*.img.gz
```

3) Resize the image to be the size you want your VM's disk to be (example with 8 GiB):

```
qemu-img resize -f raw openwrt-*.img 8G
```

4) Create a new VM in Proxmox. Make sure to use:

* No installation media
* SeaBIOS
* No drives

Do not start the VM yet.

5) Import the resized OpenWRT image into the new VM (replace VMID and STORAGEID with yours):

```
qm importdisk VMID openwrt-*.img STORAGEID
```

6) Go to the VM -> Hardware, select the newly imported disk named "Unused Disk 0", press "Edit", set it to VirtIO with "Discard" and "IO Thread" enabled, then press OK.

7) Go to the VM -> Options -> Boot Order, make sure that ```virtio0``` is at the top and is the only one that is ticked.

8) Add whatever networking or other devices you need.

9) You're done! Start the VM and enjoy all the routing.