#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
REAL_HOME="$HOME"
TARGET_HOME_DIR="${TARGET_HOME:-$REAL_HOME}"
TARGET_CONFIG_DIR="$TARGET_HOME_DIR/.config"
TARGET_ZSH_DIR="$TARGET_HOME_DIR/.oh-my-zsh"
TARGET_ZSH_CUSTOM_DIR="$TARGET_ZSH_DIR/custom"
TARGET_LOCAL_SHARE_DIR="$TARGET_HOME_DIR/.local/share"
SOURCE_HOME_DIR="${SOURCE_HOME:-$REAL_HOME}"
BACKUP_ROOT="${DOTFILES_BACKUP_DIR:-$TARGET_HOME_DIR/.local/state/config-backups}"
BACKUP_DIR="$BACKUP_ROOT/dotfiles-$(date +%Y%m%d-%H%M%S)"
MISE_SOURCE_FILE="$REPO_ROOT/mise.toml"
TARGET_MISE_CONFIG_FILE="$TARGET_CONFIG_DIR/mise/config.toml"

log() {
  printf '%s\n' "$*"
}

target_home_enabled() {
  [ "$TARGET_HOME_DIR" != "$REAL_HOME" ]
}

copy_to_target() {
  local source_path="$1"
  local target_path="$2"

  if [ ! -e "$source_path" ]; then
    return
  fi

  mkdir -p "$(dirname "$target_path")"
  cp -R "$source_path" "$target_path"
}

backup_current_to_repo() {
  log "Backing up current shell and terminal config into $DOTFILES_DIR"

  copy_to_target "$SOURCE_HOME_DIR/.zshrc" "$DOTFILES_DIR/.zshrc"
  copy_to_target "$SOURCE_HOME_DIR/.config/starship.toml" "$DOTFILES_DIR/starship.toml"
  copy_to_target "$SOURCE_HOME_DIR/.config/cosmic-term/config.toml" "$DOTFILES_DIR/config/cosmic-term/config.toml"
  copy_to_target "$SOURCE_HOME_DIR/.config/ghostty/config" "$DOTFILES_DIR/config/ghostty/config"
  copy_to_target "$SOURCE_HOME_DIR/.config/mise/config.toml" "$MISE_SOURCE_FILE"

  mkdir -p "$DOTFILES_DIR/custom"
  for custom_file in "$SOURCE_HOME_DIR/.oh-my-zsh/custom/"*.zsh; do
    copy_to_target "$custom_file" "$DOTFILES_DIR/custom/$(basename "$custom_file")"
  done

  if [ -d "$SOURCE_HOME_DIR/.oh-my-zsh/custom/themes" ]; then
    mkdir -p "$DOTFILES_DIR/custom/themes"
    cp -R "$SOURCE_HOME_DIR/.oh-my-zsh/custom/themes/." "$DOTFILES_DIR/custom/themes/"
  fi

  log "Backup complete. Review the changes and commit what belongs in the repo."
}

backup_current_home() {
  mkdir -p "$BACKUP_DIR"

  copy_to_target "$TARGET_HOME_DIR/.zshrc" "$BACKUP_DIR/.zshrc"
  copy_to_target "$TARGET_CONFIG_DIR/starship.toml" "$BACKUP_DIR/starship.toml"
  copy_to_target "$TARGET_CONFIG_DIR/cosmic-term/config.toml" "$BACKUP_DIR/config/cosmic-term/config.toml"
  copy_to_target "$TARGET_CONFIG_DIR/ghostty/config" "$BACKUP_DIR/config/ghostty/config"
  copy_to_target "$TARGET_MISE_CONFIG_FILE" "$BACKUP_DIR/config/mise/config.toml"

  if [ -d "$TARGET_ZSH_CUSTOM_DIR" ]; then
    mkdir -p "$BACKUP_DIR/custom"
    for custom_file in "$TARGET_ZSH_CUSTOM_DIR/"*.zsh; do
      copy_to_target "$custom_file" "$BACKUP_DIR/custom/$(basename "$custom_file")"
    done

    if [ -d "$TARGET_ZSH_CUSTOM_DIR/themes" ]; then
      mkdir -p "$BACKUP_DIR/custom/themes"
      cp -R "$TARGET_ZSH_CUSTOM_DIR/themes/." "$BACKUP_DIR/custom/themes/"
    fi
  fi

  log "Current home config backed up to $BACKUP_DIR"
}

restore_mise_from_repo() {
  if [ ! -f "$MISE_SOURCE_FILE" ]; then
    log "No repo-managed mise.toml found at $MISE_SOURCE_FILE"
    return
  fi

  mkdir -p "$(dirname "$TARGET_MISE_CONFIG_FILE")"
  cp "$MISE_SOURCE_FILE" "$TARGET_MISE_CONFIG_FILE"
  log "Restored mise config to $TARGET_MISE_CONFIG_FILE"
}

restore_from_repo() {
  log "Restoring repo-managed dotfiles from $DOTFILES_DIR"

  if target_home_enabled; then
    log "Using alternate target home: $TARGET_HOME_DIR"
  fi

  backup_current_home

  mkdir -p "$TARGET_CONFIG_DIR"
  mkdir -p "$TARGET_CONFIG_DIR/cosmic-term"
  mkdir -p "$TARGET_CONFIG_DIR/ghostty"
  mkdir -p "$TARGET_ZSH_CUSTOM_DIR"

  cp "$DOTFILES_DIR/.zshrc" "$TARGET_HOME_DIR/.zshrc"
  cp "$DOTFILES_DIR/starship.toml" "$TARGET_CONFIG_DIR/starship.toml"
  cp "$DOTFILES_DIR/config/cosmic-term/config.toml" "$TARGET_CONFIG_DIR/cosmic-term/config.toml"
  cp "$DOTFILES_DIR/config/ghostty/config" "$TARGET_CONFIG_DIR/ghostty/config"
  cp -R "$DOTFILES_DIR/custom/." "$TARGET_ZSH_CUSTOM_DIR/"
  restore_mise_from_repo

  log "Restore complete."
}

install_oh_my_zsh() {
  if [ -d "$TARGET_ZSH_DIR" ]; then
    log "Oh My Zsh already installed."
    return
  fi

  if target_home_enabled; then
    log "Installing Oh My Zsh into alternate target home $TARGET_HOME_DIR"
  else
    log "Installing Oh My Zsh"
  fi

  env HOME="$TARGET_HOME_DIR" RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
}

install_starship() {
  if [ "$TARGET_HOME_DIR" = "$REAL_HOME" ] && command -v starship >/dev/null 2>&1; then
    log "Starship already installed."
    return
  fi

  if [ -x "$TARGET_HOME_DIR/.local/bin/starship" ]; then
    log "Starship already installed in $TARGET_HOME_DIR/.local/bin"
    return
  fi

  log "Installing Starship"
  mkdir -p "$TARGET_HOME_DIR/.local/bin"
  curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$TARGET_HOME_DIR/.local/bin"
}

install_font() {
  local font_dir="$TARGET_LOCAL_SHARE_DIR/fonts"
  local archive_path="$font_dir/JetBrainsMono.tar.xz"

  mkdir -p "$font_dir"

  if [ -f "$font_dir/JetBrainsMonoNerdFont-Regular.ttf" ]; then
    log "JetBrains Mono Nerd Font already installed."
    return
  fi

  log "Installing JetBrains Mono Nerd Font"
  curl -fLo "$archive_path" \
    https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.tar.xz
  tar -xf "$archive_path" -C "$font_dir"
  rm -f "$archive_path"
  fc-cache -fv >/dev/null
}

install_plugin() {
  local name="$1"
  local repo_url="$2"
  local plugin_root="$TARGET_ZSH_CUSTOM_DIR/plugins"
  local plugin_dir="$plugin_root/$name"

  mkdir -p "$plugin_root"

  if [ -d "$plugin_dir/.git" ]; then
    log "Updating $name"
    git -C "$plugin_dir" pull --ff-only
    return
  fi

  if [ -d "$plugin_dir" ]; then
    log "Plugin directory already exists for $name. Leaving it in place."
    return
  fi

  log "Installing $name"
  git clone "$repo_url" "$plugin_dir"
}

install_plugins() {
  install_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
  install_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
  install_plugin "zsh-completions" "https://github.com/zsh-users/zsh-completions"
}

install_dotfiles() {
  install_oh_my_zsh
  install_starship
  install_font
  install_plugins
  restore_from_repo

  if [ "$TARGET_HOME_DIR" = "$REAL_HOME" ] && [ "${SHELL:-}" != "$(command -v zsh)" ]; then
    log "Set Zsh as your default shell when ready: chsh -s \"$(command -v zsh)\""
  fi

  log "Installation complete. Restart your terminal or run 'zsh'."
}

case "${1:-help}" in
  backup)
    backup_current_to_repo
    ;;
  restore)
    restore_from_repo
    ;;
  restore-mise)
    restore_mise_from_repo
    ;;
  install)
    install_dotfiles
    ;;
  help|--help|-h)
    echo "Usage: $0 [backup|restore|restore-mise|install]"
    echo ""
    echo "Commands:"
    echo "  backup   Import current shell and terminal config into this repo"
    echo "  restore  Copy repo-managed dotfiles into your home directory"
    echo "  restore-mise  Copy repo-managed mise config into your home directory"
    echo "  install  Install shell tooling, fonts, plugins, and restore dotfiles"
    ;;
  *)
    echo "Usage: $0 [backup|restore|restore-mise|install]"
    exit 1
    ;;
esac
