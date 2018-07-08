# Auter contrib directory

This directory contains useful scripts, config files and/or cron schedules which can be used as examples for more complex and interesting implementations of auter as well as useful scripts which are specifically created for the the auter pre/post functions.


# WARNING!!!

These scripts are not part of the default auter package. These scripts are entirely optional and are provided AS IS without guarantee or of any kind. Entire risk arising out of the use of any contrib scripts and documentation remains with you. With that in mind, please always ensure that you entirely review and understand what the script is doing before implementing.

While these scripts may be updated, expanded and new scripts added, this is not the primary focus of Auter.


# Contributing

As mentioned before, contrib scripts are not the primary focus of the project however please do feel free to raise feature requests if you have any ideas or better still, fork the auter repo and send us a pull request with your proposed contrib script.

If you do find any problems with any of the contrib scripts, please raise an issue in this repo with a title prefix of "CONTRIB: ".

# Guidelines
- This collection of scripts should be generic enough to be used on any server or environment.
- A new directory should be created for each new purpose
- In each directory there MUST have a README.md file created with the layout provided below
- If there are any prerequisites or configuration requirements or options for the scripts to work, they should be documented in the README.md
- Scripts should be explicitly include the interpreter line ie: #!/bin/sh or #!/usr/bin/python
- Scripts should be set as executable before uploading
- Scripts MUST return an exit code of 0 for a successful run. Any exceptions will cause auter to fail
- Script names should contain:
  - A prefixed number to be used for execution order
  - Either be a brief description or the package that is being called
  - Reference to the intended phase
  - Optional: The interpreter suffix is not required but may be useful ie:
    - 50-notifyAvailablePatches-post-prep
    - 01-configsnap.pre-apply
    - 50-removeFromAppPool.pre-reboot
    - 70-appStartConfirmation.post-reboot.sh
- It is also highly recommended that script names follow the xx-filename (where xx are padded digits) naming convention to ensure correct script execution order. See the man page for more information.


# README.md layout template
```
# <BASE NAME OF SCRIPTS>

<SHORT DESCRIPTION OF THE PURPOSE OF THE SCRIPTS>

# Script Details

Language: <THE LANGUAGE THE SCRIPTS ARE WRITTEN IN>
Supported OS: CENTOS>=6 RHEL>=6 Fedora>=26 Ubuntu>=16.04 Debian>=9
Additional setup required: <YES / NO>
Dependencies: <Any package dependencies>

# Description

Detailed description of the scripts including the purpose of the scripts

# Pre-requisites and dependencies

Details of any packages that need to be installed and any config that is required

# Files and explanations

This should be a list of files that should be included in the directory and an explanation of what each file does

# Any additional information or sections
```

# Git Pull Request guidelines

- Code reviews will be done for all files for all pull requests
  - Take this as constructive feedback and do not be discouraged if changes are requested
  - Code reviews may take a while however feel free to comment on the PR if you want to give it a nudge
  - Code reviews will assess logic, code structure, naming convention and style. Please ensure you are following the google guidelines: https://google.github.io/styleguide/
