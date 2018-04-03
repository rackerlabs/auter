**Test Plan**

When you make changes ensure at the very minimum you should test the following:

```
auter --disable         # deletes /var/lib/auter/enabled, prints "auter disabled"
auter --status          # prints "auter is currently disabled"
auter --enable          # touches /var/lib/auter/enabled, prints "auter enabled"
auter --status          # prints "auter is currently enabled and not running"
auter --help            # shows help message
auter --version         # prints "auter VERSIONNUMBER"
man auter               # check the contents of the man page
```

If you don't have any updates available do this:

```
yum install zsh
yum downgrade zsh
```

Prepare custom scripts:

```
echo 'logger custom pre prep script ran' > /etc/auter/pre-prep.d/pre_prep_script
echo 'logger custom post prep script ran' > /etc/auter/post-prep.d/post_prep_script
echo 'logger custom pre apply script ran' > /etc/auter/pre-apply.d/pre_apply_script
echo 'logger custom post apply script ran' > /etc/auter/post-apply.d/pre_apply_script
echo 'logger custom pre reboot script ran' > /etc/auter/pre-reboot.d/pre_reboot_script
echo 'logger custom post reboot script ran' > /etc/auter/post-reboot.d/post_reboot_script
chmod +x /etc/auter/*.d/*script
```

Now there will be at least one update:

```
auter --prep
    prints "INFO: Running with: ./auter --prep Updates downloaded", /var/lib/auter/last-prep-auter
    /var/lib/auter/last-prep-default contains update info

auter --apply
    prints "INFO: Running with: /usr/bin/auter --apply; Applying updates; Updates complete, you may need to reboot for some updates to take effect
    Run 'yum history info' or 'dnf history info' and verify that update was applied
    /var/lib/auter/last-update-default contains update info

auter --reboot
    prints "INFO: Running with: ./auter --reboot; Rebooting server" followed by shutdown message
    tail /var/log/messages should include text "root: custom pre reboot script ran"
    cat /etc/cron.d/auter-postreboot-auter should show "@reboot root /usr/bin/auter --postreboot --config auter"
    5 mins after the reboot, tail /var/log/messages should include text "root: custom post reboot script ran"
```

**Documentation**

When making any changes to code, make sure documentation (--help, man page) has been updated to reflect any changes

**Release Process**

1.  Ensure that all files are updated to the version of the release number you're about to tag.  This includes:
  - auter
  - NEWS
  - auter.spec

2.  Add notes to auter.spec and NEWS with a list of the changes for this release

3.  Push to github

4.  Tag a release through github

5.  Engage with the RPM building process to get RPMs built based on the new tag, and attach those to the github release. 
