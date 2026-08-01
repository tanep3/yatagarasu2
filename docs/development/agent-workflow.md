# Yatagarasu 2 Agent Workflow

## Agent topology

```text
Primary Sol
  ├─ code_mapper / Luna              (targeted evidence)
  ├─ domain_architect / Sol           (structural design)
  ├─ architecture_challenger / Sol    (design falsification)
  ├─ rust_core_implementer / Terra    (single Rust write owner)
  ├─ python_adapter_implementer / Terra (single Python write owner)
  ├─ test_engineer / Luna             (tests and execution evidence)
  ├─ implementation_reviewer / Terra  (independent implementation review)
  └─ integration_judge / Sol          (conditional structural court)
```

The primary agent is not a manager that redoes every task. It owns scope, routing, conflict resolution, and final synthesis.

## Standard feature route

This is the structural route. Use it only when public domain contracts, ownership, Effect Graphs,
persistence, security, concurrency, recovery, provider routing, or cross-runtime contracts change.

```text
Scope
  -> Domain design
  -> Adversarial design review
  -> One implementation owner
  -> Test engineering
  -> Independent implementation review
  -> Final synthesis
```

Use `integration_judge` only when the Gate F triggers in
[`review-gates.md`](review-gates.md#gate-f--structural-acceptance) apply.

## Adapter-local route

For a change that does not alter a public contract:

```text
Targeted mapping (optional)
  -> Python or Rust adapter implementer
  -> Focused tests
  -> Implementation reviewer (risk-based)
  -> Final synthesis
```

If the implementer discovers a contract or ownership change, stop and return to the domain gate.

Use `test_engineer` when the behavior has important failure modes, the relevant test surface is unclear,
or independent test ownership materially improves confidence. The primary agent may run straightforward,
focused checks for a narrow local change.

Use `implementation_reviewer` when the change has meaningful regression risk, concurrency or failure
semantics, broad call-site impact, or tests that do not obviously prove the behavior.

## Mechanical route

For documentation, formatting, configuration metadata, and generated-file refreshes that do not alter
runtime behavior or public contracts:

```text
Primary agent
  -> Relevant artifact checks
  -> Final synthesis
```

Do not delegate merely to satisfy a process checklist.

## Defect route

```text
code_mapper (when location is unclear)
  -> test_engineer reproduces or defines failing evidence
  -> relevant implementer makes the smallest correction
  -> test_engineer reruns
  -> implementation_reviewer
```

Escalate to `domain_architect` when the defect originates from an invalid state model, missing Event, wrong Effect boundary, or ambiguous Policy.

For an obvious, bounded defect with a known location and no contract change, `code_mapper` is unnecessary,
and the primary agent may run focused regression evidence without a separate `test_engineer`.

## Review route

Read-only reviews may run in parallel only when their scopes do not duplicate each other. A useful split is:

- implementation correctness;
- test adequacy;
- external API or contract verification.

Do not spawn multiple generic reviewers.

## Handoff contract

Every delegation should include:

```text
Goal:
In scope:
Out of scope:
Relevant files and symbols:
Approved contracts:
Architectural invariants:
Acceptance criteria:
Commands to run:
Expected return:
```

The agent should not be asked to rediscover information already known by the parent.

## Model economy

- Sol: ambiguous domain decisions, adversarial architecture review, structural acceptance.
- Terra: implementation, debugging, code review, complex test diagnosis.
- Luna: mapping, deterministic tests, command execution, repetitive evidence collection.

Use high reasoning only where edge cases or cross-boundary logic justify it.
Subagents increase total token use, so narrower scopes and shorter handoffs matter more than raw agent count.

The project configuration requests four concurrent slots. Write ownership remains serialized even when
read-only investigation uses the remaining slots.
