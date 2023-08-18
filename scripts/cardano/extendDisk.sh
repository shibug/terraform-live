#How to extend disk size
Stop the VM.
Increase the size of the OS disk from the portal.
Restart the VM, and then sign in to the VM as a root user.
dps
sudo -s
systemctl stop docker
systemctl status docker
df -Th
mount | grep "/dev/sdb"
umount /dev/sdb1
mount | grep "/dev/sdb"
df -Th
parted /dev/sdb
    print
    Fix
    rm 1
    mkpart ext4part 1049kB 100%
    print
    quit
e2fsck -f /dev/sdb1
resize2fs /dev/sdb1
mount | grep "/dev/sdb"
mount -av
mount | grep "/dev/sdb"