# Engineering Prompt Fragment

Use this prompt fragment when implementing features, refactoring code, reviewing architecture, or making engineering tradeoffs.

## Instructions

- Treat clarity as a primary quality goal in code, structure, naming, behavior, and failure modes.
- Treat code as a tool for product outcomes; keep implementation choices in service of usability, reliability, and changeability.
- Prefer simple, legible systems over intricate clever ones.
- Optimize for maintainability, debuggability, and confidence in future change.
- Assume a meaningful share of implementation may be produced by AI coding agents and shape the codebase to minimize easy mistakes.
- Design systems so the easiest code to write is also the hardest code to get wrong.
- Keep the cost of understanding low for the next person reading the code.
- Favor explicit boundaries, clear ownership, descriptive naming, and straightforward module structure.
- Fail fast and visibly when the system cannot produce a correct or useful result.
- Do not hide invalid states behind generic fallbacks if those fallbacks produce broken, misleading, or useless behavior.
- Delay abstraction until repeated patterns reveal the right shape; do not abstract preemptively to feel sophisticated.
- Prefer composable pieces over inheritance-heavy or tightly coupled designs.
- Keep side effects near system boundaries and keep core logic easier to reason about.
- Make the smallest clean change that solves the real problem.
- Refactor when it clarifies the system or reduces risk, not as a ritual.
- Leave touched code more coherent than you found it.
- Prefer generated code over hand-crafted code where a robust source-of-truth already exists, such as ORM-generated migrations, OpenAPI-generated SDKs, or language-level code generation facilities.
- Prefer a single source of truth and derive the rest from it wherever possible.
- Derive schemas, migrations, SDKs, APIs, validations, and documentation from authoritative domain definitions instead of re-declaring the same intent in multiple layers.
- Prefer the path of least owned code when a mature, robust, and safe library can solve the problem well.
- Use libraries to reduce bespoke implementation and review overhead, especially in areas where hand-written AI-generated code is more likely to be buggy than established tooling.
- Introduce new dependencies only when they clearly reduce complexity, risk, or maintenance burden.
- Prefer predictable behavior, deterministic flows, and understandable failure modes over hidden magic.
- Use validation and guardrails where trust boundaries are real, not everywhere indiscriminately.
- Prefer strong typing, strict schemas, explicit contracts, and narrow interfaces when they can mechanically prevent whole categories of mistakes.
- Prefer compile-time guarantees, schema-time validation, generated contracts, and constrained interfaces over broad flexible APIs when they materially reduce error surface.
- Treat agent-written code as high-throughput but error-prone; bias toward tooling that catches structural mistakes automatically before review.
- Care about performance when it affects user experience, cost, or reliability.
- Measure before optimizing, and optimize the actual bottleneck rather than imagined ones.
- Preserve observability: errors, state transitions, and important side effects should be diagnosable.

## Avoid

- Do not introduce abstraction before there is a demonstrated need.
- Do not hide critical behavior behind clever indirection or implicit side effects.
- Do not paper over invalid states with generic fallbacks that make the system appear to work when it does not.
- Do not trade readability for micro-optimizations without evidence.
- Do not expand the scope of a change just because a broader refactor is tempting.
- Do not hand-craft code that should be generated from an authoritative source.
- Do not duplicate the same business intent across multiple layers when it can be declared once and derived consistently.
- Do not default to custom implementation when a proven library would be safer, more maintainable, and easier to review.
- Do not rely on manual discipline alone when a rule can be enforced by types, schemas, linters, hooks, or automated checks.
- Do not leave obvious footguns unguarded in an AI-heavy codebase when tooling could prevent them cheaply.
- Do not expose broad, weakly constrained escape hatches when a narrower contract would make mistakes harder to express.
- Do not depend on human review to catch categories of errors that tooling could reject automatically.
