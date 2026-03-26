#!/usr/bin/env bash

set -euo pipefail

if command -v mise >/dev/null 2>&1; then
  mise --version
  exit 0
fi

if [ "${CONFIG_DRY_RUN:-0}" = "1" ]; then
  echo "[dry-run] Would install mise with: curl https://mise.run | sh"
  exit 0
fi

echo "Installing mise"
curl https://mise.run | sh

echo "mise installed. Ensure $HOME/.local/bin is on your PATH if this is a new shell."
