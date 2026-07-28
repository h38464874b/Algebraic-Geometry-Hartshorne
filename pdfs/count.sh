find . -name "*.pdf" -print0 |
while IFS= read -r -d '' f; do
    pages=$(pdfinfo "$f" | awk '/^Pages:/ {print $2}')
    printf "%5d  %s\n" "$pages" "$f"
    total=$((total + pages))
    echo $total
done
echo "------------------------"