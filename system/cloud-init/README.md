# Cloud-Init

Use `cloud-init` for first boot on VPS hosts and cloud-image based local tests.

Recommended pattern:

1. `cloud-init` creates the user, installs Python and base packages, and gets the host reachable
2. Ansible applies the long-lived shared configuration from this repo
3. `mise` restores your primary runtime and task layer
4. `devbox` is optional, only if a repo later proves it needs more than `mise`

This keeps first boot small and provider-friendly while leaving the real config in one reusable place.

## Files

- `server-user-data.example.yaml` is a starter for VPS user-data

## Next Step

After the host comes up and you can SSH in, run the server playbook from your control machine.
