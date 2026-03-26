#!/usr/bin/env bash

set -euo pipefail
shopt -s dotglob nullglob globstar

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/.opencode"
TARGET_DIR="${1:-.}"

copy_if_missing() {
  local source_path="$1"
  local target_path="$2"

  mkdir -p "$(dirname "$target_path")"

  if [ -e "$target_path" ]; then
    echo "Skipping existing $target_path"
    return
  fi

  cp "$source_path" "$target_path"
  echo "Copied $target_path"
}

echo "Setting up OpenCode project template in $TARGET_DIR"
mkdir -p "$TARGET_DIR"

copy_if_missing "$SCRIPT_DIR/opencode.json" "$TARGET_DIR/opencode.json"

for source_path in "$TEMPLATE_DIR"/**/*; do
  if [ ! -f "$source_path" ]; then
    continue
  fi

  if [[ "$source_path" == *"/node_modules/"* ]]; then
    continue
  fi

  relative_path="${source_path#"$TEMPLATE_DIR/"}"
  copy_if_missing "$source_path" "$TARGET_DIR/.opencode/$relative_path"
done

echo "Setup complete."
echo "Next steps:"
echo "1. Review $TARGET_DIR/opencode.json for project-specific overrides."
echo "2. Enable any copied plugins you want under $TARGET_DIR/.opencode/plugin/."
