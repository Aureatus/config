#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/vm-config.sh"
CREATE_VM_SCRIPT="$SCRIPT_DIR/create-test-vm.sh"

usage() {
  cat <<'EOF'
Usage: ./system/scripts/vmctl.sh <command> [config-file] [snapshot-name]

Commands:
  up                Create if missing, start if needed, then open the VM viewer
  reset             Recreate the VM from current config and leave it running
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
  vm_resolve_config_file "$1"
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

vm_load_config "$CONFIG_FILE"

LIBVIRT_URI="${LIBVIRT_URI:-qemu:///system}"
VM_NAME="${VM_NAME:-config-desktop-test}"
SNAPSHOT_NAME="${SNAPSHOT_OVERRIDE:-${SNAPSHOT_NAME:-fresh-install}}"
AUTOINSTALL_OUTPUT_DIR="${AUTOINSTALL_OUTPUT_DIR:-$VM_CONFIG_SHARED_ROOT_DEFAULT/$VM_NAME/autoinstall}"

run_cmd() {
  if [ "${CONFIG_DRY_RUN:-0}" = "1" ]; then
    printf '[dry-run] '
    printf '%q ' "$@"
    printf '\n'
    return
  fi

  "$@"
}

open_viewer() {
  if [ "${CONFIG_DRY_RUN:-0}" = "1" ]; then
    printf '[dry-run] %q %q %q %q %q >%q 2>%q\n' \
      virt-viewer \
      --connect \
      "$LIBVIRT_URI" \
      --spice-disable-usbredir \
      "$VM_NAME" \
      /dev/null \
      /dev/null
    return
  fi

  virt-viewer --connect "$LIBVIRT_URI" --spice-disable-usbredir "$VM_NAME" >/dev/null 2>/dev/null
}

domain_exists() {
  virsh --connect "$LIBVIRT_URI" dominfo "$VM_NAME" >/dev/null 2>&1
}

domain_state() {
  virsh --connect "$LIBVIRT_URI" domstate "$VM_NAME" 2>/dev/null | tr -d '\r'
}

ensure_domain_exists() {
  if domain_exists; then
    return
  fi

  echo "VM '$VM_NAME' does not exist yet. Creating it now..."
  run_cmd "$CREATE_VM_SCRIPT" "$CONFIG_FILE"
}

start_domain_if_needed() {
  local state

  ensure_domain_exists

  if [ "${CONFIG_DRY_RUN:-0}" = "1" ] && ! domain_exists; then
    return
  fi

  state="$(domain_state)"
  case "$state" in
    running|idle|blocked|paused|pmsuspended)
      return
      ;;
    "shut off"|shut*|crashed|nostate)
      echo "Starting VM '$VM_NAME'..."
      run_cmd virsh --connect "$LIBVIRT_URI" start "$VM_NAME"
      ;;
    *)
      echo "VM '$VM_NAME' is in state '$state'. Leaving it unchanged."
      ;;
  esac
}

delete_all_snapshots() {
  local snapshot_name
  local snapshots

  snapshots="$(virsh --connect "$LIBVIRT_URI" snapshot-list "$VM_NAME" --name 2>/dev/null || true)"
  if [ -z "$snapshots" ]; then
    return
  fi

  while IFS= read -r snapshot_name; do
    if [ -n "$snapshot_name" ]; then
      run_cmd virsh --connect "$LIBVIRT_URI" snapshot-delete "$VM_NAME" "$snapshot_name"
    fi
  done <<< "$snapshots"
}

confirm_domain_reset() {
  local confirmation

  if [ "${CONFIG_DRY_RUN:-0}" = "1" ] || [ "${VM_RESET_CONFIRM:-}" = "$VM_NAME" ]; then
    return
  fi

  if [ ! -t 0 ]; then
    echo "Refusing to reset existing VM '$VM_NAME' without confirmation." >&2
    echo "Set VM_RESET_CONFIRM='$VM_NAME' for a non-interactive reset." >&2
    return 1
  fi

  printf "Type the VM name '%s' to destroy and recreate it: " "$VM_NAME"
  read -r confirmation
  if [ "$confirmation" != "$VM_NAME" ]; then
    echo "Reset cancelled."
    return 1
  fi
}

reset_domain() {
  if domain_exists; then
    confirm_domain_reset

    if [ "$(domain_state)" != "shut off" ]; then
      run_cmd virsh --connect "$LIBVIRT_URI" destroy "$VM_NAME"
    fi

    delete_all_snapshots
    run_cmd virsh --connect "$LIBVIRT_URI" undefine "$VM_NAME" --nvram --remove-all-storage
  fi

  run_cmd "$CREATE_VM_SCRIPT" "$CONFIG_FILE"
}

case "$COMMAND" in
  up)
    start_domain_if_needed
    open_viewer
    ;;
  reset)
    reset_domain
    ;;
  status)
    run_cmd virsh --connect "$LIBVIRT_URI" dominfo "$VM_NAME"
    ;;
  start)
    start_domain_if_needed
    ;;
  shutdown)
    run_cmd virsh --connect "$LIBVIRT_URI" shutdown "$VM_NAME"
    ;;
  force-stop)
    run_cmd virsh --connect "$LIBVIRT_URI" destroy "$VM_NAME"
    ;;
  view)
    start_domain_if_needed
    open_viewer
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
