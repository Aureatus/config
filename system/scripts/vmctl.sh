#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOCAL_CONFIG_FILE="$SYSTEM_DIR/vm/desktop-test.local.env"
EXAMPLE_CONFIG_FILE="$SYSTEM_DIR/vm/desktop-test.env.example"

usage() {
  cat <<'EOF'
Usage: ./system/scripts/vmctl.sh <command> [config-file] [snapshot-name]

Commands:
  status            Show VM status
  start             Start the VM
  shutdown          Gracefully shut down the VM
  force-stop        Force stop the VM
  view              Open the VM with virt-viewer
  snapshot-list     List snapshots
  snapshot-create   Create the configured clean snapshot
  snapshot-revert   Revert to the configured clean snapshot

If config-file is omitted, vmctl uses:
  system/vm/desktop-test.local.env   if it exists
  system/vm/desktop-test.env.example otherwise

For snapshot-create and snapshot-revert, the snapshot name defaults to SNAPSHOT_NAME from the config.
EOF
}

resolve_config_file() {
  if [ "${1:-}" = "" ]; then
    if [ -f "$LOCAL_CONFIG_FILE" ]; then
      printf '%s' "$LOCAL_CONFIG_FILE"
      return
    fi

    printf '%s' "$EXAMPLE_CONFIG_FILE"
    return
  fi

  printf '%s' "$1"
}

if [ "${1:-}" = "" ] || [ "${1:-}" = "help" ] || [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

COMMAND="$1"
CONFIG_FILE="$(resolve_config_file "${2:-}")"
SNAPSHOT_OVERRIDE="${3:-}"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Config file not found: $CONFIG_FILE"
  exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

LIBVIRT_URI="${LIBVIRT_URI:-qemu:///system}"
VM_NAME="${VM_NAME:-config-desktop-test}"
SNAPSHOT_NAME="${SNAPSHOT_OVERRIDE:-${SNAPSHOT_NAME:-fresh-install}}"

run_cmd() {
  if [ "${CONFIG_DRY_RUN:-0}" = "1" ]; then
    printf '[dry-run] '
    printf '%q ' "$@"
    printf '\n'
    return
  fi

  "$@"
}

case "$COMMAND" in
  status)
    run_cmd virsh --connect "$LIBVIRT_URI" dominfo "$VM_NAME"
    ;;
  start)
    run_cmd virsh --connect "$LIBVIRT_URI" start "$VM_NAME"
    ;;
  shutdown)
    run_cmd virsh --connect "$LIBVIRT_URI" shutdown "$VM_NAME"
    ;;
  force-stop)
    run_cmd virsh --connect "$LIBVIRT_URI" destroy "$VM_NAME"
    ;;
  view)
    run_cmd virt-viewer --connect "$LIBVIRT_URI" "$VM_NAME"
    ;;
  snapshot-list)
    run_cmd virsh --connect "$LIBVIRT_URI" snapshot-list "$VM_NAME"
    ;;
  snapshot-create)
    run_cmd virsh --connect "$LIBVIRT_URI" snapshot-create-as "$VM_NAME" "$SNAPSHOT_NAME" --description "Config repo VM baseline snapshot"
    ;;
  snapshot-revert)
    run_cmd virsh --connect "$LIBVIRT_URI" snapshot-revert "$VM_NAME" "$SNAPSHOT_NAME" --force
    ;;
  *)
    usage
    exit 1
    ;;
esac
