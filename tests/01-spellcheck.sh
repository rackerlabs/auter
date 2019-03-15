#!/bin/bash

r='\033[31m'
w='\033[0m'
g='\033[32m'

if ! command -v aspell &>/devnull; then echo "apsell not installed. Aborting test"; exit 1; fi

EXITCODE=0
AUTERDIR="$(dirname `pwd`)"
TESTDIR="$(pwd)"
CHANGEDFILES="$(find "${AUTERDIR}" -name CHANGEDFILES)"

if [[ -f "${CHANGEDFILES}" ]]; then
  readarray -t FILELIST <<< "$(find "${AUTERDIR}" -type f -not -path '*/\.*' | egrep "$(xargs <"${CHANGEDFILES}" | tr ' ' '|')")"
else
  readarray -t FILELIST < <(find "${AUTERDIR}" -type f -not -path '*/\.*')
fi

for FILE in "${FILELIST[@]}"; do
  FILE=$(realpath "${FILE}")
  SPELLINGMISTAKES=$(aspell -a --personal="${TESTDIR}"/.aspell_auter_dictionary 2>&1 < "${FILE}" | egrep -iv '@|\*|Error|^$' | cut -d ' ' -f 2)
  if [[ -n "${SPELLINGMISTAKES}" ]]; then
    EXITCODE=1
    SPELLINGMISTAKESCOUNT=$(echo "${SPELLINGMISTAKES}" | wc -w)
    SPELLINGMISTAKES=$(echo "${SPELLINGMISTAKES}" | sort -u)
    echo -e "${r}[ FAILED ]${w} ${SPELLINGMISTAKESCOUNT} spelling mistakes found in $FILE"
    for WORD in ${SPELLINGMISTAKES}; do
      echo "$WORD - $(grep -n " ${WORD}" "${FILE}" | awk -F: '{print $1}' | xargs)"
    done
  else
    echo -e "$g[ OK ] $w Tested $FILE for spelling mistakes"
  fi
done
exit "${EXITCODE}"
