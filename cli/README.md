# forge

`forge` is a Bun + TypeScript wrapper for the repo's operational commands.

It provides two modes:

- CLI wrappers around common `setup.sh` commands
- an OpenTUI launcher for keyboard-driven command selection

## Install

```bash
cd ~/dev/config/cli
bun install
```

To build and install a standalone executable into `~/.local/bin/forge`:

```bash
cd ~/dev/config/cli
bun run install-local
```

That also stores the repo root in `~/.config/forge/repo-root`, so the compiled executable can be launched from anywhere.

## Usage

### TUI launcher

```bash
bun run src/index.ts tui
forge tui
```

### List commands

```bash
bun run src/index.ts list
forge list
```

### Run a command directly

```bash
bun run src/index.ts run vm-smoke-reset
bun run src/index.ts run server-config ansible/inventory/hosts.local.ini
forge vm-desktop
```

### Dry-run a command

```bash
bun run src/index.ts --dry-run vm-desktop-reset
forge --dry-run vm-smoke-reset
```

### Shortcut form

```bash
bun run src/index.ts vm-desktop
```

## Notes

- The TypeScript CLI is the new operator-facing wrapper layer.
- The existing shell scripts still exist as the backend implementation for now.
- Commands run from the repo root so relative paths still work.
- The standalone executable resolves the repo root from `CONFIG_REPO_ROOT`, `~/.config/forge/repo-root`, the current working directory, or the executable path.
