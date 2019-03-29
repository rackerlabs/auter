#!/bin/bash


cd /root || exit
useradd -m builduser
su - builduser -c 'rpmdev-setuptree'

cp -a auter "auter-$VERSION"
tar --group=builduser --owner=builduser -czf "$VERSION.tar.gz" "auter-$VERSION"
cp -v "$VERSION.tar.gz" /home/builduser/rpmbuild/SOURCES/
cp -v auter/auter.spec /home/builduser/rpmbuild/SPECS/
chown -R builduser. /home/builduser/

su - builduser -c 'rpmbuild -ba rpmbuild/SPECS/auter.spec'
