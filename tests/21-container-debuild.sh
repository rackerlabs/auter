#!/bin/bash

if [[ $(whoami) == "root" ]]; then
  echo "I am root... Handing over to builduser"
  sudo -u builduser /home/builduser/21-container-debuild.sh
else
   echo "I am builduser... I am building"
   cd /home/builduser
   tar -xzf /home/builduser/*.tar.gz
   mv /home/builduser/auter /home/builduser/auter-"$(grep Version auter/auter.spec | awk '{print $2}')"
#   tar -czf "$(grep Version auter*/auter.spec | awk '{print $2}')".tar.gz auter-"$(grep Version auter*/auter.spec | awk '{print $2}')"
   cd auter*
   make deb
   cd "$(find . -maxdepth 1 -type d | grep auter | grep -v orig)"
   debuild -us -uc
   cd ../
   tar -czf /home/builduser/auter.deb.tar.gz auter*deb
fi
