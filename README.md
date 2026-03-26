# Development Configuration

Centralized repository for personal development environment setup, shared AI guidance, reusable project templates, and machine bootstrap helpers.

## Structure

```text
config/
├── README.md
├── AGENTS.md
├── setup.sh
├── mise.toml                        # Pinned shared runtimes for this repo and new machines
├── devbox.json                      # Optional portable shell for this repo
├── opencode.json                    # Symlink to ai/agents/opencode/opencode.json
├── ai/
│   ├── shared/                      # Agent-agnostic guidance and curated skills
│   │   ├── prompts/                 # Reusable prompt fragments and philosophy source material
│   │   ├── skills/                  # Remote skill manifest + local custom skills
│   │   └── README.md
│   └── agents/
│       └── opencode/                # OpenCode project template and plugin helpers
├── dotfiles/                        # Shell, prompt, terminal, and mise configuration
├── system/                          # Package manifests, reinstall checklist, state capture
└── templates/                       # Reusable starters for future project repos
```

## Fresh Machine Bootstrap

On a new machine, clone the repo and run the bootstrap flow from the repo root:

```bash
git clone git@github.com:Aureatus/config.git ~/dev/config
cd ~/dev/config
./setup.sh bootstrap
```

`bootstrap` currently:

- Installs the curated apt package set in `system/packages/apt.txt`
- Reinstalls tracked Flatpak apps from `system/state/flatpak-apps.txt` when present
- Restores shell, prompt, terminal, and global `mise` configuration from `dotfiles/`
- Runs `mise install` if `mise` is already available

To install the portable toolchain layer after bootstrap:

```bash
./setup.sh dev-env
```

## Before Reinstalling Linux

Capture what is installed now before you wipe the machine:

```bash
./setup.sh capture
./setup.sh backup-kde
```

Then work through `system/reinstall-checklist.md` for the manual backups that should never live in git.

## Portability Direction

For future VPS, mini PC, and wearable-adjacent work, this repo should stay lightweight at the machine layer and portable at the workload layer.

- Use `system/packages/apt.txt` only for the thin base machine bootstrap
- Keep shell, terminal, and operator preferences in `dotfiles/`
- Use `mise.toml` for pinned shared runtimes so laptops, mini PCs, and VPS hosts can share the same toolchain definitions
- Use `devbox.json` as the optional portable shell wrapper for repo-local helper commands
- Prefer Docker Compose or similar service definitions for workloads you want to move between local hardware and VPS hosts
- Keep secrets and device-specific credentials outside git and inject them at deploy time

See `system/portable-strategy.md` for the recommended hybrid approach.

## AI Configuration Model

### Shared Source of Truth

`ai/shared/` is the canonical home for reusable AI material that should not belong to one specific tool.

- `ai/shared/prompts/*.md` contains reusable prompt fragments that can be copied into repo-level context
- `ai/shared/skills/manifest.ts` curates optional remote skills to keep track of in git
- `ai/shared/skills/custom/` is reserved for local skills you own

The content is intentionally tool-agnostic:

- Markdown for human-authored guidance
- TypeScript only where a tiny registry or helper actually benefits from it
- Repo-level `AGENTS.md` remains the authoritative place for project-specific context

### OpenCode Template

`ai/agents/opencode/` holds the repo-managed OpenCode project template.

It provides:

- `opencode.json` as a base project config
- `.opencode/` template files and plugins
- `setup.sh` to copy missing template files into a target project

## Quick Start

### OpenCode Project Template

To copy the repo-managed OpenCode project template into a project:

```bash
./setup.sh opencode ./my-project
```

The installer copies missing files only; it does not merge or overwrite existing project config.

### Shared Prompts

If you want reusable philosophy or prompt material, use:

- `ai/shared/prompts/product.md`
- `ai/shared/prompts/engineering.md`
- `ai/shared/prompts/design.md`
- `ai/shared/prompts/testing.md`

Bring the relevant parts into repo-level `AGENTS.md` or other agent config where they make sense.
They are written as copy-ready instruction fragments rather than as general reference docs.

### Dotfiles Configuration

To restore shell and terminal configuration after the base packages are available:

```bash
./setup.sh dotfiles
```

### Portable Tooling

To install `mise`, restore the pinned runtime config, install the configured runtimes, and install `devbox`:

```bash
./setup.sh dev-env
```

To do a safe local config test without touching your current home directory:

```bash
./setup.sh test-portable-env
```

### System Package Install

To install only the base machine packages and tracked Flatpak apps:

```bash
./setup.sh system
```

## Components

### AI / Shared

- **Prompts**: Product, engineering, design, and testing prompt fragments
- **Skills**: Curated remote skills plus a home for future custom skills
- **Model**: Shared source material, not global auto-sync

### AI / OpenCode

- **Project Template**: Base `opencode.json` and plugin templates for new repos
- **Installer**: Simple copy-if-missing setup flow
- **Plugins**: Idle notification and validation helpers in `.opencode/plugin/`

### Dotfiles

- **Zsh + Oh My Zsh**: Modern shell with useful plugins
- **Starship**: Clean, informative prompt configuration
- **CLI Tools**: eza, bat, fd, ripgrep, fzf setup
- **Terminal Setup**: JetBrains Mono Nerd Font plus tracked Ghostty and Cosmic Terminal configs

### System

- **Bootstrap packages**: Curated apt package manifest for a new Pop or Ubuntu install
- **Captured state**: Exported package inventories in `system/state/`
- **Desktop backup**: KDE backup helper and reinstall checklist
- **VM testing**: Full-DE validation flow in `system/vm-testing.md` plus CLI helpers in `system/scripts/create-test-vm.sh` and `system/scripts/vmctl.sh`

### Templates

- **Devbox starter**: Copyable `templates/devbox/` pattern for future repos
- **Pinned runtimes**: Shared `mise` defaults for new portable projects

## Contributing

When updating the machine bootstrap layer:

1. Keep `system/packages/apt.txt` curated and readable rather than dumping every package on the machine into it
2. Use `./setup.sh capture` to refresh `system/state/` after meaningful environment changes
3. Keep `mise.toml` pinned intentionally rather than drifting back to `latest`
4. Keep secrets, private keys, browser profiles, and similar data out of tracked repo paths

When updating the AI layer:

1. Edit `ai/shared/prompts/` for reusable philosophy and prompt material
2. Edit `ai/shared/skills/manifest.ts` only if you want to curate skill references in git
3. Edit `ai/agents/<tool>/` only for tool-specific template files
4. Update `README.md`, `AGENTS.md`, and component READMEs when the architecture changes

## License

MIT License - see LICENSE file for details.
