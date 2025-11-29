# Development Configuration

Centralized repository for all development tool configurations and dotfiles.

## Structure

```
config/
├── ai/
│   └── opencode/          # OpenCode AI assistant configurations
├── dotfiles/              # System shell and tool configurations (future)
├── editors/               # Editor-specific configurations (future)
└── development/           # Other development tool configs (future)
```

## Quick Start

### OpenCode Configuration

To set up OpenCode in a new project:

```bash
# Clone this repository
git clone https://github.com/yourusername/config.git .opencode

# Use the setup script
cd .opencode/ai/opencode
./setup.sh /path/to/your/project
```

Or directly:
```bash
curl -s https://raw.githubusercontent.com/yourusername/config/main/ai/opencode/setup.sh | bash -s /path/to/your/project
```

## Components

### AI/OpenCode
- **Configuration**: Complete OpenAI Codex setup with multiple model variants
- **Plugins**: Idle validation, linting, and type checking automation
- **MCP Integration**: Exa search and other Model Context Protocol tools

### Future Components
- **dotfiles**: Shell configurations (zsh, starship, etc.)
- **editors**: VSCode, Neovim, and other editor settings
- **development**: Docker, Git, and other dev tool configurations

## Contributing

Each component is maintained independently but follows the same structure:
- `README.md` with usage instructions
- `setup.sh` for easy installation
- Configuration files and plugins
- Documentation for customization

## License

MIT License - see LICENSE file for details.