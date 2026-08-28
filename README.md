# Development Configuration

Centralized repository for personal development environment setup, shared AI guidance, reusable project templates, and machine bootstrap helpers.

## Structure

```text
config/
├── README.md
├── AGENTS.md
├── setup.sh
├── ansible/                         # Preferred shared config layer for desktops and servers
├── cli/                             # Bun + TypeScript TUI/CLI wrapper for repo commands
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
├── system/                          # Package manifests, cloud-init, reinstall checklist, state capture
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

- Uses Ansible as the primary local-machine bootstrap path
- Installs the curated apt package set from `system/packages/apt.txt`
- Restores shell, prompt, terminal, and global `mise` configuration
- Installs the pinned runtimes from `mise.toml`

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
- Use `ansible/` as the shared configuration engine for both desktops and servers
- Keep shell, terminal, and operator preferences in `dotfiles/`
- Use `mise.toml` for pinned shared runtimes so laptops, mini PCs, and VPS hosts can share the same toolchain definitions
- Treat `devbox.json` as optional and secondary; only use it if `mise` is not enough for a repo
- Use `system/cloud-init/` for first boot on VPS or cloud-image hosts
- Prefer Docker Compose or similar service definitions for workloads you want to move between local hardware and VPS hosts
- Keep secrets and device-specific credentials outside git and inject them at deploy time

The recommended rule is: Bash stays thin, Ansible does the real shared config work, `mise` is the main user-facing tool layer, and TypeScript only makes sense for small repo-specific helpers or generators.

That now includes `cli/`, which wraps the most common repo operations in a Bun + OpenTUI operator interface while the shell scripts remain the backend implementation.

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
- `ai/shared/prompts/developer-operability.md`
- `ai/shared/prompts/testing.md`

Bring the relevant parts into repo-level `AGENTS.md` or other agent config where they make sense.
They are written as copy-ready instruction fragments rather than as general reference docs.

### Dotfiles Configuration

To restore shell and terminal configuration after the base packages are available:

```bash
./setup.sh dotfiles
```

### Portable Tooling

To install `mise`, restore the pinned runtime config, and install the configured runtimes:

```bash
./setup.sh dev-env
```

If you later decide you want the optional `devbox` layer too:

```bash
./setup.sh devbox
```

To do a safe local config test without touching your current home directory:

```bash
./setup.sh test-portable-env
```

### Operator CLI / TUI

To use the Bun + OpenTUI wrapper:

```bash
cd cli
bun install
bun run src/index.ts tui
```

To build and install the standalone executable:

```bash
cd cli
bun run install-local
forge tui
```

Or run a command directly:

```bash
cd cli
bun run src/index.ts vm-smoke-reset
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
- **VM testing**: Full-DE validation flow in `system/vm-testing.md` plus zero-click CLI helpers in `system/scripts/list-vm-presets.sh`, `system/scripts/resolve-vm-iso.sh`, `system/scripts/build-autoinstall-seed.sh`, `system/scripts/create-test-vm.sh`, `system/scripts/fix-kvm-access.sh`, and `system/scripts/vmctl.sh`

### Shared Config

- **Ansible**: Shared config engine for desktop and server targets in `ansible/`
- **Cloud-init**: First-boot VPS and cloud-image starter files in `system/cloud-init/`
- **Mise**: Primary shared runtime and task layer for user-facing tools
- **Thin Bash**: `setup.sh` remains a friendly entrypoint, not the long-term config engine

For VM testing, start with the `ubuntu-24.04-server-smoke` preset when you only want a fast confidence check, then switch to `ubuntu-24.04-server-kde` for the full desktop path.

### Templates

- **Pinned runtimes**: Shared `mise` defaults for new portable projects
- **Optional Devbox starter**: Copyable `templates/devbox/` pattern if a repo truly needs it

## Contributing

When updating the machine bootstrap layer:

1. Keep `system/packages/apt.txt` curated and readable rather than dumping every package on the machine into it
2. Use `./setup.sh capture` to refresh `system/state/` after meaningful environment changes
3. Keep `mise.toml` pinned intentionally rather than drifting back to `latest`
4. Keep secrets, private keys, browser profiles, and similar data out of tracked repo paths

## Recommended Commands

For the preferred local-machine bootstrap path:

```bash
./setup.sh bootstrap
```

For the quickest VM smoke test path:

```bash
./setup.sh vm-smoke
```

To rebuild that smoke VM from current config:

```bash
./setup.sh vm-smoke-reset
```

For the full desktop VM path:

```bash
./setup.sh vm-desktop
./setup.sh vm-desktop-reset
```

For shared local desktop config:

```bash
./setup.sh desktop-config
```

For shared remote server or VPS config:

```bash
cp ansible/inventory/hosts.example.ini ansible/inventory/hosts.local.ini
$EDITOR ansible/inventory/hosts.local.ini
./setup.sh server-config ansible/inventory/hosts.local.ini
```

If the host requires a sudo password instead of passwordless sudo, use:

```bash
ASK_BECOME_PASS=1 ./setup.sh server-config ansible/inventory/hosts.local.ini
```

The example `cloud-init` file uses passwordless sudo for simplicity, so `ASK_BECOME_PASS=1` is only for hosts you provision differently.

When updating the AI layer:

1. Edit `ai/shared/prompts/` for reusable philosophy and prompt material
2. Edit `ai/shared/skills/manifest.ts` only if you want to curate skill references in git
3. Edit `ai/agents/<tool>/` only for tool-specific template files
4. Update `README.md`, `AGENTS.md`, and component READMEs when the architecture changes

## License

MIT License - see LICENSE file for details.
