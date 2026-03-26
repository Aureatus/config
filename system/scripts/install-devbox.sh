#!/usr/bin/env bash

set -euo pipefail

if command -v devbox >/dev/null 2>&1; then
  devbox version
  exit 0
fi

if [ "$(id -u)" -eq 0 ]; then
  echo "Run the Devbox installer as a non-root user."
  exit 1
fi

if [ "${CONFIG_DRY_RUN:-0}" = "1" ]; then
  echo "[dry-run] Would install Devbox with: curl -fsSL https://get.jetify.com/devbox | bash"
  exit 0
fi

echo "Installing Devbox"
echo "Note: Devbox may install Nix in single-user mode if it is not already present."
curl -fsSL https://get.jetify.com/devbox | bash
