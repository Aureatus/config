#!/bin/bash

# OpenCode Config Setup Script
# Usage: ./setup.sh [target-directory]

set -e

TARGET_DIR="${1:-.}"
CONFIG_REPO="https://github.com/yourusername/config.git"

echo "Setting up OpenCode configuration in $TARGET_DIR..."

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Clone the config repository as .opencode
if [ -d "$TARGET_DIR/.opencode" ]; then
    echo "OpenCode config already exists. Updating..."
    cd "$TARGET_DIR/.opencode"
    git pull origin main
else
    echo "Cloning OpenCode configuration..."
    git clone "$CONFIG_REPO" "$TARGET_DIR/.opencode"
fi

# Copy the configuration file to the target directory
if [ ! -f "$TARGET_DIR/opencode.json" ]; then
    echo "Copying opencode.json to project root..."
    cp "$TARGET_DIR/.opencode/ai/opencode/opencode.json" "$TARGET_DIR/"
else
    echo "opencode.json already exists in project root. Skipping copy."
fi

echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Customize opencode.json if needed"
echo "2. Install dependencies: npm install (for type checking)"
echo "3. Start using OpenCode with your configuration"