#!/bin/bash

. _helpers

EXITCODE=0

# Create a list of script files to be checked.
if [[ -f "$CHANGEDFILES" ]]; then
  readarray -t FILELIST < <(find "$AUTERDIR" -type f -not -path '*/\.*' | egrep "$(xargs <"$CHANGEDFILES" | tr ' ' '|')")
else
  readarray -t FILELIST < <(find "$AUTERDIR" -type f -not -path '*/\.*')
fi

for FILE in "${FILELIST[@]}"; do
  grep -q '^#!/.*sh' "$FILE" && SCRIPTSTOTEST+=("$FILE")
done

# SC2102 is related to https://github.com/koalaman/shellcheck/issues/682. This
# was previously removed from the online checker but still exists in the
# standalone package.
SHELLCHECK_EXCLUSIONS="SC2102"

for SCRIPT in "${SCRIPTSTOTEST[@]}"; do
  # Define script specifc exclusions. Reasons should be documented as comments
  # This can be done bu adding "# shellcheck disable=SC2016" to the previous line in the script
  # ----------------------------------------------#
  # Excluding SC2016 due to line 11 of 10-rpmbuild.sh. Expansion is specifically blocked
  # [[ "${SCRIPT}" =~ 10-rpmbuild.sh ]] && SHELLCHECK_EXCLUSIONS+=",SC2016"
  # ----------------------------------------------#

  SHELLCHECK_OUTPUT="$(shellcheck -e "$SHELLCHECK_EXCLUSIONS" "$SCRIPT")"
  if [[ $? -eq 0 ]]; then
    log_success "$SCRIPT passed ShellCheck"
  else
    log_fail "$SCRIPT failed ShellCheck"
    awk '{printf "│    %s\n",$0}' <<< "$SHELLCHECK_OUTPUT"
    echo "└──────────────────────────────────────────────────────────────────────"
    EXITCODE=1
  fi
done
exit "$EXITCODE"
