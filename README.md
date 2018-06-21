# auter

Automatic updates for RHEL, CentOS, Fedora, Ubuntu and Debian Linux servers, with the ability to run pre/post hooks, pre-download packages and reboot after the updates.

**Note about contributions**
Auter is an open source project and we welcome users to send in feature requests and report any bugs in our issues page. We also welcome any help with maintaining the application and any code contributions.

**What does auter mean?**
Automatic Update Transaction Execution by Rackspace.

**When to use Auter?**

Updates should be applied regularly to Linux systems in order to apply security and bug fixes. For some of those updates, for example the kernel, or a shared library, a system restart is required for those updates to take effect. Whether you apply those updates manually, or automatically will depend on your requirements.

Auter provides a host-based (i.e. installed on the OS) way on systems using yum/dnf/apt-get (RHEL, CentOS, Fedora, Amazon Linux, Ubuntu, Debian etc.) for automatically applying updates and rebooting. For servers, it is often the case that updates and reboots must only happen during defined maintenance windows. Auter provides flexible scheduling to ensure updates and reboots happen when you want them to. Auter allows you to customize how updates run - you can pre-download updates in advance of the window to apply them, and you can run custom scripts before and after the updates.

Here's some cases where other options may be better:

- I want to update nightly, and will handle reboots myself - yum-cron or dnf-automatic do exactly this
- I want a console to manage updates to all my systems - a central management system like RHN Satellite, or perhaps updates applied via a configuration management system like Chef or Puppet. These all need some additional infrastructure, and may impose some limits on flexibility.

**Enable/Disable**

Adds or removes a lockfile that auter will check the presence of to see whether to do anything. This will also remove the pidfile if the process is no longer running:
```
auter --enable
auter --disable
```

**Configure**

Edit /etc/auter/auter.conf. See the comments in that file for help. yum/dnf/apt-get configuration should be used to configure anything affecting yum/dnf/apt-get, for example packages to exclude.

**Set Regular Schedule**

Edit /etc/cron.d/auter. The following can have different times:

```
prep - Pre-download packages from yum (if downloadonly option is supported)
apply - Apply updates and reboot
```

Typically, you may want *apply* to run on one day for your UAT, and another later day for your Production servers.

**Set Irregular Schedule**

If the times you want this to run varies such that its not definable in a crontab, disable the cron jobs and instead create at jobs (as root):

```
echo '/usr/bin/auter --apply' | at 1am Feb 17
echo '/usr/bin/auter --apply' | at 4am Mar 20
echo '/usr/bin/auter --apply' | at 2am Apr 19
```

**Run at boot time**

To apply updates on every boot, set a cron job in /etc/cron.d/auter:

```
@reboot    root /usr/bin/auter --apply
```

**Manual Run**

You'll usually want everything to run via cron, but you can also run auter manually should you wish to. Please review the documentation for each phase. Example for debugging:
note: If you are wanting to manually run the reboot phase, ensure that the AUTOREBOOT option is set to "no"
```
auter --prep
auter --apply
auter --reboot
```

**RPM Packages**

auter is available in Fedora 23 and newer, and EPEL for el6 and el7:
- <https://admin.fedoraproject.org/pkgdb/package/rpms/auter/>
