#!/usr/bin/env bash

set -euo pipefail

TARGET_USER="${KVM_SERVICE_USER:-libvirt-qemu}"
SERVICE_NAME="${KVM_LIBVIRT_SERVICE:-libvirtd}"

usage() {
  cat <<'EOF'
Usage: sudo ./system/scripts/fix-kvm-access.sh

Ensure the libvirt QEMU service user can access /dev/kvm and related devices.

This script:
- inspects the device groups for /dev/kvm and /dev/vhost-*
- adds the libvirt service user to any missing groups
- restarts libvirtd
EOF
}

if [ "${1:-}" = "help" ] || [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this script with sudo so it can update service-user groups and restart libvirtd."
  exit 1
fi

if ! getent passwd "$TARGET_USER" >/dev/null; then
  echo "Service user not found: $TARGET_USER"
  exit 1
fi

device_paths=(/dev/kvm /dev/vhost-net /dev/vhost-vsock)
required_groups=()

contains_group() {
  local wanted="$1"
  local existing

  for existing in "${required_groups[@]:-}"; do
    if [ "$existing" = "$wanted" ]; then
      return 0
    fi
  done

  return 1
}

for device_path in "${device_paths[@]}"; do
  if [ ! -e "$device_path" ]; then
    continue
  fi

  device_group="$(stat -c '%G' "$device_path")"
  if [ -n "$device_group" ] && [ "$device_group" != "UNKNOWN" ] && ! contains_group "$device_group"; then
    required_groups+=("$device_group")
  fi
done

if [ "${#required_groups[@]}" -eq 0 ]; then
  echo "No KVM-related device groups found."
  exit 1
fi

current_groups="$(id -nG "$TARGET_USER")"
updated=0

for device_group in "${required_groups[@]}"; do
  case " $current_groups " in
    *" $device_group "*)
      ;;
    *)
      usermod -aG "$device_group" "$TARGET_USER"
      updated=1
      ;;
  esac
done

systemctl restart "$SERVICE_NAME"

echo "Updated $TARGET_USER groups: $(id -nG "$TARGET_USER")"
echo "Relevant device permissions:"
for device_path in "${device_paths[@]}"; do
  if [ -e "$device_path" ]; then
    stat -c '%A %U %G %n' "$device_path"
  fi
done

if [ "$updated" -eq 0 ]; then
  echo "No group changes were needed; $SERVICE_NAME was restarted."
else
  echo "Added $TARGET_USER to the required KVM-related groups and restarted $SERVICE_NAME."
fi
