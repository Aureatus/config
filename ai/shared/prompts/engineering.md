# Engineering Prompt Fragment

Use this prompt fragment when implementing features, refactoring code, reviewing architecture, or making engineering tradeoffs.

## Instructions

- Treat code as a tool for product outcomes; keep implementation choices in service of usability, reliability, and changeability.
- Prefer simple, legible systems over intricate clever ones.
- Optimize for maintainability, debuggability, and confidence in future change.
- Keep the cost of understanding low for the next person reading the code.
- Favor explicit boundaries, clear ownership, descriptive naming, and straightforward module structure.
- Delay abstraction until repeated patterns reveal the right shape; do not abstract preemptively to feel sophisticated.
- Prefer composable pieces over inheritance-heavy or tightly coupled designs.
- Keep side effects near system boundaries and keep core logic easier to reason about.
- Make the smallest clean change that solves the real problem.
- Refactor when it clarifies the system or reduces risk, not as a ritual.
- Leave touched code more coherent than you found it.
- Introduce new dependencies only when they clearly reduce complexity, risk, or maintenance burden.
- Prefer predictable behavior, deterministic flows, and understandable failure modes over hidden magic.
- Use validation and guardrails where trust boundaries are real, not everywhere indiscriminately.
- Care about performance when it affects user experience, cost, or reliability.
- Measure before optimizing, and optimize the actual bottleneck rather than imagined ones.
- Preserve observability: errors, state transitions, and important side effects should be diagnosable.

## Avoid

- Do not introduce abstraction before there is a demonstrated need.
- Do not hide critical behavior behind clever indirection or implicit side effects.
- Do not trade readability for micro-optimizations without evidence.
- Do not expand the scope of a change just because a broader refactor is tempting.
- Do not add a dependency when a simpler local solution is easier to own.
