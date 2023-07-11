#!/bin/bash

output_file="git_most_commits.csv"
directory="/Users/ryan/Development/vets-api/app/controllers"

# Create a temporary file
temp_file=$(mktemp)

# Clear the output file
> "$output_file"

# Write CSV header
echo "File	Authors	Timestamps" >> "$output_file"

# Find all files in the directory and store the result in the temporary file
find "$directory" -type f -print0 > "$temp_file"

# Iterate through all files in the temporary file
while IFS= read -r -d '' filename; do
  echo "Processing $filename..."

  # Use git log to get the authors with the most commits for the current file
  authors=$(git log --format="%aN" "$filename" |
    sort |
    uniq -c |
    sort -rn)

  # Extract the portion of the file path after /controllers/
  relative_path=$(echo "$filename" | sed "s|$directory/||")

  # Remove leading portions of the path before /controllers/
  relative_path=$(echo "$relative_path" | sed "s/^[^\/]*\/controllers\///")

  # Get the latest commit timestamp for the current file
  latest_commit=$(git log -1 --format="%ad" --date=format:"%B %Y" "$filename")

  # Append the information to the output file
  authors_line=""
  while read -r line; do
    commits=$(echo "$line" | awk '{print $1}')
    author=$(echo "$line" | awk '{$1=""; print $0}' | xargs)
    authors_line+=" $commits author $author"
  done <<< "$authors"

  echo "$relative_path	$authors_line	$latest_commit" >> "$output_file"

done < "$temp_file"

# Remove the temporary file
rm "$temp_file"

echo "Completed. Results are saved in $output_file."
