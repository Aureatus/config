# OpenCode Configuration

A shared OpenCode configuration that can be easily pulled into new projects.

This is part of a larger `config/` repository structure that includes:
- `ai/opencode/` - OpenCode configurations and plugins
- `dotfiles/` - System shell and tool configurations (future)
- `editors/` - Editor-specific configurations (future)

## Setup

1. Clone this repository into your project:
   ```bash
   git clone https://github.com/yourusername/config.git .opencode
   ```

2. Or add as a submodule:
   ```bash
   git submodule add https://github.com/yourusername/config.git .opencode
   ```

3. Copy the configuration file to your project root:
   ```bash
   cp .opencode/opencode.json .
   ```

## Configuration

The `opencode.json` file includes:

- **OpenAI Codex Authentication** with multiple model variants
- **Playwright MCP** for browser automation and testing
- **Exa MCP** for web search capabilities
- **Permission settings** for external directory access

### Available Models

- `gpt-5.1-codex-low/medium/high` - Standard codex models
- `gpt-5.1-codex-max-*` - Enhanced codex models with larger context
- `gpt-5.1-codex-mini-*` - Lightweight codex models
- `gpt-5.1-*` - Standard GPT-5.1 models

## MCP (Model Context Protocol) Servers

### Playwright
Browser automation and testing capabilities:
- **Headless browser control** for web scraping and testing
- **Video recording** (1280x720) for debugging
- **Trace collection** for performance analysis
- **Output directory**: `./playwright-mcp-output`

### Exa
Web search and content retrieval:
- **Real-time web search** with up-to-date information
- **Content extraction** from specific URLs
- **Configurable result counts** and search depth

## Plugins

### idle-notify

Simple idle notification plugin that provides desktop and audio alerts when the session becomes idle:

- **Desktop notifications** for idle state
- **Sound alerts** using system notification sounds
- **Lightweight** - no validation checks, just notifications

#### Requirements

- `notify-send` and `paplay` for notifications (Linux)

### biome-validate

Code validation plugin that runs checks when the session becomes idle:

- **Biome linting** for supported file types
- **TypeScript type checking** via `bun run check-types`
- **Error reporting** with detailed output for failures
- **Only runs on changed files** for efficiency

#### Supported File Types

The Biome linting supports: JavaScript, TypeScript, JSX, TSX, Vue, Svelte, Astro, JSON, CSS, SCSS, Markdown

#### Requirements

- Git repository
- `bun` package manager
- `biome` linter (installed via bunx)
- `notify-send` and `paplay` for error notifications (Linux)

### Plugin Configuration

To use these plugins, update your `opencode.json`:

```json
{
  "plugin": [
    "opencode-openai-codex-auth@4.0.2",
    "./.opencode/plugin/idle-notify.ts",
    "./.opencode/plugin/biome-validate.ts"
  ]
}
```

Or use just one:

```json
{
  "plugin": [
    "opencode-openai-codex-auth@4.0.2",
    "./.opencode/plugin/idle-notify.ts"
  ]
}
```

## Usage

Once configured, OpenCode will automatically:

1. Use specified model and settings
2. Load the configured plugins
3. Run validation checks (if using biome-validate) when idle
4. Notify you of idle state and any issues that need attention

## Customization

You can modify the `opencode.json` file to:

- Change the default model
- Add/remove MCP servers
- Adjust plugin settings
- Modify permission preferences

For project-specific customizations, consider maintaining a separate `opencode.json` in your project root that extends this base configuration.