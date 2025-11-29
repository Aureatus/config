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

## Files

- `.zshrc` - Zsh configuration
- `starship.toml` - Starship prompt config
- `custom/` - Oh My Zsh custom plugins

## Setup New Machine

1. Clone this repo
2. Run `./manage.sh install`
3. Restart terminal

Enjoy your modern terminal! 🚀