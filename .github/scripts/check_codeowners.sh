#!/bin/bash

set -e

# All newly added files in this PR
CHANGED_FILES=CHANGED_FILES=$(git diff --name-only --diff-filter=A HEAD~1 HEAD)

check_in_codeowners() {
    local file="$1"
    while [[ "$file" != '.' && "$file" != '/' ]]; do
        # Check if the file or directory is in CODEOWNERS
				echo "Checking CODEOWNERS for: $file"
        if grep -qE "^\s*${file}(/|\s+|\$)" .github/CODEOWNERS; then
            return 0
        fi
        # Move to the parent directory

				echo "PARENT DIR: Checking CODEOWNERS for: $file"
        file=$(dirname "$file")
    done
    return 1
}
for FILE in $CHANGED_FILES
do
  # Check if the file or any of its parent directories are in CODEOWNERS
  if ! check_in_codeowners "$FILE"; then
    echo "Error: $FILE (or its parent directories) does not have a CODEOWNERS entry."
    exit 1
  fi
done

echo "All changed files or their parent directories have a CODEOWNERS entry."
