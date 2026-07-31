# Yatagarasu 2 — Codex Development Constitution

## Mission

Yatagarasu 2 is not a procedural rewrite of Yatagarasu 1.
It reconstructs the discovered domain as State, Event, Rule, Transition, Decision, Effect, and Effect Graph.

The repository must remain understandable from its structures and contracts without tracing one giant execution sequence.

## Architectural invariants

1. Domain boundaries are design decisions. Process boundaries are deployment decisions.
2. A state has exactly one owner.
3. Rules are pure and never perform I/O.
4. Transitions are deterministic state transformations.
5. Effects are immutable values, not immediate calls.
6. Effect adapters never mutate WorldState. They return result Events.
7. The Kernel connects laws; it must not accumulate device-, conversation-, or provider-specific intelligence.
8. Core code does not depend on concrete products, network protocols, filesystem paths, clocks, GPUs, microphones, cameras, or LLM providers.
9. Python inference workers and external capabilities do not own WorldState, plans, provider state, or conversation state.
10. Codex tool calls and LLM proposals are not trusted commands. They return to the Kernel as proposals and pass policy validation.
11. Uncertainty in the physical world must remain explicit. Never promote an assumed observation into a confirmed fact.
12. Extend by adding types, rules, policies, plan contributors, ports, adapters, and projections—not by growing a central conditional workflow.
13. Abstraction must improve correctness, latency, diagnosis, recovery, replaceability, or usability. Decorative abstraction is rejected.
14. Yatagarasu 1 remains operational while Yatagarasu 2 is developed. Do not mix incomplete Yatagarasu 2 code into the production robot environment.

## Source dependency direction

```text
domain <- application <- ports <- adapters
                     \- bootstrap wires concrete implementations
```

- `domain` never imports `application`, `ports`, `adapters`, or `bootstrap`.
- `application` may use domain types and abstract ports, but knows no concrete product names.
- `adapters` implement ports and translate external representations.
- `bootstrap` is the only place that assembles concrete adapters.
- Transport schemas must not become domain types.

## Workflow routing

The primary Sol agent owns scope, routing, conflict resolution, and final integration.
Delegation is proportional to risk; agent count is not a quality metric.

Before a non-trivial change, classify it as one of these routes:

### Mechanical route

Use for documentation, formatting, configuration metadata, generated-file refreshes, and other changes
that do not alter runtime behavior or public contracts.

- The primary agent may complete the change directly.
- Run only checks relevant to the changed artifact.
- Do not spawn reviewers merely to confirm a mechanical edit.

### Local route

Use for a bounded defect or adapter-local change that preserves public domain contracts, state ownership,
Effect Graphs, persistence, security, and local/remote contracts.

- Use `code_mapper` only when the affected path is unclear.
- Assign exactly one write owner for each code area.
- Run focused tests derived from the observable behavior.
- Use `implementation_reviewer` when failure risk, regression scope, or test ambiguity justifies it.
- Escalate immediately to the structural route if a contract or ownership change is discovered.

### Structural route

Use when Commands, Events, State, Rules, Transitions, Decisions, Effects, Policies, Ports, Projections,
ownership, Effect Graphs, persistence, migration, concurrency, cancellation, retry, idempotency, security,
recovery, provider routing, physical-world assumptions, or Rust/Python/local/remote contracts change.

1. Use `domain_architect` to produce an implementation contract and acceptance criteria.
2. Use `architecture_challenger` to falsify the design before implementation.
3. Resolve every mandatory condition before writing production code.
4. Assign exactly one write owner per code area: `rust_core_implementer` or `python_adapter_implementer`.
5. Use `test_engineer` to derive and run tests from the acceptance criteria.
6. Use `implementation_reviewer` after implementation and tests exist.
7. Use `integration_judge` only for the structural acceptance triggers defined in the workflow document.

For the detailed routes, handoff contract, review gates, and model economy, read:

- `docs/development/agent-workflow.md`
- `docs/development/review-gates.md`

## Delegation constraints

- Do not run write-heavy agents in parallel against overlapping files.
- Give each agent a bounded goal, relevant files, approved contracts, acceptance criteria, and exclusions.
- Do not ask agents to rediscover context already established by the primary thread.
- Parallelize read-only evidence gathering; serialize writes.
- Stop a subagent when its bounded question is answered.
- Return summaries and evidence rather than raw logs unless reproduction requires them.

## Required implementation report

Every implementation must report:

- files changed;
- contracts added or changed;
- invariants relied upon;
- tests run and results;
- known limitations;
- migration or compatibility impact;
- unresolved questions.

## Definition of done

A change is done only when:

- acceptance criteria are demonstrably satisfied;
- the dependency direction remains valid;
- state ownership remains unambiguous;
- Effects and result Events preserve failure and uncertainty;
- tests cover the changed behavior and important failure modes;
- no required review gate remains unresolved;
- documentation is updated when a public contract or architectural decision changes.
