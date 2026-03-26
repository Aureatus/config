# VM Testing

Use a VM as the canonical full-desktop sandbox for this repo.

The preferred workflow is CLI-driven with repo-managed config, not `virt-manager` menus.

## Why a VM

- A fake-home sandbox protects your current dotfiles and config paths, but it is not a real security boundary.
- A VM lets you test package installs, desktop behavior, fonts, terminal defaults, shell startup, `mise`, and `devbox` in a clean environment.

## Recommended Host Setup

- KVM/QEMU
- `virt-install`
- `virsh`
- `virt-viewer`
- one clean base image for the desktop stack you care about most

Good first target:

- Pop!_OS or Ubuntu with KDE, because that matches the current workstation most closely

Recommended VM sizing for a first pass on this machine:

- 3 vCPUs
- 8 GB RAM minimum
- 50-80 GB qcow2 disk
- UEFI if the guest image supports it
- SPICE display
- default NAT networking is fine for the first round

If the guest feels sluggish during package installs or KDE startup, bump it to 4 vCPUs later.

## Repo-Managed VM Config

Start by creating a local config file for the VM definition:

```bash
cp system/vm/desktop-test.env.example system/vm/desktop-test.local.env
```

Then edit:

```bash
$EDITOR system/vm/desktop-test.local.env
```

At minimum, set:

- `ISO_PATH`

The rest of the defaults are already set up for this machine, including `3` vCPUs.

## First VM To Build

Start with one "golden" desktop validation VM instead of trying to model every future machine at once.

Suggested guest:

- Ubuntu 24.04 + KDE, or the closest Pop/KDE setup you can install cleanly

Name it something obvious, for example:

- `config-desktop-test`

## CLI Creation Flow

Create the VM from the repo-managed config:

```bash
./system/scripts/create-test-vm.sh system/vm/desktop-test.local.env
```

Open the guest display from the CLI:

```bash
./system/scripts/vmctl.sh view system/vm/desktop-test.local.env
```

Finish the base OS install in the guest with a simple local user.

Once the guest reaches a clean, updated post-install state, shut it down and create the baseline snapshot:

```bash
./system/scripts/vmctl.sh snapshot-create system/vm/desktop-test.local.env fresh-install
```

From that point on, always test from the snapshot instead of hand-cleaning the guest.

## Snapshot Workflow

1. Create the VM with `./system/scripts/create-test-vm.sh`.
2. Complete the base OS install.
3. Shut it down and create a clean snapshot with `./system/scripts/vmctl.sh snapshot-create`.
4. Revert to that snapshot for each test run.
5. Start the guest with `./system/scripts/vmctl.sh start`.
6. Open it with `./system/scripts/vmctl.sh view`.
7. Clone the config repo inside the guest and run the setup flow.
8. Record anything manual that should become scripted or documented.
9. Shut down, revert to the clean snapshot, and repeat.

Useful host-side commands:

```bash
./system/scripts/vmctl.sh status system/vm/desktop-test.local.env
./system/scripts/vmctl.sh start system/vm/desktop-test.local.env
./system/scripts/vmctl.sh shutdown system/vm/desktop-test.local.env
./system/scripts/vmctl.sh snapshot-list system/vm/desktop-test.local.env
./system/scripts/vmctl.sh snapshot-revert system/vm/desktop-test.local.env fresh-install
```

## Guest Prep Before Running Repo Setup

Inside the guest, get just enough working to clone and test the repo:

```bash
sudo apt update
sudo apt install -y git curl
```

If you use SSH for GitHub, restore or inject a test SSH key first. Otherwise, clone over HTTPS for the VM test.

## About "Fully CLI Driven"

The host-side VM lifecycle is now CLI-driven and config-driven.

- VM definition lives in `system/vm/desktop-test.local.env`
- VM creation uses `create-test-vm.sh`
- VM lifecycle and snapshots use `vmctl.sh`

The remaining interactive part is the OS installer inside the guest window.

If you later want truly unattended guest installation too, the next layer is an Ubuntu autoinstall or similar seeded installer. That can be added after this CLI-first loop is working well.

## Recommended First Validation Run

Inside the guest:

```bash
git clone git@github.com:Aureatus/config.git ~/dev/config
cd ~/dev/config
./setup.sh bootstrap
./setup.sh dev-env
```

If you want to validate more conservatively on the first pass:

```bash
git clone git@github.com:Aureatus/config.git ~/dev/config
cd ~/dev/config
./setup.sh system
./setup.sh dotfiles
./setup.sh dev-env
```

## Suggested Validation Order

Inside the VM guest:

```bash
git clone git@github.com:Aureatus/config.git ~/dev/config
cd ~/dev/config
./setup.sh bootstrap
./setup.sh dev-env
```

Then verify:

- the shell starts correctly
- Ghostty and terminal font config land where expected
- `mise install` restores the pinned runtime versions
- `devbox shell` works in the repo
- KDE-specific behavior still feels correct after reboot/login

Command checks:

```bash
zsh --version
starship --version
mise ls
devbox version
devbox shell
```

Inside `devbox shell`, confirm that:

```bash
devbox run help
mise current
```

## Desktop Checks

Do these manually in the guest session:

- open a terminal and confirm the font looks correct
- start a new shell and confirm `mise` activates cleanly
- confirm `~/.config/mise/config.toml` exists
- confirm `~/.config/ghostty/config` exists
- confirm `~/.config/cosmic-term/config.toml` exists
- log out and log back in
- reboot once and confirm the setup still behaves the same way

## What To Record During Each Run

Keep short notes for each snapshot run:

- what command failed
- what was missing or still manual
- whether the fix belongs in `setup.sh`, `dotfiles/manage.sh`, `mise.toml`, `devbox.json`, or docs
- whether the issue is desktop-specific or generic

That turns each VM pass into concrete follow-up work instead of vague memory.

## What To Test Here Instead Of The Fake-Home Sandbox

- full desktop environment behavior
- package-manager interactions
- login shell defaults
- fonts and terminal rendering
- Nix/Devbox installation side effects
- reboot and session persistence

## Notes

- Keep the fake-home sandbox for quick local safety checks.
- Treat the VM as the final proof step before changing the real workstation.
- The goal is not to make the first VM perfect; it is to make each rerun faster and more repeatable from the `fresh-install` snapshot.
