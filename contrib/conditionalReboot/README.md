# conditionalReboot.sh

# Short Description
This script will assess the running distribution and do some basic checks to assess if a reboot is required. The main advantage of using this script is that it will reboot the server using `auter --reboot` which will also run any pre-reboot and post-reboot scripts.


# Script Details

Language: BASH
Supported OS: CENTOS>=6 RHEL>=6 Fedora>=26 Ubuntu>=16.04 Debian>=9
Additional setup required: NO
Dependencies: python 


# Description

1. This script will assess what Linux distribution is running based on the python "platform" library.
2. Identify the list of packages that were updated
3. If OS is RHEL/CentOS/Fedora/Oracle Linux:
    * run `/usr/bin/needs-restarting` if it exists
    * Compare the running kernel to the default kernel from grub.conf
3. If OS is Debian/Ubuntu check if file `/var/run/reboot-required` exists
4. Check if any deleted (updated) libraries have open file handles
5. Check if any user-defined applications were updated (see APPLIST definition in script)
6. If a reboot is required, log the reason and start a new process which does the following:
    * Check if auter has completed (Check the pidfile)
    * Execute `auter --reboot`


# Pre-requisites and dependencies

`/usr/bin/python` must exist. If only python3 is installed on the system, ensure there is a symlink at `/usr/lib/python`

# Files and explanations

This script should be put in relevant the post-apply.d directory (default is `/etc/auter/post-apply.d/`).


# Any additional information or sections

None
