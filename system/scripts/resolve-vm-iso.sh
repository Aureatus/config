#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/vm-config.sh"

usage() {
  cat <<'EOF'
Usage: ./system/scripts/resolve-vm-iso.sh [config-file]

Resolve the local ISO path for a VM config.

- If ISO_PATH is set, it is used directly.
- If ISO_URL is set, the ISO is downloaded into a local cache and that cached path is returned.

Defaults:
  system/vm/desktop-test.local.env   if it exists
  system/vm/desktop-test.env.example otherwise

Set CONFIG_DRY_RUN=1 to print the expected cached path without downloading.
EOF
}

resolve_config_file() {
  vm_resolve_config_file "$1"
}

log() {
  printf '%s\n' "$*" >&2
}

derive_filename_from_url() {
  local url="$1"
  local stripped_url="${url%%\?*}"
  basename "$stripped_url"
}

verify_sha256() {
  local file_path="$1"
  local expected_sha="$2"

  if ! command -v sha256sum >/dev/null 2>&1; then
    log "sha256sum is required to verify ISO_SHA256"
    exit 1
  fi

  printf '%s  %s\n' "$expected_sha" "$file_path" | sha256sum --check --status
}

if [ "${1:-}" = "help" ] || [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

CONFIG_FILE="$(resolve_config_file "${1:-}")"

if [ ! -f "$CONFIG_FILE" ]; then
  log "Config file not found: $CONFIG_FILE"
  exit 1
fi

vm_load_config "$CONFIG_FILE"

ISO_PATH_VALUE="${ISO_PATH:-}"
ISO_URL="${ISO_URL:-}"
ISO_FILENAME="${ISO_FILENAME:-}"
ISO_SHA256="${ISO_SHA256:-}"
ISO_CACHE_DIR="${ISO_CACHE_DIR:-$VM_CONFIG_SHARED_ROOT_DEFAULT/isos}"
FORCE_ISO_REFRESH="${FORCE_ISO_REFRESH:-0}"

if [ -n "$ISO_PATH_VALUE" ]; then
  vm_assert_path_outside_repo "$ISO_PATH_VALUE" "ISO"
  vm_assert_path_not_under_home_for_system_libvirt "$ISO_PATH_VALUE" "ISO"

  if [ ! -f "$ISO_PATH_VALUE" ]; then
    log "ISO file not found: $ISO_PATH_VALUE"
    exit 1
  fi

  if [ -n "$ISO_SHA256" ] && ! verify_sha256 "$ISO_PATH_VALUE" "$ISO_SHA256"; then
    log "ISO_SHA256 does not match local file: $ISO_PATH_VALUE"
    exit 1
  fi

  printf '%s\n' "$ISO_PATH_VALUE"
  exit 0
fi

if [ -z "$ISO_URL" ]; then
  log "Set either ISO_PATH or ISO_URL in $CONFIG_FILE"
  exit 1
fi

if [ -z "$ISO_FILENAME" ]; then
  ISO_FILENAME="$(derive_filename_from_url "$ISO_URL")"
fi

if [ -z "$ISO_FILENAME" ]; then
  log "Could not derive an ISO filename from ISO_URL. Set ISO_FILENAME explicitly."
  exit 1
fi

cached_iso_path="$ISO_CACHE_DIR/$ISO_FILENAME"
vm_assert_path_outside_repo "$cached_iso_path" "ISO cache"
vm_assert_path_not_under_home_for_system_libvirt "$cached_iso_path" "ISO cache"

if [ -f "$cached_iso_path" ] && [ "$FORCE_ISO_REFRESH" != "1" ]; then
  if [ -n "$ISO_SHA256" ] && ! verify_sha256 "$cached_iso_path" "$ISO_SHA256"; then
    log "Cached ISO checksum mismatch, removing stale file: $cached_iso_path"
    rm -f "$cached_iso_path"
  else
    printf '%s\n' "$cached_iso_path"
    exit 0
  fi
fi

if [ "${CONFIG_DRY_RUN:-0}" = "1" ]; then
  log "[dry-run] Would download $ISO_URL to $cached_iso_path"
  printf '%s\n' "$cached_iso_path"
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  log "curl is required to download ISO_URL"
  exit 1
fi

vm_ensure_shared_dir "$ISO_CACHE_DIR"
tmp_download_path="$cached_iso_path.part"

log "Downloading ISO from $ISO_URL"
curl -fL --progress-bar "$ISO_URL" -o "$tmp_download_path"

if [ -n "$ISO_SHA256" ] && ! verify_sha256 "$tmp_download_path" "$ISO_SHA256"; then
  rm -f "$tmp_download_path"
  log "Downloaded ISO checksum mismatch for $ISO_URL"
  exit 1
fi

mv "$tmp_download_path" "$cached_iso_path"
chmod 644 "$cached_iso_path"
printf '%s\n' "$cached_iso_path"
