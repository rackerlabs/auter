# configsnap

Run configsnap at each major phase of auter. Configsnap records useful system state information and creates backups of some configuration files. These can be compared at different points in time based on tags.

# Script Details

Language: bash

Supported OS: CENTOS>=6 RHEL>=6 Fedora>=26 Ubuntu>=16.04 Debian>=9

Additional setup required: YES

Dependencies: configsnap

# Description

This set of scripts will run configsnap at the following points:
 - pre-apply
 - post-apply
 - pre-reboot
 - post-reboot

Note that the pre-reboot script is only useful when the AUTOREBOOT=no

# Pre-requisites and dependencies

 - configsnap needs to be installed:
```
yum install epel-release
yum install configsnap
```

# Files and explanations

 - /etc/auter/pre-apply.d/01-configsnap-pre
  Captured data before the server is updated

 - /etc/auter/post-apply.d/50-configsnap-post-apply
  Captured data aftere the server has been updated

 - /etc/auter/pre-reboot.d/50-configsnap-pre-reboot
  Captured data before the server is rebooted

 - /etc/auter/post-reboot.d/99-configsnap-post-reboot
  Captured data before the server has been rebooted

# Configsnap options used

 - The base directory for configsnap files has been set to /root
 - The tag has been set to auter-configsnap-$(date +%Y-%m-%d)
  Note that this will need to be adjusted if updates span over the change of a day ie:
  apply runs at 23:00
  reboot runs at 02:00


