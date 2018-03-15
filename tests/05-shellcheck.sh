#!/bin/bash
r='\033[31m'
w='\033[0m'
g='\033[32m'

EXITCODE=0
AUTERDIR="$(cd "$(dirname "$0")" ; cd ../ ; pwd -P )"
CHANGEDFILES="$(find "${AUTERDIR}" -name CHANGEDFILES)"

# Create a list of script files to be checked. These are files 
if [[ -f "${CHANGEDFILES}" ]]; then
  ALLFILES=$(find "${AUTERDIR}" -type f -not -path '*/\.*' | egrep "$(xargs <"${CHANGEDFILES}" | tr ' ' '|')")
  
else
  ALLFILES=$(find "${AUTERDIR}" -type f -not -path '*/\.*')
fi

for FILE in ${ALLFILES}; do
  grep -q '^#!/.*sh' "${FILE}" && SCRIPTSTOTEST+="${FILE} "
done

echo "${SCRIPTSTOTEST}"

# Add non-shebang scripts manually
grep -q "auter.aptModule" "${CHANGEDFILES}" && SCRIPTSTOTEST+=" ${AUTERDIR}/auter.aptModule "
grep -q "auter.yumdnfModule" "${CHANGEDFILES}" && SCRIPTSTOTEST+=" ${AUTERDIR}/auter.yumdnfModule "

# Custom shellcheck exclusions
SHELLCHECK_EXCLUSIONS=",SC2102,SC2124,SC2155,SC2148"

echo "===================================="
for SCRIPT in ${SCRIPTSTOTEST}; do

  # Define script specifc exclusions. Reasons should be documented as comments
  # This can be done bu adding "# shellcheck disable=SC2016" to the previous line in the script
  # ----------------------------------------------#
  # Excluding SC2016 due to line 11 of 10-rpmbuild.sh. Expansion is specifically blocked
#  [[ "${SCRIPT}" =~ 10-rpmbuild.sh ]] && SHELLCHECK_EXCLUSIONS+=",SC2016"
  # ----------------------------------------------#

  SCRIPT=$(realpath "${SCRIPT}")
  SHELLCHECK_OUTPUT=$(shellcheck -e SC2044"${SHELLCHECK_EXCLUSIONS}" "${SCRIPT}")
  if [[ $? -eq 0 ]]; then
    echo -e "$g[ OK ] $w Tested ${SCRIPT} for common coding mistakes"
  else
    EXITCODE=1
    echo -e "${r} [ FAILED ]${w} Tested ${SCRIPT} for common coding mistakes"
    echo "${SHELLCHECK_OUTPUT}"
  fi
  echo "===================================="
done
exit "${EXITCODE}"
