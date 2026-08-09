# 共通Executionのcanonical contract

この文書は、すべてのBehaviorが共有するEffect Graph、EffectOccurrence、dispatch、結果取込、取消、重複排除、Recovery接続の唯一の正式定義です。Camera、Conversation、Memory、Agentなどの意味は所有せず、release時に閉じた語彙を型引数として受けます。

## Releaseで閉じる語彙

```text
ReleaseExecutionVocabulary {
  PlannedPayload = CameraPlannedPayload | ConversationPlannedPayload,
  DispatchPayload = CameraDispatchPayload | ConversationDispatchPayload,
  ResultPayload = CameraResultPayload | ConversationResultPayload
}

PlannedEffectSpec<P> {
  effect_kind, schema_version,
  payload: P,
  configuration_snapshot_version,
  candidate_profile_refs, policy_refs
}

DispatchEffect<D> {
  effect_kind, schema_version,
  payload: D,
  effective_profile_binding,
  policy_bindings,
  authorization_bindings,
  correlation
}

ExternalResultPayload<R> { payload: R }
```

`P`、`D`、`R`はcompile時に閉じたrelease sumです。runtime plugin、登録順、文字列lookup、中央の意味catalogではありません。新しいBehavior versionは型variantとその純粋なplanned→dispatch Ruleを追加できますが、共通Execution法則はpayload内部を分岐しません。

```text
ExecutionCorrelation {
  interaction_id, qualia_session_id, graph_id,
  occurrence_id, attempt_id, attempt_generation
}

ResourceClaim { resource: ResourceKey, mode: Exclusive | Shared(capacity) }

GuardExpr = All(NonEmptyList<GuardExpr>) |
  Any(NonEmptyList<GuardExpr>) |
  DependencyTerminal(EffectOccurrenceId) |
  GuardFactSatisfied(GuardFactRef) |
  InteractionNotCancelled(InteractionId)

GuardFactRef {
  fact_id, fact_kind, subject_refs,
  issuer_contract_id, issuer_revision
}

ResultPhase = Started | Progress(progress_ordinal) | Terminal

PortResultEnvelope<R> {
  event_id,
  adapter_identity, adapter_operation_id,
  occurrence_id, attempt_id, attempt_generation,
  result_phase,
  payload: ExternalResultPayload<R>,
  diagnostic_ref?
}
```

Behavior固有guardは、所有Contextのpure Ruleが型付きDecisionを作り、対応Transitionの結果Eventから`GuardFactRef`を発行します。Executionはfactの意味を再判断せず、identity/revision/statusだけを検証します。closure、callback、script、自由文字列predicateをGuardへ入れません。

## ContextとState

### SD-CTX-EXE-001 — Execution Context

Graph、Occurrence、dispatch attempt、resource lease、guard fact ledger、durable revocation、結果相関を唯一所有します。Behavior Context、Scheduler、dispatcher、Adapter、journal replayは変更しません。

### SD-STA-EXE-001 — ExecutionState

```text
ExecutionState<P,D> {
  graphs: Map<GraphId, GraphRecord>,
  occurrences: Map<EffectOccurrenceId, OccurrenceRecord<P>>,
  attempts: Map<DispatchAttemptId, DispatchAttempt<D>>,
  resource_leases: Map<ResourceLeaseId, ResourceLease>,
  guard_facts: Map<GuardFactId, GuardFactRecord>
}

OccurrenceRecord<P> {
  occurrence_id, graph_id,
  planned_effect_spec: PlannedEffectSpec<P>,
  dependencies, guard, resource_claims,
  lifecycle, active_attempt_id?, result_event_ids,
  revoked_reason?
}

OccurrenceLifecycle = Planned | PendingDurable |
  DispatchClaimed | DispatchIntentCommitted |
  Started | Terminal | Revoked | Recovering

DispatchAttempt<D> {
  attempt_id, occurrence_id, attempt_generation,
  dispatcher_identity, result_correlation,
  dispatch_intent_mark: MonotonicMark,
  dispatch_effect: DispatchEffect<D>,
  lifecycle: Claimed | DispatchIntentCommitted |
    Started | Terminal | OutcomeUnknown
}

ResourceLease {
  lease_id, graph_id, owner_occurrence_id,
  scope: Occurrence | Graph | NamedInterval,
  resource, mode, release_guard,
  lifecycle: Pending | Active | Released,
  recovery_policy_binding
}

GuardFactRecord {
  fact_ref, source_event_id,
  status: Satisfied | Revoked
}
```

不変条件:

- 同値Effectの各出現は別Occurrence IDを持つ。
- 意味順序はdependencyとGuardだけで決め、ID、生成順、resource claimを順序に使わない。
- 一Occurrenceのactive attemptは最大一つ。
- dispatcherへ渡せるのはdurable `DispatchIntentCommitted`だけである。
- claim時に完全な不変`DispatchEffect`をattemptへ固定し、Application/Adapterが後付けしない。
- revoked workをrestart後にpendingへ戻さない。
- resultは完全なattempt correlationとstable adapter operation IDを持つ。

## Event

### SD-EVT-ING-001 — IngestedExternalEvent

```text
IngestedExternalEvent<R> {
  envelope: PortResultEnvelope<R>,
  ingest_mark: MonotonicMark
}
```

### SD-EVT-EXE-001 — EffectExecutionStartedAccepted

外部作用を試みた、または開始した事実です。適用・完了の証拠ではありません。

### SD-EVT-EXE-002 — EffectExecutionFailed

```text
EffectExecutionFailed<F> {
  correlation: ExecutionCorrelation,
  failure: F,
  external_outcome: NotPhysical |
    DefinitelyNotApplied | OutcomeUnknown,
  basis, diagnostic_ref?
}
```

### SD-EVT-EXE-003 — GuardFactRecorded

Behavior所有Contextが導いた型付き事実を、source Eventとissuer revision付きでExecutionへ登録するEventです。fact payloadやBehavior Stateを所有しません。

## Rule、Decision、Transition

### SD-RUL-EXE-001 — DetermineReadyOccurrences

dependency、閉じたGuard、revocation、resource availabilityをpureに評価します。payload kind、製品名、Behavior意味を分岐しません。

### SD-RUL-EXE-002 — DecideDispatchClaim

```text
DispatchClaimInput<P,View> {
  expected_state_revision, ready_occurrence_id,
  behavior_dispatch_view: View,
  next_attempt_generation,
  dispatch_intent_mark: MonotonicMark
}

DispatchClaimDecision<D> = Rejected(DispatchConflict) |
  Claim {
    expected_state_revision,
    attempt_id,
    lease_ids,
    dispatch_effect: DispatchEffect<D>,
    next_state
  }
```

Behaviorのpure planned→dispatch Ruleが完全な`DispatchEffect<D>`を返した場合だけClaimできます。共通Ruleはpayloadを補完しません。IDは入力から決定論的に構成し、Rule/Transition内でclock、乱数、I/Oを呼びません。

### SD-TRN-EXE-001 — RegisterGraphAndPending

cycle、self-edge、別Graph edge、未知Guard Fact、型不整合を拒否し、Graph、Occurrence、pending leaseをExecution Stateへ登録します。

### SD-TRN-EXE-002 — ApplyDispatchClaim

Claimをexpected revisionへ決定論的に適用します。CASとClock取得はApplication境界が行います。

### SD-TRN-EXE-003 — ApplyOccurrenceResult

occurrence、attempt、generation、phase一致の結果だけを一度適用します。Terminal後の別Terminal、未知、旧session結果はRecovery/auditへ隔離します。

### SD-TRN-EXE-004 — RevokeInteractionDescendants

Cancellation後、未dispatch子孫をdurable revokeします。in-flight作用の停止は主張しません。

### SD-TRN-EXE-006 — ReleaseResourceLease

閉じたrelease guardを評価し、Execution leaseだけをReleasedへ進めます。OutcomeUnknown/Recovery handoffで別Contextの非再利用Stateが必要な場合は、同じUnit of Workで両Transitionをcommitします。

### SD-TRN-EXE-007 — ApplyGuardFact

issuer contract、subject、revision、source Eventが一致するfactだけをSatisfied/Revokedへ適用します。Behavior Stateを変更しません。

### SD-TRN-EXE-008 — ApplyCompetingOccurrenceWinner

同じ競合groupに属する二つ以上のOccurrenceについて、pure Behavior Ruleが選んだwinner Eventを
expected Execution revisionへ一度だけ適用し、loser occurrenceをRevokedまたはRecoveringへ進めます。
競合の業務意味は判断せず、group、correlation、winner未確定、revision一致だけを検証します。
後着resultでwinnerを反転しません。

## 永続化

### SD-PER-EXE-001 — DurableExecutionBoundary

State revision、Graph/Occurrence、dispatch attempt、lease、guard fact、owner Context Event、Projection再構築参照を一つのUnit of Workへcommitできます。dispatcherはdurable intentだけを送ります。journal/Projection replayはEffect生成、ready化、dispatchを行いません。

### SD-PER-EXE-002 — DurableResultInbox

```text
ResultInboxKey {
  adapter_identity, adapter_operation_id,
  occurrence_id, attempt_id, attempt_generation,
  result_phase
}
```

State適用前にstable keyで保存し、同一key/同一payloadは一度だけ適用、同一key/異payloadはConflict quarantineとします。一attemptのTerminalは一つだけです。Adapterへはinbox commit後だけackします。`event_id`は監査metadataでありdedupe keyではありません。

## 実装責務

### SD-MOD-EXE-001 — DispatchClaimApplicationService

owner Contextのread viewとExecution revisionを取得し、Behavior固有pure planned→dispatch Rule、`SD-RUL-EXE-001`、`SD-RUL-EXE-002`を評価します。readyならClock Portからmarkを取得し、ClaimをCAS commitします。CAS失敗時は古いmark/Decisionを破棄して再読込・再評価します。commit後のdurable intentだけをdispatcherへ公開します。

Kernelは`P/D/R`の意味variantを分岐しません。release vocabularyの型結合はcompile時のapplication composition、具体Adapter bindingはBootstrapが行います。
