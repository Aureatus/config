#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPONENT="${1:-help}"
TARGET_DIR="${2:-.}"
SECOND_ARG="${2:-}"

log() {
  printf '%s\n' "$*"
}

ensure_local_bin_on_path() {
  if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
  fi
}

resolve_repo_path() {
  local path="$1"

  if [ -z "$path" ] || [[ "$path" = /* ]]; then
    printf '%s\n' "$path"
    return
  fi

  if [ -e "$SCRIPT_DIR/$path" ]; then
    printf '%s\n' "$SCRIPT_DIR/$path"
    return
  fi

  printf '%s\n' "$path"
}

usage() {
  cat <<'EOF'
Usage: ./setup.sh <component> [component-arg]

Components:
  bootstrap     Run the preferred local-machine bootstrap path via Ansible
  system        Install curated system packages and tracked Flatpak apps
  dotfiles      Restore shell, prompt, terminal, and mise configuration
  dev-env       Install mise and the pinned runtimes for this repo
  devbox        Install the optional Devbox layer
  vm-desktop    Create or start the full desktop VM and open the viewer
  vm-desktop-reset  Recreate the full desktop VM from current config
  vm-smoke      Create or start the fast smoke-test VM and open the viewer
  vm-smoke-reset  Recreate the smoke-test VM from current config
  desktop-config  Run the Ansible desktop playbook on localhost
  server-config   Run the Ansible server playbook against an inventory
  test-portable-env  Restore config into a disposable target home for safe testing
  capture       Export current machine state into system/state/
  backup-kde    Archive KDE config outside the repo
  sync-ai       Sync shared AI guidance into OpenCode when Bun is available
  opencode      Copy the repo-managed OpenCode project template into a project
  help          Show this help message

Examples:
  ./setup.sh bootstrap
  ./setup.sh dev-env
  INSTALL_DEVBOX=1 ./setup.sh dev-env
  ./setup.sh devbox
  ./setup.sh vm-desktop
  ./setup.sh vm-desktop-reset
  ./setup.sh vm-smoke
  ./setup.sh vm-smoke-reset
  ./setup.sh desktop-config
  ./setup.sh server-config ansible/inventory/hosts.local.ini
  ./setup.sh test-portable-env
  ./setup.sh sync-ai
  ./setup.sh capture
  ./setup.sh opencode ~/dev/projects/my-app
EOF
}

run_system() {
  "$SCRIPT_DIR/system/scripts/install-packages.sh"
}

ensure_ansible_playbook() {
  if command -v ansible-playbook >/dev/null 2>&1; then
    return
  fi

  if [ "${CONFIG_DRY_RUN:-0}" = "1" ]; then
    log "[dry-run] Would install ansible-core and python3-apt so ansible-playbook is available"
    return
  fi

  if ! command -v apt-get >/dev/null 2>&1 || ! command -v sudo >/dev/null 2>&1; then
    log "ansible-playbook is not installed and this host cannot auto-install it. Install ansible-core first."
    exit 1
  fi

  sudo apt-get update
  sudo apt-get install -y ansible-core python3-apt
}

run_ansible_playbook() {
  local playbook_path="$1"
  shift

  ensure_ansible_playbook

  if [ "${CONFIG_DRY_RUN:-0}" = "1" ]; then
    printf '[dry-run] ANSIBLE_CONFIG=%q ansible-playbook %q' "$SCRIPT_DIR/ansible/ansible.cfg" "$playbook_path"
    for arg in "$@"; do
      printf ' %q' "$arg"
    done
    printf '\n'
    return
  fi

  ANSIBLE_CONFIG="$SCRIPT_DIR/ansible/ansible.cfg" ansible-playbook "$playbook_path" "$@"
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

  if [ "${INSTALL_DEVBOX:-0}" = "1" ]; then
    "$SCRIPT_DIR/system/scripts/install-devbox.sh"
    ensure_local_bin_on_path
  fi
}

run_devbox() {
  "$SCRIPT_DIR/system/scripts/install-devbox.sh"
  ensure_local_bin_on_path
}

run_vm_smoke() {
  local vm_config_path="${SECOND_ARG:-$SCRIPT_DIR/system/vm/smoke-test.env.example}"

  "$SCRIPT_DIR/system/scripts/vmctl.sh" up "$vm_config_path"
}

run_vm_smoke_reset() {
  local vm_config_path="${SECOND_ARG:-$SCRIPT_DIR/system/vm/smoke-test.env.example}"

  "$SCRIPT_DIR/system/scripts/vmctl.sh" reset "$vm_config_path"
}

run_vm_desktop() {
  local vm_config_path="${SECOND_ARG:-}"

  if [ -n "$vm_config_path" ]; then
    "$SCRIPT_DIR/system/scripts/vmctl.sh" up "$vm_config_path"
    return
  fi

  "$SCRIPT_DIR/system/scripts/vmctl.sh" up
}

run_vm_desktop_reset() {
  local vm_config_path="${SECOND_ARG:-}"

  if [ -n "$vm_config_path" ]; then
    "$SCRIPT_DIR/system/scripts/vmctl.sh" reset "$vm_config_path"
    return
  fi

  "$SCRIPT_DIR/system/scripts/vmctl.sh" reset
}

run_test_portable_env() {
  "$SCRIPT_DIR/system/scripts/test-portable-env.sh"
}

run_ai_sync() {
  ensure_local_bin_on_path

  if [ "${CONFIG_DRY_RUN:-0}" = "1" ]; then
    log "[dry-run] Would run OpenCode shared context sync"
    return
  fi

  if ! command -v bun >/dev/null 2>&1; then
    log "bun is not installed yet. Install your Bun or mise toolchain first, then run './setup.sh sync-ai'."
    exit 1
  fi

  (
    cd "$SCRIPT_DIR/ai/agents/opencode"
    bun run sync-global
  )
}

run_desktop_config() {
  run_ansible_playbook "$SCRIPT_DIR/ansible/playbooks/desktop.yml" \
    -i "$SCRIPT_DIR/ansible/inventory/localhost.ini" \
    --connection=local \
    --ask-become-pass
}

run_server_config() {
  local inventory_input="${SECOND_ARG:-ansible/inventory/hosts.example.ini}"
  local inventory_path
  local -a extra_args=()

  inventory_path="$(resolve_repo_path "$inventory_input")"

  if [ "${ASK_BECOME_PASS:-0}" = "1" ]; then
    extra_args+=(--ask-become-pass)
  fi

  run_ansible_playbook "$SCRIPT_DIR/ansible/playbooks/server.yml" \
    -i "$inventory_path" \
    "${extra_args[@]}"
}

run_capture() {
  "$SCRIPT_DIR/system/scripts/capture-state.sh"
}

run_backup_kde() {
  "$SCRIPT_DIR/system/scripts/backup-kde-config.sh"
}

run_bootstrap() {
  run_desktop_config
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
  "devbox")
    run_devbox
    ;;
  "vm-desktop")
    run_vm_desktop
    ;;
  "vm-desktop-reset")
    run_vm_desktop_reset
    ;;
  "vm-smoke")
    run_vm_smoke
    ;;
  "vm-smoke-reset")
    run_vm_smoke_reset
    ;;
  "desktop-config"|"ansible-desktop")
    run_desktop_config
    ;;
  "server-config"|"ansible-server")
    run_server_config
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
  "sync-ai"|"ai-sync")
    run_ai_sync
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
