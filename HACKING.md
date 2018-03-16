### Test Plan

For any changes that are made, the following should be considered the bare minimum to be tested:

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

Use the following to setup auter's pre/post scripts:

```
echo 'logger custom pre prep script ran' > /etc/auter/pre-prep.d/pre_prep_script
echo 'logger custom post prep script ran' > /etc/auter/post-prep.d/post_prep_script
echo 'logger custom pre apply script ran' > /etc/auter/pre-apply.d/pre_apply_script
echo 'logger custom post apply script ran' > /etc/auter/post-apply.d/pre_apply_script
echo 'logger custom pre reboot script ran' > /etc/auter/pre-reboot.d/pre_reboot_script
echo 'logger custom post reboot script ran' > /etc/auter/post-reboot.d/post_reboot_script
chmod +x /etc/auter/*.d/*script
```

#### Basic guidelines for testing:

1. Test the commands manually in a normal shell session.
2. Test for both positive and negative outcomes.
3. Test the effects of the change in the function. Again, if possible, test success and failure conditions
4. Test the all functionality in auter that is affected by they code changes.

##### Testing template

This should be completed in all pull requests before being merged.

```
### <OS test version>

#### auter status

[ pass/fail ] auter --status
    - Check: /var/lib/auter/enabled exists

[ pass/fail ] auter --disable
    - Check: /var/lib/auter/enabled does not exist

[ pass/fail ] auter --enable
    - Check: /var/lib/auter/enabled exists

[ pass/fail ] auter --help
    - check: same output when running 'auter' without arguments

[ pass/fail ] auter --version
    - check: prints 'auter VERSION'

#### update manually

[ pass/fail ] auter --prep
    - Check: prints "INFO: Running with: ./auter --prep Updates downloaded", /var/lib/auter/last-prep-auter
    - Check: /var/lib/auter/last-prep-default contains update info
    - Check: updates downloaded to /var/cache/auter/default
    - Check: pre/post prep scripts ran successfully with messages logged to syslog

[ pass/fail ] auter --apply
    - Check: prints "INFO: Running with: /usr/bin/auter --apply; Applying updates; Updates complete, you may need to reboot for some updates to take effect
    - Check: expected updates were applied using 'yum history info' or 'dnf history info'
    - Check: /var/lib/auter/last-update-default contains update info
    - Check: no upates available after running
    - Check: pre/post apply scripts ran successfully, messages logged to syslog

[ pass/fail ] auter --reboot working
    - Check: reboot scheduled in 2 minutes time
    - Check: prints "INFO: Running with: ./auter --reboot; Rebooting server" followed by shutdown message
    - Check: 5 minutes after reboot is complete pre/post reboot scripts ran successfully with messages logged to syslog

#### updates via cron

[ pass/fail ] auter --prep --stdout
    - Check: updates downloaded to /var/cache/auter/default
    - Check: pre/post prep scripts ran successfully, messages logged to syslog
    - Check: output from auter also mailed to root user on CentOS boxes, output logged to syslog on Fedora systems

[ pass/fail ] auter --apply --stdout
    - Check: no updates available after running
    - Check: pre/post scripts ran successfully with messages logged to syslog
    - Check: output from auter also mailed to root user on CentOS boxes, output logged to syslog on Fedora systems

[ pass/fail ] auter --reboot --stdout
    - Check: server rebooted after 2 minutes
    - Check: pre/post scripts ran successfully
    - Check: output from auter also mailed to the root user on CentOS, output logged to syslog on Fedora

#### new functionality testing

[ pass/fail ] <test new functionality added>
    - Check:
```

#### Documentation

When making any changes to code, make sure documentation (--help, man page) has been updated with the new functionality.

#### Merge Rules

- All pull requests should be made against the develop branch
- All pull requests MUST be reviewed and approved before merging
- Pull request reviews and merges MUST be completed by another maintainer
- If possible squash and merge commits
- All travis-ci tests should pass before merging
    - If the spellcheck test fails, adding the problematic words to the dictionary is a valid option
    - If the shellcheck test fails, you should fix the issues mentioned or adjust the test with explicit comments for the check code and why it is being ignored
    - The adjustments to the test files may need to be merged before the PR will pass the tests. This should be done as a separate PR referencing the associated PR for the changes.

#### Release Process

1. Ensure that all files are updated to the version of the release number you're about to tag.  This includes:
    - auter
    - NEWS
    - auter.spec
2. Add notes to auter.spec and NEWS with a list of the changes for this release
3. Push to github
4. Tag a release through github
5. Engage with the RPM building process to get RPMs built based on the new tag, and attach those to the github release. 

