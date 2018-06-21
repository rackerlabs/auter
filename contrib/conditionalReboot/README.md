# conditionalReboot.sh

# Short Description
This script will assess the running distribution and do some basic checks to assess if a reboot is required.
# Script Details

Language: BASH
Supported OS: CENTOS>=6 RHEL>=6 Fedora>=26 Ubuntu>=16.04 Debian>=9
Additional setup required: NO
Dependencies: <Any package dependencies>

# Description

This script will assess what Linux distribution is running based on the following files:
- /etc/redhat-release
- /etc/debian_version
- lsb_release -is (If available)

# Pre-requisites and dependencies

Details of any packages that need to be installed and any config that is required 

# Files and explanations

This should be a list of files that should be included in the directory and an explanation of what each file does

# Any additional information or sections
