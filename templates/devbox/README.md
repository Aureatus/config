# Devbox Template

This starter gives new repos the same portability pattern used by `~/dev/config`.

## Model

- `mise.toml` owns runtime versions
- `devbox.json` owns the portable shell wrapper and repo-local helper commands
- app services stay in project-level Compose, systemd, or app-specific scripts

## How To Use It

1. Copy `mise.toml` and `devbox.json` into the new repo root.
2. Adjust the pinned `mise` versions for the project if needed.
3. Edit the `devbox.json` packages and scripts for the project.
4. Run `mise install`.
5. Run `devbox shell`.
6. Commit `devbox.lock` once it is generated.

## Suggested Flow

```bash
cp ~/dev/config/templates/devbox/mise.toml ./mise.toml
cp ~/dev/config/templates/devbox/devbox.json ./devbox.json
mise install
devbox shell
```

If the repo has sensitive or machine-specific values, keep them in `.env` or `mise.local.toml` and do not commit them.
