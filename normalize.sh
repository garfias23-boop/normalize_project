#!/bin/bash
# Full name: Adelecia garfias
# Purpose: Normalize the "Other stars" section of a Wikipedia star-list
#          into CSV: Star Name, Description
# Usage: ./normalize.sh [input_file]
# Notes:
#   - Reads input from $1, or defaults to input.txt
#   - Writes CSV to stdout: ./normalize.sh input.txt > output.csv
#   - Record lines look like: "     * NAME — DESCRIPTION"
#   - Wrapped records (continuation lines) are joined back onto the
#     previous record before splitting.
#   - Accumulation STOPS at the first section header after the list
#     (e.g. "See also") so trailing sections don't leak into the last record.
#   - lynx footnote markers (^[1]) are stripped.

INPUT="${1:-input.txt}"

echo "Star Name,Description"

sed -n '/BPM 37093/,$p' "$INPUT" |
awk '
  /^[[:space:]]*(See also|References|External links|Notes|Bibliography)[[:space:]]*$/ {
      if (composite != "") { print composite; composite = "" }
      exit
  }
  /^[[:space:]]*\*[[:space:]]/ {
      if (composite != "") print composite
      composite = $0
      next
  }
  {
      if (composite != "") composite = composite " " $0
  }
  END { if (composite != "") print composite }
' |
grep ' — ' |
while IFS= read -r line; do
    line=$(sed -E 's/^[[:space:]]+//' <<< "$line")
    line=$(sed -E 's/^\*[[:space:]]+//' <<< "$line")
    line=$(sed -E 's/\^?\[[0-9]+\]//g' <<< "$line")
    line=$(sed -E 's/[[:space:]]+/ /g' <<< "$line")
    line=$(sed -E 's/^ //; s/ $//' <<< "$line")

    name="${line%% — *}"
    desc="${line#* — }"

    name=$(sed -E 's/^ +//; s/ +$//' <<< "$name")
    desc=$(sed -E 's/^ +//; s/ +$//' <<< "$desc")

    [[ -z "$name" || -z "$desc" ]] && continue

    name=${name//\"/\"\"}
    desc=${desc//\"/\"\"}

    [[ "$name" == *,* ]] && name="\"$name\""
    [[ "$desc" == *,* ]] && desc="\"$desc\""

    echo "$name,$desc"
done
