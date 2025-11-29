#!/bin/bash

# Dotfiles backup and restore script
# Usage: ./manage.sh [backup|restore|install]

DOTFILES_DIR="$HOME/dev/config/dotfiles"
BACKUP_DIR="$DOTFILES_DIR/backups/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

case "$1" in
    backup)
        echo "📦 Backing up dotfiles..."
        mkdir -p "$DOTFILES_DIR"
        cp ~/.zshrc "$DOTFILES_DIR/" 2>/dev/null || true
        cp ~/.config/starship.toml "$DOTFILES_DIR/" 2>/dev/null || true
        # Only backup custom configs, not the plugin repos themselves
        mkdir -p "$DOTFILES_DIR/custom/plugins"
        cp -r ~/.oh-my-zsh/custom/*.zsh "$DOTFILES_DIR/custom/" 2>/dev/null || true
        echo "✅ Backed up to $DOTFILES_DIR"
        ;;
        
    restore)
        echo "🔄 Restoring dotfiles..."
        if [ ! -d "$DOTFILES_DIR" ]; then
            echo "❌ Dotfiles directory not found: $DOTFILES_DIR"
            exit 1
        fi
        
        # Create backup of current configs
        mkdir -p "$BACKUP_DIR"
        cp ~/.zshrc "$BACKUP_DIR/" 2>/dev/null || true
        cp ~/.config/starship.toml "$BACKUP_DIR/" 2>/dev/null || true
        cp -r ~/.oh-my-zsh/custom "$BACKUP_DIR/" 2>/dev/null || true
        echo "📦 Current configs backed up to $BACKUP_DIR"
        
        # Restore from dotfiles
        cp "$DOTFILES_DIR/.zshrc" ~/.zshrc 2>/dev/null || true
        mkdir -p ~/.config
        cp "$DOTFILES_DIR/starship.toml" ~/.config/starship.toml 2>/dev/null || true
        mkdir -p ~/.oh-my-zsh
        cp -r "$DOTFILES_DIR/custom" ~/.oh-my-zsh/ 2>/dev/null || true
        echo "✅ Restored from $DOTFILES_DIR"
        ;;
        
    install)
        echo "🚀 Installing dotfiles on new system..."
        
        # Install dependencies
        echo "📦 Installing packages..."
        sudo apt update
        sudo apt install -y zsh curl git eza bat fd-find fzf ripgrep
        
        # Install Oh My Zsh
        if [ ! -d "$HOME/.oh-my-zsh" ]; then
            echo "📦 Installing Oh My Zsh..."
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        fi
        
        # Install Starship
        if ! command -v starship &> /dev/null; then
            echo "📦 Installing Starship..."
            curl -sS https://starship.rs/install.sh | sh
        fi
        
        # Install Nerd Font
        echo "📦 Installing JetBrains Mono Nerd Font..."
        FONT_DIR="$HOME/.local/share/fonts"
        mkdir -p "$FONT_DIR"
        if [ ! -f "$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]; then
            curl -fLo "$FONT_DIR/JetBrainsMono.tar.xz" \
                https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.tar.xz
            tar -xf "$FONT_DIR/JetBrainsMono.tar.xz" -C "$FONT_DIR"
            rm "$FONT_DIR/JetBrainsMono.tar.xz"
            fc-cache -fv
        fi
        
        # Configure terminal font for Cosmic Terminal and Ghostty
        echo "🔧 Configuring terminal font..."
        
        # Cosmic Terminal configuration
        mkdir -p "$HOME/.config/cosmic-term"
        if [ ! -f "$HOME/.config/cosmic-term/config.toml" ]; then
            cat > "$HOME/.config/cosmic-term/config.toml" << 'EOF'
[font]
family = "JetBrains Mono Nerd Font"
size = 12
EOF
        fi
        
        # Ghostty configuration
        mkdir -p "$HOME/.config/ghostty"
        if [ ! -f "$HOME/.config/ghostty/config" ]; then
            cat > "$HOME/.config/ghostty/config" << 'EOF'
font-family = JetBrains Mono Nerd Font
font-size = 12
EOF
        fi
        
        # Create terminal font setup instructions
        cat > "$HOME/.config/terminal-font-setup.md" << 'EOF'
# Terminal Font Configuration

JetBrains Mono Nerd Font has been installed and configured for:

## Cosmic Terminal
- Font should be automatically set to "JetBrains Mono Nerd Font"
- If not showing: Settings → Font → "JetBrains Mono Nerd Font"

## Ghostty  
- Font should be automatically set to "JetBrains Mono Nerd Font"
- If not showing: Edit ~/.config/ghostty/config and ensure `font-family` is set

## Other terminals:
- **Kitty**: Add `font_family JetBrains Mono Nerd Font` to ~/.config/kitty/kitty.conf
- **Alacritty**: Add `family: JetBrainsMono NerdFont` to ~/.config/alacritty/alacritty.yml
- **VS Code**: Settings → "terminal.integrated.fontFamily" → "JetBrains Mono Nerd Font"

Restart your terminal after changing the font.
EOF
        
        # Install plugins
        echo "📦 Installing Zsh plugins..."
        mkdir -p ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null || true
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null || true
        git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions 2>/dev/null || true
        
        # Restore configs
        "$0" restore
        
        # Set Zsh as default
        echo "🔧 Setting Zsh as default shell..."
        if command -v sudo >/dev/null; then
            echo "Enter your password to set Zsh as default shell:"
            sudo chsh -s $(which zsh) $USER
        else
            echo "⚠️  Could not set Zsh as default shell (no sudo). Run manually:"
            echo "   chsh -s $(which zsh)"
        fi
        
        echo "✅ Installation complete! Restart your terminal or run 'zsh'"
        ;;
        
    *)
        echo "Usage: $0 [backup|restore|install]"
        echo ""
        echo "Commands:"
        echo "  backup   - Backup current configs to ~/dev/config/dotfiles"
        echo "  restore  - Restore configs from ~/dev/config/dotfiles"
        echo "  install  - Install everything on a new system"
        exit 1
        ;;
esac