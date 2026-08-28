#!/usr/bin/env bash

VM_CONFIG_HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VM_CONFIG_SYSTEM_DIR="$(cd "$VM_CONFIG_HELPER_DIR/.." && pwd)"
VM_CONFIG_REPO_ROOT="$(cd "$VM_CONFIG_SYSTEM_DIR/.." && pwd)"
VM_CONFIG_LOCAL_FILE="$VM_CONFIG_SYSTEM_DIR/vm/desktop-test.local.env"
VM_CONFIG_EXAMPLE_FILE="$VM_CONFIG_SYSTEM_DIR/vm/desktop-test.env.example"
VM_CONFIG_PRESET_DIR="$VM_CONFIG_SYSTEM_DIR/vm/presets"
VM_CONFIG_SHARED_ROOT_DEFAULT="/var/tmp/config-vm"

vm_abspath() {
  local path="$1"

  if [[ "$path" = /* ]]; then
    printf '%s' "$path"
    return
  fi

  printf '%s' "$PWD/$path"
}

vm_assert_path_outside_repo() {
  local path="$1"
  local label="$2"
  local abs_path

  abs_path="$(vm_abspath "$path")"
  case "$abs_path" in
    "$VM_CONFIG_REPO_ROOT"|"$VM_CONFIG_REPO_ROOT"/*)
      printf 'Refusing repo-local %s path: %s\n' "$label" "$abs_path" >&2
      printf 'Keep large ISOs and VM artifacts outside %s\n' "$VM_CONFIG_REPO_ROOT" >&2
      return 1
      ;;
  esac
}

vm_is_system_libvirt() {
  [ "${LIBVIRT_URI:-qemu:///system}" = "qemu:///system" ]
}

vm_assert_path_not_under_home_for_system_libvirt() {
  local path="$1"
  local label="$2"
  local abs_path

  if ! vm_is_system_libvirt; then
    return 0
  fi

  abs_path="$(vm_abspath "$path")"
  case "$abs_path" in
    "$HOME"|"$HOME"/*)
      printf 'Refusing home-directory %s path for qemu:///system: %s\n' "$label" "$abs_path" >&2
      printf 'Use a path outside %s, for example %s\n' "$HOME" "$VM_CONFIG_SHARED_ROOT_DEFAULT" >&2
      return 1
      ;;
  esac
}

vm_ensure_shared_dir() {
  local dir_path="$1"

  mkdir -p "$dir_path"
  chmod 755 "$dir_path"
}

vm_resolve_config_file() {
  if [ "${1:-}" = "" ]; then
    if [ -f "$VM_CONFIG_LOCAL_FILE" ]; then
      printf '%s' "$VM_CONFIG_LOCAL_FILE"
      return
    fi

    printf '%s' "$VM_CONFIG_EXAMPLE_FILE"
    return
  fi

  printf '%s' "$1"
}

vm_list_presets() {
  local preset_file

  for preset_file in "$VM_CONFIG_PRESET_DIR"/*.env; do
    if [ -f "$preset_file" ]; then
      basename "$preset_file" .env
    fi
  done
}

vm_load_config() {
  local config_file="$1"
  local preset_name
  local preset_file

  if [ ! -f "$config_file" ]; then
    printf 'Config file not found: %s\n' "$config_file" >&2
    return 1
  fi

  # shellcheck source=/dev/null
  source "$config_file"

  preset_name="${VM_PRESET:-}"
  if [ -n "$preset_name" ]; then
    preset_file="$VM_CONFIG_PRESET_DIR/$preset_name.env"
    if [ ! -f "$preset_file" ]; then
      printf 'VM preset not found: %s\n' "$preset_name" >&2
      printf 'Available presets:\n' >&2
      vm_list_presets | sed 's/^/  - /' >&2
      return 1
    fi

    # shellcheck source=/dev/null
    source "$preset_file"
    # shellcheck source=/dev/null
    source "$config_file"
  fi
}
