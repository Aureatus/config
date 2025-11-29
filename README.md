# OpenCode Configuration

A shared OpenCode configuration repository that can be easily pulled into new projects.

## Setup

1. Clone this repository into your project:
   ```bash
   git clone https://github.com/yourusername/opencode-config.git .opencode
   ```

2. Or add as a submodule:
   ```bash
   git submodule add https://github.com/yourusername/opencode-config.git .opencode
   ```

3. Copy the configuration file to your project root:
   ```bash
   cp .opencode/opencode.json .
   ```

## Configuration

The `opencode.json` file includes:

- **OpenAI Codex Authentication** with multiple model variants
- **Exa MCP** for web search capabilities
- **Permission settings** for external directory access

### Available Models

- `gpt-5.1-codex-low/medium/high` - Standard codex models
- `gpt-5.1-codex-max-*` - Enhanced codex models with larger context
- `gpt-5.1-codex-mini-*` - Lightweight codex models
- `gpt-5.1-*` - Standard GPT-5.1 models

## Plugins

### idle-validate

Automatically runs validation checks when the session becomes idle:

- **Biome linting** for supported file types
- **TypeScript type checking** via `bun run check-types`
- **Desktop notifications** for idle state and failures
- **Sound alerts** using system notification sounds

#### Supported File Types

The Biome linting supports: JavaScript, TypeScript, JSX, TSX, Vue, Svelte, Astro, JSON, CSS, SCSS, Markdown

#### Requirements

- Git repository
- `bun` package manager
- `biome` linter (installed via bunx)
- `notify-send` and `paplay` for notifications (Linux)

## Usage

Once configured, OpenCode will automatically:

1. Use the specified model and settings
2. Load the idle-validate plugin
3. Run validation checks when idle
4. Notify you of any issues that need attention

## Customization

You can modify the `opencode.json` file to:

- Change the default model
- Add/remove MCP servers
- Adjust plugin settings
- Modify permission preferences

For project-specific customizations, consider maintaining a separate `opencode.json` in your project root that extends this base configuration.