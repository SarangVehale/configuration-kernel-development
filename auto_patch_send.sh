#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 \"commit message\""
  exit 1
fi

# Stage all changes
git add .

# Commit with Signed-off-by
git commit -s -m "$1"

# Generate patch for last commit
git format-patch -1 HEAD

# Find maintainers for changed files
MAINTAINERS=$(git diff --name-only HEAD~1 HEAD | xargs ./scripts/get_maintainer.pl | grep -E "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" | sort -u | paste -sd "," -)

if [ -z "$MAINTAINERS" ]; then
  echo "No maintainers found, please specify --to manually."
  exit 1
fi

echo "Sending patch to: $MAINTAINERS"

# Send patch email (configure your SMTP in git config)
git send-email --to="$MAINTAINERS" *.patch

