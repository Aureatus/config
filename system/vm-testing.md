# VM Testing

Use a VM as the canonical full-desktop sandbox for this repo.

The preferred workflow is CLI-driven with repo-managed config, not `virt-manager` menus.

The repo now includes a zero-click Ubuntu autoinstall path for the guest OS itself, not just the host-side VM lifecycle.

## Why a VM

- A fake-home sandbox protects your current dotfiles and config paths, but it is not a real security boundary.
- A VM lets you test package installs, desktop behavior, fonts, terminal defaults, shell startup, and `mise` in a clean environment.

## Recommended Host Setup

- KVM/QEMU
- `virt-install`
- `virsh`
- `virt-viewer`
- one clean base image for the desktop stack you care about most

Good first target:

- Pop!_OS or Ubuntu with KDE, because that matches the current workstation most closely

For the unattended install path, use an Ubuntu Server ISO and let autoinstall add the KDE session packages.

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
./system/scripts/list-vm-presets.sh
```

Then edit:

```bash
$EDITOR system/vm/desktop-test.local.env
```

At minimum, set:

- `VM_PRESET` if you want a different named distro preset
- `ISO_URL` if you want to change the default download source
- or `ISO_PATH` if you want to point at a local ISO you already have

The default example already points at the official Ubuntu 24.04.4 server ISO and caches it locally on first use.
The rest of the defaults are already set up for this machine, including `3` vCPUs and an Ubuntu autoinstall profile.

Important safety rule:

- the ISO cache lives outside the repo by default under `/var/tmp/config-vm/isos`
- autoinstall seed artifacts live outside the repo by default under `/var/tmp/config-vm/<vm-name>/autoinstall`
- the resolver refuses repo-local paths and home-directory paths for libvirt system VMs so you do not accidentally hit permission errors or commit multi-gigabyte images

Acceleration note:

- `VM_ACCEL="kvm"` is the fast default
- if the host KVM device permissions are broken, you can temporarily use `VM_ACCEL="tcg"` for software emulation, but it will be much slower

If you hit `Could not access KVM kernel module: Permission denied` on the host, the repo includes a helper:

```bash
sudo ./system/scripts/fix-kvm-access.sh
```

## First VM To Build

Start with one "golden" desktop validation VM instead of trying to model every future machine at once.

Suggested guest:

- Ubuntu 24.04 Server ISO plus the repo-managed autoinstall profile that adds KDE packages

Useful presets:

- `ubuntu-24.04-server-kde` for the full desktop-oriented validation path
- `ubuntu-24.04-server-smoke` for a much faster smoke test that skips KDE packages and `mise install`

If you just want the fastest path without editing any VM config, use:

```bash
./setup.sh vm-smoke
```

That command uses `system/vm/smoke-test.env.example` and brings up a disposable smoke VM with lighter CPU, RAM, and disk settings.

To rebuild the smoke VM from the latest repo state in one command:

```bash
./setup.sh vm-smoke-reset
```

For the full desktop VM, the equivalent commands are:

```bash
./setup.sh vm-desktop
./setup.sh vm-desktop-reset
```

Name it something obvious, for example:

- `config-desktop-test`

## CLI Creation Flow

Create the VM from the repo-managed config:

```bash
./system/scripts/create-test-vm.sh system/vm/desktop-test.local.env
```

Or use the simplest path, which creates the VM if needed, starts it if needed, and opens the viewer:

```bash
./system/scripts/vmctl.sh up system/vm/desktop-test.local.env
```

If `AUTOINSTALL_ENABLED=1`, the VM definition step also:

- resolves `ISO_URL` into a cached local ISO if needed
- renders `user-data` and `meta-data`
- builds a NoCloud seed ISO under `/var/tmp/config-vm/<vm-name>/autoinstall/`
- boots the Ubuntu installer with the `autoinstall` kernel parameter

If `AUTOINSTALL_AUTO_APPLY_CONFIG=1`, the guest will also auto-apply the repo config on first boot.

For the default smoke and server+KDE presets, console autologin is also enabled for the configured user so you usually do not need to type credentials just to inspect the VM.

The default server+KDE preset is tuned for speed by:

- using the Ubuntu Server minimal install source
- preinstalling the curated bootstrap apt package set during autoinstall
- skipping the duplicate apt/bootstrap pass during first-boot Ansible apply

If you mostly want to validate the auto-apply + Ansible plumbing, switch the VM to `ubuntu-24.04-server-smoke` and rerun. That preset is intentionally much faster than the full desktop path.

For the default local VM presets, the auto-apply path now injects a local archive of your current working tree, so uncommitted local changes are included automatically.
If you explicitly switch back to `AUTOINSTALL_CONFIG_REPO_MODE="remote-clone"`, then the repo URL and git ref settings take over instead.

Open the guest display from the CLI if you want to watch progress:

```bash
./system/scripts/vmctl.sh view system/vm/desktop-test.local.env
```

Once the guest reaches a clean, updated post-install state, shut it down and create the baseline snapshot:

```bash
./system/scripts/vmctl.sh snapshot-create system/vm/desktop-test.local.env fresh-install
```

From that point on, always test from the snapshot instead of hand-cleaning the guest.

## Snapshot Workflow

1. Create the VM with `./system/scripts/create-test-vm.sh`.
2. Let the unattended installer complete.
3. Let first-boot auto-apply finish inside the guest.
4. Shut it down and create a clean snapshot with `./system/scripts/vmctl.sh snapshot-create`.
5. Revert to that snapshot for each test run.
6. Start the guest with `./system/scripts/vmctl.sh start`.
7. Open it with `./system/scripts/vmctl.sh view`.
8. Record anything manual that should become scripted or documented.
9. Shut down, revert to the clean snapshot, and repeat.

Useful host-side commands:

```bash
./system/scripts/vmctl.sh up system/vm/desktop-test.local.env
./system/scripts/vmctl.sh reset system/vm/desktop-test.local.env
./system/scripts/vmctl.sh status system/vm/desktop-test.local.env
./system/scripts/vmctl.sh start system/vm/desktop-test.local.env
./system/scripts/vmctl.sh shutdown system/vm/desktop-test.local.env
./system/scripts/vmctl.sh snapshot-list system/vm/desktop-test.local.env
./system/scripts/vmctl.sh snapshot-revert system/vm/desktop-test.local.env fresh-install
```

`vmctl.sh` now opens `virt-viewer` with USB redirection disabled, which suppresses the noisy but harmless SPICE USB warning.

To inspect the generated autoinstall inputs:

```bash
ls /var/tmp/config-vm/config-desktop-test/autoinstall/
```

To inspect the in-guest first-boot automation log after boot:

```bash
sudo cat /var/log/config-firstboot.log
```

To force a fresh ISO download instead of reusing the cache:

```bash
FORCE_ISO_REFRESH=1 ./system/scripts/create-test-vm.sh system/vm/desktop-test.local.env
```

## Guest Prep Before Running Repo Setup

If you use the repo-managed autoinstall path, the guest should already have:

- a local user
- `git`
- `curl`
- `ansible-core`
- `python3-apt`
- `qemu-guest-agent`
- a KDE session via `plasma-desktop` and `sddm`

With the default VM preset, the guest should also have already auto-applied the shared desktop config on first boot.

Default credentials, if you do need them, are whatever you set in the VM env file. The current examples use `ubuntu` / `ubuntu` until you change them.

If you disabled autoinstall and installed manually instead, get just enough working to clone and test the repo:

```bash
sudo apt update
sudo apt install -y git curl
```

If you use SSH for GitHub, restore or inject a test SSH key first. Otherwise, clone over HTTPS for the VM test.

## About "Fully CLI Driven"

The host-side VM lifecycle is now CLI-driven and config-driven.

- VM definition lives in `system/vm/desktop-test.local.env`
- named distro defaults live in `system/vm/presets/*.env`
- ISO resolution and caching use `resolve-vm-iso.sh`
- VM creation uses `create-test-vm.sh`
- VM lifecycle and snapshots use `vmctl.sh`
- guest autoinstall data is rendered by `build-autoinstall-seed.sh`

The remaining interactive part can now be reduced to watching the installer progress in the guest window.

If you later want to go even further, the next layer would be tuning the autoinstall profile and first-boot behavior rather than replacing the VM stack itself.

## Recommended First Validation Run

With the default VM preset, the first boot should already:

- clone the repo into `~/dev/config`
- run the desktop Ansible playbook
- install the pinned `mise` runtimes

So the first validation run is mostly inspection rather than manual setup.

For the smoke preset, first boot should instead:

- clone the repo into `~/dev/config`
- run the `server-smoke` Ansible playbook
- install `mise` itself, but skip `mise install`

That makes it a good fast confidence check before doing the heavier desktop run.

## Suggested Validation Order

Inside the VM guest, confirm the auto-apply result first:

```bash
ls ~/dev/config
test -f ~/.config/mise/config.toml
```

Then verify:

- the shell starts correctly
- Ghostty and terminal font config land where expected
- `mise install` restores the pinned runtime versions
- optional `devbox` still works if you explicitly install it later
- KDE-specific behavior still feels correct after reboot/login

Command checks:

```bash
zsh --version
starship --version
mise ls
```

If you explicitly install the optional `devbox` layer later, you can additionally verify `devbox version` and `devbox shell`, but that is no longer part of the default path.

## Desktop Checks

Do these manually in the guest session:

- open a terminal and confirm the font looks correct
- start a new shell and confirm `mise` activates cleanly
- confirm SDDM or the graphical login/session came up after autoinstall
- confirm `~/.config/mise/config.toml` exists
- confirm `~/.config/ghostty/config` exists
- confirm `~/.config/cosmic-term/config.toml` exists
- log out and log back in
- reboot once and confirm the setup still behaves the same way

## What To Record During Each Run

Keep short notes for each snapshot run:

- what command failed
- what was missing or still manual
- whether the fix belongs in `setup.sh`, `dotfiles/manage.sh`, `mise.toml`, optional `devbox.json`, or docs
- whether the issue is desktop-specific or generic

That turns each VM pass into concrete follow-up work instead of vague memory.

## What To Test Here Instead Of The Fake-Home Sandbox

- full desktop environment behavior
- package-manager interactions
- login shell defaults
- fonts and terminal rendering
- Nix or optional Devbox installation side effects if you chose to add that layer
- reboot and session persistence

## Notes

- Keep the fake-home sandbox for quick local safety checks.
- Treat the VM as the final proof step before changing the real workstation.
- The goal is not to make the first VM perfect; it is to make each rerun faster and more repeatable from the `fresh-install` snapshot.
- The zero-click path currently assumes an Ubuntu Server ISO with `casper/vmlinuz` and `casper/initrd`; if you switch install media or remote ISO source, update the kernel/initrd paths in `system/vm/desktop-test.local.env`.
