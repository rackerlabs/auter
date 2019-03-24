
# Auter

> Automatic Update Transaction Execution by Rackspace

[![Build Status](https://travis-ci.org/rackerlabs/auter.svg?branch=develop)](https://travis-ci.org/rackerlabs/auter)

Automatic updates for RHEL and Debian based distributions with the ability to
pre-download packages, run hooks, and perform automated reboots.

## Why use Auter?
It is important to maintain regular system patching on Linux servers to keep up
with the latest's bug and security fixes; some of these updates will require
service or server reboots which is where Auter fits in.

Auter provides a flexible, host-based, solution for updating system packages
via the distributions default package manager. It is possible to configure
independent configuration profiles that can be run individually either manually
on the command  line, or scheduled using cron jobs. This would allow weekly
updates to take place without a reboot, and a monthly patching schedule for the
kernel and other core services that require a reboot.

Auter is also capable of caching available updates, and subsequently only
installing from the cache. This allows package versions to be synchronized
across environments that have different installation dates.

There are also cases when other options are more suitable:
 - I want to update nightly and handle reboots manually: yum-cron or
   dnf-automatic
 - I want to manage updates via a central management console: RHN Satellite
   configuration management systems such as Chef or Puppet

## Installation
Auter is available for RHEL and its derivatives via the EPEL repository.
```bash
$ yum/dnf install auter
```

There isn't currently a package maintained for Debian, however we provide a
`.deb` package on the [releases
page](https://github.com/rackerlabs/auter/releases).

## Setup
All Auter configuration information is stored in `/etc/auter/auter.conf`; it
allows you set basic options such as the sleep delay (`MAXDELAY`) and the
whether automatic reboots should take place based on successful patching.

_More information can be found on the [Wiki](https://github.com/rackerlabs/auter/wiki/Configuration)._

## Usage
Auter can be run either manually:
```bash
$ auter --prep
$ auter --apply
```
or via cron:
```bash
# Prep Every Friday at 22:00
0 22 * * Fri root /usr/bin/auter --prep
# Apply Every Saturday at 23:00
0 23 * * Sat root /usr/bin/auter --apply
```
_For more examples and usage, please refer to the [Wiki]( https://github.com/rackerlabs/auter/wiki/Usage)._

## Contributing
Please read
[HACKING.md](https://github.com/rackerlabs/auter/blob/master/HACKING.md) for
details on how to contribute, and the process for submitting pull requests.

## Maintainers
- Paolo Gigante
- Nick Rhodes

See also the list of original
[contributors](https://github.com/rackerlabs/auter/blob/master/MAINTAINERS.md)
who started the project.

The Auter team can be reached via our mailing list
[auter-devel@rackspace.com](mailto://auter-devel@rackspace.com).

