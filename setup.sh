#!/bin/bash

# Config Setup Script
# Usage: ./setup.sh [component] [target-directory]

set -e

COMPONENT="${1:-opencode}"
TARGET_DIR="${2:-.}"
CONFIG_REPO="https://github.com/yourusername/config.git"

case "$COMPONENT" in
  "opencode"|"ai/opencode")
    echo "Setting up OpenCode configuration..."
    TEMP_DIR=$(mktemp -d)
    git clone "$CONFIG_REPO" "$TEMP_DIR"
    
    if [ -d "$TARGET_DIR/.opencode" ]; then
        echo "OpenCode config already exists. Updating..."
        cd "$TARGET_DIR/.opencode"
        git pull origin main
    else
        echo "Cloning configuration..."
        git clone "$CONFIG_REPO" "$TARGET_DIR/.opencode"
    fi
    
    # Copy the configuration file to the target directory
    if [ ! -f "$TARGET_DIR/opencode.json" ]; then
        echo "Copying opencode.json to project root..."
        cp "$TARGET_DIR/.opencode/ai/opencode/opencode.json" "$TARGET_DIR/"
    else
        echo "opencode.json already exists in project root. Skipping copy."
    fi
    
    rm -rf "$TEMP_DIR"
    ;;
    
  "dotfiles")
    echo "Setting up dotfiles configuration..."
    
    if [ -d "$HOME/dev/config/dotfiles" ]; then
        echo "Dotfiles already exist. Updating..."
        cd "$HOME/dev/config/dotfiles"
        git pull origin main
    else
        echo "Cloning configuration repository..."
        mkdir -p "$HOME/dev"
        git clone "$CONFIG_REPO" "$HOME/dev/config"
    fi
    
    echo "Running dotfiles installation..."
    cd "$HOME/dev/config/dotfiles"
    ./manage.sh install
    ;;
    
  "help"|"-h"|"--help")
    echo "Usage: $0 [component] [target-directory]"
    echo ""
    echo "Available components:"
    echo "  opencode     OpenCode AI assistant configuration"
    echo "  dotfiles     System shell and tool configurations"
    echo "  help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 opencode ./my-project"
    echo "  $0 opencode"
    echo "  $0 dotfiles"
    exit 0
    ;;
    
  *)
    echo "Unknown component: $COMPONENT"
    echo "Use '$0 help' for available options"
    exit 1
    ;;
esac

echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Customize configuration files if needed"
echo "2. Install any required dependencies"
echo "3. Start using your configured tools"