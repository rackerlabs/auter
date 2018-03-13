#!/bin/bash
r='\033[31m'
w='\033[0m'
g='\033[32m'

[[ ! -f /usr/bin/aspell ]] && echo "apsell not installed. Aborting test" && exit 1

EXITCODE=0
AUTERDIR="$(cd "$(dirname "$0")" ; cd ../ ; pwd -P )"
TESTDIR="$(cd "$(dirname "$0")" ; pwd -P )"
CHANGEDFILES="$(find "${AUTERDIR}" -name CHANGEDFILES)"

if [[ -f "${CHANGEDFILES}" ]]; then
  FILELIST=$(find "${AUTERDIR}" -type f -not -path '*/\.*' | egrep "$(xargs <"${CHANGEDFILES}" | tr ' ' '|')")
else
  FILELIST=$(find "${AUTERDIR}" -type f -not -path '*/\.*')
fi

for FILE in ${FILELIST}; do 
  unset SPELLINGMISTAKES
  FILE=$(realpath "${FILE}")
  SPELLINGMISTAKES=$(aspell -a --personal="${TESTDIR}"/.aspell_auter_dictionary 2>&1 < "${FILE}" | egrep -iv '@|\*|Error|^$' | cut -d ' ' -f 2)
  if [[ -n "${SPELLINGMISTAKES}" ]]; then
    EXITCODE=1
    SPELLINGMISTAKESCOUNT=$(echo "${SPELLINGMISTAKES}" | wc -w)
    SPELLINGMISTAKES=$(echo "${SPELLINGMISTAKES}" | sort -u)
    echo -e "${r} [ FAILED ]${w} ${SPELLINGMISTAKESCOUNT} spelling mistakes found in $FILE"
    for WORD in ${SPELLINGMISTAKES}; do
      echo "$WORD - $(grep -n " ${WORD}" "${FILE}" | awk -F: '{print $1}' | xargs)"
    done
  else
    echo -e "$g[ OK ] $w Tested $FILE for spelling mistakes"
  fi
done
exit "${EXITCODE}"
