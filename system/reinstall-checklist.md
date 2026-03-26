# Reinstall Checklist

Use this before and after reinstalling Linux.

## Before Reinstall

- Run `./setup.sh capture` from the repo root to refresh `system/state/`
- Run `./setup.sh backup-kde` if you want a file-level KDE backup in addition to Konsave
- Verify your latest `konsave` snapshot still exists: `konsave -l`
- Back up repositories, local databases, `.env` files, and anything under `~/Documents` or `~/Downloads` that matters
- Copy secrets and identity material somewhere safe:
  - `~/.ssh`
  - `~/.gnupg`
  - password-manager exports or vault backups
  - browser profile or bookmarks backup
  - `~/.config/opencode`
  - any custom credentials under `~/.config`, `~/.local/share`, or app-specific directories

## Safe Test Loop

- Use `./setup.sh test-portable-env` for fast local config tests against a disposable target home
- Use `system/vm-testing.md` for the real full-DE sandbox flow with a VM and snapshots
- Treat the VM as the final proof step before applying changes to the real workstation

## After Reinstall

- Restore SSH and GPG keys before cloning private repos
- Clone this repo: `git clone git@github.com:Aureatus/config.git ~/dev/config`
- Run `./setup.sh bootstrap` from `~/dev/config`
- Run `./setup.sh dev-env` to install `mise`, install the pinned runtimes, and install `devbox`
- Restore non-repo config and app data from your backups
- Restore KDE via `konsave -a <backup-name>` or unpack the archive from `./setup.sh backup-kde`

## Sanity Checks

- `zsh --version`
- `starship --version`
- `git --version`
- `mise ls`
- `devbox version`
- `gh auth status`
- `opencode --version`
- `flatpak list`
