# Shared AI Prompts

`ai/shared/` is the tool-agnostic home for reusable AI material in this repository.

## Principles

- Keep shared philosophy as prompt fragments, not global generated context
- Treat repo-level `AGENTS.md` files as the authoritative source of project context
- Use Markdown for prompt content and TypeScript only when a tiny registry or helper genuinely benefits from it
- Avoid YAML in this system

## Layout

```text
shared/
├── prompts/
│   ├── product.md
│   ├── engineering.md
│   ├── design.md
│   ├── developer-operability.md
│   └── testing.md
├── skills/
│   ├── manifest.ts
│   └── custom/
└── README.md
```

## Prompts

`prompts/` holds reusable prompt fragments that are intended to be copied largely verbatim into repo-level `AGENTS.md` files or tool-specific prompt/config files.

Use them when writing:

- repo-level `AGENTS.md` files
- OpenCode or other agent-specific prompt/config files
- copied shared sections for projects that want the same philosophy

Each prompt file should read like instruction text rather than like explanatory notes.

Current prompt fragments:

- `product.md` - product behavior, prioritization, defaults, and scope tradeoffs
- `engineering.md` - implementation quality, architecture bias, maintainability, and change strategy
- `design.md` - interaction quality, hierarchy, visual direction, and accessibility
- `developer-operability.md` - internal tooling, scriptability, observability, and agent-friendly development workflows
- `testing.md` - verification posture, test strategy, and confidence in change

## Skills

`skills/manifest.ts` is an optional curated list of remote skills worth keeping track of in git.

`skills/custom/` is reserved for future local skills if you decide to own some directly in this repo.
