#!/usr/bin/env bash
# Rebuild the index and publish everything in this folder to GitHub Pages.
# Usage: ./sync.sh ["optional commit message"]
set -euo pipefail
cd "$(dirname "$0")"

./build-index.sh

if git diff --quiet && git diff --cached --quiet && [ -z "$(git status --porcelain)" ]; then
  echo "Nothing to sync — no changes."
  exit 0
fi

git add -A

msg="${1:-}"
if [ -z "$msg" ]; then
  n=$(git diff --cached --name-only | grep -c '\.html$' || true)
  msg="Publish update ($n html file(s) touched) - $(date -u '+%Y-%m-%d %H:%M UTC')"
fi

git commit -q -m "$msg"
git push -q origin main

echo
echo "Pushed. Live in ~30-60s:"
echo "  https://sourapdatta.github.io/tech-analysis/"
