Name:           auter
Version:        0.6
Release:        1%{?dist}
Summary:        Prepare and apply updates

License:        ASL 2.0
URL:            https://github.com/rackerlabs/auter
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch

Requires:       cronie, /usr/bin/yum

%description
auter (optionally) pre-downloads updates and then runs then automatically on a set schedule, and optionally reboots to finish applying updates

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}%{_bindir} %{buildroot}%{_sharedstatedir}/auter \
  %{buildroot}%{_sysconfdir}/cron.d %{buildroot}%{_sysconfdir}/auter \
  %{buildroot}%{_mandir}/man1 %{buildroot}%{_localstatedir}/run/auter \
  %{buildroot}%{_sharedstatedir}/auter/pre-reboot.d \
  %{buildroot}%{_sharedstatedir}/auter/post-reboot.d \
  %{buildroot}%{_sharedstatedir}/auter/pre-apply.d \
  %{buildroot}%{_sharedstatedir}/auter/post-apply.d
install -m 755 auter %{buildroot}%{_bindir}
install -m 644 auter.cron %{buildroot}%{_sysconfdir}/cron.d/auter
install -m 644 auter.conf %{buildroot}%{_sysconfdir}/auter/auter.conf
install -m 644 auter.man %{buildroot}%{_mandir}/man1/auter.1
chmod 755 %{buildroot}%{_sharedstatedir}/auter/*.d

%post
# If this is the first time install, create the lockfile by default
if [ $1 -eq 1 ]; then
  /usr/bin/auter --enable
fi

%preun
# If this is a complete removal, then remove lockfile
if [ $1 -eq 0 ]; then
 /usr/bin/auter --disable
fi

%files
%defattr(-,root,root,-)
%doc README.md
%doc %{_mandir}/man1/auter.1*
%license LICENSE
%{_sharedstatedir}/auter
%config(noreplace) %{_sysconfdir}/auter/auter.conf
%config(noreplace) %{_sysconfdir}/cron.d/auter
%{_bindir}/auter
%{_localstatedir}/run/auter
%dir %{_sharedstatedir}/auter/pre-reboot.d
%dir %{_sharedstatedir}/auter/post-reboot.d
%dir %{_sharedstatedir}/auter/pre-apply.d
%dir %{_sharedstatedir}/auter/post-apply.d

%changelog
* Wed Jul 06 2016 Cameron Beere <cameron.beere@rackspace.co.uk>
- Release version 0.6
- Add maintainers file

* Thu Apr 28 2016 Cameron Beere <cameron.beere@rackspace.co.uk>
- Release version 0.5
- Added transaction ID logging
- Disable random sleepis when running from a tty
- Rename variables to be package manager agonistic
- Add cron examples for @reboot jobs
- Update default auter config file location
- Remove example script files
- Diable cronjobs & enable lockfile on installation
- Switch to using pre/post script directories instead of files
- Add better handling for option parsing
- Added CONFIGSET variable used to distinguish between distinct configs
- Various bugfixes

* Wed Mar 23 2016 Piers Cornwell <piers.cornwell@rackspace.co.uk>
- Release version 0.4
- Support DNF
- Add HACKING.md
- Exit if custom config file doesn't exist
- Change post reboot script to use cron instead of rc.local
- Report if there are no updates at prep time
- Record prep and apply output
- Updated man page

* Mon Mar 14 2016 Paolo Gigante <paolo.gigante@rackspace.co.uk>
- Release version 0.3
- Better defined exit codes
- Added bounds check for MAXDELAY
- Updated documentation with more details abount configuration options
- Fixed logging error if downloadonly is not available

* Thu Mar 10 2016 Piers Cornwell <piers.cornwell@rackspace.co.uk>
- Release version 0.2
- Locking
- Trap Ctrl+C during dangerous section
- Add --status flag
- Move reboot script to /etc/rc.d/rc.local
- Add random delay
- Change from sysv service to --enable/--disable
- Added warnings when pre/post hooks exist but are not executable
- Removed yum transaction support
- Added pid locking to prevent multiple instances of auter running at the same time

* Fri Mar 02 2016 Mike Frost <mike.frost@rackspace.co.uk>
- Release version 0.1
