# Auter email notifications

A collection of contrib scripts for sending email notifications containing
details of auter patching stages.

# Script Details

* Language: bash
* Supported OS: CENTOS>=6 RHEL>=6 Fedora>=26 Ubuntu>=16.04 Debian>=9
* Additional setup required: YES
* Dependencies: auter, mailx, configsnap

# Description

## auter-notify.module

Main script containing the logic behind the mail notifications. It takes a
single argument which is the stage being run in the format:

- pre-prep
- post-prep
- pre-apply
- post-apply
- pre-reboot
- post-reboot

## notify.pre-apply

Example pre-apply script calling the auter-notify.module.

## notify.post-apply

Example post-apply script calling the auter-notify.module.

## report-configsnap.post-apply

Example custom auter-notify script that provides additional body content. The
script uses the post-apply configsnap diff to report any state differences
between pre and post apply. It uses the default confignap BASEDIR (-d) of
`/root`, and tag (-t) `auter-configsnap-"$(date +%Y-%m-%d)"` to determine the
last files created by auter pre/post configsnap scripts. The script will need to
be edited if you are not using the default configsnap contrib script setup.

## report-rpmnew.post-apply

Script to report all rpmnew files that were created during the last update.

# Pre-requisites and dependencies

* **auter**
* **mailx** for sending email
* **all scripts must have the executable bit set**
* **configsnap** for the report-configsnap.post-apply example

# Files and explanations

|             File             |                               Purpose                                |
|------------------------------|----------------------------------------------------------------------|
| auter-notify.module          | Callable script for sending email                                    |
| notify.pre-apply             | Example script for the pre-apply stage                               |
| notify.post-apply            | Example script for the post-apply stage                              |
| report-configsnap.post-apply | Example custom script for displaying the diff result from configsnap |
| report-rpmnew.post-apply     | Example custom script for finding updated config files               |

The reporting scripts should be placed in the /etc/auter/auter-notify.d/ directory.

# Any additional information or sections

These scripts assume a correctly configured MTA on the server. The
report-configsnap.post-apply script also assumes that configsnap is being run
during the pre-apply or post-prep stages as well as the post-apply stage to
generate state files to diff against.
