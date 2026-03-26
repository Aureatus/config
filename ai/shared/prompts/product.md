# Product Prompt Fragment

Use this prompt fragment when shaping product behavior, planning features, reviewing scope, or making tradeoffs that affect user value.

## Instructions

- Prioritize real repeated usefulness over demo-friendly novelty.
- Solve the sharpest user problem first before expanding scope or adding optional complexity.
- Favor strong defaults over configuration-heavy flexibility unless configurability is itself a core product requirement.
- Optimize for fast understanding: users should be able to tell what the product does, what just happened, and what to do next.
- Treat onboarding, empty states, loading states, success states, and failure states as core product surfaces rather than cleanup work.
- Design flows so users can recover from mistakes; destructive actions should be explicit and, when practical, reversible.
- Prefer products with a clear source of truth for core concepts, states, permissions, and outcomes.
- Keep product behavior consistent across UI, API, automation, docs, and support surfaces by deriving from the same domain rules wherever practical.
- Make important state, permissions, constraints, and consequences legible to users instead of burying them in edge cases or support docs.
- If a fallback cannot preserve a valid and useful experience, prefer a clear limitation or failure over a misleading degraded path.
- When choosing between more features and more clarity, prefer the version that is easier to understand and trust.
- Ship polished slices of value instead of broad, half-finished surfaces.
- Remove options, branches, or settings that create cognitive load without adding meaningful user value.
- Prefer reliability, legibility, and calm interaction over cleverness or unnecessary surprise.
- Use copy, pacing, defaults, and flow structure to make the product feel intentional.
- Consider edge cases during design, not after the main path is already locked in.
- Ask whether a feature earns its complexity; if the answer is weak, simplify or cut it.
- Judge product quality by whether real users can succeed with confidence, not by how much was built.

## Avoid

- Do not optimize for feature count when it harms clarity.
- Do not treat onboarding as a wall of explanation instead of a path to value.
- Do not leave ambiguous waiting states, dead clicks, or unexplained failures.
- Do not bolt on recovery, error handling, or edge-case behavior as an afterthought.
- Do not add flexibility that weakens the default experience for the majority of users.
- Do not let different product surfaces invent conflicting versions of the same business rule or user state.
- Do not let the product imply something worked, is available, or is saved when the underlying system state says otherwise.
