# Dotfiles

My personal Zsh + Starship + Modern CLI setup.

## Quick Start

```bash
# Clone and install on new system
git clone <your-repo> ~/dev/config
cd ~/dev/config/dotfiles
./manage.sh install
```

## What's Included

- **Zsh + Oh My Zsh** with useful plugins
- **Starship** prompt with clean configuration
- **Modern CLI tools**: eza, bat, fd, ripgrep, fzf
- **Enhanced Git** with better diffs
- **Smart aliases** and better history

## Management

```bash
./manage.sh backup    # Backup current configs
./manage.sh restore   # Restore from backup
./manage.sh install   # Full setup on new system
```

## Source of Truth

This directory is the canonical home for these dotfiles.

- Edit and reference `~/dev/config/dotfiles`
- Do not maintain a separate standalone `~/dev/dotfiles` repo copy

## Plugin Management

- `./manage.sh install` installs the third-party Oh My Zsh plugins needed by `.zshrc`
- `.zshrc` is the source of truth for which plugins are enabled in the shell
- Downloaded plugin repos under `custom/plugins/` are treated as install-time dependencies and are gitignored
- If custom plugin code is added later, it can be tracked explicitly at that time

## Files

- `.zshrc` - Zsh configuration
- `starship.toml` - Starship prompt config
- `custom/` - Oh My Zsh custom config and plugin templates

## Setup New Machine

1. Clone this repo
2. Run `./manage.sh install`
3. Restart terminal

Enjoy your modern terminal! 🚀
