#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

dart pub global run mason_cli:mason get

while IFS= read -r b; do
  echo "mason make $b -> example/lib/ui"
  dart pub global run mason_cli:mason make "$b" -o example/lib/ui --on-conflict overwrite -q
done < <(grep -E '^  portal_' mason.yaml | sed -E 's/^  (portal_[a-z_]+):.*/\1/' | sort -u)

echo "Done."
