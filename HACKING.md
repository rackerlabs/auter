**Test Plan**

When you make changes ensure at the very minimum you should test the following:

```
auter --disable         # deletes /var/lib/auter/enabled, prints "auter disabled"
auter --status          # prints "auter is currently disabled"
auter --enable          # touches /var/lib/auter/enabled, prints "auter enabled"
auter --status          # prints "auter is currently enabled and not running"
auter --help            # shows help message
auter --version         # prints "auter VERSIONNUMBER"
```

If you don't have any updates available do this:

```
yum install zsh
yum downgrade zsh
```

Prepare custom scripts:

```
echo 'logger custom pre reboot script ran' > /var/lib/auter/pre_reboot_script
echo 'logger custom post reboot script ran' > /var/lib/auter/post_reboot_script
chmod +x /var/lib/auter/*script
```

Now there will be at least one update:

```
Edit /etc/auter/auter.conf to set MAXDELAY=1

auter --prep
    prints "Running with: ./auter --prep Updates downloaded", /var/lib/auter/last-prep-auter
    /var/lib/auter/last-prep-auter contains update info

auter --apply
    prints "Running with: /usr/bin/auter --apply; Applying updates; Updates complete, you may need to reboot for some updates to take effect
    Run 'yum history info' and verify that update was applied
    /var/lib/auter/last-update-auter contains update info (same as yum history)

auter --reboot
    prints "Running with: ./auter --reboot; Rebooting server" followed by shutdown message
    tail /var/log/message should include text "root: custom pre reboot script ran"
    cat /etc/cron.d/auter-postreboot-auter should show "@reboot root /usr/bin/auter --postreboot --config auter"
    After the reboot, tail /var/log/message should include text "root: custom post reboot script ran"
```

**Documentation**

When making any changes to code, make sure documentation (--help, man page) has been updated to reflect any changes

**Release Process**

1.  Ensure that all files are updated to the version of the release number you're about to tag.  This includes:
  - auter
  - auter.man
  - NEWS
  - auter.spec

2.  Regenerate the man page using help2man:

  # help2man --include=auter.help2man --no-info ./auter > auter.man

3.  Add notes to auter.spec and NEWS with a list of the changes for this release

4.  Push to github

5.  Tag a release through github

6.  Engage with the rpmbuilding process to get rpms built based on the new tab, and attach those to the github release. 
