#!/bin/sh

set -euo pipefail

if [ -z "$1" ]; then
  target="$(pwd)"
else
  target="$1"
fi

if ! [ -d "$target" ]; then
  echo "Error: $target is not a directory!"
  exit 1
fi

AUTOSCAN_IT8_VALUES="${AUTOSCAN_IT8_VALUES=${HOME}/Pictures/IT8/R200209.txt}"
AUTOSCAN_SCANNER_NAME="${AUTOSCAN_SCANNER_NAME=ScanJet 5590}"

it8_path="$target/it8.tiff"
alt_it8_path="$target/it8.tif"
it8_scan="$it8_path"
if ! [ -f "$it8_scan" ]; then
  it8_scan="$alt_it8_path"

  if ! [ -f "$it8_scan" ]; then
    echo "Error: couldn't find an IT8 scan!"
    echo "Checked \`$it8_path\` and \`$alt_it8_path\`"
    exit 1
  fi
fi

it8_scan_base="$(echo "$it8_scan" | sed -E 's,.tiff?$,,')"

cd "$target"

today="$(date "+%Y-%m-%d")"

# Produce an Argyll-format data file based on the readings in the chart
scanin -v "$it8_scan" "$(brew --prefix argyll-cms)/ref/it8.cht" "$AUTOSCAN_IT8_VALUES"
# Transform Argyll's .ti3 into a .icc
colprof -v -D"${AUTOSCAN_SCANNER_NAME} ${today}" -qm -as "$it8_scan_base"

icc_path="${it8_scan_base}.icc"
mkdir -p profiled

# Create copies of each TIFF with the ICC embedded
for scan in *.tif*; do
  base="$(basename "$scan")"
  convert "$scan" -profile "$icc_path" profiled/$base
done
