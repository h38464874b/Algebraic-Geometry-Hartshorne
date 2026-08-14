#!/bin/bash

rm -rf ./pdfs/*

# Loop through each chapter directory
for chapter in chapter*; do
  # Loop through each section inside the chapter
  for section in "$chapter"/section*; do
    chapter_num=$(echo "$chapter" | grep -o '[0-9]\+')
    section_num=$(echo "$section" | grep -o '[0-9]\+')

    # Create a new filename
    new_name="$(basename "$chapter")_$(basename "$section").pdf"

    texfile=$(find "$section" -maxdepth 1 -name "*.tex" -print -quit)

    if [ -n "$texfile" ]; then
      echo "Compiling $new_name..."
      pdflatex \
          -interaction=nonstopmode \
          -halt-on-error \
          -output-directory="$section" \
          "$texfile" > /dev/null
    fi

    # Copy and rename the file to the destination
    # cp "$section/exercises.pdf" "/pdfs/$new_name"
  done
done
