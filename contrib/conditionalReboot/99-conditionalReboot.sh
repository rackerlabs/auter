#!/bin/bash

# Set static variables
###############################################################################
# This is a space separated list of applications which will always require a
# reboot if updated.
# Examples:
#   APPLIST=""
#   APPLIST="kernel*"
#   APPLIST="kernel* *lib*"
APPLIST="kernel*"
###############################################################################

# Function definitions
###############################################################################
function logit() {
  # If running on a tty, or the --stdout option is provided, print to screen
  tty -s && echo "$1"
  logger -p info -t auter "$1"
}
###############################################################################

# Calculated variables
###############################################################################
DISTRIBUTION="$(python -c "import platform; print platform.linux_distribution()[0]")"
# for later use:
# [[ "${DISTRIBUTION}" =~ debian|Ubuntu ]] && SYSTEMLOG="/var/log/syslog"
# [[ "${DISTRIBUTION}" =~ CentOS|Red\ Hat|Fedora ]] && SYSTEMLOG="/var/log/messages"
# TRANSACTIONID="$(awk -F'[()]' '/auter:.*Transaction/{print substr($2,22)}' "${SYSTEMLOG}" | sort | tail -n1)"
if [[ "${DISTRIBUTION}" =~ CentOS|Red\ Hat|Fedora|Oracle\ Linux ]]; then
  PACKAGESUPDATED=($(awk -F" : " '/Running transaction$/,/Updated:/ {print $2}' /var/lib/auter/last-apply-output-default | awk '{print $1}' | sort -u))
elif [[ "${DISTRIBUTION}" =~ debian|Ubuntu ]]; then
  PACKAGESUPDATED=($(grep "$(date +%Y-%m-%d)" /var/log/dpkg.log | awk '{if ($3=="upgrade" || $3=="install") {print $4}}'))
else
  logit "Distribution not detected by $0. Exiting"
  exit 1
fi
REBOOTREQURIRED=()
###############################################################################

# If the OS is CentOS or Red Hat, check if the /usr/bin/needs-restarting script
# is available
if [[ "${DISTRIBUTION}" =~ CentOS|Red\ Hat|Fedora|Oracle\ Linux ]]; then
  if [[ -f /usr/bin/needs-restarting ]]; then
    if needs-restarting -h | egrep -q "^[[:space:]]*-r"; then
      needs-restarting -r &>/dev/null || REBOOTREQURIRED+=("/usr/bin/needs-restarting -r assessment")
    else
      [[ $(needs-restarting | wc -l) -gt 0 ]] && REBOOTREQURIRED+=("/usr/bin/needs-restarting assesment")
    fi
  fi
fi

# Identify if there are any libraries that are running but deleted
LIBCHECK=$(PATH=/usr/sbin:/usr/local/sbin:$PATH lsof | grep lib | grep DEL)
[[ -n "${LIBCHECK}" ]] && REBOOTREQURIRED+=("detected deleted libraries")

# This is primarily for Debian and Ubuntu
[[ -f /var/run/reboot-required ]] && REBOOTREQURIRED+=("/var/run/reboot-required exists")

# Check if any of the packages in the APPLIST were updated
if [[ -n ${APPLIST} ]]; then
  for PACKAGEMATCH in $APPLIST; do
    # Excluding SC2001 for readability purposes
    # shellcheck disable=SC2001
    PACKAGEMATCH=$(echo "$PACKAGEMATCH" | sed 's/*/.*/g')
    for PACKAGE in "${PACKAGESUPDATED[@]}"; do
      if echo "${PACKAGE}" | grep -q "${PACKAGEMATCH}"; then
        REBOOTREQURIRED+=("package ${PACKAGE} was updated and is in the $0 APPLIST config")
      fi
    done
  done
fi

# Reboot the server using auter
if [[ -n "${REBOOTREQURIRED[@]}" ]]; then
  logit "$0 assessed that the server needs to be rebooted. The assessments that triggered this requirement are:"
  for REBOOTMATCH in "${REBOOTREQURIRED[@]}"
  do
    logit "Rebooting because ${REBOOTMATCH}"
  done
  logit "Reboot required, rebooting server after running auter process completes"
  (while test -f "${PIDFILE}"; do sleep 5; done; auter --reboot) &
else
  logit "Reboot not required"
fi
