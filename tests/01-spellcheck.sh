#!/bin/bash
r='\033[31m'
w='\033[0m'
g='\033[32m'
y='\033[33m'
b='\033[1;34m'

for FILE in $(find ../ -maxdepth 1 -type f -not -path '*/\.*'); do
  unset SPELLINGMISTAKES
  echo "Testing $FILE for spelling mistakes"
  SPELLINGMISTAKES=$(cat ${FILE} | aspell -a --personal=./aspell_auter_dictionary 2>&1| egrep -iv '@|*|Error' | cut -d ' ' -f 2)
  if [[ $(echo "${SPELLINGMISTAKES}" | wc -l) == "" ]]; then
    echo -e "\e[0A ${r} [ FAILED ]${w} Tested $FILE for spelling mistakes"
    echo $SPELLINGMISTAKES
    for WORD in ${SPELLINGMISTAKES}; do
      grep --color -n ${WORD} ${FILE}
    done
  else
    echo -e "\e[0A $g[ OK ] $w Tested $FILE for spelling mistakes"
  fi
done
