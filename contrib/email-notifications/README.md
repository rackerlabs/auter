# Auter email notifications

Send brief notification emails with information on the respective auter stage
for which the email is reporting on.

# Script Details

* Language: bash
* Supported OS: CENTOS>=6 RHEL>=6 Fedora>=26 Ubuntu>=16.04 Debian>=9
* Additional setup required: YES
* Dependencies: auter, mailx

# Description

Detailed description of the scripts including the purpose of the scripts 

## notify.post-prep

Determine whether the prepare stage completed successfully and include
the prep'd packages and and error information in the notification email.

## notify.pre-apply

Sends an email with the start time of the auter --apply stage.

## notify.pre-reboot

Sends an email with the estimated reboot time.

## notify.post-reboot

Sends a notification email once the post reboot scripts are run and the auter
patching process is complete.

# Pre-requisites and dependencies

* auter
* **mailx** for sending email

# Files and explanations

| File | Purpose |
| ---- | ------- |
| notify.post-prep | Send email with information on the prep phase |
| notify.post-apply | Send email with information on the prep phase |
| notify.pre-reboot | Send email with information on the prep phase |
| notify.post-reboot | Send email with information on the prep phase |
| auter-notify.conf | Auter email notification common config file |

# Any additional information or sections

These scripts assume a correctly configured MTA on the server.
