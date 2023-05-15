#!/bin/bash

echo "Building"
cd /root/auter || exit

make deb
cd "$(find . -maxdepth 1 -type d | grep auter | grep -v orig)" || (echo "Failed to cd to auter directory created by Makefile" && exit 1)
debuild -us -uc >/dev/null
