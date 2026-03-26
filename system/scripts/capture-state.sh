#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
STATE_DIR="$SYSTEM_DIR/state"
APT_STATE_FILE="$STATE_DIR/apt-manual.txt"
FLATPAK_STATE_FILE="$STATE_DIR/flatpak-apps.txt"
SYSTEM_INFO_FILE="$STATE_DIR/system-info.txt"

mkdir -p "$STATE_DIR"

if command -v apt-mark >/dev/null 2>&1; then
  apt-mark showmanual | LC_ALL=C sort > "$APT_STATE_FILE"
else
  printf '# apt-mark not available on this host\n' > "$APT_STATE_FILE"
fi

if command -v flatpak >/dev/null 2>&1; then
  flatpak list --app --columns=application | LC_ALL=C sort > "$FLATPAK_STATE_FILE"
else
  printf '# flatpak not available on this host\n' > "$FLATPAK_STATE_FILE"
fi

{
  printf 'captured_at=%s\n' "$(date -Iseconds)"
  if [ -r /etc/os-release ]; then
    . /etc/os-release
    printf 'os=%s\n' "${PRETTY_NAME:-unknown}"
  fi
  printf 'kernel=%s\n' "$(uname -srmo)"
  printf 'hostname=%s\n' "$(hostname)"
} > "$SYSTEM_INFO_FILE"

echo "Captured machine state into $STATE_DIR"
echo "Review and commit the updated files if they reflect the current machine."
