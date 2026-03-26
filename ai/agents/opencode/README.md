# OpenCode Project Template

`ai/agents/opencode/` contains the repo-managed OpenCode template files for projects.

## What Lives Here

- `opencode.json` - base OpenCode project config
- `.opencode/` - reusable plugin templates and helper files
- `setup.sh` - simple copy-if-missing installer for a target project

## Setup

From the repo root:

```bash
./setup.sh opencode /path/to/your/project
```

Or directly from this directory:

```bash
./setup.sh /path/to/your/project
```

The script copies tracked template files into the target project if they are missing. It does not try to adopt, merge, or overwrite existing project config.

## Shared Philosophy

Shared philosophy does not live here.

If you want reusable philosophy or prompt fragments, use `../../shared/prompts/` as source material and bring the relevant parts into repo-level `AGENTS.md` or other agent config where it makes sense.

## Template Contents

- `opencode.json`
- `.opencode/.gitignore`
- `.opencode/package.json`
- `.opencode/bun.lock`
- `.opencode/plugin/*.ts`

The installer ignores `.opencode/node_modules/`.

## Tooling

- `package.json` is for local type-checking of OpenCode plugin files
- `tsconfig.json` covers the plugin TypeScript files and the shared skill manifest
