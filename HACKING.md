# Contributing

When contributing to this repository, please feel free to first start a
discussion either via issue or our mailing list
[auter-devel@rackspace.com](mailto://auter-devel@rackspace.com) before working
on the change.

## Pull Requests

- Ensure all tests pass on your forked branch prior to submitting the PR; if
  necessary add words flagged by the 01-spellcheck.sh test to the dictionary
- All pull requests should be made against the develop branch
- Update the help and man pages with any additional functionality being added by
  the PR; try to do this in independent commits to make reviewing easier
- Update the file list in 01-spellcheck.sh if adding a new documentation file
- Don't bump version numbers - this will be done during a release

### Code standards

We adhere to Google's [shell style guide](https://google.github.io/styleguide/shell.xml). 
Historically one of the exceptions was to declare all variables in capitals, not just 
global variables, but work is ongoing to gradually conform to the style guide.

### Testing changes

For all changes, the following should be considered the bare minimum to be
tested:

```bash
auter --disable      # deletes /var/lib/auter/enabled, prints "auter disabled"
auter --status       # prints "auter is currently disabled"
auter --enable       # touches /var/lib/auter/enabled, prints "auter enabled"
auter --status       # prints "auter is currently enabled and not running"
auter --help         # shows help message
auter --version      # prints "auter VERSIONNUMBER"
man auter            # check the contents of the man page reflect the relevant changes
man auter.conf		 # if relevant, check the contents of the man page reflect the changes
```

If no updates are available, try downgrading a package like openssl or curl
which often has several versions available.

RHEL based distributions:

```bash
$ yum --showduplicates list curl
$ yum downgrade curl libcurl
```

Debian based distributions:

```bash
# This will give you a list of packages that have multiple versions available in the repos:
for PKG in $(dpkg --list | awk '{print $2}'); do
    VERSIONS="$(apt-cache showpkg $PKG | awk '/Versions:/,/^Reverse Depends:/ {if ($1 ~ /^[0-9]/) print $1}' | xargs)"

    [[ $(echo ${VERSIONS} | wc -w) -gt 1 ]] && echo "$PKG -% $VERSIONS"
done | column -t -s "%"

$ apt-get update
$ apt-get install <PACKAGE>=<VERSION>
```

_Note: You may need to also downgrade dependencies._

#### Pre/Post script functionality

Use the following to setup the pre/post scripts:

```bash
echo 'logger custom pre prep script ran' > /etc/auter/pre-prep.d/pre_prep_script
echo 'logger custom post prep script ran' > /etc/auter/post-prep.d/post_prep_script
echo 'logger custom pre apply script ran' > /etc/auter/pre-apply.d/pre_apply_script
echo 'logger custom post apply script ran' > /etc/auter/post-apply.d/post_apply_script
echo 'logger custom pre reboot script ran' > /etc/auter/pre-reboot.d/pre_reboot_script
echo 'logger custom post reboot script ran' > /etc/auter/post-reboot.d/post_reboot_script
chmod +x /etc/auter/*.d/*script
```

#### General guidelines for testing

1. Run the base commands directly via command line testing for both positive and
   negative outcomes
2. Run the base commands via `at` job, again testing both positive and negative
   outcomes
3. Test the effects of the change in the function. Again, if possible, test
   success and failure conditions
4. Test all functionality in Auter that is affected by the code changes.


#### Release Process

1. A new issue should be raised with the title of "Prep for <VERSION> Release"
2. Ensure all required pull requests for the new release have been merged to the
   develop branch
3. A maintainer with admin rights to the master branch in rackerlabs/auter
   should create a new branch based from the develop branch:

```sh
git clone --branch=develop https://github.com/rackerlabs/auter.git rackerlabs/auter
cd rackerlabs/auter
git checkout -b Release-<NEW_VERSION>
git push origin Release-<NEW_VERSION>
```

4. Any new pull requests should be made to the develop branch. The only changes
   to the Release-<NEW_VERSION> should be fixing of any review issues for that
   branch.
5. Full testing for all supported distributions should be carried out and
   tracked in a github project created for the release. Example:
   https://github.com/rackerlabs/auter/projects/1
6. Once all testing has been completed for Release-<NEW_VERSION>, the reviewer
   should merge the Release-<NEW_VERSION> branch to both master and develop
   branches.
7. Tag a new release named <NEW_VERSION> using template
   <major_version>.<minor_version> (Eg: Release 0.11)


##### Testing template

This should be completed for all supported distributions in all pull requests to
the master branch before being merged.

```
# <OS test version>
# Steps taken to create install file:
    ```
    ```
---
# Test 1: Basic auter status tests
1) Do a fresh install of auter
2) Execute: `auter --status`
Checks:
    - __[ pass/fail ]__ Exit code 0
    - __[ pass/fail ]__ Prints "auter is currently enabled and not running" to screen
    - __[ pass/fail ]__ /var/lib/auter/enabled exists

3) Execute: `auter --disable`
Checks:
    - __[ pass/fail ]__ Exit code 0
    - __[ pass/fail ]__ Prints "INFO: auter disabled" to screen
    - __[ pass/fail ]__ /var/lib/auter/enabled does not exist

4) Execute: `auter --status`
Checks:
    - __[ pass/fail ]__ Exit code 0
    - __[ pass/fail ]__ Prints "auter is currently disabled" to screen
    - __[ pass/fail ]__ /var/lib/auter/enabled does not exist

5) Execute: `auter --enable`
    - __[ pass/fail ]__ Exit code 0
    - __[ pass/fail ]__ Prints "INFO: auter enabled" to screen
    - __[ pass/fail ]__ /var/lib/auter/enabled exists

6) Execute: `auter --help`
    - __[ pass/fail ]__ Exit code 0
    - __[ pass/fail ]__ Prints the auter help to screen

7) Execute: `auter` (no arguments provided)
    - __[ pass/fail ]__ Exit code 0
    - __[ pass/fail ]__ Prints the auter help to screen


8) Execute: `auter --version`
    - __[ pass/fail ]__ Exit code 0
    - __[ pass/fail ]__ Prints the correct auter version
---

# Test 2: Manual process - default config [ PASS/FAIL ]
### Config settings
1) `egrep -v "^$|^#" /etc/auter/auter.conf`
    ```

    ```
2) Prepare custom scripts: Execute:
    ```
    echo 'logger custom pre prep script ran' > /etc/auter/pre-prep.d/pre_prep_script
    echo 'logger custom post prep script ran' > /etc/auter/post-prep.d/post_prep_script
    echo 'logger custom pre apply script ran' > /etc/auter/pre-apply.d/pre_apply_script
    echo 'logger custom post apply script ran' > /etc/auter/post-apply.d/post_apply_script
    echo 'logger custom pre reboot script ran' > /etc/auter/pre-reboot.d/pre_reboot_script
    echo 'logger custom post reboot script ran' > /etc/auter/post-reboot.d/post_reboot_script
    chmod +x /etc/auter/*.d/*script
    ```
3) Execute: `auter --prep`
    - __[ pass/fail ]__ prints the following block to stdout:
        ```
        INFO: Running with: /usr/bin/auter --prep
        INFO: Running in an interactive shell, disabling all random sleeps
        INFO: Running Pre-Prep script /etc/auter/pre-prep.d/pre_prep_script
        INFO: Updates downloaded
        INFO: Running Post-Prep script /etc/auter/post-prep.d/post_prep_script
        ```
    - __[ pass/fail ]__ **_/var/lib/auter/last-prep-output-default_** contains yum download-only output
    - __[ pass/fail ]__ updates downloaded to **_/var/cache/yum/..._**
    - __[ pass/fail ]__ pre/post prep scripts ran successfully with messages logged to syslog
    ##### Output from prep:
    ```

    ```
4) Execute `auter --apply`
    - __[ pass/fail ]__ prints the following block to stdout: Note: For debian based distros there will not be a transaction ID
        ```
        INFO: Running with: /usr/bin/auter --apply
        INFO: Running in an interactive shell, disabling all random sleeps
        INFO: Running Pre-Apply script /etc/auter/pre-apply.d/pre_apply_script
        INFO: Applying updates
        INFO: Running Post-Apply script /etc/auter/post-apply.d/pre_apply_script
        INFO: Updates complete (yum Transaction ID : <ID>). You may need to reboot for some updates to take effect
        INFO: Auter successfully ran at <TIMESTAMP>
        ```
    - __[ pass/fail ]__ expected updates were applied. Check **_/var/log/apt/history.log_** or **_/var/log/yum.log_**
    - __[ pass/fail ]__ **_/var/lib/auter/last-apply-output-default_** contains update info
    - __[ pass/fail ]__ no updates available after running. Check `yum update <<<n` or `apt-get --just-print upgrade`
    - __[ pass/fail ]__ pre/post apply scripts ran successfully, messages logged to syslog
    - __[ pass/fail ]__ no mail is sent to the root user with the stdout from auter
     ##### Output from apply:
    ```

    ```
5) Execute 'auter --reboot`
    - __[ pass/fail ]__ prints the following block to stdout:
        ```
        INFO: Running with: /usr/bin/auter --reboot
        INFO: Running in an interactive shell, disabling all random sleeps
        INFO: Running Pre-Reboot script /etc/auter/pre-reboot.d/pre_reboot_script
        INFO: Adding post-reboot-hook to run scripts under /etc/auter/post-reboot.d to /etc/cron.d/auter-postreboot-default
        INFO: Rebooting server
        ```
    - __[ pass/fail ]__ reboot scheduled in 2 minutes time
    - __[ pass/fail ]__ pre reboot script ran successfully, messages logged to syslog
    - __[ pass/fail ]__ **_/etc/cron.d/auter-postreboot-default_** contains `@reboot root /usr/bin/auter --postreboot --config /etc/auter/auter.conf`
    - __[ pass/fail ]__ **_/etc/cron.d/auter-postreboot-default_** has the correct permissions: `root:root:0644`
    ##### Output from reboot:
    ```

    ```
6) After server has rebooted:
    - __[ pass/fail ]__ Server actually rebooted: Execute `uptime`
    - __[ pass/fail ]__ **_ /etc/cron.d/auter-postreboot-default _** has been removed after the has fully completed the startup process
    - __[ pass/fail ]__ post reboot script ran successfully, messages logged to syslog
     ##### Full auter logs:
     Execute: `egrep "auter|custom" /var/log/messages` or `egrep "auter|custom" /var/log/syslog` or `journalctl -S today | egrep "auter|custom"`
     ```

     ```
---

# Test 3: Updates via cron - default config with `--stdout` option [ PASS/FAIL ]
### Config settings
1) `egrep -v "^$|^#" /etc/auter/auter.conf`
    ```

    ```
2) Prepare custom scripts: Execute:
    ```
    echo 'logger custom pre prep script ran' > /etc/auter/pre-prep.d/pre_prep_script
    echo 'logger custom post prep script ran' > /etc/auter/post-prep.d/post_prep_script
    echo 'logger custom pre apply script ran' > /etc/auter/pre-apply.d/pre_apply_script
    echo 'logger custom post apply script ran' > /etc/auter/post-apply.d/post_apply_script
    echo 'logger custom pre reboot script ran' > /etc/auter/pre-reboot.d/pre_reboot_script
    echo 'logger custom post reboot script ran' > /etc/auter/post-reboot.d/post_reboot_script
    chmod +x /etc/auter/*.d/*script
    ```
3) Adjust the MAXDELAY value to avoid extended sleep times
    ```
    sed -i 's/MAXDELAY.*$/MAXDELAY="60"/g' /etc/auter/auter.conf
    ```
4) Schedule a cron job for prep to run in 5 minutes and watch the logs:
    ```
    echo "$(date --date="5 minutes" +%_M" "%_H" "%d" "%_m" *") root $(which auter) --prep --stdout" > /etc/cron.d/auter-prep
    tail -n0 -f /var/log/messages or tail -f /var/log/syslog or journalctl -f
    ```
    After auter has completed the prep:
    - __[ pass/fail ]__ Expected logs:
        ```
        auter: INFO: Running with: /usr/bin/auter --prep --stdout
        auter: INFO: Running Pre-Prep script /etc/auter/pre-prep.d/pre_prep_script
        root: custom pre prep script ran
        auter: INFO: Updates downloaded
        auter: INFO: Running Post-Prep script /etc/auter/post-prep.d/post_prep_scrip
        root: custom post prep script ran
        ```
    - __[ pass/fail ]__ **_/var/lib/auter/last-prep-output-default_** contains yum download-only output
    - __[ pass/fail ]__ updates downloaded to **_/var/cache/yum/…_** or **_/var/cache/apt/archives/..._**
    - __[ pass/fail ]__ pre/post prep scripts ran successfully with messages logged to syslog
    - __[ pass/fail ]__ mail sent to root user with stdout output from auter. Debian will log stdout to syslog rather than mail
    Output from logs:
    ```

    ```
5) Schedule a cron job for apply to run in 5 minutes and watch the logs:
    ```
    echo "$(date --date="5 minutes" +%_M" "%_H" "%d" "%_m" *") root $(which auter) --apply --stdout" > /etc/cron.d/auter-apply
    tail -n0 -f /var/log/messages or tail -f /var/log/syslog or journalctl -f
    ```
    After auter has completed the apply: Note: For debian based distros there will not be a transaction ID
    - __[ pass/fail ]__ Expected logs:
        ```
        auter: INFO: Running with: /usr/bin/auter --apply --stdout
        auter: INFO: Running Pre-Apply script /etc/auter/pre-apply.d/pre_apply_script
        root: custom pre apply script ran
        auter: INFO: Applying updates
        auter: INFO: Running Post-Apply script /etc/auter/post-apply.d/pre_apply_script
        root: custom post apply script ran
        auter: INFO: Updates complete (yum Transaction ID : 86). You may need to reboot for some updates to take effect
        auter: INFO: Auter successfully ran at 2018-07-18T14:59:24+0000
        ```
    - __[ pass/fail ]__ no updates available after running
    - __[ pass/fail ]__ pre/post scripts ran successfully with messages logged to syslog
    - __[ pass/fail ]__ mail sent to root user with stdout output from auter. Debian will log stdout to syslog rather than mail
    Output from logs:
    ```

    ```
6) Schedule a cron job to run auter --reboot in 5 minutes and watch the logs:
    ```
    echo "$(date --date="5 minutes" +%_M" "%_H" "%d" "%_m" *") root $(which auter) --reboot --stdout" > /etc/cron.d/auter-reboot
    tail -n0 -f /var/log/messages or tail -f /var/log/syslog or journalctl -f
    ```
    - __[ pass/fail ]__ Expected logs:
        ```
        INFO: Running with: /usr/bin/auter --reboot --stdout
        INFO: Running Pre-Reboot script /etc/auter/pre-reboot.d/98-configsnap-pre-reboot
        INFO: Running Pre-Reboot script /etc/auter/pre-reboot.d/pre_reboot_script
        custom pre reboot script ran
        INFO: Adding post-reboot-hook to run scripts under /etc/auter/post-reboot.d to /etc/cron.d/auter-postreboot-default
        INFO: Rebooting server
        ```
    - __[ pass/fail ]__ pre-reboot scripts ran successfully
    - __[ pass/fail ]__ Wall message is printed
    - __[ pass/fail ]__ mail sent to root user with stdout output from auter. Debian will log stdout to syslog rather than mail
    - __[ pass/fail ]__ Server reboots
    Output from logs:
    ```

    ```
7) After the server has booted, it may take up to 2 minutes for auter logs to appear. watch the logs:
    ```
    egrep "auter:|custom" /var/log/messages | awk '/auter --reboot/,0'
    or
    egrep "auter:|custom" /var/log/syslog | awk '/auter --reboot/,0'
    or
    journalctl -S today | egrep auter|custom | awk '/auter --reboot/,0'
    ```
    - __[ pass/fail ]__ Expected logs:
        ```
        auter: INFO: Running with: /usr/bin/auter --reboot --stdout
        auter: INFO: Running Pre-Reboot script /etc/auter/pre-reboot.d/pre_reboot_script
        root: custom pre reboot script ran
        auter: INFO: Adding post-reboot-hook to run scripts under /etc/auter/post-reboot.d to /etc/cron.d/auter-postreboot-default
        auter: INFO: Rebooting server
        auter: INFO: Running with: /usr/bin/auter --postreboot --config /etc/auter/auter.conf
        auter: INFO: Removed post-reboot hook: /etc/cron.d/auter-postreboot-default
        auter: INFO: Running Post-Reboot script /etc/auter/post-reboot.d/post_reboot_script
        root: custom post reboot script ran
        ```
    - __[ pass/fail ]__ post-reboot scripts ran successfully
    - __[ pass/fail ]__  output from auter also mailed to the root user on CentOS, output logged to syslog on Fedora
    Output from logs:
    ```

    ```
#### new functionality testing
### Config settings
1) `egrep -v "^$|^#" /etc/auter/auter.conf`
    ```

    ```
2) Details of new feature

3) Test command
    Expected outcome:
    ```

    ```
4) Next Test:
etc...
```
