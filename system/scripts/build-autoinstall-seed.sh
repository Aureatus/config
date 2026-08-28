#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/vm-config.sh"

default_config_repo_ref() {
  local repo_root="$1"
  local branch_name

  if git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch_name="$(git -C "$repo_root" branch --show-current 2>/dev/null || true)"
  fi

  printf '%s\n' "${branch_name:-main}"
}

default_config_repo_url() {
  local repo_root="$1"
  local remote_url

  if git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    remote_url="$(git -C "$repo_root" remote get-url origin 2>/dev/null || true)"
  fi

  case "$remote_url" in
    git@github.com:*)
      remote_url="https://github.com/${remote_url#git@github.com:}"
      ;;
    ssh://git@github.com/*)
      remote_url="https://github.com/${remote_url#ssh://git@github.com/}"
      ;;
  esac

  printf '%s\n' "${remote_url:-https://github.com/Aureatus/config.git}"
}

build_local_repo_archive() {
  local repo_root="$1"
  local archive_path="$2"
  local repo_path

  git -C "$repo_root" ls-files --cached --others --exclude-standard -z |
    while IFS= read -r -d '' repo_path; do
      if [ -e "$repo_root/$repo_path" ] || [ -L "$repo_root/$repo_path" ]; then
        printf '%s\0' "$repo_path"
      fi
    done |
    tar --null -czf "$archive_path" -C "$repo_root" --files-from=-
}

append_unique_package() {
  local wanted="$1"

  if [ -n "$wanted" ] && ! contains_autoinstall_package "$wanted"; then
    autoinstall_package_list+=("$wanted")
  fi
}

append_packages_from_file() {
  local file_path="$1"
  local line

  if [ ! -f "$file_path" ]; then
    return
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"

    append_unique_package "$line"
  done < "$file_path"
}

usage() {
  cat <<'EOF'
Usage: ./system/scripts/build-autoinstall-seed.sh [config-file]

Render Ubuntu autoinstall user-data/meta-data and build a NoCloud seed ISO.

Defaults:
  system/vm/desktop-test.local.env   if it exists
  system/vm/desktop-test.env.example otherwise
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

AUTOINSTALL_ENABLED="${AUTOINSTALL_ENABLED:-0}"
VM_NAME="${VM_NAME:-config-desktop-test}"
AUTOINSTALL_OUTPUT_DIR="${AUTOINSTALL_OUTPUT_DIR:-$VM_CONFIG_SHARED_ROOT_DEFAULT/$VM_NAME/autoinstall}"
AUTOINSTALL_HOSTNAME="${AUTOINSTALL_HOSTNAME:-$VM_NAME}"
AUTOINSTALL_USERNAME="${AUTOINSTALL_USERNAME:-ubuntu}"
AUTOINSTALL_REALNAME="${AUTOINSTALL_REALNAME:-$AUTOINSTALL_USERNAME}"
AUTOINSTALL_PASSWORD="${AUTOINSTALL_PASSWORD:-}"
AUTOINSTALL_PASSWORD_HASH="${AUTOINSTALL_PASSWORD_HASH:-}"
AUTOINSTALL_LOCALE="${AUTOINSTALL_LOCALE:-en_US.UTF-8}"
AUTOINSTALL_KEYBOARD_LAYOUT="${AUTOINSTALL_KEYBOARD_LAYOUT:-us}"
AUTOINSTALL_TIMEZONE="${AUTOINSTALL_TIMEZONE:-UTC}"
AUTOINSTALL_INSTANCE_ID="${AUTOINSTALL_INSTANCE_ID:-$VM_NAME-autoinstall}"
AUTOINSTALL_INSTALL_OPENSSH="${AUTOINSTALL_INSTALL_OPENSSH:-1}"
AUTOINSTALL_ALLOW_PW="${AUTOINSTALL_ALLOW_PW:-1}"
AUTOINSTALL_SSH_KEY_FILE="${AUTOINSTALL_SSH_KEY_FILE:-}"
AUTOINSTALL_ENABLE_AUTOLOGIN="${AUTOINSTALL_ENABLE_AUTOLOGIN:-0}"
AUTOINSTALL_PACKAGES="${AUTOINSTALL_PACKAGES:-qemu-guest-agent plasma-desktop sddm konsole git curl}"
AUTOINSTALL_AUTO_APPLY_CONFIG="${AUTOINSTALL_AUTO_APPLY_CONFIG:-0}"
AUTOINSTALL_INCLUDE_BOOTSTRAP_PACKAGES="${AUTOINSTALL_INCLUDE_BOOTSTRAP_PACKAGES:-$AUTOINSTALL_AUTO_APPLY_CONFIG}"
AUTOINSTALL_CONFIG_REPO_MODE="${AUTOINSTALL_CONFIG_REPO_MODE:-remote-clone}"
AUTOINSTALL_CONFIG_REPO_URL="${AUTOINSTALL_CONFIG_REPO_URL:-$(default_config_repo_url "$VM_CONFIG_REPO_ROOT")}"
AUTOINSTALL_CONFIG_REPO_REF="${AUTOINSTALL_CONFIG_REPO_REF:-$(default_config_repo_ref "$VM_CONFIG_REPO_ROOT")}"
AUTOINSTALL_CONFIG_PLAYBOOK="${AUTOINSTALL_CONFIG_PLAYBOOK:-ansible/playbooks/desktop.yml}"
AUTOINSTALL_SOURCE_ID="${AUTOINSTALL_SOURCE_ID:-}"
autoinstall_package_list=()

contains_autoinstall_package() {
  local wanted="$1"
  local existing

  for existing in "${autoinstall_package_list[@]:-}"; do
    if [ "$existing" = "$wanted" ]; then
      return 0
    fi
  done

  return 1
}

if [ "$AUTOINSTALL_ENABLED" != "1" ]; then
  echo "AUTOINSTALL_ENABLED is not set to 1 in $CONFIG_FILE"
  exit 1
fi

vm_assert_path_outside_repo "$AUTOINSTALL_OUTPUT_DIR" "autoinstall output"
vm_assert_path_not_under_home_for_system_libvirt "$AUTOINSTALL_OUTPUT_DIR" "autoinstall output"

if [ -z "$AUTOINSTALL_PASSWORD_HASH" ]; then
  if [ -z "$AUTOINSTALL_PASSWORD" ]; then
    echo "Set AUTOINSTALL_PASSWORD or AUTOINSTALL_PASSWORD_HASH in $CONFIG_FILE"
    exit 1
  fi

  if ! command -v openssl >/dev/null 2>&1; then
    echo "openssl is required to hash AUTOINSTALL_PASSWORD"
    exit 1
  fi

  AUTOINSTALL_PASSWORD_HASH="$(printf '%s' "$AUTOINSTALL_PASSWORD" | openssl passwd -6 -stdin)"
fi

vm_ensure_shared_dir "$AUTOINSTALL_OUTPUT_DIR"

USER_DATA_PATH="$AUTOINSTALL_OUTPUT_DIR/user-data"
META_DATA_PATH="$AUTOINSTALL_OUTPUT_DIR/meta-data"
SEED_ISO_PATH="$AUTOINSTALL_OUTPUT_DIR/seed.iso"
REPO_ARCHIVE_PATH="$AUTOINSTALL_OUTPUT_DIR/config-repo.tar.gz"
FIRSTBOOT_SCRIPT_PATH="$AUTOINSTALL_OUTPUT_DIR/config-firstboot.sh"
FIRSTBOOT_SERVICE_PATH="$AUTOINSTALL_OUTPUT_DIR/config-firstboot.service"

rm -f "$SEED_ISO_PATH"
rm -f "$REPO_ARCHIVE_PATH"
rm -f "$FIRSTBOOT_SCRIPT_PATH" "$FIRSTBOOT_SERVICE_PATH"

case "$AUTOINSTALL_CONFIG_REPO_MODE" in
  local-archive)
    build_local_repo_archive "$VM_CONFIG_REPO_ROOT" "$REPO_ARCHIVE_PATH"
    ;;
  remote-clone)
    ;;
  *)
    echo "Unsupported AUTOINSTALL_CONFIG_REPO_MODE: $AUTOINSTALL_CONFIG_REPO_MODE"
    echo "Use one of: local-archive, remote-clone"
    exit 1
    ;;
esac

if [ "$AUTOINSTALL_AUTO_APPLY_CONFIG" = "1" ]; then
  cat > "$FIRSTBOOT_SCRIPT_PATH" <<EOF
#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/config-firstboot.log"
MARKER_FILE="/var/lib/config-firstboot.done"
TARGET_USER="${AUTOINSTALL_USERNAME}"
TARGET_HOME="/home/${AUTOINSTALL_USERNAME}"
REPO_MODE="${AUTOINSTALL_CONFIG_REPO_MODE}"
REPO_URL="${AUTOINSTALL_CONFIG_REPO_URL}"
REPO_REF="${AUTOINSTALL_CONFIG_REPO_REF}"
REPO_DIR="\$TARGET_HOME/dev/config"
REPO_ARCHIVE="/var/tmp/config-repo.tar.gz"
ANSIBLE_CONFIG_PATH="\$REPO_DIR/ansible/ansible.cfg"
PLAYBOOK_PATH="\$REPO_DIR/${AUTOINSTALL_CONFIG_PLAYBOOK}"
INVENTORY_PATH="\$REPO_DIR/ansible/inventory/localhost.ini"
BOOTSTRAP_SUDOERS="/etc/sudoers.d/90-${AUTOINSTALL_USERNAME}-config-bootstrap"

exec > >(tee -a "\$LOG_FILE") 2>&1

if [ -f "\$MARKER_FILE" ]; then
  echo "[config-firstboot] already completed"
  exit 0
fi

echo "[config-firstboot] preparing repo from mode \$REPO_MODE"
install -d -m 0755 -o "\$TARGET_USER" -g "\$TARGET_USER" "\$TARGET_HOME/dev"

if [ "\$REPO_MODE" = "local-archive" ] && [ -f "\$REPO_ARCHIVE" ]; then
  rm -rf "\$REPO_DIR"
  install -d -m 0755 -o "\$TARGET_USER" -g "\$TARGET_USER" "\$REPO_DIR"
  tar -xzf "\$REPO_ARCHIVE" -C "\$REPO_DIR"
  chown -R "\$TARGET_USER":"\$TARGET_USER" "\$REPO_DIR"
else
  echo "[config-firstboot] cloning \$REPO_URL (ref \$REPO_REF)"
  if [ -d "\$REPO_DIR/.git" ]; then
    sudo -u "\$TARGET_USER" git -C "\$REPO_DIR" fetch --depth 1 origin "\$REPO_REF"
    sudo -u "\$TARGET_USER" git -C "\$REPO_DIR" checkout "\$REPO_REF"
    sudo -u "\$TARGET_USER" git -C "\$REPO_DIR" reset --hard FETCH_HEAD
  else
    sudo -u "\$TARGET_USER" git clone --depth 1 --branch "\$REPO_REF" "\$REPO_URL" "\$REPO_DIR"
  fi
fi

echo "[config-firstboot] applying \$PLAYBOOK_PATH"
sudo -u "\$TARGET_USER" env ANSIBLE_CONFIG="\$ANSIBLE_CONFIG_PATH" ansible-playbook "\$PLAYBOOK_PATH" -i "\$INVENTORY_PATH" --connection=local -e config_install_packages=false -e config_install_flatpak_apps=false

rm -f "\$BOOTSTRAP_SUDOERS"
touch "\$MARKER_FILE"
systemctl disable config-firstboot.service >/dev/null 2>&1 || true
echo "[config-firstboot] complete"
EOF

  cat > "$FIRSTBOOT_SERVICE_PATH" <<EOF
[Unit]
Description=Config first-boot apply
After=network-online.target
Wants=network-online.target
ConditionPathExists=!/var/lib/config-firstboot.done

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/config-firstboot.sh

[Install]
WantedBy=multi-user.target
EOF

  chmod 755 "$FIRSTBOOT_SCRIPT_PATH"
  chmod 644 "$FIRSTBOOT_SERVICE_PATH"
fi

cat > "$USER_DATA_PATH" <<EOF
#cloud-config
autoinstall:
  version: 1
  locale: $AUTOINSTALL_LOCALE
  keyboard:
    layout: $AUTOINSTALL_KEYBOARD_LAYOUT
  timezone: $AUTOINSTALL_TIMEZONE
EOF

if [ -n "$AUTOINSTALL_SOURCE_ID" ]; then
  cat >> "$USER_DATA_PATH" <<EOF
  source:
    id: $AUTOINSTALL_SOURCE_ID
EOF
fi

cat >> "$USER_DATA_PATH" <<EOF
  identity:
    hostname: $AUTOINSTALL_HOSTNAME
    realname: $AUTOINSTALL_REALNAME
    username: $AUTOINSTALL_USERNAME
    password: '$AUTOINSTALL_PASSWORD_HASH'
  storage:
    layout:
      name: direct
  ssh:
    install-server: $( [ "$AUTOINSTALL_INSTALL_OPENSSH" = "1" ] && printf 'true' || printf 'false' )
    allow-pw: $( [ "$AUTOINSTALL_ALLOW_PW" = "1" ] && printf 'true' || printf 'false' )
EOF

if [ -n "$AUTOINSTALL_SSH_KEY_FILE" ]; then
  if [ ! -f "$AUTOINSTALL_SSH_KEY_FILE" ]; then
    echo "SSH key file not found: $AUTOINSTALL_SSH_KEY_FILE"
    exit 1
  fi

  {
    printf '    authorized-keys:\n'
    while IFS= read -r key_line || [ -n "$key_line" ]; do
      if [ -n "$key_line" ]; then
        printf '      - %s\n' "$key_line"
      fi
    done < "$AUTOINSTALL_SSH_KEY_FILE"
  } >> "$USER_DATA_PATH"
fi

for package_name in $AUTOINSTALL_PACKAGES; do
  append_unique_package "$package_name"
done

if [ "$AUTOINSTALL_INCLUDE_BOOTSTRAP_PACKAGES" = "1" ]; then
  append_packages_from_file "$VM_CONFIG_SYSTEM_DIR/packages/apt.txt"
fi

if [ "$AUTOINSTALL_AUTO_APPLY_CONFIG" = "1" ]; then
  append_unique_package 'ansible-core'
  append_unique_package 'python3-apt'
fi

if [ "${#autoinstall_package_list[@]}" -gt 0 ]; then
  {
    printf '  packages:\n'
    for package_name in "${autoinstall_package_list[@]}"; do
      printf '    - %s\n' "$package_name"
    done
  } >> "$USER_DATA_PATH"
fi

if [ "$AUTOINSTALL_AUTO_APPLY_CONFIG" = "1" ]; then

  cat >> "$USER_DATA_PATH" <<EOF
  user-data:
    write_files:
EOF

  if [ "$AUTOINSTALL_CONFIG_REPO_MODE" = "local-archive" ]; then
    cat >> "$USER_DATA_PATH" <<EOF
      - path: /var/tmp/config-repo.tar.gz
        permissions: '0644'
        owner: root:root
        encoding: b64
        content: |
EOF
    base64 "$REPO_ARCHIVE_PATH" | sed 's/^/          /' >> "$USER_DATA_PATH"
  fi

  cat >> "$USER_DATA_PATH" <<EOF
      - path: /etc/sudoers.d/90-${AUTOINSTALL_USERNAME}-config-bootstrap
        permissions: '0440'
        owner: root:root
        content: |
          ${AUTOINSTALL_USERNAME} ALL=(ALL) NOPASSWD:ALL
      - path: /usr/local/sbin/config-firstboot.sh
        permissions: '0755'
        owner: root:root
        content: |
          #!/usr/bin/env bash
          set -euo pipefail

          LOG_FILE="/var/log/config-firstboot.log"
          MARKER_FILE="/var/lib/config-firstboot.done"
          TARGET_USER="${AUTOINSTALL_USERNAME}"
          TARGET_HOME="/home/${AUTOINSTALL_USERNAME}"
          REPO_MODE="${AUTOINSTALL_CONFIG_REPO_MODE}"
          REPO_URL="${AUTOINSTALL_CONFIG_REPO_URL}"
          REPO_REF="${AUTOINSTALL_CONFIG_REPO_REF}"
          REPO_DIR="\$TARGET_HOME/dev/config"
          REPO_ARCHIVE="/var/tmp/config-repo.tar.gz"
          ANSIBLE_CONFIG_PATH="\$REPO_DIR/ansible/ansible.cfg"
          PLAYBOOK_PATH="\$REPO_DIR/${AUTOINSTALL_CONFIG_PLAYBOOK}"
          INVENTORY_PATH="\$REPO_DIR/ansible/inventory/localhost.ini"
          BOOTSTRAP_SUDOERS="/etc/sudoers.d/90-${AUTOINSTALL_USERNAME}-config-bootstrap"

          exec > >(tee -a "\$LOG_FILE") 2>&1

          if [ -f "\$MARKER_FILE" ]; then
            echo "[config-firstboot] already completed"
            exit 0
          fi

          echo "[config-firstboot] preparing repo from mode \$REPO_MODE"
          install -d -m 0755 -o "\$TARGET_USER" -g "\$TARGET_USER" "\$TARGET_HOME/dev"

          if [ "\$REPO_MODE" = "local-archive" ] && [ -f "\$REPO_ARCHIVE" ]; then
            rm -rf "\$REPO_DIR"
            install -d -m 0755 -o "\$TARGET_USER" -g "\$TARGET_USER" "\$REPO_DIR"
            tar -xzf "\$REPO_ARCHIVE" -C "\$REPO_DIR"
            chown -R "\$TARGET_USER":"\$TARGET_USER" "\$REPO_DIR"
          else
            echo "[config-firstboot] cloning \$REPO_URL (ref \$REPO_REF)"
            if [ -d "\$REPO_DIR/.git" ]; then
              sudo -u "\$TARGET_USER" git -C "\$REPO_DIR" fetch --depth 1 origin "\$REPO_REF"
              sudo -u "\$TARGET_USER" git -C "\$REPO_DIR" checkout "\$REPO_REF"
              sudo -u "\$TARGET_USER" git -C "\$REPO_DIR" reset --hard FETCH_HEAD
            else
              sudo -u "\$TARGET_USER" git clone --depth 1 --branch "\$REPO_REF" "\$REPO_URL" "\$REPO_DIR"
            fi
          fi

          echo "[config-firstboot] applying \$PLAYBOOK_PATH"
          sudo -u "\$TARGET_USER" env ANSIBLE_CONFIG="\$ANSIBLE_CONFIG_PATH" ansible-playbook "\$PLAYBOOK_PATH" -i "\$INVENTORY_PATH" --connection=local -e config_install_packages=false -e config_install_flatpak_apps=false

          rm -f "\$BOOTSTRAP_SUDOERS"
          touch "\$MARKER_FILE"
          echo "[config-firstboot] complete"
    runcmd:
      - [ bash, -lc, /usr/local/sbin/config-firstboot.sh ]
EOF
fi

cat >> "$USER_DATA_PATH" <<EOF
  late-commands:
EOF

if [ "$AUTOINSTALL_ENABLE_AUTOLOGIN" = "1" ]; then
  cat >> "$USER_DATA_PATH" <<EOF
    - curtin in-target --target=/target -- mkdir -p /etc/systemd/system/getty@tty1.service.d
    - curtin in-target --target=/target -- sh -c 'printf "[Service]\\nExecStart=\\nExecStart=-/sbin/agetty --autologin ${AUTOINSTALL_USERNAME} --noclear %%I linux\\n" > /etc/systemd/system/getty@tty1.service.d/autologin.conf'
    - curtin in-target --target=/target -- mkdir -p /etc/sddm.conf.d
    - curtin in-target --target=/target -- sh -c 'printf "[Autologin]\\nUser=${AUTOINSTALL_USERNAME}\\nSession=plasma.desktop\\n" > /etc/sddm.conf.d/autologin.conf'
EOF
fi

if [ "$AUTOINSTALL_AUTO_APPLY_CONFIG" = "1" ]; then
  cat >> "$USER_DATA_PATH" <<'EOF'
    - sh -c 'set -e; SEED_MNT=/run/config-seed; SEED_DEV="$(blkid -L CIDATA 2>/dev/null || true)"; [ -n "$SEED_DEV" ] || SEED_DEV=/dev/sr1; mkdir -p "$SEED_MNT" /target/usr/local/sbin /target/etc/systemd/system /target/var/tmp; mount -o ro "$SEED_DEV" "$SEED_MNT"; cp "$SEED_MNT/config-firstboot.sh" /target/usr/local/sbin/config-firstboot.sh; cp "$SEED_MNT/config-firstboot.service" /target/etc/systemd/system/config-firstboot.service; if [ -f "$SEED_MNT/config-repo.tar.gz" ]; then cp "$SEED_MNT/config-repo.tar.gz" /target/var/tmp/config-repo.tar.gz; fi; umount "$SEED_MNT"'
    - curtin in-target --target=/target -- systemctl enable config-firstboot.service
EOF
fi

cat >> "$USER_DATA_PATH" <<'EOF'
    - curtin in-target --target=/target -- systemctl enable qemu-guest-agent || true
    - curtin in-target --target=/target -- systemctl enable sddm || true
    - curtin in-target --target=/target -- systemctl set-default graphical.target || true
EOF

cat > "$META_DATA_PATH" <<EOF
instance-id: $AUTOINSTALL_INSTANCE_ID
local-hostname: $AUTOINSTALL_HOSTNAME
EOF

chmod 644 "$USER_DATA_PATH" "$META_DATA_PATH"

if ! command -v xorriso >/dev/null 2>&1; then
  echo "xorriso is required to build the seed ISO"
  exit 1
fi

(
  cd "$AUTOINSTALL_OUTPUT_DIR"
  xorriso -as mkisofs -output "$SEED_ISO_PATH" -volid CIDATA -joliet -rock . >/dev/null 2>&1
)

chmod 644 "$SEED_ISO_PATH"

printf '%s\n' "$SEED_ISO_PATH"
