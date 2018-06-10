# Build Guide
***
This is a walkthrough to manually build the install files for auter. This is not the release process, this is specifically for building the .rpm or .deb files for testing purposes.

**Better way of generating the files:**
- Install docker-ce on your PC
- from the auter directory execute the following:
  - For rpm file:
  ```# tests/10-rpmbuild.sh```
  - For deb file (This is only once PR#119 has been merged):
  ```# 20-debuild.sh```

# Manual steps
****
**Steps to create a .deb file:**
1) Build a debian 9 cloud server
2) Update the system and reboot:
    ```
    # apt-get update && apt-get upgrade
    # reboot
    ```
3) Install the required tools:
    ```
    # apt-get update && apt install debhelper devscripts build-essential vim dh-make help2man
    ```

4) Create a build user and switch to that account
notes:
- "adduser" NOT "useradd"
- Use a valid password
- Other details can be blanks
    ```
    # adduser builder
    # su - builder
    ```
5) Clone the auter repo and switch to the required tagged version:
    ```
    # git clone git@github.com:rackerlabs/auter.git
    # cd auter
    # git checkout <TAG>          eg: git checkout 0.11
    ```
6) Make the sources files
    ```
    # make deb
    # cd auter-<TAG>
    ```
7) build the package:
    7.a) To build an unsigned package:
    ```
    # debuild -us -uc
    ```
    7.b) To build a gpg signed package:
    ```
    # debuild -S -sa -k$(gpg --list-key --with-colons | awk -F: '/^pub:/ { print $5 }')
    ```
***
**Steps to create a .rpm file:**
1) Build a CentOS cloud server (6 or 7)

2) Install the required packages:
    ```
    yum -y install rpm-build elfutils-libelf rpm-libs rpm-python gcc make help2man sudo
    ```
3) Add a build user:
    ```
    useradd builduser
    ```
4) Make the build directories:
    ```
    mkdir -p /home/builduser/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
    ```
5) Create the .macros config:
    ```
    echo '%_topdir %(echo $HOME)/rpmbuild' > /home/builduser/.rpmmacros
    ```
6) Clone the auter repo and switch to the required tagged version:
    ```
    # git clone git@github.com:rackerlabs/auter.git
    # cd auter
    # git checkout <TAG>          eg: git checkout 0.11
    ```
7) Make the sources files and copy them to the builduser's home:
    ```
    make sources
    cp auter-*.tar.gz /home/builduser/
    cp auter.spec /home/builduser/rpmbuild/SPECS
    chown -R builduser.builduser /home/builduser
    ```
8) Switch to the builduser account and extract the sources
    ```
    su - builduser
    cd /home/builduser
    ```
9) Move the sources into the correct location with the correct sources name
    ```
    mv auter*.tar.gz /home/builduser/rpmbuild/SOURCES/$(awk '/Version/ {print $2}' /home/builduser/rpmbuild/SPECS/auter.spec).tar.gz
    ```
10) Start building the rpm
    ```
    cd /home/builduser/rpmbuild/SPECS
    rpmbuild -ba auter.spec
    ```
***
