#!/usr/bin/env bash
# commit.sh — Commit and push changes with a descriptive message
# Usage: ./commit.sh <message> [branch]
#
# Example:
#   ./commit.sh "fix: H-01 — writeLimiter fail-closed" main

set -euo pipefail

MESSAGE="${1:?Usage: $0 <commit_message> [branch]}"
BRANCH="${2:-main}"

if ! git diff --quiet; then
  echo "Changes detected — staging and committing..."
  git add -A
  git commit -m "$MESSAGE"
  echo "Pushing to $BRANCH..."
  git push origin "$BRANCH"
  echo "✅ Done."
else
  echo "No changes to commit."
fi
