#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPONENT="${1:-help}"
TARGET_DIR="${2:-.}"

log() {
  printf '%s\n' "$*"
}

ensure_local_bin_on_path() {
  if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
  fi
}

usage() {
  cat <<'EOF'
Usage: ./setup.sh <component> [target-directory]

Components:
  bootstrap     Install base packages and restore repo-managed user config
  system        Install curated system packages and tracked Flatpak apps
  dotfiles      Restore shell, prompt, terminal, and mise configuration
  dev-env       Install mise/devbox and install pinned runtimes for this repo
  test-portable-env  Restore config into a disposable target home for safe testing
  capture       Export current machine state into system/state/
  backup-kde    Archive KDE config outside the repo
  opencode      Copy the repo-managed OpenCode project template into a project
  help          Show this help message

Examples:
  ./setup.sh bootstrap
  ./setup.sh dev-env
  ./setup.sh test-portable-env
  ./setup.sh capture
  ./setup.sh opencode ~/dev/projects/my-app
EOF
}

run_system() {
  "$SCRIPT_DIR/system/scripts/install-packages.sh"
}

run_dotfiles() {
  if [ "${CONFIG_DRY_RUN:-0}" = "1" ]; then
    log "[dry-run] Would restore dotfiles and global mise config into ${TARGET_HOME:-$HOME}"
    return
  fi

  "$SCRIPT_DIR/dotfiles/manage.sh" install
}

run_mise_install() {
  ensure_local_bin_on_path

  if [ "${CONFIG_DRY_RUN:-0}" = "1" ]; then
    log "[dry-run] Would restore mise config into ${TARGET_HOME:-$HOME} and run 'mise install' from $SCRIPT_DIR"
    return
  fi

  "$SCRIPT_DIR/dotfiles/manage.sh" restore-mise

  if ! command -v mise >/dev/null 2>&1; then
    log "mise is not installed yet. Run './setup.sh dev-env' to install the pinned toolchain."
    return
  fi

  (
    cd "$SCRIPT_DIR"
    mise trust -y "$SCRIPT_DIR/mise.toml" >/dev/null
    mise trust -y "$HOME/.config/mise/config.toml" >/dev/null 2>&1 || true
    mise install
  )
}

run_dev_env() {
  "$SCRIPT_DIR/system/scripts/install-mise.sh"
  ensure_local_bin_on_path
  run_mise_install

  if [ "${SKIP_DEVBOX_INSTALL:-0}" = "1" ]; then
    log "Skipping Devbox install because SKIP_DEVBOX_INSTALL=1."
    return
  fi

  "$SCRIPT_DIR/system/scripts/install-devbox.sh"
  ensure_local_bin_on_path
}

run_test_portable_env() {
  "$SCRIPT_DIR/system/scripts/test-portable-env.sh"
}

run_capture() {
  "$SCRIPT_DIR/system/scripts/capture-state.sh"
}

run_backup_kde() {
  "$SCRIPT_DIR/system/scripts/backup-kde-config.sh"
}

run_bootstrap() {
  run_system
  run_dotfiles
  run_mise_install
}

case "$COMPONENT" in
  "bootstrap"|"all")
    run_bootstrap
    ;;
  "system")
    run_system
    ;;
  "dotfiles")
    run_dotfiles
    ;;
  "dev-env"|"portable-tools")
    run_dev_env
    ;;
  "test-portable-env")
    run_test_portable_env
    ;;
  "capture")
    run_capture
    ;;
  "backup-kde")
    run_backup_kde
    ;;
  "opencode"|"ai/opencode"|"ai/agents/opencode")
    "$SCRIPT_DIR/ai/agents/opencode/setup.sh" "$TARGET_DIR"
    ;;
  "help"|"-h"|"--help")
    usage
    ;;
  *)
    echo "Unknown component: $COMPONENT"
    echo ""
    usage
    exit 1
    ;;
esac
