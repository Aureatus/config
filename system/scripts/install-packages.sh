#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APT_PACKAGE_FILE="$SYSTEM_DIR/packages/apt.txt"
FLATPAK_STATE_FILE="$SYSTEM_DIR/state/flatpak-apps.txt"

trim_line() {
  local line="$1"

  line="${line%%#*}"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"

  printf '%s' "$line"
}

read_list_file() {
  local file_path="$1"
  local -n result_ref="$2"
  local line

  while IFS= read -r line || [ -n "$line" ]; do
    line="$(trim_line "$line")"
    if [ -n "$line" ]; then
      result_ref+=("$line")
    fi
  done < "$file_path"
}

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This installer currently supports apt-based systems only."
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required for package installation."
  exit 1
fi

apt_packages=()
read_list_file "$APT_PACKAGE_FILE" apt_packages

if [ "${#apt_packages[@]}" -gt 0 ]; then
  echo "Installing curated apt packages from $APT_PACKAGE_FILE"

  if [ "${CONFIG_DRY_RUN:-0}" = "1" ]; then
    printf '[dry-run] apt packages: %s\n' "${apt_packages[*]}"
  else
    sudo apt-get update
    sudo apt-get install -y "${apt_packages[@]}"
  fi
fi

if command -v flatpak >/dev/null 2>&1 && [ -f "$FLATPAK_STATE_FILE" ]; then
  flatpak_apps=()
  read_list_file "$FLATPAK_STATE_FILE" flatpak_apps

  if [ "${#flatpak_apps[@]}" -gt 0 ]; then
    echo "Restoring tracked Flatpak apps from $FLATPAK_STATE_FILE"

    if [ "${CONFIG_DRY_RUN:-0}" = "1" ]; then
      printf '[dry-run] flatpak apps: %s\n' "${flatpak_apps[*]}"
    else
      flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      flatpak install --user -y flathub "${flatpak_apps[@]}"
    fi
  fi
fi

echo "System package installation complete."
