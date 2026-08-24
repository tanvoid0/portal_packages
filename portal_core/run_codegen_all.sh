#!/bin/bash
set -e

PACKAGES=(
  "packages/portal_core_annotations"
  "packages/portal_core_codegen"
  "packages/portal_core_models"
)

for pkg in "${PACKAGES[@]}"; do
  echo "Running codegen in $pkg..."
  (cd "$pkg" && dart run build_runner build --delete-conflicting-outputs)
done

echo "Code generation complete for all packages." 