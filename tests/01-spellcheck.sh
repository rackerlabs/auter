#!/bin/bash

. "$(dirname "$0")"/_helpers

if ! command -v aspell &>/devnull; then echo "apsell not installed. Aborting test"; exit 1; fi

EXITCODE=0

FILELIST=( "$AUTERDIR/auter.conf.man" )
FILELIST+=( "$AUTERDIR/auter.help2man-sections" )
FILELIST+=( "$AUTERDIR/HACKING.md" )
FILELIST+=( "$AUTERDIR/README.md" )
FILELIST+=( "$AUTERDIR/NEWS" )
FILELIST+=( "$AUTERDIR/buildGuide.md" )
FILELIST+=( "$AUTERDIR/contrib/README.md" )

for FILE in "${FILELIST[@]}"; do
  if aspel_out="$(aspell -a --personal="${TESTDIR}"/.aspell_auter_dictionary 2>&1 < "${FILE}")"; then
    spelling_mistakes="$(awk '/^&/{print $2}' <<< "$aspel_out")"
    if [[ -n "$spelling_mistakes" ]]; then
      log_fail "$FILE failed SpellCheck"
      EXITCODE=1
      sort <<< "$spelling_mistakes" | uniq -c
    else
      log_success "$FILE passed SpellCheck"
    fi

  else
    log_fail "$aspel_out"
    exit 1
  fi

done
exit $EXITCODE
