#!/bin/bash

if [[ $(whoami) == "root" ]]; then
  echo "I am root... Handing over to builduser"
  sudo -u builduser /home/builduser/11-container-rpmbuild.sh
else
   echo "I am builduser... I am building"
   cd /home/builduser
   tar -xzvf /home/builduser/*.tar.gz
   mv /home/builduser/auter /home/builduser/auter-"$(grep Version auter/auter.spec | awk '{print $2}')"
   tar -cvzf "$(grep Version auter*/auter.spec | awk '{print $2}')".tar.gz auter-"$(grep Version auter*/auter.spec | awk '{print $2}')"
   mv "$(grep Version auter*/auter.spec | awk '{print $2}')".tar.gz rpmbuild/SOURCES
   cd /home/builduser/rpmbuild/SPECS
   rpmbuild -ba auter.spec
   cd /home/builduser/rpmbuild/RPMS/noarch
   tar -cvzf /home/builduser/auter.rpm.tar.gz auter*rpm
fi
