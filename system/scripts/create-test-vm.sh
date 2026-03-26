#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOCAL_CONFIG_FILE="$SYSTEM_DIR/vm/desktop-test.local.env"
EXAMPLE_CONFIG_FILE="$SYSTEM_DIR/vm/desktop-test.env.example"

usage() {
  cat <<'EOF'
Usage: ./system/scripts/create-test-vm.sh [config-file]

Create the desktop validation VM using virt-install and a sourced env file.

Defaults:
  system/vm/desktop-test.local.env   if it exists
  system/vm/desktop-test.env.example otherwise

Set CONFIG_DRY_RUN=1 to print the virt-install command without creating the VM.
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

if [ "${1:-}" = "help" ] || [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

CONFIG_FILE="$(resolve_config_file "${1:-}")"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Config file not found: $CONFIG_FILE"
  exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

LIBVIRT_URI="${LIBVIRT_URI:-qemu:///system}"
VM_NAME="${VM_NAME:-config-desktop-test}"
ISO_PATH="${ISO_PATH:-}"
VCPUS="${VCPUS:-3}"
RAM_MB="${RAM_MB:-8192}"
DISK_SIZE_GB="${DISK_SIZE_GB:-64}"
NETWORK_NAME="${NETWORK_NAME:-default}"
BOOT_FIRMWARE="${BOOT_FIRMWARE:-uefi}"
GRAPHICS="${GRAPHICS:-spice}"
VIDEO_MODEL="${VIDEO_MODEL:-virtio}"
OSINFO_NAME="${OSINFO_NAME:-}"
DISK_PATH="${DISK_PATH:-}"
VM_AUTOSTART="${VM_AUTOSTART:-0}"

if ! command -v virt-install >/dev/null 2>&1; then
  echo "virt-install is required. Install the libvirt virt-install tooling first."
  exit 1
fi

if [ -z "$ISO_PATH" ]; then
  echo "Set ISO_PATH in $CONFIG_FILE before creating the VM."
  exit 1
fi

if [ ! -f "$ISO_PATH" ]; then
  echo "ISO file not found: $ISO_PATH"
  exit 1
fi

disk_arg="size=$DISK_SIZE_GB,format=qcow2,bus=virtio"
if [ -n "$DISK_PATH" ]; then
  if [ "${CONFIG_DRY_RUN:-0}" != "1" ]; then
    mkdir -p "$(dirname "$DISK_PATH")"
  fi
  disk_arg="path=$DISK_PATH,size=$DISK_SIZE_GB,format=qcow2,bus=virtio"
fi

osinfo_arg="detect=on,require=off"
if [ -n "$OSINFO_NAME" ]; then
  osinfo_arg="$osinfo_arg,name=$OSINFO_NAME"
fi

cmd=(
  virt-install
  --connect "$LIBVIRT_URI"
  --name "$VM_NAME"
  --memory "$RAM_MB"
  --vcpus "$VCPUS"
  --cpu host-passthrough
  --disk "$disk_arg"
  --cdrom "$ISO_PATH"
  --network "network=$NETWORK_NAME,model=virtio"
  --graphics "$GRAPHICS"
  --video "$VIDEO_MODEL"
  --sound none
  --rng /dev/urandom
  --osinfo "$osinfo_arg"
  --boot "$BOOT_FIRMWARE"
  --noautoconsole
)

if [ "${CONFIG_DRY_RUN:-0}" = "1" ]; then
  printf '[dry-run] '
  printf '%q ' "${cmd[@]}"
  printf '\n'
  exit 0
fi

"${cmd[@]}"

if [ "$VM_AUTOSTART" = "1" ]; then
  virsh --connect "$LIBVIRT_URI" autostart "$VM_NAME"
fi

echo "Created VM '$VM_NAME' using $CONFIG_FILE"
echo "Open the guest with: ./system/scripts/vmctl.sh view $CONFIG_FILE"
echo "After the base OS install, create the clean snapshot with: ./system/scripts/vmctl.sh snapshot-create $CONFIG_FILE"
