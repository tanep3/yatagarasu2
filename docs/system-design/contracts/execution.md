# 共通Executionのcanonical contract

この文書は、すべてのBehaviorが共有するEffect Graph、EffectOccurrence、dispatch、結果取込、取消、重複排除、Recovery接続の唯一の正式定義です。Camera、Conversation、Memory、Agentなどの意味は所有せず、release時に閉じた語彙を型引数として受けます。

## Releaseで閉じる語彙

```text
ReleaseExecutionVocabulary {
  PlannedPayload = CameraPlannedPayload | ConversationPlannedPayload |
    ConfigurationPlannedPayload | RuntimeBindingPlannedPayload |
    RuntimeControlPlannedPayload |
    MigrationPlannedPayload,
  DispatchPayload = CameraDispatchPayload | ConversationDispatchPayload |
    ConfigurationDispatchPayload | RuntimeBindingDispatchPayload |
    RuntimeControlDispatchPayload |
    MigrationDispatchPayload,
  ResultPayload = CameraResultPayload | ConversationResultPayload |
    ConfigurationResultPayload | RuntimeBindingResultPayload |
    RuntimeControlResultPayload |
    MigrationResultPayload,
  ResumeContribution = FiniteConversationResumeContribution
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

### SD-MOD-EXE-002 — ResumeContributionContract

```text
BehaviorResumeContribution =
  FiniteConversationResumeContribution

ResumeContribution<C> {
  qualia_session_id,
  behavior_identity, behavior_version,
  behavior_owner_context_id,
  behavior_state_ref, expected_behavior_state_revision,
  checkpoint_ref, checkpoint_digest,
  pinned_revisions,
  behavior_resume_rule_ref: ClosedPureRuleRef<C>,
  behavior_resume_transition_ref: ClosedTransitionRef<C>,
  behavior_claim_rejection_rule_ref: ClosedPureRuleRef<C>,
  behavior_claim_rejection_transition_ref: ClosedTransitionRef<C>,
  execution_resume_plan: ExecutionResumePlan
}

ExecutionResumePlan {
  source_graph_id,
  checkpoint_digest,
  restart_epoch,
  source_execution_subject,
  replacement_execution_subject,
  resume_commit_id,
  resume_request_refs: NonEmptySet<CheckpointResumeRequestId>,
  replacements: NonEmptyList<ResumeReplacementPlan>
}

ResumeReplacementPlan {
  resume_request_id,
  prior_occurrence_id, prior_attempt_id,
  replacement_occurrence_id,
  resume_generation, replacement_execution_subject,
  planned_effect_spec: PlannedEffectSpec<P>,
  dependencies, guard, resource_claims,
  checkpoint_node_digest
}
```

ContributionはBehavior ownerの純粋Ruleが作り、そのowner Transitionだけがcheckpoint Stateをresumeします。さらに、置換Occurrenceのnormal claimが恒久拒否された場合に、Behavior ownerがその事実をどの型付きFailureと終端へ写すかを、閉じたrejection Rule/Transition refとして必ず宣言します。Rule/Transition refはreleaseで閉じたvariantであり、文字列、callback、service locatorではありません。`ExecutionResumePlan`は実行済みEffectまたは旧Occurrenceを再利用せず、DefinitelyNotAppliedと確定した復旧対象ごとに新しいplanned occurrence/specを作るための値です。dispatch effect、attempt、BindingUse、resource lease、dispatch intent/outboxは含みません。適合Contributionまたはrejection mappingがないBehaviorはResumeFromCheckpointを選択できません。KernelはContribution variantの業務意味も拒否後の利用者表現も判断せず、相関、revision、digest、Execution不変条件だけを検証します。

### SD-MOD-EXE-003 — ExecutionLineageAndResumeProvenance

同じInteraction／Qualiaに属する仕事を、restart前後で別の実行世代として表します。Interaction identity、Qualia identity、Execution generationを相互代用しません。

```text
ExecutionLineageId = Hash(interaction_id, qualia_session_id)
ExecutionGeneration = OpaqueMonotonic<ExecutionLineageId>

InteractionExecutionSubject {
  lineage_id, generation,
  interaction_id, qualia_session_id
}

ExecutionLineageRecord {
  lineage_id, interaction_id, qualia_session_id,
  current_generation,
  subjects: Map<ExecutionGeneration, ExecutionSubjectRecord>,
  lifecycle: Active | Revoked | Terminal,
  cancellation_event_ref?
}

ExecutionSubjectRecord {
  subject: InteractionExecutionSubject,
  parent_subject?,
  origin:
    InitialAdmission |
    ResumeCommit {
      resume_commit_id, restart_epoch, prior_subject
    },
  lifecycle: Active | Superseded | Revoked | Terminal
}

OccurrenceOrigin =
  InitialAdmission { initial_lineage_event_ref } |
  ResumeReplacement {
    resume_request_id, resume_commit_id,
    restart_epoch, prior_execution_subject
  }
```

利用者取消はexact generationだけでなくlineage全体を対象にします。旧generationのlate resultは旧subjectのRecovery／auditへだけ隔離し、後続generationのOccurrence、Presentation、terminalを変更しません。Management subjectは従来どおり`ManagementOperationRef`であり、このlineageへ混入しません。

初期Interaction仕事は必ずgeneration `0`の`InitialAdmission` subjectから始まります。Interaction/Qualia admission、Behavior ownerの初期State、初期Graph/Occurrence登録より先にlineageだけを作りません。また、Graph登録側がlineageを推測して後付けしません。

```text
ExecutionCorrelation =
  InteractionExecutionCorrelation {
    interaction_id, qualia_session_id, common
  } |
  ManagementExecutionCorrelation {
    management_operation: ManagementOperationRef, common
  }

ExecutionCorrelationCommon {
  graph_id, occurrence_id, attempt_id,
  attempt_generation: ExecutionAttemptGeneration
}

ManagementOperationRef =
  ConfigurationApplication {
    configuration_change_id, configuration_application_id,
    application_step_id
  } |
  RuntimeRestart {
    restart_operation_id, configuration_application_id,
    desired_revision, atomic_group_id
  } |
  WorkspaceMigration { migration_plan_id, migration_step_id }

ExecutionSubjectRef =
  InteractionSubject(InteractionExecutionSubject) |
  ManagementSubject(ManagementOperationRef)

ResourceClaim =
  AcquireResourceClaim {
    resource: ResourceKey,
    mode: Exclusive | Shared(capacity)
  } |
  ContinueNamedIntervalLeaseClaim {
    resource: ResourceKey,
    mode: Exclusive | Shared(capacity),
    existing_lease_id: ResourceLeaseId,
    named_interval_ref: NamedResourceIntervalRef,
    holder_ref: NamedResourceIntervalHolderRef
  }

GuardExpr = All(NonEmptyList<GuardExpr>) |
  Any(NonEmptyList<GuardExpr>) |
  DependencyTerminal(EffectOccurrenceId) |
  GuardFactSatisfied(GuardFactRef) |
  ExecutionSubjectNotRevoked(ExecutionSubjectRef)

GuardFactRef {
  fact_id, fact_kind, subject_refs,
  issuer_contract_id, issuer_revision,
  source: GuardFactSource
}

GuardFactSource =
  OccurrenceProduced {
    producer_occurrence_id,
    owner_event_kind
  } |
  ExternalObservationProduced {
    owner_context_id,
    owner_event_kind,
    external_operation_id
  } |
  OwnerStateDerived {
    owner_context_id,
    owner_event_kind,
    source_state_revision
  }

GuardFactDeclaration {
  fact_ref,
  consumer_occurrence_ids
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

Behaviorまたはmanagement操作の所有Contextがpure RuleとTransitionで導いたEventから`GuardFactRef`を発行します。Unit of Work、Application service、Bootstrap、Adapterはissuerになりません。未来に成立するfactはGraph登録時に`GuardFactDeclaration`として宣言し、Occurrence由来ならproducer occurrenceとowner Event kind、外部観測またはOwner State由来なら明示variantを必須にします。Executionはfactの意味を再判断せず、identity、issuer revision、lifecycle、因果関係だけを検証します。未宣言fact、source不明、closure、callback、script、自由文字列predicateをGuardへ入れません。

## ContextとState

### SD-CTX-EXE-001 — Execution Context

Graph、Occurrence、dispatch attempt、resource lease、guard fact ledger、durable revocation、結果相関を唯一所有します。Behavior Context、Scheduler、dispatcher、Adapter、journal replayは変更しません。

### SD-STA-EXE-001 — ExecutionState

```text
ExecutionState<P,D> {
  execution_lineages: Map<ExecutionLineageId, ExecutionLineageRecord>,
  graphs: Map<GraphId, GraphRecord>,
  occurrences: Map<EffectOccurrenceId, OccurrenceRecord<P>>,
  attempts: Map<DispatchAttemptId, DispatchAttempt<D>>,
  resource_leases: Map<ResourceLeaseId, ResourceLease>,
  recovery_custodies: Map<RecoveryCustodyId, RecoveryCustodyRecord>,
  checkpoint_resume_requests: Map<CheckpointResumeRequestId,
    CheckpointResumeRequestRecord>,
  resume_commits: Map<ExecutionResumeCommitId,
    ExecutionResumeCommitRecord>,
  guard_facts: Map<GuardFactId, GuardFactRecord>,
  subject_revocations: Map<ExecutionRevocationTarget,
    SubjectRevocationRecord>
}

OccurrenceRecord<P> {
  occurrence_id, graph_id,
  execution_subject: ExecutionSubjectRef,
  occurrence_origin: OccurrenceOrigin,
  planned_effect_spec: PlannedEffectSpec<P>,
  dependencies, guard, resource_claims,
  lifecycle, active_attempt_id?, result_event_ids,
  revoked_reason?
}

OccurrenceLifecycle = Planned | PendingDurable |
  AwaitingClaim |
  DispatchClaimed | DispatchIntentCommitted |
  Started | Terminal | Revoked | Recovering

OccurrenceRevocationReason =
  SubjectCancelled | CompetingOccurrenceLost |
  DependencyFailed | RestartHandoff

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
  named_interval_ref?: NamedResourceIntervalRef,
  holder_ref?: NamedResourceIntervalHolderRef,
  resource, mode, release_guard,
  lifecycle: Pending | Active | TransferredToRecoveryCustody |
    Quarantined | Released,
  recovery_policy_binding
}

RecoveryCustodyRecord {
  custody_id, execution_subject, owner_context_id,
  original_lease_ids: NonEmptySet<ResourceLeaseId>,
  recovery_operation_kinds,
  privileged_claims: NonEmptySet<RecoveryResourceClaim>,
  stage_occurrences: Map<Query | Cancel | Reconcile,
    NotDeclared | Pending | Attempted | Terminal>,
  reconciliation?: RecoveryCustodyReconciliation,
  lifecycle: Active | Reconciled | Released | Quarantined
}

RecoveryResourceClaim {
  custody_id, resource,
  permission: Query | Cancel | Reconcile
}

RecoveryCustodyReconciliation {
  result: DefinitelyApplied | DefinitelyNotApplied | StillUnknown,
  owner_event_id, evidence_refs,
  resolution_policy_ref
}

CheckpointResumeRequestRecord {
  resume_request_id,
  prior_execution_subject, prior_occurrence_id, prior_attempt_id,
  prior_custody_id,
  qualia_session_id, behavior_identity, behavior_version,
  checkpoint_ref, checkpoint_digest,
  restart_epoch,
  resume_execution_subject: InteractionExecutionSubject,
  resume_generation,
  resume_commit_id?,
  replacement_occurrence_id?,
  lifecycle: RecoveryPending | ResumableAwaitingClaim |
    ReplacementRegistered | Claimed | Rejected | Quarantined
}

ExecutionResumeCommitRecord {
  resume_commit_id,
  lineage_id,
  source_execution_subject,
  replacement_execution_subject,
  restart_epoch,
  qualia_session_id, checkpoint_ref,
  checkpoint_generation: BehaviorCheckpointGenerationRef,
  checkpoint_digest, source_graph_id,
  contribution_digest, resumed_occurrence_ids,
  lifecycle: Committed
}

GuardFactRecord {
  declaration: GuardFactDeclaration,
  source_event_id?,
  status: Declared | Pending | Satisfied | Revoked
}

ExecutionRevocationTarget =
  ExactSubject(ExecutionSubjectRef) |
  InteractionLineage(ExecutionLineageId)

SubjectRevocationRecord {
  target: ExecutionRevocationTarget,
  source_event_id,
  status: Active | Revoked
}
```

`ContinueNamedIntervalLeaseClaim`は、すでに同じholderが所有するActiveなNamedInterval leaseを後続Occurrenceが継続利用するための一般契約です。exact lease/resource/mode/interval/holderとOwner State由来のholder factが一致する場合だけ自己競合を回避し、新しいleaseやcapacityを作りません。別holder、Released/Quarantined lease、owner fact欠損、resource/mode不一致は通常の競合として拒否します。Kernelはholderの業務意味を解釈せず、型付きrefと宣言済みfactの同一性だけを検証します。

checkpoint resumeの許可edgeは次だけです。

| From | To | 必須根拠 |
| --- | --- | --- |
| `RecoveryPending` | `ResumableAwaitingClaim` | exact custody=`DefinitelyNotApplied` + `SD-PER-EXE-005` |
| `RecoveryPending` | `Rejected` | `DefinitelyApplied`またはResume不適合 |
| `RecoveryPending` | `Quarantined` | `StillUnknown` |
| `ResumableAwaitingClaim` | `ReplacementRegistered` | exact checkpoint/Behavior Contribution + `SD-PER-RST-004` |
| `ReplacementRegistered` | `Claimed` | Behavior固有normal dispatch UoWのcurrent Policy/authorization/readiness CAS |
| `ReplacementRegistered` | `Rejected` | normal dispatch UoWのtyped rejection |

`ResumableAwaitingClaim`は実行許可ではありません。`ReplacementRegistered`もplanned occurrenceが存在することだけを示し、claimには必ずnormal dispatch UoWが必要です。

不変条件:

- 同値Effectの各出現は別Occurrence IDを持つ。
- 意味順序はdependencyとGuardだけで決め、ID、生成順、resource claimを順序に使わない。
- 一Occurrenceのactive attemptは最大一つ。
- dispatcherへ渡せるのはdurable `DispatchIntentCommitted`だけである。
- claim時に完全な不変`DispatchEffect`をattemptへ固定し、Application/Adapterが後付けしない。
- revokedまたはRecoveringの旧Occurrenceをpending/claim/dispatchへ戻さない。Resumeは必ず別subject・別Occurrence IDのplanned workを登録する。
- Resume replacementは同じlineageの厳密に次のExecution generationを持ち、`ResumeReplacement` provenanceとresume requestを欠くものはclaimできない。
- 利用者取消はInteraction lineageをRevokedにする。取消後は既存・将来の全generationをclaimできず、Resumeによって取消を迂回できない。
- restart handoffとその結果はexact restart epochとsource subject generationだけを対象にし、後続generationへ伝播しない。
- resultは完全なattempt correlationとstable adapter operation IDを持つ。
- Interactionとmanagement操作の取消は、同じ`ExecutionSubjectNotRevoked`とdurable revocation ledgerで扱う。
- OccurrenceProduced Guard Factのproducerがconsumer自身またはconsumerのdescendantであるGraphは`SelfCausalGuardCycle`として拒否する。ExternalObservationProducedとOwnerStateDerivedはOccurrence edgeを捏造せず、issuer/source schemaだけを検証する。
- OutcomeUnknown資源は通常leaseをReleasedにせずRecovery custodyへ移管する。通常claimはcustody中資源を利用できず、同じcustodyのQuery/Cancel/Reconcileだけがprivileged recovery claimでdispatchできる。
- custodyはownerの型付きreconciliationなしに解放しない。`DefinitelyApplied`と`DefinitelyNotApplied`だけがlease release候補であり、`StillUnknown`は必ずQuarantinedにする。Quarantined resourceは通常claimにも別custodyにも再利用させない。
- 初期契約では一つのcustodyにQuery、Cancel、Reconcileを各最大一Occurrence、各最大一attemptだけ登録できる。terminal後の再attempt、同種Occurrence追加、次回Recovery Graph生成を拒否する。
- 宣言済みRecovery stageを一度ずつ試しても確定できない場合、Ownerは`StillUnknown + Quarantine`へ終端する。再試行回数、budget、次Occurrence生成は初期契約に存在しない。

Recovery custodyの許可lifecycle edgeは次だけです。

| From | To | 必須根拠 |
| --- | --- | --- |
| `Active` | `Reconciled` | exact owner resolution Event + terminal query/cancel/reconcile evidence |
| `Reconciled` | `Released` | `DefinitelyApplied`または`DefinitelyNotApplied` |
| `Reconciled` | `Quarantined` | `StillUnknown` + Owner Quarantine Decision |

`Active`を維持して次のRecovery attemptを生成するedgeはありません。`Reconciled`は同じUnit of Work内の中間Transitionであり、単独commitしません。

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

### SD-EVT-EXE-004 — GuardFactDeclared

Graph登録時に、未来factのidentity、issuer、source variant、Occurrence producerならそのID、owner Event kind、consumer集合を固定したEventです。fact成立の主張ではありません。

### SD-EVT-EXE-005 — RecoveryCustodyResolved

```text
RecoveryCustodyResolved {
  custody_id, original_occurrence_id, original_attempt_id,
  owner_context_id, owner_event_id,
  result: DefinitelyApplied | DefinitelyNotApplied | StillUnknown,
  decision: Release | Quarantine,
  evidence_refs, resolution_policy_ref
}
```

外部結果そのものではなく、結果所有Contextがquery/cancel/reconcile evidenceを評価して確定したDecision Eventです。`StillUnknown + Release`は構築できません。

### SD-EVT-EXE-006 — ExecutionResumePlanCommitted

exact Qualia session、checkpoint digest、source Graph、Contribution digest、DefinitelyNotAppliedで終端した旧Occurrenceと、それを置換する新しいplanned Occurrenceの集合を固定するEXE owner Eventです。attempt、dispatch Effect、BindingUse、resource lease、dispatch intent/outboxの確定を意味しません。Behavior StateまたはQualia Stateのresumeも、このEvent単独では意味しません。

### SD-EVT-EXE-007 — CheckpointResumeClaimResolved

```text
CheckpointResumeClaimResolved {
  resume_request_id, resume_commit_id,
  replacement_execution_subject,
  replacement_occurrence_id,
  result:
    Claimed { attempt_id } |
    Rejected { reason }
}
```

normal dispatch claimと同じSnapshotでEXE ownerが確定するEventです。`Claimed`はattempt／lease／必要なBindingUse／dispatch intent／outboxとの同時commitを必須とします。`Rejected`はそれらが一件も作られていない確定拒否だけを表し、一時的なBusyやCAS競合を永久拒否へ変換しません。

### SD-EVT-EXE-008 — InitialExecutionLineageAdmitted

```text
InitialExecutionLineageAdmitted {
  lineage_id, generation: 0,
  interaction_id, qualia_session_id,
  initial_execution_subject,
  admission_identity, behavior_identity, behavior_version,
  initial_graph_id, initial_graph_digest
}
```

Interaction admission、Behavior初期State、初期Graph/Occurrenceを同じUnit of Workで受理したEXE ownerの事実です。外部Effectの開始やQualia Activeを意味しません。同じ`lineage_id`／`admission_identity`で同一payloadなら冪等再生でき、interaction、session、Behavior、Graph digestのいずれかが異なる再利用はConflictです。

## Rule、Decision、Transition

### SD-RUL-EXE-001 — DetermineReadyOccurrences

dependency、閉じたGuard、revocation、resource availabilityをpureに評価します。payload kind、製品名、Behavior意味を分岐しません。

Interaction subjectの`ExecutionSubjectNotRevoked`は、exact subject revocationとその`InteractionLineage` revocationの双方が不在で、lineage lifecycleがActiveの場合だけ成立します。generationが新しくてもlineage取消を迂回できません。

`CausalGuardAcyclic`をOccurrenceProduced Guard Factへ適用し、producerとconsumerが同一、またはproducerがconsumerのdescendantである因果循環を拒否します。ExternalObservationProducedとOwnerStateDerivedはproducer occurrenceを持たないため、明示source schemaとissuerを検証し、架空のedgeを作りません。これはfact kindの意味をKernelへ持ち込まない一般則です。

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

`ContinueNamedIntervalLeaseClaim`は、exact Active lease、named interval/holder、Owner-issued holder fact、release guard未成立をpureに検証します。同じholderの継続claimは既存leaseを再利用し、attemptごとの二重leaseを生成しません。他holderはそのActive exclusive leaseにblockされます。

Recovery Effectのclaimは通常resource availabilityを迂回しません。`RecoveryResourceClaim`がactive custody、original resource、許可operation kindと完全一致する場合だけ、custody自身が保持する旧exclusive leaseと競合せずdispatchできます。他Graph、通常Effect、別custodyのclaimは拒否します。

### SD-RUL-EXE-003 — DecideRecoveryCustodyResolution

exact custody、original occurrence/attempt、owner revision、stable target operation、query/cancel/reconcileのterminal evidence、owner Policyをpureに評価します。全宣言stageは各最大一attemptであり、確定証拠がなければ`Quarantine`だけを返します。次のRecovery occurrenceを要求するDecisionは返しません。

```text
RecoveryCustodyDecision =
  ReconciledDefinitelyApplied { owner_event, release_resources } |
  ReconciledDefinitelyNotApplied { owner_event, release_resources } |
  Quarantine { owner_event, quarantine_reason } |
  RejectLateOrConflictingEvidence
```

late/duplicateはcustody identity、target operation ID、result inbox keyまで一致する同値結果だけをidempotent no-opにし、異payload、別generation、Released/Quarantined後の結果を元Stateへ適用しません。

### SD-RUL-EXE-004 — ValidateExecutionResumePlan

exact session/Graph、checkpoint digest、pin済みconfiguration/profile revisionの保持、旧Occurrenceのterminal evidence、Released custodyの`DefinitelyNotApplied`証拠、strictly next resume generation、置換用`PlannedEffectSpec`、dependencies、guard、resource claimsをpureに検証します。加えて、source subjectがlineageのcurrent generationで、replacement subjectが同じlineageの厳密な次世代であること、restart epoch／handoff／checkpoint／resume requestが一致すること、lineageがRevokedでないこと、同じ`(lineage_id, replacement generation)`のcommitが未登録であること、全replacementが新subjectと`ResumeReplacement` provenanceを持つことを必須にします。旧Occurrenceまたは旧attemptを再活性化せず、置換Occurrence IDが決定論的かつ未登録である場合だけ`ResumeReplacementPlan`を許可します。Terminal success、DefinitelyApplied、StillUnknown、未解決custody、別Graph、stale checkpoint、宣言なしnode、dispatch Effect・attempt・BindingUse・lease・outboxを含むplanを拒否します。current authorization、data transfer、safety、runtime readinessはここで成功扱いせず、後続の通常dispatch UoWが再評価します。payloadのBehavior意味は分岐しません。

### SD-RUL-EXE-005 — DecideCheckpointResumeClaimOutcome

```text
ResumeClaimOutcome =
  NotResumeReplacement |
  MarkClaimed {
    resume_request_id, resume_commit_id,
    replacement_subject, occurrence_id, attempt_id
  } |
  MarkRejected {
    resume_request_id, resume_commit_id, reason
  } |
  KeepReplacementRegistered { retryable_conflict }
```

normal dispatch claimのDecision、Occurrence provenance、resume request／commit、current lineage、restart epochをpureに照合します。claim成功は`MarkClaimed`、認可失効、lineage取消、generation不一致等の確定拒否は`MarkRejected`、一時的な資源競合やCAS競合は`KeepReplacementRegistered`だけを返します。Resume replacementをinitial occurrenceとして扱うDecision、別世代のrequestをClaimedにするDecision、attemptなしのMarkClaimedは構築できません。

### SD-RUL-EXE-006 — ValidateInitialExecutionLineageAdmission

Accepted interaction admission identity、exact interaction/Qualia/Behavior identity、決定論的`ExecutionLineageId`、generation `0`、initial subject、初期Graph ID/digestをpureに検証します。lineage未登録なら`AdmitInitialLineage`、同じidentityと全payloadが一致する既存commitなら`IdempotentReplay`、同じlineageまたはadmission identityを別interaction、session、Behavior、Graph digestへ再利用した場合は`Conflict`だけを返します。generation `0`以外、parent subject、`ResumeCommit` origin、既存lineageへの二つ目のinitial Graphを拒否します。

### SD-TRN-EXE-001 — RegisterGraphAndPending

cycle、self-edge、別Graph edge、未宣言Guard Fact、source不明、型不整合を拒否します。commit candidateでは未来factをDeclaredとして検証し、Graph/Occurrence/pending leaseと原子commitするとき`SD-TRN-EXE-009`でPendingへ進めます。OccurrenceProduced declarationはproducer occurrenceとowner Event kindを必須とし、同じ登録候補上でcausal cycleを検証します。既に満たされた外部factを参照する場合も、既存ledgerのexact fact identityとissuer revisionが一致しなければ拒否します。

### SD-TRN-EXE-009 — AdvanceGuardFactLifecycle

DeclaredからGraph commit後のPending、PendingからSatisfiedまたはRevokedへだけ進めます。Satisfied/Revokedは終端で反転しません。exact owner Event、issuer revision、source variantが宣言と一致しない入力、未宣言fact、同一fact IDの異payloadを拒否します。

### SD-TRN-EXE-010 — TransferResourceLeaseToRecoveryCustody

OutcomeUnknown、またはin-flight取消をRecoveryへ引き渡すexact occurrence/attempt、active lease、停止未確認、Recovery owner Decisionを検証し、通常leaseを`TransferredToRecoveryCustody`へ進め、同じ資源のQuery/Cancel/Reconcileだけを許すcustodyを登録します。Occurrenceが宣言済みNamedInterval leaseを継続利用している場合は、そのexact lease/interval/holderとOwner factも同じcustodyへ原子的に移し、通常generation leaseだけ、またはNamedInterval leaseだけを残しません。取消Effectを先にdispatchしてから移管するのではなく、移管とprivileged Cancel claim登録を同時に行います。Released、再利用可能、外部作用停止を主張しません。

### SD-TRN-EXE-011 — ApplyRecoveryCustodyResolution

Active custodyだけを、owner Eventと`SD-RUL-EXE-003`のDecisionに従いReconciledへ進め、`RecoveryCustodyReconciliation`を固定します。late/duplicate/異payloadを拒否します。このTransition単独ではleaseをReleased/Quarantinedへ進めません。

### SD-TRN-EXE-012 — FinalizeRecoveryCustody

Reconciled custodyと固定済みreconciliationだけを入力にします。DefinitelyApplied/DefinitelyNotAppliedなら全original leaseとcustodyをReleasedへ、StillUnknownかつOwner Quarantine Decisionなら全original leaseとcustodyをQuarantinedへ進めます。StillUnknown→Released、Active→Released、部分lease release、Quarantined→Releasedを拒否します。永続化境界は`SD-TRN-EXE-011`とこのTransitionを`SD-PER-EXE-005`内で合成するため、Reconciledだけをcommitしません。

### SD-TRN-EXE-013 — ApplyExecutionResumePlan

`SD-RUL-EXE-004`が許可したexact planだけを適用します。Released custodyのDefinitelyNotAppliedで終端した旧Occurrenceは変更せず、source subjectをSuperseded、replacement subjectを同じlineageの次generationのActiveとして登録し、lineageの`current_generation`を一段だけ進めます。各`ResumeReplacementPlan`から新しいOccurrenceを`AwaitingClaim`として登録し、replacement subject、`ResumeReplacement` provenance、dependencies、guard、resource claimsの要求値をplanned specへ固定します。同時にcheckpoint resume requestを`ResumableAwaitingClaim → ReplacementRegistered`へ進め、`resume_commit_id`を結び、`ExecutionResumeCommitRecord`と`SD-EVT-EXE-006`を一度固定します。`resume_commits`はQualia sessionではなくcommit IDをkeyとし、同じQualia内の後続generationを拒みません。

このTransitionはattempt、dispatch Effect、BindingUse、resource lease、`DispatchIntentCommitted`、outboxを作りません。置換Occurrenceを送信可能にするには、必ず後続のBehavior固有normal dispatch UoWを通し、current AUT/DAT/safety、exact runtime generation、fresh readiness、BindingUse、resource availabilityを再評価・全CASします。Agentは`SD-PER-AGT-001`、Toolは`SD-PER-TOL-001`、非Codex runtime能力は`SD-PER-RBI-002`、Camera等は各canonical normal claim境界を使用します。一件でもrevoke、stale、generation交代、競合があればattempt、BindingUse、intent、outboxを一切残さずtyped rejectionへ進めます。旧Occurrence identity、旧attempt/generation、旧dispatch payloadを再利用しません。このTransitionは`SD-PER-RST-004`内だけでBehavior owner/QLI/RST Transitionと同時commitします。

### SD-TRN-EXE-014 — ApplyCheckpointResumeClaimOutcome

`SD-RUL-EXE-005`とexact `SD-EVT-EXE-007`だけを適用するresume request claim結果の唯一mutatorです。`ReplacementRegistered → Claimed`と`ReplacementRegistered → Rejected`だけを許可し、別subject、別generation、別Occurrence、別commit、既に終端したrequestを拒否します。Claimedは`SD-PER-EXE-006`の同じcommitにexact attemptが存在する場合だけ適用し、Rejectedはattempt、BindingUse、lease、intent、outboxが一件も生成されていない場合だけ適用します。`KeepReplacementRegistered`はStateを変更しません。

### SD-TRN-EXE-015 — InitializeExecutionLineage

`SD-RUL-EXE-006.AdmitInitialLineage`とexact `SD-EVT-EXE-008`だけを適用し、generation `0`の`ExecutionLineageRecord(Active)`、parentなしの`ExecutionSubjectRecord(origin=InitialAdmission)`を一度登録します。同じadmission identity/payloadのreplayはno-op、異payloadはConflictです。このTransition単独ではGraph、Occurrence、Interaction、Qualia、Behavior Stateを変更せず、`SD-PER-EXE-007`外のcommitを拒否します。

### SD-TRN-EXE-002 — ApplyDispatchClaim

Claimをexpected revisionへ決定論的に適用します。Resume replacement provenanceを持つOccurrenceは、同じTransition compositionに`SD-TRN-EXE-014.MarkClaimed`がない入力を拒否します。CASとClock取得はApplication境界が行います。

### SD-TRN-EXE-003 — ApplyOccurrenceResult

occurrence、attempt、generation、phase一致の結果だけを一度適用します。Terminal後の別Terminal、未知、旧session結果はRecovery/auditへ隔離します。

### SD-TRN-EXE-004 — RevokeExecutionSubjectDescendants

Interaction取消またはmanagement操作取消のOwner Eventを型付きrevocation targetへ縮約し、未dispatch子孫をdurable revokeします。Interactionの`SD-EVT-INT-001 CancellationAccepted`はexact subjectだけでなく`InteractionLineage`をRevokedにし、現在の全未claim occurrenceと未claim resume requestをrevoke／Rejectedへ進め、将来generationの登録とclaimを拒否します。in-flight作用は同じlineage correlationで既存Recoveryへ移し、停止を主張しません。旧generationのlate resultは旧subjectのRecovery／auditだけへ隔離し、新generationを変更しません。

### SD-TRN-EXE-006 — ReleaseResourceLease

閉じたrelease guardを評価し、Execution leaseだけをReleasedへ進めます。OutcomeUnknown/Recovery handoffで別Contextの非再利用Stateが必要な場合は、同じUnit of Workで両Transitionをcommitします。

### SD-TRN-EXE-007 — ApplyGuardFact

issuer contract、subject、revision、source Event、宣言済みsource variantが一致するPending factだけをSatisfied/Revokedへ適用します。内部では`SD-TRN-EXE-009`を用い、Behavior Stateを変更しません。

readyを生むOwner EventとこのTransitionは`SD-PER-EXE-003`で同一Snapshot revisionへcommitします。Factのproducerとconsumerの因果循環、issuer偽装、同一Fact IDの異payloadは拒否します。

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

### SD-PER-EXE-003 — OwnerEventAndGuardFactUoW

readyを生むOwner State Transition、Owner Event、そのexact Eventから導いた`GuardFactRef`、`SD-TRN-EXE-007`のGuard Fact登録を一つのState Snapshot revisionへcommitします。`GuardFactEmissionRequired`と宣言したOwner EventはFact欠落commitを拒否します。inbox適用後にcrashした場合はSnapshot内のinboxからこのUoW全体を冪等再開し、journal replayは使いません。

### SD-PER-EXE-004 — OutcomeUnknownRecoveryCustodyUoW

Executionと結果所有Contextのexpected revision、exact occurrence/attempt、active leases、`OutcomeUnknown | InFlightCancellationRecoveryHandoff`、Recovery ownerを全CASします。`SD-TRN-EXE-003`のRecovering化、owner Recovery Event/State、`SD-TRN-EXE-010`による全lease custody移管、Query/Cancel/Reconcile用privileged claims、そのRecovery Graph/Occurrences/pendingを同じSnapshot revisionへcommitします。Graphには各Recovery stageを最大一Occurrenceだけ登録し、各Occurrenceは一attempt限りとします。一つでも競合すれば全て棄却し、通常leaseだけ、custodyだけ、Recovery Effectだけを残しません。

### SD-PER-EXE-005 — RecoveryCustodyResolutionUoW

Execution、結果所有Context、Recovery Graph ownerのexpected revision、exact custody/original occurrence/attempt、全original lease、一回限りのquery/cancel/reconcile terminal inbox evidence、owner resolution Eventを全CASします。`SD-RUL-EXE-003`のDecision、owner Transition、owner固有のBinding/RevisionUse等のRecovery use Transition、`SD-TRN-EXE-011`のActive→Reconciled、`SD-TRN-EXE-012`のReconciled→Released/Quarantined、original/recovery Occurrenceのterminal/revoke、privileged claim失効、全leaseおよび全Recovery useのreleaseまたはquarantineを一つのTransition compositionとして同じSnapshot revisionへcommitします。

DefinitelyNotAppliedかつcheckpoint再開候補がある場合は、旧Occurrenceをterminalのまま保持し、`CheckpointResumeRequestRecord`を`RecoveryPending → ResumableAwaitingClaim`へ同じcommitで進めます。ここでは置換Occurrence、attempt、BindingUse、lease、dispatch intent/outboxを作りません。DefinitelyAppliedはresume requestをRejected、StillUnknownはQuarantinedへ進めます。一つでも競合すれば全棄却します。特にAgent turnでは`AgentTurnBinding`と`AgentRuntimeBindingUseRecord`を同じ結果へ終端し、useだけをRecoveryに残しません。crash後は同じcustody IDとinbox keyでUoW全体を再開し、owner Stateだけ、Reconciledだけ、leaseだけ、custodyだけ、resume eligibilityだけを先に確定しません。

### SD-PER-EXE-006 — ResumeAwareNormalDispatchClaimComposition

Resume専用dispatch経路ではなく、すべてのBehavior固有normal claim UoWへ課す原子合成契約です。Resume replacementをclaimする場合、owner Context、EXE、AUT/DAT/safety、対象runtime、exact replacement subject／lineage、resume request／commitのexpected revisionを全CASし、通常のplanned→dispatch Rule、BindingUse／resource lease取得、不変dispatch Effect、attempt、dispatch intent/outbox、`SD-RUL-EXE-005`、`SD-EVT-EXE-007.Claimed`、`SD-TRN-EXE-014`を同じSnapshot revisionへcommitします。一件でも失効、lineage取消、世代交代、競合があれば全書込みを棄却します。

確定拒否ではattempt、BindingUse、lease、intent、outboxを一切作らず、replacement Occurrenceのrevoke、`SD-EVT-EXE-007.Rejected`、`SD-TRN-EXE-014`を同じcommitへ適用します。一時的BusyとCAS競合は`ReplacementRegistered`を維持します。Agentの`SD-PER-AGT-001`、Toolの`SD-PER-TOL-001`、非Codex runtimeの`SD-PER-RBI-002`、Camera等の各normal claim UoWはこの合成契約へ適合し、resume occurrenceをinitial occurrence用経路へ落としません。crash後はresume request／attempt／outboxの同じidentityから全体を再開し、requestだけClaimed、またはattemptだけを残しません。

`Rejected` commitはEXE事実の確定までであり、Behavior Failure、Presentation、Interaction/Qualia終端を共通Executionが発明しません。exact `SD-EVT-EXE-007.Rejected`はContributionが宣言したBehavior owner rejection Rule/Transitionへ渡し、各Behavior固有のcross-owner terminal UoWで必ず消費します。

### SD-PER-EXE-007 — InitialInteractionExecutionAdmissionComposition

すべてのBehavior初期admission UoWへ課す原子合成契約です。CFG、BRP、IRP、INT、QLI、Behavior owner、EXEのexpected revision、Accepted admission identity、exact interaction/session/Behavior version、pin済みCFG snapshot/BRP/IRP revision、決定論的initial Graph identity/digestを全CASします。`SD-PER-CFG-005`の三RevisionUse取得component、`SD-RUL-EXE-006`、`SD-EVT-EXE-008`、`SD-TRN-EXE-015`、Behavior初期Transition、`SD-TRN-EXE-001`による初期Graph/Occurrence/pending登録、Interaction/Qualia admission Transitionを同じState Snapshot revisionへcommitします。

同じadmission identityと同じ全payloadの再送は既存のRevisionUse/lineage/Graph/Behavior admission結果を返し、二つ目のUse、Graph、Occurrence、checkpointを作りません。同じlineageまたはadmission identityでinteraction、session、Behavior、revision binding、Graph digestが異なる場合は全書込みをConflictとして棄却します。一つでもCAS競合した場合はCFG useだけ、BRP/IRP useだけ、lineageだけ、Interaction/Qualiaだけ、Behavior Stateだけ、Graphだけを残さず、再読込後に同じidentityから全体を再評価します。

## 実装責務

### SD-MOD-EXE-001 — DispatchClaimApplicationService

owner Contextのread viewとExecution revisionを取得し、Behavior固有pure planned→dispatch Rule、`SD-RUL-EXE-001`、`SD-RUL-EXE-002`を評価します。Resume provenanceがあるOccurrenceではさらに`SD-RUL-EXE-005`を必須評価し、`SD-PER-EXE-006`へ合成します。readyならClock Portからmarkを取得し、ClaimをCAS commitします。CAS失敗時は古いmark/Decisionを破棄して再読込・再評価します。commit後のdurable intentだけをdispatcherへ公開します。

Kernelは`P/D/R`の意味variantを分岐しません。release vocabularyの型結合はcompile時のapplication composition、具体Adapter bindingはBootstrapが行います。
