#cloud-config
write_files:
 - path: /etc/docker/daemon.json
   permissions: '0644'
   owner: root:root
   content: |
      {
        "data-root": "/data/docker",
        "experimental": true,        
        "icc": false,
        "metrics-addr": "0.0.0.0:9323",
        "no-new-privileges": true,
        "userland-proxy": false
      }
 - path: /etc/cron.weekly/docker
   permissions: '0755'
   owner: root:root
   content: |
       #!/bin/sh -e
       # prune docker system
       /usr/bin/docker system prune -af > /var/log/docker-system-prune.log
 - path: /etc/cron.daily/lun1-discard
   permissions: '0755'
   owner: root:root
   content: |
       #!/bin/sh -e
       # discard unused blocks from mounted device
       /sbin/fstrim -v /data > /var/log/lun1-discard-block.log   

packages:
 - software-properties-common
 - apt-transport-https

apt:
  sources:
    docker.list:
      source: "deb [arch=amd64] https://download.docker.com/linux/ubuntu $RELEASE stable"
      keyid: 9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88
      keyserver: https://download.docker.com/linux/ubuntu/gpg

runcmd:
%{if keep_disk == false ~}
 - echo ';' | sfdisk /dev/disk/azure/scsi1/lun1
 - partprobe
 - mkfs.ext4 /dev/disk/azure/scsi1/lun1-part1 -L 'Data Storage'
%{ endif ~} 
 - mkdir /data
 - echo "UUID=$(blkid /dev/disk/azure/scsi1/lun1-part1 -s UUID -o value) /data ext4 defaults,nofail,nobarrier 0 2" >> /etc/fstab
 - mount -a
 - apt-get install -y docker-ce docker-ce-cli containerd.io
