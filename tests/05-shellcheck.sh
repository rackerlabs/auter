#!/bin/bash
r='\033[31m'
w='\033[0m'
g='\033[32m'

EXITCODE=0
AUTERDIR="$(cd "$(dirname "$0")" ; cd ../ ; pwd -P )"
TESTDIR="$(cd "$(dirname "$0")" ; pwd -P )"

# Create a list of script files to be checked. These are files 
ALLFILES=$(find "${AUTERDIR}" -type f -not -path '*/\.*')
for FILE in ${ALLFILES}; do
  grep -q '^#!/' "${FILE}" && SCRIPTSTOTEST+="${FILE} "
done
echo "${SCRIPTSTOTEST}"

# Add non-shebang scripts manually
SCRIPTSTOTEST+="auter.aptModule auter.yumdnfModule"

for SCRIPT in ${SCRIPTSTOTEST}; do
  SCRIPT=$(realpath "${SCRIPT}")
  echo "Testing $FILE for common coding mistakes"
  SHELLCHECK_OUTPUT=$(shellcheck -e SC2044 "${SCRIPT}")
  if [[ $? -eq 0 ]]; then
    echo -e "\e[0A $g[ OK ] $w Tested ${SCRIPT} for common coding mistakes"
  else
    echo -e "\e[0A ${r} [ FAILED ]${w} Tested ${SCRIPT} for common coding mistakes"
    echo "${SHELLCHECK_OUTPUT}"
  fi
  echo "===================================="
done
