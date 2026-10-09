#!/bin/bash
set -euo pipefail

# Locate the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# The project root is one directory above etc/
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Work from the project root
cd "$ROOT_DIR"

# Loop through each chapter directory
for chapter in chapter*; do

    [[ -d "$chapter" ]] || continue

    # Loop through each section inside the chapter
    for section in "$chapter"/section*; do

        [[ -d "$section" ]] || continue

        # Find the TeX file in the section folder
        texfile=$(find "$section" -maxdepth 1 \
            -type f -name "*.tex" -print -quit)

        if [[ -n "$texfile" ]]; then
            echo "Compiling $texfile..."

            pdflatex \
                -interaction=nonstopmode \
                -halt-on-error \
                -output-directory="$section" \
                "$texfile" > /dev/null

            echo "Finished: $section"
        else
            echo "No TeX file found in $section"
        fi

    done
done

echo "All sections compiled successfully."
