lvm-snap.pre-apply

Description: creates an LVM snapshot on the logical volume underneath root filesystem, if applicable.

# Script Details

Language: bash
Supported OS: CENTOS>=6 RHEL>=6 Fedora>=26 Ubuntu>=16.04 Debian>=8
Additional setup required: NO
Dependencies: auter, util-linux, lvm2

# Forewords of caution
This script is not going through each and every possible checks to ensure a snapshot revert will be successful. It was tested in different scenario and will do a reasonable amount of checks, halting on possible issues, but we do not guarantee that a revert will always be successful and/or without issues. We strongly recommand to do your own testing before using this on anything you hold dear.

# Description

This script executes the following steps:

* Check if lvm is in use for the root filesystem
* Check if /bin, /etc, /lib, /lib64, /sbin, /usr, /var are on a separate filesystem => halt if confirmed
* Check if there is a reasonable amount of free unallocated space in the VG (default = 20 %)
* Check if there are snapshots already created (we do not allow multiple snapshots to be created by default)
* If all checks are passed then create a new snapshot with a descriptive name associating it with auter (format: <snap_root_auter_YYYY-MM-DD_HHMMSS>)
* Set up automatic removal of the snapshot after a number of days (default = 3). If the removal fails, modify /etc/motd to alert about the failed removal on next login.

# Pre-requisites and dependencies

* Of course **auter** should be installed on the server.
* The script is using command **findmnt** to help determine if root filesystem '/' is on an LVM logical volume. You need util-linux package to use this program.
* You **should not** make use of this script if your root filesystem '/' **is not** on an LVM logical volume, otherwise it will fail with a non-zero code exit that will prevent auter to run.
* LVM command-line tools need to be installed on the system (lvcreate / lvremove /lvs /vgs). This should need require extra installing if you have lvm2 package installed.

Variables at the beginning of the script may be altered to adjust to your needs.


# Files and explainations

^ File ^ Purpose ^
| lvm-snap.pre-apply | handles all steps: lvm checks, snapshot creation and scheduled removal |

# Reverting a snapshot
If you decide to revert the root filesystem to the time of the snapshot, you will need to do the following.

**WARNING**: you will lose all data modified on the logical volume since the snapshot. This is **not** reversible.

1. Merge the LVM snapshot with its origin to revert:
```
lvconvert --mergesnapshot <LV_VG>/<LV_SNAP>
[output]
  Can't merge until origin volume is closed.
  Merging of snapshot centos/snap_root_auter_2018-01-08_092517 will occur on next activation of centos/root.
```
1. **If** your /boot directory resides on an separate filesystem, you **need** to update the grub default file to load the entry matching the kernel used prior the patching (for example, setting up `GRUB_DEFAULT=1` in /etc/default/grub will match previously installed kernel.) If in doubt, look back into the script's log file and compare with list of grub entries in /boot/grub2/grub.conf . Keep in mind grub starts numbering at 0.
Once you have set up Grub, update your grub configuration to reflect your change. The way to do this may slightly vary depending of your platform ('grub2' denomination on RHEL based distro has been replaced by 'grub' on modern Debian based distributions):
RHEL based:
```
grub2-mkconfig -o /boot/grub2/grub.cfg
```
Debian based:
```
update-grub
```
1. Reboot the device to validate.
