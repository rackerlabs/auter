### Test Plan

For any changes that are made, the following should be considered the bare minimum to be tested:

```sh
auter --disable         # deletes /var/lib/auter/enabled, prints "auter disabled"
auter --status          # prints "auter is currently disabled"
auter --enable          # touches /var/lib/auter/enabled, prints "auter enabled"
auter --status          # prints "auter is currently enabled and not running"
auter --help            # shows help message
auter --version         # prints "auter VERSIONNUMBER"
man auter               # check the contents of the man page
```

If you don't have any updates available do this:

```sh
yum install zsh
yum downgrade zsh
```

Use the following to setup auter's pre/post scripts:

```sh
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

```md
### Config settings

AUTOREBOOT="no"
ONLYINSTALLFROMPREP="yes"
PREDOWNLOADUPDATES=yes

### <OS test version>

#### auter status

[ pass/fail ] auter --status
    - Check: /var/lib/auter/enabled exists

[ pass/fail ] auter --disable
    - Check: /var/lib/auter/enabled does not exist

[ pass/fail ] auter --enable
    - Check: /var/lib/auter/enabled exists

[ pass/fail ] auter --help
    - Check: same output when running 'auter' without arguments

[ pass/fail ] auter --version
    - Check: prints 'auter VERSION'

#### update manually

[ pass/fail ] auter --prep
    - Check: prints "INFO: Running with: ./auter --prep Updates downloaded" to stdout
    - Check: /var/lib/auter/last-prep-default contains update info
    - Check: updates downloaded to /var/cache/auter/default
    - Check: pre/post prep scripts ran successfully with messages logged to syslog

[ pass/fail ] auter --apply
    - Check: prints "INFO: Running with: /usr/bin/auter --apply; Applying updates; Updates complete, you may need to reboot for some updates to take effect" to stdout
    - Check: expected updates were applied using 'yum history info' or 'dnf history info'
    - Check: /var/lib/auter/last-update-default contains update info
    - Check: no upates available after running
    - Check: pre/post apply scripts ran successfully, messages logged to syslog
    - Check: no mail is sent to the root user with the stdout from auter

[ pass/fail ] auter --reboot
    - Check: reboot scheduled in 2 minutes time
    - Check: prints "INFO: Running with: ./auter --reboot; Rebooting server" followed by shutdown message to stdout
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

#### Pull Request Rules

- All pull requests should be made against the develop branch
- All pull requests MUST be reviewed and approved before merging
- Pull request reviews and merges MUST be completed by another maintainer
- Always squash and merge commits prior to submitting a pull request
- All travis-ci tests should pass before merging
    - If the spellcheck test fails, adding the problematic words to the dictionary is a valid option
    - If the shellcheck test fails, you should fix the issues mentioned or add a shellcheck ignore directive to the previous line along with a comment on why it is being ignored

#### Release Process

1. A new issue should be raised with the title of "Prep for <VERSION> Release"
2. Ensure all required PRs for the new release have been merged to the develop branch
3. A maintainer with admin rights to the master branch in rackerlabs/auter should create a new branch based from the develop branch:

```sh
git clone --branch=develop https://github.com/rackerlabs/auter.git rackerlabs/auter
cd rackerlabs/auter
git checkout -b Release-<NEW_VERSION>
git push origin Release-<NEW_VERSION>
```

4. Any new PRs should be made to the develop branch. The only changes to the Release-<NEW_VERSION> should be fixing of any review issues for that branch.
5. Full testing for all supported OSs should be carried out and tracked in a github project created for the release. Example: https://github.com/rackerlabs/auter/projects/1
6. Once all testing has been completed for Release-<NEW_VERSION>, the reviewer should merge the Release-<NEW_VERSION> branch to both master and develop branches.
7. Tag a new release named <NEW_VERSION> using template <major ver>.<minor ver> (Eg: Release 0.11)
