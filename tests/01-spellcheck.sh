#!/bin/bash
r='\033[31m'
w='\033[0m'
g='\033[32m'

EXITCODE=0
AUTERDIR="$(cd "$(dirname "$0")" ; cd ../ ; pwd -P )"
TESTDIR="$(cd "$(dirname "$0")" ; pwd -P )"
echo "Testing files in $TESTDIR"

for FILE in $(find $AUTERDIR -maxdepth 1 -type f -not -path '*/\.*'); do
  unset SPELLINGMISTAKES
  FILE=$(realpath "${FILE}")
  echo "Testing $FILE for spelling mistakes"
  SPELLINGMISTAKES=$(aspell -a --personal="${TESTDIR}"/.aspell_auter_dictionary 2>&1 < "${FILE}" | egrep -iv '@|\*|Error|^$' | cut -d ' ' -f 2)
  if [[ -n "${SPELLINGMISTAKES}" ]]; then
    EXITCODE=1
    SPELLINGMISTAKESCOUNT=$(echo "${SPELLINGMISTAKES}" | wc -w)
    SPELLINGMISTAKES=$(echo "${SPELLINGMISTAKES}" | sort -u)
    echo -e "\e[0A ${r} [ FAILED ]${w} ${SPELLINGMISTAKESCOUNT} spelling mistakes found in $FILE"
    for WORD in ${SPELLINGMISTAKES}; do
      echo "$WORD - $(grep -n " ${WORD}" "${FILE}" | awk -F: '{print $1}' | xargs)"
    done
  else
    echo -e "\e[0A $g[ OK ] $w Tested $FILE for spelling mistakes"
  fi
done
exit "${EXITCODE}"
