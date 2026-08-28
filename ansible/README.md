# Ansible Setup

Use Ansible as the shared configuration layer for local desktops, VMs, and remote VPS hosts.

## Why This Exists

- `setup.sh` is still useful as a thin entrypoint and compatibility layer
- Ansible is the preferred shared config engine because it is idempotent and works both locally and over SSH
- `cloud-init` handles first boot; Ansible handles repeatable machine state

## Layout

```text
ansible/
├── ansible.cfg
├── inventory/
│   ├── localhost.ini
│   └── hosts.example.ini
├── playbooks/
│   ├── desktop.yml
│   └── server.yml
└── roles/
    ├── common/
    ├── desktop/
    ├── runtime/
    └── user-config/
```

## Recommended Use

### Local Desktop

```bash
./setup.sh desktop-config
```

That runs the desktop playbook against `localhost` and will prompt for sudo when needed.

### Remote Server or VPS

```bash
cp ansible/inventory/hosts.example.ini ansible/inventory/hosts.local.ini
$EDITOR ansible/inventory/hosts.local.ini
./setup.sh server-config ansible/inventory/hosts.local.ini
```

If the host requires a sudo password, add `ASK_BECOME_PASS=1` to that command.
The example `cloud-init` file uses passwordless sudo, so this is only needed for hosts you provision differently.

Make sure the inventory username matches the user you create in `system/cloud-init/server-user-data.example.yaml`.

## Layering Model

- `cloud-init` gets the machine to a reachable baseline
- `ansible/playbooks/server.yml` applies shared CLI, shell, and runtime config to a VPS
- `ansible/playbooks/desktop.yml` adds desktop-oriented config like terminal files and fonts
- `mise.toml` stays the pinned runtime source of truth
- `devbox.json` stays optional and should only be used when `mise` is not enough for a repo

The server path copies repo-managed config files onto the host and then uses the installed global `mise` config there, so it does not depend on the repo existing at the same path on the remote machine.

## Why Not TypeScript For This Layer

TypeScript still makes sense for repo-specific helpers or generators, but not as the main config engine.

- Ansible already solves idempotent package, file, user, and service management
- It works locally and over SSH without inventing a custom protocol
- It maps cleanly onto VPS workflows after `cloud-init` finishes first boot

## Notes

- Desktop playbook installs the current curated apt package list from `system/packages/apt.txt`
- Server playbook deliberately skips GUI terminal config and fonts
- Devbox install is disabled by default in both playbooks and should stay optional
