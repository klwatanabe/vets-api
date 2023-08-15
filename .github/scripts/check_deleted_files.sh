#!/bin/bash

set -e

# Fetch the latest state of the remote repository
git fetch origin

# Compare the current state of the branch with the base branch (e.g., origin/master)
# to get the list of deleted files.
DELETED_FILES=$(git diff --name-only --diff-filter=D origin/master...HEAD)

# Check if a file's or its parent directory's reference is in CODEOWNERS
file_in_codeowners() {
    local file="$1"
    while [[ "$file" != '.' && "$file" != '/' ]]; do
        if grep -qE "^\s*${file}(/|\s+|\$)" .github/CODEOWNERS; then
            return 0
        fi
        # Move to the parent directory
        file=$(dirname "$file")
    done
    return 1
}

for FILE in $DELETED_FILES
do
  # Check if the deleted file's or its parent directory's reference is still in CODEOWNERS
  if file_in_codeowners "$FILE"; then
    # Check if other files in the same directory still exist
    PARENT_DIR=$(dirname "$FILE")
    if [ "$(ls -A "$PARENT_DIR" 2>/dev/null)" ]; then
      # Other files in the directory still exist, so it's okay
      continue
    else
      # The entire directory has been deleted, but its reference still exists in CODEOWNERS
      echo "Error: $FILE (or its parent directories) is deleted but its reference still exists in CODEOWNERS."
      exit 1
    fi
  fi
done

echo "All references to deleted files are consistent with CODEOWNERS."
