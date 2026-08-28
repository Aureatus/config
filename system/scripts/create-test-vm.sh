#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ISO_RESOLVER_SCRIPT="$SYSTEM_DIR/scripts/resolve-vm-iso.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/vm-config.sh"

usage() {
  cat <<'EOF'
Usage: ./system/scripts/create-test-vm.sh [config-file]

Create the desktop validation VM using virt-install and a sourced env file.

If AUTOINSTALL_ENABLED=1 in the config, this script also renders a NoCloud seed ISO
and switches to the Ubuntu autoinstall boot path.

Defaults:
  system/vm/desktop-test.local.env   if it exists
  system/vm/desktop-test.env.example otherwise

Set CONFIG_DRY_RUN=1 to print the virt-install command without creating the VM.
EOF
}

resolve_config_file() {
  vm_resolve_config_file "$1"
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

vm_load_config "$CONFIG_FILE"

LIBVIRT_URI="${LIBVIRT_URI:-qemu:///system}"
VM_NAME="${VM_NAME:-config-desktop-test}"
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
AUTOINSTALL_ENABLED="${AUTOINSTALL_ENABLED:-0}"
INSTALL_KERNEL_PATH="${INSTALL_KERNEL_PATH:-casper/vmlinuz}"
INSTALL_INITRD_PATH="${INSTALL_INITRD_PATH:-casper/initrd}"
AUTOINSTALL_OUTPUT_DIR="${AUTOINSTALL_OUTPUT_DIR:-$VM_CONFIG_SHARED_ROOT_DEFAULT/$VM_NAME/autoinstall}"
AUTOINSTALL_AUTO_APPLY_CONFIG="${AUTOINSTALL_AUTO_APPLY_CONFIG:-0}"
AUTOINSTALL_CONFIG_PLAYBOOK="${AUTOINSTALL_CONFIG_PLAYBOOK:-ansible/playbooks/desktop.yml}"
AUTOINSTALL_CONFIG_REPO_MODE="${AUTOINSTALL_CONFIG_REPO_MODE:-remote-clone}"
VM_ACCEL="${VM_ACCEL:-kvm}"

if ! command -v virt-install >/dev/null 2>&1; then
  echo "virt-install is required. Install the libvirt virt-install tooling first."
  exit 1
fi

resolved_iso_path="$("$ISO_RESOLVER_SCRIPT" "$CONFIG_FILE")"

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
  --network "network=$NETWORK_NAME,model=virtio"
  --graphics "$GRAPHICS"
  --video "$VIDEO_MODEL"
  --sound none
  --rng /dev/urandom
  --osinfo "$osinfo_arg"
  --boot "$BOOT_FIRMWARE"
  --noautoconsole
)

case "$VM_ACCEL" in
  kvm)
    cmd+=(--virt-type kvm)
    ;;
  tcg|qemu)
    cmd+=(--virt-type qemu)
    ;;
  auto)
    ;;
  *)
    echo "Unsupported VM_ACCEL value: $VM_ACCEL"
    echo "Use one of: kvm, tcg, auto"
    exit 1
    ;;
esac

if [ "$AUTOINSTALL_ENABLED" = "1" ]; then
  seed_iso_path="$SYSTEM_DIR/scripts/build-autoinstall-seed.sh"
  if [ "${CONFIG_DRY_RUN:-0}" = "1" ]; then
    generated_seed_iso="$AUTOINSTALL_OUTPUT_DIR/seed.iso"
  else
    generated_seed_iso="$("$seed_iso_path" "$CONFIG_FILE")"
  fi

  cmd+=(
    --disk "path=$generated_seed_iso,device=cdrom,readonly=on"
    --location "$resolved_iso_path,kernel=$INSTALL_KERNEL_PATH,initrd=$INSTALL_INITRD_PATH"
    --extra-args "autoinstall"
  )
else
  cmd+=(--cdrom "$resolved_iso_path")
fi

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
if [ "$AUTOINSTALL_ENABLED" = "1" ]; then
  echo "Autoinstall is enabled. Watch the guest until it reboots into the installed system."
  if [ "$AUTOINSTALL_AUTO_APPLY_CONFIG" = "1" ]; then
    if [ "$AUTOINSTALL_CONFIG_REPO_MODE" = "local-archive" ]; then
      echo "First boot will unpack the current local config working tree and run $AUTOINSTALL_CONFIG_PLAYBOOK inside the guest."
    else
      echo "First boot will auto-clone the config repo and run $AUTOINSTALL_CONFIG_PLAYBOOK inside the guest."
    fi
    echo "Follow progress in the guest or inspect /var/log/config-firstboot.log after boot."
  fi
fi
echo "After the base OS install, create the clean snapshot with: ./system/scripts/vmctl.sh snapshot-create $CONFIG_FILE"
