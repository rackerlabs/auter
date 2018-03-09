#!/bin/bash
r='\033[31m'
w='\033[0m'
g='\033[32m'

for FILE in $(find ../ -type f -not -path '*/\.*'); do
  FILE=$(realpath "${FILE}")
  echo "Testing $FILE for common coding mistakes"
  SHELLCHECK_OUTPUT=$(shellcheck -e SC2044 "${FILE}")
  if [[ $? -eq 0 ]]; then
    echo -e "\e[0A $g[ OK ] $w Tested ${FILE} for common coding mistakes"
  else
    echo -e "\e[0A ${r} [ FAILED ]${w} Tested ${FILE} for common coding mistakes"
    echo "${SHELLCHECK_OUTPUT}"
  fi
  echo "===================================="
done
