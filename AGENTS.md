# Config Repository

This repository contains centralized configuration for local tooling, shared AI context, reusable project templates, and machine bootstrap workflows.

## Structure

```text
config/
├── README.md
├── AGENTS.md
├── setup.sh
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/
│   ├── playbooks/
│   └── roles/
├── cli/
│   ├── package.json
│   ├── tsconfig.json
│   └── src/
├── mise.toml
├── devbox.json
├── opencode.json                    # Symlink to ai/agents/opencode/opencode.json
├── ai/
│   ├── shared/
│   │   ├── prompts/
│   │   │   ├── product.md
│   │   │   ├── engineering.md
│   │   │   ├── design.md
│   │   │   ├── developer-operability.md
│   │   │   └── testing.md
│   │   ├── skills/
│   │   │   ├── manifest.ts
│   │   │   └── custom/
│   │   └── README.md
│   └── agents/
│       └── opencode/
│           ├── opencode.json
│           ├── .opencode/plugin/
│           ├── setup.sh
│           ├── package.json
│           └── README.md
├── dotfiles/
│   ├── .zshrc
│   ├── starship.toml
│   ├── config/
│   │   ├── cosmic-term/config.toml
│   │   └── ghostty/config
│   └── manage.sh
├── system/
    ├── cloud-init/
    ├── packages/apt.txt
    ├── portable-strategy.md
    ├── state/
    ├── vm/
    │   ├── .gitignore
    │   ├── desktop-test.env.example
    │   └── presets/
    ├── reinstall-checklist.md
    ├── vm-testing.md
    └── scripts/
        ├── build-autoinstall-seed.sh
        ├── create-test-vm.sh
        ├── fix-kvm-access.sh
        ├── install-mise.sh
        ├── install-devbox.sh
        ├── list-vm-presets.sh
        ├── test-portable-env.sh
        ├── resolve-vm-iso.sh
        ├── vmctl.sh
        ├── capture-state.sh
        ├── install-packages.sh
        └── backup-kde-config.sh
└── templates/
    └── devbox/
        ├── README.md
        ├── mise.toml
        └── devbox.json
```

## AI Architecture

### Shared AI (`ai/shared/`)

Agent-agnostic AI source of truth:

- `prompts/` contains reusable prompt fragments intended for repo-level `AGENTS.md` and tool-specific prompt/config files
- `skills/manifest.ts` curates optional remote skills to track in git
- `skills/custom/` is reserved for local custom skills if you create them later

Important rules:

- Treat `ai/shared/` as the canonical home for reusable AI guidance
- Treat repo-level `AGENTS.md` files as the authoritative source of project context
- Prefer Markdown for prompts and TypeScript only where a small registry or helper truly helps
- Do not introduce YAML for this system
- Keep prompt files copy-ready and instruction-oriented rather than explanatory

### OpenCode Template (`ai/agents/opencode/`)

OpenCode project template files live here:

- `opencode.json` is the base project config
- `.opencode/` contains plugin templates and helper files
- `setup.sh` copies missing template files into a target project

Important rules:

- Shared philosophy belongs in `ai/shared/prompts/`, not in this template directory
- Repo-specific `AGENTS.md` remains the right place for project-local context
- The installer does not merge or overwrite existing project config

## Dotfiles (`dotfiles/`)

System shell and CLI tool configurations:

- `dotfiles/` is the canonical dotfiles source of truth
- `.zshrc` enables shell plugins
- `config/` contains tracked terminal emulator config
- `manage.sh install` restores repo-managed dotfiles, global `mise` config, and fetches third-party Oh My Zsh plugins

## Portable Tooling

- `mise.toml` is the pinned runtime source of truth for shared machine and repo tooling
- `devbox.json` defines the optional repo-local portable shell layer when `mise` alone is not enough
- `templates/devbox/` is the copyable starter for future repos that truly need that extra layer

## Ansible

Shared machine configuration should prefer Ansible over custom shell logic:

- `ansible/playbooks/desktop.yml` is the preferred local desktop path
- `ansible/playbooks/server.yml` is the preferred VPS/server path
- `setup.sh` remains a thin convenience wrapper around these playbooks
- TypeScript is appropriate for repo-specific generators or validation, not as the main machine config engine

## Operator CLI

`cli/` is the Bun + TypeScript wrapper layer for operator-facing commands:

- `bun run src/index.ts tui` launches the OpenTUI picker
- `bun run src/index.ts <command-id>` runs a wrapper command directly
- `bun run install-local` builds and installs the standalone `forge` executable into `~/.local/bin/`
- the shell scripts remain the backend implementation for now, but `cli/` is the preferred interactive entrypoint

## System Bootstrap (`system/`)

Machine-level reinstall helpers:

- `packages/apt.txt` is the curated base package list for apt-based systems
- `cloud-init/` holds first-boot examples for VPS and cloud-image based machines
- `state/` contains generated package inventory snapshots produced by `./setup.sh capture`
- `reinstall-checklist.md` tracks the manual backups and restore steps that should not live in git
- `vm-testing.md` is the full-DE validation flow using a VM and snapshots
- `vm/desktop-test.env.example` is the config-driven VM definition starter
- `vm/presets/*.env` are named distro defaults for common VM targets
- `resolve-vm-iso.sh` turns `ISO_URL` into a cached local ISO path when you do not want to manage local ISO files yourself, using libvirt-safe paths by default
- `build-autoinstall-seed.sh` renders Ubuntu autoinstall inputs for zero-click guest installs
- `scripts/backup-kde-config.sh` writes archives outside the repo so desktop backups stay out of version control
- `list-vm-presets.sh` exposes the available named presets from the CLI
- `fix-kvm-access.sh` repairs host-side KVM group access for libvirt when Pop or custom udev permissions break it
- `create-test-vm.sh` and `vmctl.sh` provide the CLI-driven VM lifecycle helpers; `vmctl.sh up` is the quickest path because it creates missing guests and starts stopped ones before opening the viewer
- `install-mise.sh` is the primary runtime bootstrap, `install-devbox.sh` is optional, and `test-portable-env.sh` manages the safe-test path

VM preset guidance:

- `ubuntu-24.04-server-smoke` is the fast confidence-check path
- `ubuntu-24.04-server-kde` is the heavier full desktop validation path
- `./setup.sh vm-smoke` is the simplest way to launch the smoke path without editing a VM config file
- `./setup.sh vm-smoke-reset` and `./setup.sh vm-desktop-reset` are the simplest ways to rebuild the VMs from current repo state

Important rules:

- Keep `packages/apt.txt` curated; do not dump every package from `apt-mark showmanual` into it
- Generated files under `system/state/` can be committed after review when they represent the current machine state
- Do not store secrets, private keys, browser profiles, or credential exports in tracked repo paths

## Quick Commands

### Machine State Capture

```bash
./setup.sh capture
./setup.sh backup-kde
```

### Fresh Machine Bootstrap

```bash
./setup.sh bootstrap
./setup.sh dev-env
./setup.sh devbox  # optional
./setup.sh vm-desktop
./setup.sh vm-desktop-reset
./setup.sh vm-smoke
./setup.sh vm-smoke-reset
```

### Shared Desktop Config

```bash
./setup.sh desktop-config
```

### Shared Server Config

```bash
./setup.sh server-config ansible/inventory/hosts.local.ini
```

### Safe Portable Test

```bash
./setup.sh test-portable-env
```

### OpenCode Project Template

```bash
./setup.sh opencode ./my-project
```

### Dotfiles Install

```bash
./setup.sh dotfiles
```

## Repository Management

- `opencode.json` at the repo root is a symlink to `ai/agents/opencode/opencode.json`
- Shared AI guidance belongs in `ai/shared/`
- Tool-specific behavior belongs in `ai/agents/<tool>/`
- User shell and terminal configuration belongs in `dotfiles/`
- Machine bootstrap state and reinstall helpers belong in `system/`
- Shared runtime pins live in `mise.toml`
- Optional repo-local shell wrappers live in `devbox.json` and `templates/devbox/` only when a repo needs more than `mise`
- Shared machine config lives in `ansible/`
- First-boot remote bootstrap examples live in `system/cloud-init/`

## Contributing

When changing the machine bootstrap layer:

1. Update `system/packages/apt.txt` for curated base package changes
2. Run `./setup.sh capture` after meaningful package or desktop app changes
3. Update `system/reinstall-checklist.md` when you discover a manual restore step worth preserving
4. Keep `mise.toml` pinned intentionally when shared tool versions change
5. Keep secrets and personal data outside tracked paths

When adding or changing AI guidance:

1. Update `ai/shared/prompts/*.md` for reusable philosophy and prompt material
2. Update `ai/shared/skills/manifest.ts` only when you want to curate remote skill references
3. Update `ai/agents/opencode/` only when the OpenCode project template itself changes
4. Keep this file, `README.md`, and component READMEs aligned with the current structure

## License

MIT License - see LICENSE file for details.
