# Config Repository

This repository contains centralized configurations for all development tools and environments.

## Structure

```
config/
├── README.md                    # Overview and setup instructions
├── setup.sh                     # Universal setup script for all components
├── opencode.json                 # Symlink to ai/opencode/opencode.json
├── ai/
│   └── opencode/               # OpenCode AI assistant configurations
│       ├── .opencode/plugin/      # Reusable OpenCode plugins
│       ├── opencode.json          # Base OpenCode configuration
│       ├── package.json            # Dependencies for plugins
│       └── README.md              # OpenCode-specific documentation
├── dotfiles/                    # System shell and tool configurations
│   ├── .zshrc                   # Zsh configuration
│   ├── starship.toml             # Starship prompt config
│   ├── manage.sh                 # Dotfiles management script
│   └── README.md                # Dotfiles documentation
└── AGENTS.md                     # This file - repository overview
```

## Components

### AI/OpenCode (`ai/opencode/`)

OpenCode AI assistant configuration and plugins:

- **Base Configuration**: Complete OpenAI Codex setup with multiple model variants
- **MCP Servers**: Playwright (browser automation) and Exa (web search)
- **Plugins**: 
  - `idle-notify.ts` - Desktop/audio notifications when idle
  - `biome-validate.ts` - Code validation and linting
  - `idle-validate.ts` - Combined notifications + validation (legacy)

**Usage**: Copy `ai/opencode/opencode.json` and desired plugins to new projects

### Dotfiles (`dotfiles/`)

System shell and CLI tool configurations:

- **Zsh + Oh My Zsh**: Modern shell with useful plugins
- **Starship**: Clean, informative prompt configuration
- **CLI Tools**: eza, bat, fd, ripgrep, fzf setup
- **Terminal Setup**: JetBrains Mono Nerd Font and configurations

**Usage**: Run `./manage.sh install` on new systems

## Quick Start

### OpenCode Configuration
```bash
# Copy to new project
cp ai/opencode/opencode.json my-project/

# Copy desired plugins
mkdir -p my-project/.opencode/plugin
cp ai/opencode/.opencode/plugin/idle-notify.ts my-project/.opencode/plugin/
```

### Dotfiles Setup
```bash
# Install on new system
cd dotfiles
./manage.sh install
```

### Universal Setup Script
```bash
# Install OpenCode config
./setup.sh opencode ./my-project

# Install dotfiles
./setup.sh dotfiles
```

## Philosophy

This repository follows a **copy-paste customization** approach:

1. **Template configurations** stored here
2. **Copy to projects** as needed
3. **Customize per project** without affecting templates
4. **Version control** project-specific changes separately

This provides:
- ✅ **Consistency** - Same base setup across projects
- ✅ **Flexibility** - Customize per project needs
- ✅ **Portability** - Easy setup on new machines
- ✅ **Version Control** - Track changes to templates and customizations

## Repository Management

- **Source of Truth**: `ai/opencode/opencode.json` (linked via symlink)
- **Plugin Templates**: `ai/opencode/.opencode/plugin/`
- **System Config**: `dotfiles/`
- **Documentation**: Each component has its own README

## Contributing

When adding new configurations:

1. Follow existing directory structure
2. Include README documentation
3. Add setup script support if needed
4. Update this AGENTS.md file

## License

MIT License - see LICENSE file for details.