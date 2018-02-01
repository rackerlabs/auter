# Auter contrib directory

This directory contains useful scripts, config files and/or cron schedules which can be used as examples for more complex and interesting implementations of auter as well as useful scripts which are specifically created for the the auter pre/post functions.

# Guidelines
- This collection of scripts should be generic enough to be used on any server or environment.
- A new directory should be created for each new purpose
- In each directory there MUST be a README.md file created with the layout provided below
- If there are any prerequisites or configuration requirements or options for the scripts to work, they should be documented in the README.md
- Scripts should be explicitly include the interpreter line ie: #!/bin/sh or #!/usr/bin/python
- Scripts should be set as executable before uploading
- Scripts MUST return an exit code of 0 for a successful run. Any exceptions will cause auter to fail
- Script names should be either a brief description or the package that is being called. The script name should also have a "-phase" suffix. Note that the interpreter suffix is not required but may be useful ie:
  - notifyAvailablePatches-post-prep
  - configsnap.pre-apply
  - removeFromAppPool.pre-reboot
  - appStartConfirmation.post-reboot.sh


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

# Files and explainations

This should be a list of files that should be included in the directory and an expaination of what each file does

# Any additional information or sctions
```

# Git Pull Request guidelines

- Code reviews will be done for all files for all pull requests
  - Take this as constructive feedback and do not be discouraged if changes are requested
  - Code reviews may take a while however feel free to comment on the PR if you want to give it a nudge
  - Code reviews will assess logic, code structure, naming convention and syle. Please ensure you are following the google guidelines: https://google.github.io/styleguide/

