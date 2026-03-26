#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SANDBOX_ROOT="$(mktemp -d)"
TARGET_HOME_DIR="$SANDBOX_ROOT/home"
TARGET_CONFIG_DIR="$TARGET_HOME_DIR/.config"

cleanup() {
  if [ "${KEEP_SANDBOX:-0}" = "1" ]; then
    echo "Keeping sandbox at $SANDBOX_ROOT"
    return
  fi

  rm -rf "$SANDBOX_ROOT"
}

trap cleanup EXIT

mkdir -p "$TARGET_HOME_DIR"

echo "Restoring repo-managed config into sandbox home $TARGET_HOME_DIR"
TARGET_HOME="$TARGET_HOME_DIR" "$REPO_ROOT/dotfiles/manage.sh" restore

test -f "$TARGET_HOME_DIR/.zshrc"
test -f "$TARGET_CONFIG_DIR/starship.toml"
test -f "$TARGET_CONFIG_DIR/ghostty/config"
test -f "$TARGET_CONFIG_DIR/cosmic-term/config.toml"
test -f "$TARGET_CONFIG_DIR/mise/config.toml"

echo "Sandbox config files restored successfully."

if command -v mise >/dev/null 2>&1; then
  echo "Repo-managed mise config was restored into the sandbox target."
  echo "Full runtime installation should be validated in the VM flow from system/vm-testing.md."
else
  echo "mise is not installed on the host, so runtime install was skipped."
fi

if command -v devbox >/dev/null 2>&1 && [ "${ALLOW_DEVBOX_IN_SANDBOX:-0}" = "1" ]; then
  echo "Running a repo helper inside devbox using the existing host devbox install"
  (
    cd "$REPO_ROOT"
    HOME="$TARGET_HOME_DIR" devbox run help
  )
else
  echo "Devbox install/test is skipped here by default. Use the VM flow in system/vm-testing.md for full-DE validation."
fi

echo "Portable env sandbox test complete."
