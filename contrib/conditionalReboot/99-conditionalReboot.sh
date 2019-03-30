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
DISTRIBUTION="$(python -c "import platform; print(platform.linux_distribution()[0])")"
REBOOTREQURIRED=()

function _deleted_file_check() {
  if LSOFEXEC="$(PATH=/usr/sbin:/usr/local/sbin:$PATH command -v lsof 2>/dev/null)"; then
    LIBCHECK=$(${LSOFEXEC} | grep lib | grep DEL)
    [[ -n "${LIBCHECK}" ]] && REBOOTREQURIRED+=("detected deleted libraries")
  else
    logit "$0 - lsof not found: unable to check running libraries"
  fi
}

function _check_applist() {
  local _pkglist=("$@")

  if [[ -n "${APPLIST}" ]]; then
    for _packagematch in $APPLIST; do
      # Excluding SC2001 for readability purposes
      # shellcheck disable=SC2001
      _packagematch=$(sed 's/*/.*/g' <<< "$_packagematch")
      for _package in "${_pkglist[@]}"; do
        if [[ "$_package" =~ $_packagematch ]]; then
          REBOOTREQURIRED+=("package $_package was updated and is in the $0 APPLIST config")
        fi
      done
    done
  fi
}

# This is primarily for Debian and Ubuntu
[[ -f /var/run/reboot-required ]] && REBOOTREQURIRED+=("/var/run/reboot-required exists")

_deleted_file_check

if [[ "${DISTRIBUTION}" =~ CentOS|Red\ Hat|Fedora|Oracle\ Linux ]]; then
  _check_applist "$(awk -F" : " '/Running transaction$/,/Updated:/ {print $2}' /var/lib/auter/last-apply-output-default | awk '{print $1}' | sort -u)"


  [[ -f /sbin/grubby ]] && GRUBBYEXEC="/sbin/grubby"
  [[ -f /usr/sbin/grubby ]] && GRUBBYEXEC="/usr/sbin/grubby"
  [[ -n "$GRUBBYEXEC" ]] && DEFKERNELVERSION=$($GRUBBYEXEC --default-kernel | sed 's/^.*vmlinuz-//g')
  if [[ -n $DEFKERNELVERSION ]]; then
    [[ ! "$DEFKERNELVERSION" == "$(uname -r)" ]] && REBOOTREQURIRED+=("Default kernel ${DEFKERNELVERSION} does not match running kernel $(uname -r)")
  fi


  if [[ -f /usr/bin/needs-restarting ]]; then
    if needs-restarting -h | grep -E -q "^[[:space:]]*-r"; then
      needs-restarting -r &>/dev/null || REBOOTREQURIRED+=("/usr/bin/needs-restarting -r assessment")
    else
      [[ $(needs-restarting | wc -l) -gt 0 ]] && REBOOTREQURIRED+=("/usr/bin/needs-restarting assesment")
    fi
  fi

elif [[ "$DISTRIBUTION" =~ debian|Ubuntu ]]; then
  _check_applist "$(grep "$(date +%Y-%m-%d)" /var/log/dpkg.log | awk '{if ($3=="upgrade" || $3=="install") {print $4}}')"

else
  logit "Distribution not detected by $0. Exiting"
  exit 1
fi

# Reboot the server using auter
if [[ -n "${REBOOTREQURIRED[*]}" ]]; then
  logit "$0 assessed that the server needs to be rebooted. The assessments that triggered this requirement are:"
  for _rebootmatch in "${REBOOTREQURIRED[@]}"; do
    logit "Rebooting because $_rebootmatch"
  done
  logit "Reboot required, rebooting server after running auter process completes"
  # Not valid as PIDFILE has been exported, and will be expanded in subshell
  # shellcheck disable=SC2016
  (timeout 600 bash -c 'while test -f "$PIDFILE"; do sleep 5; done; auter --reboot') &
else
  logit "Reboot not required"
fi
