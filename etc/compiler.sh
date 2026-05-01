#!/bin/bash

# Loop through each chapter directory
for chapter in chapter*; do
  # Loop through each section inside the chapter
  for section in "$chapter"/section*; do
    if [ -f "$section/exercises.pdf" ]; then
      # Extract chapter and section numbers
      chapter_num=$(echo "$chapter" | grep -o '[0-9]\+')
      section_num=$(echo "$section" | grep -o '[0-9]\+')
      
      # Create a new filename
      new_name="$(basename "$chapter")_$(basename "$section").pdf"
      
      # Copy and rename the file to the destination
      cp "$section/exercises.pdf" "pdfs/$new_name"
    fi
  done
done
