# Review Gates

These gates apply according to the route selected in the root `AGENTS.md`.

- Mechanical route: no formal gate; run artifact-relevant checks.
- Local route: Gate C is required; Gates D and E are risk-based.
- Structural route: Gates A through E are required; Gate F is conditional on its structural triggers.

Selecting fewer gates must never be used to disguise a structural change as a local one.

## Gate A — Domain Design

Required when domain contracts or ownership change.

Pass conditions:

- the owner of every changed state is named;
- Commands, Events, Effects, and result Events are distinguished;
- Rules and Transitions remain pure;
- Effect Graph dependencies and resource claims are explicit;
- failure and uncertainty are modeled;
- acceptance criteria are externally testable.

## Gate B — Architecture Challenge

Pass conditions:

- no hidden orchestration was found;
- no product or transport leaks into Core;
- no process boundary is mistaken for a domain boundary;
- cancellation, timeout, retry, idempotency, and recovery are addressed where relevant;
- no Python worker or LLM provider acquires domain ownership.

## Gate C — Implementation

Pass conditions:

- implementation matches the approved contract;
- dependency direction is preserved;
- changes are bounded and coherent;
- compatibility and migration impact are reported;
- focused checks pass.

## Gate D — Test Evidence

Pass conditions:

- acceptance criteria map to tests;
- important failure modes are tested;
- deterministic lower-level tests are preferred;
- test doubles preserve the contract rather than bypassing it;
- gaps are explicit.

## Gate E — Independent Review

Pass conditions:

- no unresolved Critical or High finding;
- Medium findings are fixed or consciously accepted by the primary agent;
- review confirms meaningful test coverage;
- escalation is explicit when structural risk remains.

## Gate F — Structural Acceptance

Conditional final gate for high-impact changes.

Pass conditions:

- design, implementation, and tests describe the same system;
- state ownership remains singular;
- runtime degradation and recovery remain coherent;
- public contracts and migrations are deployable;
- rollout conditions are stated.
