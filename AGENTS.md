# Config Repository

This repository contains centralized configuration for local tooling, shared AI context, reusable project templates, and machine bootstrap workflows.

## Structure

```text
config/
├── README.md
├── AGENTS.md
├── setup.sh
├── mise.toml
├── devbox.json
├── opencode.json                    # Symlink to ai/agents/opencode/opencode.json
├── ai/
│   ├── shared/
│   │   ├── prompts/
│   │   │   ├── product.md
│   │   │   ├── engineering.md
│   │   │   ├── design.md
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
    ├── packages/apt.txt
    ├── portable-strategy.md
    ├── state/
    ├── vm/
    │   ├── .gitignore
    │   └── desktop-test.env.example
    ├── reinstall-checklist.md
    ├── vm-testing.md
    └── scripts/
        ├── create-test-vm.sh
        ├── install-mise.sh
        ├── install-devbox.sh
        ├── test-portable-env.sh
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
- `devbox.json` defines the optional repo-local portable shell layer
- `templates/devbox/` is the copyable starter for future repos

## System Bootstrap (`system/`)

Machine-level reinstall helpers:

- `packages/apt.txt` is the curated base package list for apt-based systems
- `state/` contains generated package inventory snapshots produced by `./setup.sh capture`
- `reinstall-checklist.md` tracks the manual backups and restore steps that should not live in git
- `vm-testing.md` is the full-DE validation flow using a VM and snapshots
- `vm/desktop-test.env.example` is the config-driven VM definition starter
- `scripts/backup-kde-config.sh` writes archives outside the repo so desktop backups stay out of version control
- `create-test-vm.sh` and `vmctl.sh` provide the CLI-driven VM lifecycle helpers
- `install-mise.sh`, `install-devbox.sh`, and `test-portable-env.sh` manage the portable tooling layer and its safe-test path

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
- Optional repo-local shell wrappers live in `devbox.json` and `templates/devbox/`

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
