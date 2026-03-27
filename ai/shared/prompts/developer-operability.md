# Developer Operability Prompt Fragment

Use this prompt fragment when designing internal development workflows, tooling, local infrastructure, verification flows, or repository conventions for humans and coding agents.

## Instructions

- Prefer developer-operable systems: reproducible, scriptable, observable, testable, and constrained enough that humans and AI agents can operate them safely and correctly.
- Prefer one-command or low-ceremony flows for setup, reset, seeding, running, and verification.
- Prefer explicit CLI entrypoints, deterministic scripts, and machine-readable outputs over manual GUI-only procedures when operational tasks matter to correctness.
- Prefer systems that an agent can boot, seed, exercise, inspect, and reset through explicit commands.
- Prefer strict linting, duplication detection, pre-commit hooks, and automated verification hooks when they materially reduce review burden and catch common mistakes early.
- Encode important rules into tooling and automation instead of relying on memory, taste, or reviewer vigilance alone.
- Prefer workflows where invalid code cannot be merged, deployed, or shipped without passing enforced checks.
- Prefer local infrastructure, disposable environments, and scripted fixtures when they make real verification practical.
- Prefer docs and setup guides that are executable, copyable, and close to the commands they describe.
- Make environment requirements, runtime assumptions, ports, entrypoints, and dependencies easy to discover from the repository itself.
- Make failures inspectable: logs, status, exit codes, and health checks should help an agent understand what went wrong and what to do next.
- Keep critical workflows headless and non-interactive when possible so they can run reliably in automation.

## Avoid

- Do not require hidden setup steps, undocumented local rituals, or GUI-only operations for core development and verification flows when they could be scripted.
- Do not make critical verification depend on unscripted human setup that an agent cannot reliably reproduce.
- Do not keep high-value verification steps as tribal knowledge instead of wiring them into the default path.
- Do not make important verification optional if it can be automated cheaply and reliably.
- Do not depend on machine history, stale local state, or accidental environment quirks for normal development workflows.
- Do not leave operational behavior opaque when a script, status command, or log surface could make it legible.
