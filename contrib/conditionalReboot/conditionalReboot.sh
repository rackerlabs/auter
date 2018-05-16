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
if [[ "${DISTRIBUTION}" =~ CentOS|Red\ Hat|Fedora ]]; then
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
if [[ "${DISTRIBUTION}" =~ CentOS|Red\ Hat|Fedora ]]; then
  if [[ -f /usr/bin/needs-restarting ]]; then
    if needs-restarting -h | egrep -q "^[[:space:]]*-r"; then
      needs-restarting -r &>/dev/null || REBOOTREQURIRED+=("/usr/bin/needs-restarting -r assessment")
    else
      [[ $(needs-restarting | wc -l) -gt 0 ]] && REBOOTREQURIRED+=("/usr/bin/needs-restarting assesment")
    fi
  fi
fi

# Identify if there are any libraries that are running but deleted
LIBCHECK=$(lsof | grep lib | grep DEL)
[[ -n "${LIBCHECK}" ]] && REBOOTREQURIRED+=("Running Library check")

# This is primarily for Debian and Ubuntu
[[ -f /var/run/reboot-required ]] && REBOOTREQURIRED+=("/var/run/reboot-required exists")

# Check if any of the packages in the APPLIST were updated
if [[ -n ${APPLIST} ]]; then
  for PACKAGEMATCH in $APPLIST; do
    # shellcheck disable=SC2001
    PACKAGEMATCH=$(echo "$PACKAGEMATCH" | sed 's/*/.*/g')
    for PACKAGE in "${PACKAGESUPDATED[@]}"; do
      if echo "${PACKAGE}" | grep -q "${PACKAGEMATCH}"; then
        REBOOTREQURIRED+=("${PACKAGE} was updated and is in the $0 APPLIST config")
      fi
    done
  done
fi

# Reboot the server using auter
if [[ -n "${REBOOTREQURIRED[@]}" ]]; then
  logit "$0 assessed that the server needs to be rebooted. The assessments that triggered this requirement are: $(printf '%s, ' "${REBOOTREQURIRED[@]}")" 
  logit "Rebooting server"
  auter --reboot
else
  logit "Reboot not required"
fi
