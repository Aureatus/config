#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

OUTPUT_ROOT="${1:-$HOME/Backups/kde-config}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE_PATH="$OUTPUT_ROOT/kde-config-$TIMESTAMP.tar.gz"
TEMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

mkdir -p "$OUTPUT_ROOT"

copy_matches() {
  local destination_root="$1"
  shift
  local pattern
  local match

  mkdir -p "$destination_root"

  for pattern in "$@"; do
    for match in $pattern; do
      cp -a --parents "$match" "$destination_root"
    done
  done
}

copy_matches "$TEMP_DIR" \
  "$HOME/.config/kde*" \
  "$HOME/.config/plasma*" \
  "$HOME/.config/kwin*" \
  "$HOME/.config/kglobalshortcutsrc" \
  "$HOME/.config/khotkeysrc" \
  "$HOME/.config/kscreenlockerrc" \
  "$HOME/.config/konsolerc" \
  "$HOME/.config/dolphinrc" \
  "$HOME/.local/share/kwin" \
  "$HOME/.local/share/plasma*" \
  "$HOME/.local/share/konsole"

tar -C "$TEMP_DIR" -czf "$ARCHIVE_PATH" .

echo "Created KDE backup: $ARCHIVE_PATH"

archives=("$OUTPUT_ROOT"/kde-config-*.tar.gz)
if [ "${#archives[@]}" -gt 5 ]; then
  IFS=$'\n' sorted_archives=($(printf '%s\n' "${archives[@]}" | LC_ALL=C sort -r))
  unset IFS

  for archive in "${sorted_archives[@]:5}"; do
    rm -f "$archive"
  done
fi
