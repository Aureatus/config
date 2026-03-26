# System Bootstrap

`system/` holds the machine-level pieces that sit beside dotfiles and AI config.

## Goals

- Install a curated base package set on a fresh Pop, Ubuntu, or Debian machine
- Capture what is currently installed before a reinstall
- Document the manual backups that should never live in git
- Keep desktop-specific archives outside the repo while still making them easy to recreate
- Stay thin enough that portable workloads can move to a VPS or mini PC without re-creating the whole machine by hand

## Layout

```text
system/
├── packages/
│   └── apt.txt
├── state/
│   └── README.md
├── vm/
│   ├── .gitignore
│   └── desktop-test.env.example
├── scripts/
│   ├── backup-kde-config.sh
│   ├── capture-state.sh
│   ├── create-test-vm.sh
│   ├── install-devbox.sh
│   ├── install-mise.sh
│   ├── install-packages.sh
│   ├── test-portable-env.sh
│   └── vmctl.sh
├── reinstall-checklist.md
├── vm-testing.md
└── README.md
```

## Core Commands

From the repo root:

```bash
./setup.sh system
./setup.sh dev-env
./setup.sh test-portable-env
./setup.sh capture
./setup.sh backup-kde
./setup.sh bootstrap
```

## Package Strategy

- `packages/apt.txt` is the small, curated bootstrap set that makes the machine usable quickly
- `state/apt-manual.txt` is a generated reference snapshot of the current machine, not the install source of truth
- `state/flatpak-apps.txt` is an optional restore input for user-level Flatpak apps
- `install-mise.sh` and `install-devbox.sh` are intentionally separate from `apt` because they are portable-tooling layers, not host bootstrap prerequisites

## Reinstall Flow

1. Before wiping the machine, run `./setup.sh capture` and `./setup.sh backup-kde`
2. Work through `system/reinstall-checklist.md` for secrets and app data
3. After reinstall, clone this repo and run `./setup.sh bootstrap`
4. Run `./setup.sh dev-env` to restore pinned runtimes and the portable shell layer
5. Restore any non-repo state like SSH keys, GPG keys, browser profiles, and app databases

## Testing Strategy

- `./setup.sh test-portable-env` restores config into a disposable target home without touching the real `~`
- `system/vm-testing.md` is the canonical full-DE sandbox flow using a VM and snapshots
- `system/vm/desktop-test.env.example` plus `create-test-vm.sh` and `vmctl.sh` provide a CLI-driven VM workflow
- The fake-home sandbox is a safety check; the VM is the final proof step

## Portability Posture

This layer is intentionally small.

- Apt is the host bootstrap, not the full source of truth for every future runtime
- `mise.toml` is the pinned runtime source of truth for shared tools
- `devbox` is the optional portable shell wrapper for repo-local commands and project templates
- Services you want to run on a VPS later should prefer Docker Compose, systemd units, or similar repo-managed artifacts
- Hardware-specific setup should stay isolated so the wearable or hand-gesture stack can diverge without polluting the generic bootstrap

More detail lives in `system/portable-strategy.md`.
