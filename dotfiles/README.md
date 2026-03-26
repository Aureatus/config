# Dotfiles

My personal Zsh + Starship + Modern CLI setup.

## Quick Start

```bash
# Clone and install on new system
git clone git@github.com:Aureatus/config.git ~/dev/config
cd ~/dev/config/dotfiles
../setup.sh dotfiles
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
- `config/` holds tracked terminal emulator config that gets restored into `~/.config/`
- `../mise.toml` is the pinned global runtime config restored into `~/.config/mise/config.toml`

## Plugin Management

- `./manage.sh install` installs the third-party Oh My Zsh plugins needed by `.zshrc`
- `.zshrc` is the source of truth for which plugins are enabled in the shell
- Downloaded plugin repos under `custom/plugins/` are treated as install-time dependencies and are gitignored
- If custom plugin code is added later, it can be tracked explicitly at that time
- `restore-mise` copies the repo-managed `mise.toml` into the target home directory

## Files

- `.zshrc` - Zsh configuration
- `starship.toml` - Starship prompt config
- `config/cosmic-term/config.toml` - Cosmic Terminal config
- `config/ghostty/config` - Ghostty config
- `custom/` - Oh My Zsh custom config and plugin templates

## Setup New Machine

1. Clone this repo
2. Run `./setup.sh dotfiles` from the repo root
3. Run `./setup.sh dev-env` to install `mise`, `devbox`, and the pinned runtimes
4. Run `chsh -s "$(command -v zsh)"` if your login shell is still not Zsh
5. Restart terminal

If you only want to refresh the repo-managed config without reinstalling packages, run `./manage.sh restore` from this directory.

For safe testing, set `TARGET_HOME=/tmp/somewhere` and run `./manage.sh restore` to write into a disposable target instead of your real home directory.
