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
├── cloud-init/
│   ├── README.md
│   └── server-user-data.example.yaml
├── state/
│   └── README.md
├── vm/
│   ├── .gitignore
│   ├── desktop-test.env.example
│   └── presets/
├── scripts/
│   ├── backup-kde-config.sh
│   ├── build-autoinstall-seed.sh
│   ├── capture-state.sh
│   ├── create-test-vm.sh
│   ├── fix-kvm-access.sh
│   ├── install-devbox.sh
│   ├── install-mise.sh
│   ├── install-packages.sh
│   ├── list-vm-presets.sh
│   ├── resolve-vm-iso.sh
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
- `install-mise.sh` is the primary user-tooling installer and `install-devbox.sh` is optional because it is only a secondary repo-shell layer

## Reinstall Flow

1. Before wiping the machine, run `./setup.sh capture` and `./setup.sh backup-kde`
2. Work through `system/reinstall-checklist.md` for secrets and app data
3. After reinstall, clone this repo and run `./setup.sh bootstrap`
4. Run `./setup.sh dev-env` to restore the pinned shared runtimes
5. Optionally run `./setup.sh devbox` only if a repo later proves it needs the extra shell layer
6. Restore any non-repo state like SSH keys, GPG keys, browser profiles, and app databases

## Testing Strategy

- `./setup.sh test-portable-env` restores config into a disposable target home without touching the real `~`
- `system/vm-testing.md` is the canonical full-DE sandbox flow using a VM and snapshots
- `system/vm/desktop-test.env.example` plus `system/vm/presets/*.env`, `list-vm-presets.sh`, `resolve-vm-iso.sh`, `build-autoinstall-seed.sh`, `create-test-vm.sh`, and `vmctl.sh` provide a CLI-driven, zero-click Ubuntu VM workflow with named presets and libvirt-safe artifact paths
- `./system/scripts/vmctl.sh up ...` is the easiest entrypoint because it creates missing VMs, starts stopped VMs, and opens the viewer
- `system/cloud-init/` holds first-boot examples for VPS and cloud-image based machines
- The fake-home sandbox is a safety check; the VM is the final proof step

Recommended VM preset order:

- `ubuntu-24.04-server-smoke` for fast plumbing checks
- `ubuntu-24.04-server-kde` for the full desktop-oriented validation path

Fastest smoke-test entrypoint:

```bash
./setup.sh vm-smoke
```

Fastest reset commands:

```bash
./setup.sh vm-smoke-reset
./setup.sh vm-desktop-reset
```

## Portability Posture

This layer is intentionally small.

- Apt is the host bootstrap, not the full source of truth for every future runtime
- `mise.toml` is the pinned runtime source of truth for shared tools
- `devbox` is optional and should only be added when `mise` is not enough for a specific repo
- Services you want to run on a VPS later should prefer Docker Compose, systemd units, or similar repo-managed artifacts
- Hardware-specific setup should stay isolated so the wearable or hand-gesture stack can diverge without polluting the generic bootstrap

More detail lives in `system/portable-strategy.md`.
