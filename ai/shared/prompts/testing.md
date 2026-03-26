# Testing Prompt Fragment

Use this prompt fragment when deciding what to test, how to verify a change, or how much confidence is required before considering work complete.

## Instructions

- Test for risk, behavior, and confidence in change rather than chasing coverage as a vanity metric.
- Put the most weight on user-critical flows, business invariants, important boundaries, and recovery from failure.
- Prefer tests that catch meaningful regressions over tests that mirror implementation details too closely.
- Prefer end-to-end tests for full user flows over over-optimizing for narrow unit coverage.
- Use unit tests for deterministic logic with clear inputs and outputs.
- Use integration tests when contracts, orchestration, or system boundaries matter.
- Use end-to-end tests for the small set of flows that must work from a user's point of view.
- Prefer real integrations, local infra, and separate test databases over mocks whenever practical.
- Mock only true external boundaries that cannot be exercised realistically, safely, or affordably in tests.
- Prefer integration coverage over mock-heavy unit tests when real behavior is affordable to exercise.
- Derive test cases from authoritative contracts, domain rules, invariants, and user-critical actions.
- When behavior is declarative or generated from a source of truth, test the definition plus the critical derived outcomes rather than duplicating the whole system by hand in tests.
- Keep tests deterministic, readable, and trustworthy.
- Eliminate flaky timing assumptions, incidental assertions, and brittle setup whenever possible.
- Test unhappy paths, partial failures, and recovery behavior when they materially affect the product.
- When a change is user-facing, verify the actual experience when practical rather than trusting only abstractions.
- Use snapshots deliberately and review visual diffs before accepting them.
- Keep the suite fast enough to be used regularly and reliable enough that passing results mean something.
- Fix flaky tests or remove them; do not normalize instability.
- Treat verification as part of the work, not as optional ceremony at the end.

## Avoid

- Do not optimize for raw coverage if it produces weak confidence.
- Do not mock code you own or infrastructure you can run locally just for convenience.
- Do not overuse mocks where exercising real integration behavior is practical.
- Do not let narrow low-level tests crowd out full user-flow coverage.
- Do not accept flaky tests as normal background noise.
- Do not let snapshot sprawl replace thoughtful assertions.
- Do not claim a change is complete without verifying the behaviors that matter most.
- Do not duplicate the full implementation logic inside tests when the real source of truth can be exercised directly.
