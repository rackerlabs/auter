#!/bin/bash

. "$(dirname "$0")"/_helpers

EXITCODE=0

# Create a list of script files to be checked.
readarray -t FILELIST < <(find "$AUTERDIR" -type f -not -path '*/\.*')

for _file in "${FILELIST[@]}"; do
  grep -q '^#!/.*sh' "$_file" && SCRIPTSTOTEST+=("$_file")
done

# SC2102 is related to https://github.com/koalaman/shellcheck/issues/682. This
# was previously removed from the online checker but still exists in the
# standalone package.
sc_excl=("SC2102")
sc_excl+=("SC1090" "SC1091") # Can't follow source
#sc_excl+=("SC2181") # Check RC directly

for _script in "${SCRIPTSTOTEST[@]}"; do
  if shellcheck_output="$(shellcheck -e "$(IFS=','; echo "${sc_excl[*]}")" "$_script")"; then
    log_success "$_script passed ShellCheck"
  else
    log_fail "$_script failed ShellCheck"
    awk '{printf "|    %s\n",$0}' <<< "$shellcheck_output"
    echo "-----------------------------------------------------------------------"
    EXITCODE=1
  fi
done
exit $EXITCODE
