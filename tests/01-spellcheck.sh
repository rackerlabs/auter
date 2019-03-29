#!/bin/bash

. "$(dirname "$0")"/_helpers

run_cmd "Check for aspell" command -v aspell

EXITCODE=0

FILELIST=("$AUTERDIR/auter.conf.man")
FILELIST+=("$AUTERDIR/auter.help2man-sections")
FILELIST+=("$AUTERDIR/HACKING.md")
FILELIST+=("$AUTERDIR/README.md")
FILELIST+=("$AUTERDIR/NEWS")
FILELIST+=("$AUTERDIR/buildGuide.md")
FILELIST+=("$AUTERDIR/contrib/README.md")

for _file in "${FILELIST[@]}"; do
  if aspel_out="$(aspell -a --personal="$TESTDIR"/.aspell_auter_dictionary 2>&1 < "$_file")"; then
    spelling_mistakes="$(awk '/^&/{print $2}' <<< "$aspel_out")"
    if [[ -n "$spelling_mistakes" ]]; then
      log_fail "$_file failed SpellCheck"
      EXITCODE=1
      sort <<< "$spelling_mistakes" | uniq -c
    else
      log_success "$_file passed SpellCheck"
    fi

  else
    log_fail "$aspel_out"
    exit 1
  fi

done
exit $EXITCODE
