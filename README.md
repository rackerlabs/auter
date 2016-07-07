# auter

Automatic updates for RHEL, CentOS or Fedora servers, with the ability to run pre/post hooks, pre-download packages & reboot after the updates.

**Enable/Disable**

Adds or removes a lockfile that auter will check the presence of to see whether to do anything:
```
auter --enable
auter --disable
```

**Configure**

Edit /etc/auter/auter.conf. See the comments in that file for help. yum/dnf configuration should be used to configure anything affecting yum/dnf, for example packages to exclude.

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

You'll usually want everything to run via cron, but you can also run auter manually should you wish to, for example for debugging:

```
auter --prep
auter --apply
```
