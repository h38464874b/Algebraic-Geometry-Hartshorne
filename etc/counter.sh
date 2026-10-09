#!/bin/bash

folder="${1:-.}"
total=0
count=0

while IFS= read -r -d '' pdf; do
  pages=$(mdls -raw -name kMDItemNumberOfPages "$pdf")

  if [[ "$pages" =~ ^[0-9]+$ ]]; then
    printf "%4d pages  %s\n" "$pages" "$pdf"
    ((total += pages))
    ((count++))
  else
    printf "ERROR       %s\n" "$pdf" >&2
  fi
done < <(find "$folder" -type f -iname '*.pdf' -print0)

echo
echo "PDF files:   $count"
echo "Total pages: $total"
