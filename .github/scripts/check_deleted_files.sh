#!/bin/bash

set -e

# Fetch all the deleted files
DELETED_FILES=$(git diff --name-only --diff-filter=D HEAD~1 HEAD)

# Check if a file's reference is in CODEOWNERS
file_in_codeowners() {
    local file="$1"
    if grep -qE "^\s*${file}(\s+|\$)" .github/CODEOWNERS; then
        return 0
    else
        return 1
    fi
}

for FILE in $DELETED_FILES
do
  # Check if the deleted file's reference is still in CODEOWNERS
  if file_in_codeowners "$FILE"; then
    echo "Error: $FILE is deleted but its reference still exists in CODEOWNERS."
    exit 1
  fi
done

echo "All references to deleted files are also removed from CODEOWNERS."
