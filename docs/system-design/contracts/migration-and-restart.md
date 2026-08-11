# Runtime restart・Workspace migrationのcanonical contract

runtime restartとmigrationは非Qualia management operationです。共通Executionのclosed payload、Management correlation、State Snapshot正本、stable operation IDを使い、完了と復旧を推測しません。

## Runtime restart

### SD-CTX-RST-001 — Runtime Control Context

restart operation、runtime recovery point、active work handoff、supervisor result、restart lifecycleを唯一所有します。Capability readiness、Qualia、EXE pendingを所有しません。

### SD-STA-RST-001 — RuntimeRestartState

```text
RuntimeRestartState {
  state_revision,
  operations: Map<RestartOperationId, RuntimeRestartRecord>,
  recovery_points: Map<RuntimeRecoveryPointId, RuntimeRecoveryPointRecord>,
  active_work_handoffs: Map<ActiveWorkHandoffId, ActiveWorkHandoffRecord>
}

RuntimeRestartRecord {
  stable_restart_operation_id,
  configuration_application_id, desired_revision, atomic_group_id,
  source_runtime_generation, target_runtime_generation,
  recovery_point_ref?, handoff_ref?,
  lifecycle: Planned | RecoveryPointPending | RecoveryPointVerified |
    HandoffPending | RestartRequested | StopObserved |
    StartObserved | Probing | Completed | Failed |
    OutcomeUnknown | Recovery | Quarantined
}

ActiveWorkHandoffRecord {
  handoff_id, restart_operation_id, restart_epoch,
  targets: NonEmptyMap<InteractionExecutionSubject,
    ActiveWorkHandoffTarget>,
  target_recovery_evidence_refs,
  qualia_recovery_decisions,
  behavior_resume_contributions,
  lifecycle: Planned | Committed | Recovering | Released
}

ActiveWorkHandoffTarget {
  restart_epoch,
  exact_execution_subject: InteractionExecutionSubject,
  qualia_session_id,
  safe_checkpoint_ref?,
  pending_occurrence_refs,
  recovery_owner_refs
}
```

### SD-MOD-RST-002 — RestartHandoffEpoch

```text
RestartHandoffEpoch = Hash(
  restart_operation_id,
  handoff_id,
  source_runtime_generation,
  target_runtime_generation
)
```

handoff、QLI Recovering、checkpoint resume request、Execution resume commitを同じepochで相関します。handoffはSnapshot時点のexact subject generationだけを対象にし、後続Resumeが作るreplacement subjectを暗黙に対象へ追加しません。同じQualiaの後続restartは別epochを持ちます。

### SD-RUL-RST-001 — DecideRuntimeRestartReadiness

verified recovery point、durable active-work handoff、expected runtime generation、management subject revocation、resource claimをpureに検証します。Starting/Active/Terminating Qualiaは同じsessionのRecoveringへ移管し、safe checkpointなしで自動Resumeしません。

### SD-RUL-RST-002 — PlanActiveWorkHandoff

Snapshot上のStarting/Active/Terminating Qualia、current execution lineage generation、未終端exact Execution subject、pending/in-flight occurrence、Recovery owner、safe checkpointをpureに列挙し、`RestartHandoffEpoch`ごとのtarget recordを作ります。対象漏れ、別session／別generation混入、owner不明、OutcomeUnknown責任未割当、既存active recovery epochの上書きを拒否します。

### SD-RUL-RST-004 — DecideActiveWorkHandoffRelease

exact handoff／restart epochに列挙された全Qualia session、exact Execution subject generation、Occurrence、resource、recovery ownerについて、terminal Stateまたはdurable handoff/custody evidenceが一件ずつ存在し、`SD-RUL-QLI-001`の四値Decisionが全sessionへ割り当てられたことをpureに検証します。ResumeFromCheckpointのsessionはexact Behavior ownerの閉じた`BehaviorResumeContribution`、checkpoint digest、source/replacement execution subject、pinned Behavior/EXE revisions、`SD-RUL-EXE-004`に適合するresume planを必須とします。AwaitOwnerDecisionが一件でもあれば`KeepRecovering`、それ以外で全責任証拠が揃えば`ReleaseHandoff`、欠落・別epoch・別session・stale generation/evidence・Contribution不在はRejectを返します。

### SD-TRN-RST-001 — ApplyRuntimeRestartTransition

exact restart/recovery-point stable operation ID、expected RST revision、typed result Eventだけをlifecycleへ適用します。recovery point作成成功をrestart成功、supervisor受付をruntime startとして扱いません。

### SD-TRN-RST-002 — ApplyActiveWorkHandoff

計画済みhandoffとexact restart epochをexpected RST revisionへ適用し、全target subject generationとRecovery ownerが固定された場合だけCommitted、`SD-PER-RST-002`で同じtarget／epochがRecoveryへ移管された場合だけRecoveringへ進めます。Releasedは`SD-TRN-RST-004`だけが適用します。QLIやEXE Stateは変更しません。

### SD-TRN-RST-003 — ApplyRuntimeRestartResolution

exact restart operation、configuration application、desired revision、atomic group、target runtime generation、fresh readiness factsに一致する`SD-EVT-RST-004`だけを適用します。Completed、Failed、OutcomeUnknown、Quarantinedを区別し、Completed以外からCFG activation factを発行しません。同値duplicateはno-op、異payloadとterminal後late resultは隔離します。

### SD-TRN-RST-004 — ApplyActiveWorkHandoffResolution

exact handoff／restart epochと`SD-EVT-RST-005`だけを適用します。AwaitOwnerDecisionを含む場合はRecoveringを維持し、全session DecisionがResumeFromCheckpoint/TerminateToHome/QuarantineResourceのいずれかで、Resume用Behavior/EXE commit evidenceと全target recovery owner evidenceがterminalまたはdurable handoff済みの場合だけReleasedへ進めます。別epochのlate resolution、Releasedからの逆行、部分target release、QLI/Behavior/EXE Stateの直接変更を拒否します。

### SD-EVT-RST-001 — RuntimeRecoveryPointVerified

logical recovery pointがexact State Snapshot revision/pending digestを保持し、Adapter検証結果をRST Contextが受理したEventです。ready FactはこのEventと`SD-TRN-EXE-007`を`SD-PER-EXE-003`で同時commitします。

### SD-EVT-RST-002 — RuntimeRestartObserved

```text
RuntimeRestartObserved =
  RestartRequestObserved { restart_operation_id, result: Accepted | Rejected | OutcomeUnknown, evidence_ref? } |
  RuntimeStopObserved { restart_operation_id, source_generation, evidence_ref } |
  RuntimeStartObserved { restart_operation_id, target_generation, evidence_ref } |
  RuntimeRestartQueryObserved {
    restart_operation_id, stable_query_operation_id,
    supervisor_state, certainty, evidence_ref?
  } |
  RuntimeRestartCancellationObserved {
    restart_operation_id, stable_cancel_operation_id,
    cancel_result, certainty, evidence_ref?
  } |
  RuntimeRestartReconciliationObserved {
    restart_operation_id, stable_reconcile_operation_id,
    query_evidence_ref, cancel_evidence_ref?,
    reconciled_state, certainty, evidence_ref?
  }
```

RequestAccepted、StopObserved、StartObserved、Query、Cancel、Reconcileを別variantとし、プロセス再起動を受付回答から推測しません。各variantからOwner-issued Guard Factを発行する場合は`SD-PER-EXE-003`を通します。

### SD-EVT-RST-003 — ActiveWorkHandoffCommitted

exact handoff、restart epoch、対象Qualia session、exact Execution subject generation、Recovery owner、safe checkpointの集合がSnapshotへ確定したRST owner Eventです。restart完了や仕事再開を意味しません。

### SD-EVT-RST-004 — RuntimeRestartResolved

```text
RuntimeRestartResolved {
  restart_operation_id,
  configuration_application_id, desired_revision, atomic_group_id,
  source_runtime_generation, target_runtime_generation,
  result: Completed | Failed | OutcomeUnknown | Quarantined,
  supervisor_evidence_refs, readiness_fact_refs,
  custody_resolution_ref?
}
```

CompletedだけがCFG用completion Guard Factを発行できます。その他は同じcorrelationのfailure/recovery Factを発行し、desired revisionをeffectiveにしません。

### SD-EVT-RST-005 — ActiveWorkHandoffResolved

exact handoff、restart epoch、全target recovery owner terminal/handoff evidence、全Qualia sessionの`SD-EVT-QLI-002`、Resume sessionのsource/replacement execution subjectとBehavior/EXE resume commit refs、結果`KeepRecovering | Released`を固定したRST owner Eventです。runtime restart完了やCFG activationを意味しません。

### SD-MOD-RST-001 — RuntimeControlExecutionPayload

```text
RuntimeControlPlannedPayload =
  CreateRecoveryPointPlan { restart_operation_id, snapshot_revision } |
  VerifyRecoveryPointPlan { recovery_point_ref, expected_digest } |
  RequestRestartPlan { restart_operation_id, target_generation } |
  QueryRestartPlan { stable_restart_operation_id } |
  CancelRestartPlan { stable_restart_operation_id } |
  ReconcileRestartPlan { stable_restart_operation_id, observed_supervisor_ref } |
  AwaitRestartDeadlinePlan { stage, deadline_policy_ref }

RuntimeControlDispatchPayload =
  CreateRecoveryPointDispatch { logical_ref, snapshot_revision, pending_digest } |
  VerifyRecoveryPointDispatch { logical_ref, expected_digest } |
  RequestRestartDispatch { verified_recovery_point_ref, handoff_ref, exact_generations } |
  QueryRestartDispatch { exact_stable_operation_id } |
  CancelRestartDispatch { exact_stable_operation_id } |
  ReconcileRestartDispatch { exact_stable_operation_id, observed_supervisor_ref } |
  AwaitRestartDeadlineDispatch { stage, anchor_mark, duration }

RuntimeControlResultPayload =
  RecoveryPointCreateObserved { logical_ref, result, certainty } |
  RecoveryPointVerifyObserved { logical_ref, observed_digest, result } |
  RestartSupervisorObserved { stable_operation_id, supervisor_state, certainty } |
  RestartCancelObserved { stable_operation_id, cancel_result, certainty } |
  RestartReconcileObserved { stable_operation_id, reconciled_state, certainty } |
  RestartDeadlineElapsed { stage, observed_mark }
```

### SD-EFX-RST-001 — CreateRuntimeRecoveryPoint

stable operation ID、logical recovery point ref、required Snapshot revision、pending digest、Management correlationを持つ不変Effectです。

### SD-EFX-RST-002 — VerifyRuntimeRecoveryPoint

exact recovery point、expected Snapshot digest、stable operation IDを検証Adapterへ依頼します。

### SD-EFX-RST-003 — RequestRuntimeRestart

verified recovery point ref、owner-issued active-work handoff Fact、expected/target runtime generation、stable operation IDを持ちます。resource claimは`RuntimeControl:Exclusive`です。

### SD-EFX-RST-004 — QueryRuntimeRestartStatus

OutcomeUnknownまたはrestart後bootstrapが同じstable operation IDのSupervisor状態を照合するEffectです。blind restartを行いません。

### SD-EFX-RST-005 — AwaitRuntimeControlDeadline

recovery point、handoff、restart request、query/cancel/reconcileの各RST stageに固定deadlineを置く不変Effectです。fresh runtime probeのdeadlineは`SD-GPH-RBI-001`の`SD-EFX-RBI-007`が所有し、RST payloadへ混入しません。deadlineは未実行の証明ではなく、OutcomeUnknown／Recoveryへ分岐させるEventを返します。

### SD-EFX-RST-006 — CancelRuntimeRestartRequest

exact stable restart operation IDの未開始またはSupervisorが取消可能と観測した要求だけを取消依頼します。停止済み、再起動済み、Unsupported、OutcomeUnknownを区別します。

### SD-EFX-RST-007 — ReconcileRuntimeRestart

query/cancel観測、Supervisor generation、必須runtime readiness evidenceを照合し、外部状態を検証依頼します。Completed、fallback、resumeを決定しません。

### SD-RUL-RST-003 — ResolveRuntimeRestartUncertainty

RST State、stable operation ID、一回限りのquery/cancel/reconcile result、runtime owner readiness factsをpureに評価し、CompleteRestart、FailRestart、QuarantineRuntimeを返します。OutcomeUnknownからrestart requestや次照会を再生成しません。確定不能な最終reconcileはQuarantineRuntimeへ閉じます。

### SD-PRT-RST-001 — RuntimeControlPort

recovery point create/verify、restart request/status query、cancel、reconcileを実装し、各段階のcertaintyとtyped resultを別々の`PortResultEnvelope<RuntimeControlResultPayload>`で返します。Supervisor/AdapterはRST Stateを変更しません。

## Runtime restart Effect Graph

### SD-GPH-RST-001 — RuntimeRestartGraph

```text
base:
  C CreateRuntimeRecoveryPoint
  V VerifyRuntimeRecoveryPoint
  R RequestRuntimeRestart
  D stage deadline occurrences
  dependencies: V<-C terminal, R<-V terminal

recovery_branch: RuntimeRestartRecoveryBranch =
  QueryRecovery {
    Q QueryRuntimeRestartStatus,
    Z ReconcileRuntimeRestart,
    dependencies: Z<-Q terminal
  } |
  CancelAndQueryRecovery {
    Q QueryRuntimeRestartStatus,
    X CancelRuntimeRestartRequest,
    Z ReconcileRuntimeRestart,
    dependencies: Z<-Q terminal, Z<-X terminal
  }

guards:
  V requires RecoveryPointCreated owner fact
  R requires RuntimeRecoveryPointVerified and ActiveWorkHandoffCommitted facts
  QueryRecovery.Z requires RuntimeRestartQueryObserved owner fact
  CancelAndQueryRecovery.Z requires RuntimeRestartQueryObserved and
    RuntimeRestartCancellationObserved owner facts
  completion requires target generationの各必須runtime ownerが発行したfresh readiness facts
resources: C/V claim RecoveryPointRef:Exclusive; R claims RuntimeControl:Exclusive; Q/X/Z use same RuntimeControl recovery custody privileged claims
```

ActiveWorkHandoffCommittedはEffect nodeではなく`SD-PER-RST-002`が作るOwnerStateDerived Guard Factです。fresh probe occurrenceはRST Graphに属しません。`StartObserved`受理時に`SD-PER-RST-001`が必須runtimeごとの`SD-GPH-RBI-001 FreshProbeOnly` instanceを別Graphとして登録し、非Codexは`SD-EFX-RBI-002`、Codexは`SD-EFX-AGT-007`を`RuntimeBindingPlannedPayload`で使用します。RST Graphとのcross-Graph dependency edgeは作らず、各runtime ownerがprobe結果から発行したfresh readiness Guard Factだけをcompletion guardに使います。各future factはGraph登録時にproducer occurrenceとowner Event kind、またはOwnerStateDerived sourceを宣言します。deadline勝者またはR OutcomeUnknownは`SD-PER-EXE-004`でRuntimeControl leaseをRecovery custodyへ移します。cancel要求がない場合はQ→Z、cancel要求がある場合はQ/X→Zの閉じたformだけを登録し、Zはdependency terminalに加えて対応する`SD-EVT-RST-002` owner factsを必須とします。Q/X/Zは各最大一Occurrence・一attemptです。RequestAcceptedや取消結果から停止を捏造せず、Z後も確定不能ならRST lifecycleとRuntimeControl資源をQuarantinedへ終端します。Zとfresh runtime owner factsが揃った後に`SD-PER-RST-003`が同じconfiguration application/desired revision/atomic group correlationの`SD-EVT-RST-004`を確定するまでCompletedにしません。

### SD-PER-RST-001 — RuntimeRestartUoW

RST lifecycle、closed RuntimeControl Occurrence/Attempt/pending/outbox、Owner Event、必要なGuard FactをState Snapshotへcommitします。`StartObserved`を受理するUoWは、RST/EXE expected revision、target runtime generation、必須runtime集合を全CASし、RST Event適用と各runtimeの`SD-GPH-RBI-001 FreshProbeOnly` Graph/Occurrence/pending登録を同じSnapshot revisionへcommitします。Codex/非Codexのprobe ownershipは各RBI Graph instanceとruntime ownerにあり、RSTはEffect/result/readiness Stateを所有しません。一件でもGraph登録に失敗すればStartObserved適用を含め全棄却し、probe漏れのCompletedを許しません。resultはdurable inbox後に適用し、restart後はSnapshot正本のintentとstable operation IDからRecoveryします。journal replayしません。

### SD-PER-RST-002 — ActiveWorkHandoffAndQualiaRecoveryUoW

RST、QLI、EXEのexpected revision、exact restart epoch、Snapshot時点のcurrent execution subject generationを全CASし、`SD-TRN-RST-002`によるhandoffのCommitted→Recovering、対象sessionごとの`SD-TRN-QLI-001`による同じepoch付きRecovering化、exact Execution subjectのRecovery責任参照、`SD-EVT-RST-003`、そのGuard Fact declaration/satisfactionを同じState Snapshot revisionへcommitします。一つでも対象、generation、epoch、revisionが変化した場合は全て棄却し、handoffだけ、Qualiaだけ、EXEだけを残しません。後続replacement subjectはこのhandoffのtargetへ追加しません。

### SD-PER-RST-003 — RuntimeRestartResolutionUoW

RST、CFG、EXE、全必須runtime ownerのexpected revisionと、exact restart/application/desired/atomic-group correlation、target generation、fresh readiness facts、Recovery custody evidenceを全CASします。Recovery branchでは`SD-PER-EXE-005`によるcustody Active→Reconciled→ReleasedまたはQuarantinedを含め、`SD-TRN-RST-003`によるRestartRecordのCompleted/Failed/OutcomeUnknown/Quarantined終端、`SD-EVT-RST-004`、Completedまたはfailure/recovery Guard Fact、`SD-TRN-EXE-007`適用、元/recovery Occurrence終端、全lease release/quarantineを同じSnapshot revisionへcommitします。一回限りのZ後もStillUnknownならRestartRecord、custody、RuntimeControl資源をQuarantinedへ進め、OutcomeUnknownのままUoWを終えません。Completed factはCFG stepを直接activateせず、`SD-PER-CFG-004`だけが後続activationを行います。crash/duplicate時はdeterministic restart operation IDから再開し、Eventだけ、Factだけ、RST terminalだけを残しません。

### SD-PER-RST-004 — ActiveWorkHandoffReleaseUoW

RST、QLI、EXE、handoffに列挙された全target recovery owner、Resume対象の全Behavior ownerのexpected revision、exact restart/handoff/restart epoch/session/source subject generation集合、terminalまたはdurable handoff/custody evidenceを全CASします。各sessionの`SD-RUL-QLI-001`、`SD-EVT-QLI-002`、`SD-TRN-QLI-002`、`SD-RUL-RST-004`、`SD-EVT-RST-005`、`SD-TRN-RST-004`、必要なEXE quarantine/release Transitionを同じSnapshot revisionへcommitします。ResumeFromCheckpointはさらにBehavior固有pure Ruleが作るContribution、Behavior owner Transition/Event、`SD-RUL-EXE-004`、`SD-TRN-EXE-013`、`SD-EVT-EXE-006`を同じcommitに含め、checkpoint owner Stateのresume、Qualia Recovering→Activeとactive epoch clear／history保持、source subjectのSuperseded化、replacement subjectの次generation登録、DefinitelyNotAppliedで終端した旧Occurrenceを置換する新しいplanned Occurrenceの`AwaitingClaim`登録を原子的に完了します。

このUoWはattempt、BindingUse、resource lease、dispatch Effect、dispatch intent/outboxを作りません。再開後の外部送信は、置換Occurrenceに対するBehavior固有normal dispatch UoWが`SD-PER-EXE-006`を合成し、current authorization、data transfer、safety、runtime generation、fresh readiness、BindingUse、resource availabilityとresume requestのClaimed化を全CASした後だけ可能です。AwaitOwnerDecisionはQualiaとhandoffを同じepochのRecoveringに維持します。TerminateToHome/QuarantineResourceは責任移管後にTerminatingを経てHomeへ進めます。一件でもtarget/evidence/revision/Contribution/epochが欠ければ全棄却し、handoffだけReleased、QualiaだけActive/Home、Behavior checkpointだけConsumed、置換subject／Occurrenceだけ、またはattempt/intent/outboxだけを残しません。旧epochの遅延結果はexact旧handoffへ隔離し、後続subject／epochを変更しません。

### SD-REC-RST-001 — RuntimeRestartRecovery

OutcomeUnknown、process stop後、new runtime readiness前、recovery point検証Failureを別状態にします。OutcomeUnknownは同じRecovery custodyのQ/X/Zだけで照合し、`SD-PER-RST-003`でcustodyをReleasedまたはQuarantinedへ終端します。新runtimeが必須Capabilityのfresh Readyを満たすまでCFG effectiveを切り替えず、別mode/Providerへfallbackしません。

## Workspace migration

### SD-CTX-MIG-001 — Workspace Migration Context

migration plan、ordered step、protected asset manifest、migration recovery point、verification/recovery lifecycleを唯一所有します。CFG StateとEXE occurrenceを所有しません。

### SD-STA-MIG-001 — MigrationState

```text
MigrationState {
  state_revision, workspace_schema_version,
  plans: Map<MigrationPlanId, MigrationPlanRecord>,
  recovery_points,
  operation_results: Map<MigrationOperationResultId,
    MigrationOperationResultRecord>,
  recovery_resolutions: Map<RecoveryCustodyId,
    MigrationRecoveryResolutionRecord>,
  recovery_generations: Map<MigrationStageScope,
    MigrationRecoveryGeneration>,
  recovery_branches: Map<MigrationRecoveryBranchKey,
    MigrationRecoveryBranchRecord>
}

MigrationPlanRecord {
  plan_id,
  source_version, target_version,
  protected_asset_manifest_digest,
  stages: MigrationStageLedger,
  next_stage: MigrationNextStage,
  lifecycle: Planned | Preflighted | BackupVerified |
    Applying | Verifying | Completed |
    Failed | Restored | OutcomeUnknown | Recovering | Quarantined
}

MigrationStageLedger {
  inspect: MigrationStageRecord<InspectStage>,
  create_recovery_point: MigrationStageRecord<CreateRecoveryPointStage>,
  verify_recovery_point: MigrationStageRecord<VerifyRecoveryPointStage>,
  ordered_apply_steps: NonEmptyList<MigrationStepRecord>,
  verify_target: MigrationStageRecord<VerifyTargetStage>,
  restore: MigrationStageRecord<RestoreStage>
}

MigrationStepRecord {
  step_id, step_payload_ref, stable_operation_id,
  dependencies: Set<MigrationStepId>,
  resource_claims, idempotency_class,
  verification_contract, rollback_contract,
  lifecycle: Pending | Ready | Dispatched | Applied |
    Failed | OutcomeUnknown | Recovering | Quarantined,
  result_event_ref?
}

MigrationStageRecord<S> {
  stage: S, stable_operation_id, dependencies,
  lifecycle: Pending | Ready | Dispatched | Applied |
    Failed | OutcomeUnknown | Recovering | Quarantined,
  result_event_ref?
}

MigrationNextStage = Inspect | CreateRecoveryPoint | VerifyRecoveryPoint |
  ApplyStep(MigrationStepId) | VerifyTarget | Restore | None

MigrationStageRef = Inspect | CreateRecoveryPoint | VerifyRecoveryPoint |
  ApplyStep(MigrationStepId) | VerifyTarget | Restore

MigrationRecoveryGeneration =
  OpaqueMonotonic<(MigrationPlanId, MigrationStageRef)>

MigrationStageScope { plan_id, stage_ref: MigrationStageRef }

MigrationRecoveryBranchKey {
  plan_id, stage_ref, custody_id,
  recovery_generation: MigrationRecoveryGeneration
}

MigrationRecoveryBranchRecord {
  key: MigrationRecoveryBranchKey,
  original_stable_operation_id,
  query_occurrence_id,
  cancel_occurrence_id?,
  reconcile_occurrence_id,
  lifecycle: Registered | Active | Terminal | Quarantined
}

MigrationOperationResultRecord {
  result_event_id, plan_id, stage_ref, stable_operation_id,
  payload_digest, certainty
}

MigrationRecoveryResolutionRecord {
  custody_id, branch_key, resolution_event_id,
  decision, evidence_refs
}
```

`ordered_apply_steps`の順序と各stepのdependencyは別の制約です。list順だけでreadyにせず、exact predecessorがAppliedであることをOwner Ruleが検証します。中間stageのDefinitelyAppliedはそのstageだけをAppliedにし、`next_stage`を最大一段だけ進めます。

stage/step lifecycle、`result_event_ref`、plan lifecycle、`next_stage`、`workspace_schema_version`を変更できるのは`SD-TRN-MIG-004`だけです。operation resultとRecovery resolutionは別ledgerに先に記録し、通常結果とRecovery結果は同じAdvance Transitionを正確に一回適用します。

Migration planの許可lifecycle/next-stage edgeは次だけです。

| From plan lifecycle | exact stage result / Decision | To plan lifecycle | next_stage |
| --- | --- | --- | --- |
| `Planned` | `InspectResolved.DefinitelyApplied` | `Preflighted` | `CreateRecoveryPoint` |
| `Preflighted` | `RecoveryPointCreated.DefinitelyApplied` | `Preflighted` | `VerifyRecoveryPoint` |
| `Preflighted` | `RecoveryPointVerified.DefinitelyApplied` | `BackupVerified` | `ApplyStep(first)` |
| `BackupVerified \| Applying` | `ApplyStepResolved.DefinitelyApplied`かつ次stepあり | `Applying` | `ApplyStep(next)` |
| `BackupVerified \| Applying` | final `ApplyStepResolved.DefinitelyApplied` | `Verifying` | `VerifyTarget` |
| `Verifying` | `TargetVerified.DefinitelyApplied` | `Completed` | `None` |
| 非終端 | 確定Failureかつrestore不要 | `Failed` | `None` |
| 非終端 | restore必要 | `Recovering` | `Restore` |
| `Recovering` | `RecoveryPointRestored.DefinitelyApplied` | `Restored` | `None` |
| `Recovering \| OutcomeUnknown` | `StillUnknown` | `Quarantined` | `None` |

Completed、Restored、Quarantinedはterminalです。上表にないskip、二段advance、Completed/Restoredからの遷移、intermediate resultからのCompletedを拒否します。

### SD-RUL-MIG-001 — ValidateMigrationPlan

source/target schema、protected assets、step dependency/cycle、resource claims、recovery point、verification/rollback contractをpureに検証します。

### SD-RUL-MIG-002 — ResolveMigrationUncertainty

exact `MigrationRecoveryBranchKey`、stable operation ID、durable inbox、一回限りのcancel/query/reconcile結果、verification contractをpureに評価し、DefinitelyApplied、DefinitelyNotApplied、RestoreRecoveryPoint、Quarantineを返します。OutcomeUnknown step、query、cancel、reconcileを再実行せず、最終照合後も不明ならそのcustodyをQuarantineへ閉じます。別stageのRecovery branchは別key/recovery generationとして独立に評価します。

### SD-RUL-MIG-003 — DecideMigrationStageAdvance

exact plan revision、`next_stage`、stage/step record、stable operation ID、通常result ledgerまたはRecovery resolution ledgerのどちらか一方のtyped result、全dependencyのAppliedをpureに評価します。

```text
MigrationStageAdvanceDecision =
  ApplyIntermediateAndAdvanceOne {
    current_stage, next_stage, result_event_id
  } |
  CompleteAfterTargetVerification { verification_event_id } |
  RestoreAfterRestoreVerification { restore_event_id } |
  FailPlan { failed_stage, failure_event_id } |
  QuarantinePlan { uncertain_stage, resolution_event_id } |
  RejectOutOfOrderOrConflictingResult
```

Inspect、recovery point create/verify、ApplyStepのDefinitelyAppliedをCompletedへ写像しません。CompletedはVerifyTarget、RestoredはRestoreのexact検証成功からだけ構築できます。`ApplyIntermediateAndAdvanceOne`は一度のTransitionで二段以上進めません。

### SD-RUL-MIG-004 — PlanMigrationRecoveryBranchRegistration

exact plan/stage scope、original occurrence/attempt/stable operation、current scoped recovery generation、existing branch/custody ledgerをpureに検証します。初回はstrictly next generation、deterministic custody/key/Q/X/R IDsを返し、同original occurrence/attempt/stageのduplicateは既存keyのIdempotentReplay、異payloadまたは別custody割当はConflictを返します。別stage scopeのgenerationは参照せず、別stageのbranchをduplicateとしません。

### SD-TRN-MIG-001 — RecordMigrationOperationResult

exact plan/stage/stable operation IDに対応するoperation固有`SD-EVT-MIG-001`だけを`operation_results`へ一度記録します。stage/step lifecycle、`result_event_ref`、plan lifecycle、`next_stage`、workspace schema versionは一切変更しません。同値duplicateはno-op、同IDの異payloadは隔離します。

### SD-TRN-MIG-002 — ApplyMigrationRecoveryObservation

exact plan/step/original stable operation/custodyに一致する`SD-EVT-MIG-002`だけをRecovery evidenceへ適用します。同値duplicateはno-op、異payload、別step、custody terminal後のlate resultは隔離し、target schema versionを変更しません。

### SD-TRN-MIG-003 — RecordMigrationRecoveryResolution

exact plan/stage/original operation/custody/recovery generationに一致する`SD-EVT-MIG-003`だけを`recovery_resolutions`へ一度記録し、対応branch recordの解決証拠を固定します。stage/step lifecycle、`result_event_ref`、plan lifecycle、`next_stage`、workspace schema versionは一切変更しません。stageへの反映は`SD-TRN-MIG-004`だけが行い、このTransitionは観測/判断記録の後に同じUoWで正確に一回呼ばれます。

### SD-TRN-MIG-004 — AdvanceMigrationStage

`SD-RUL-MIG-003`のDecisionをexact current stage recordへ適用する唯一のTransitionです。入力は`operation_results`または`recovery_resolutions`のどちらか一方のexact ledger recordです。中間成功はcurrentをAppliedにして`result_event_ref`を固定し、`next_stage`を一段だけ進め、次stageをdependency成立時だけReadyにします。final target verificationだけをCompleted、restore verificationだけをRestoredにします。同じledger recordの二重適用、step skip、二段advance、別step result適用、AppliedからPendingへの逆行を拒否します。

### SD-TRN-MIG-005 — RegisterMigrationRecoveryBranch

`SD-RUL-MIG-004`の初回Decisionと`SD-EVT-MIG-005`だけを適用し、stage scope別`recovery_generations`を一段進め、`recovery_branches`にexact branch recordを追加します。stage/step record、plan lifecycle、`next_stage`、workspace schema versionは変更しません。IdempotentReplayはno-op、同stage/original attemptの別generation、別stageの既存keyへの統合、二段generation advanceを拒否します。

### SD-EVT-MIG-001 — MigrationStepResolved

```text
MigrationStepResolved =
  InspectResolved { plan_id, stable_operation_id, result, certainty, evidence_ref? } |
  RecoveryPointCreated { plan_id, recovery_point_ref, stable_operation_id, result, certainty, evidence_ref? } |
  RecoveryPointVerified { plan_id, recovery_point_ref, stable_operation_id, result, certainty, evidence_ref? } |
  ApplyStepResolved { plan_id, step_id, step_payload_ref, stable_operation_id, result, certainty, evidence_ref? } |
  TargetVerified { plan_id, target_version, stable_operation_id, result, certainty, evidence_ref? } |
  RecoveryPointRestored { plan_id, recovery_point_ref, stable_operation_id, result, certainty, evidence_ref? }
```

operation固有variantを相互代用せず、certaintyとFailure原因を失いません。中間variantはplan Completed/Restoredを意味しません。

### SD-EVT-MIG-004 — MigrationStageAdvanced

exact plan/current stage/result Eventと、一段先の`next_stage`を固定したOwner Eventです。CompletedはTargetVerified、RestoredはRecoveryPointRestoredをsourceにする場合だけ発行できます。

### SD-EVT-MIG-005 — MigrationRecoveryBranchRegistered

exact `MigrationStageScope`、old/new recovery generation、custody ID、branch key、deterministic Q/X/R occurrence ID、original occurrence/attemptを固定したMIG owner Eventです。stage/plan advanceやRecovery解決を意味しません。

### SD-EVT-MIG-002 — MigrationRecoveryObserved

```text
MigrationRecoveryObserved =
  CancellationObserved {
    branch_key: MigrationRecoveryBranchKey,
    plan_id, stage_ref: MigrationStageRef, original_stable_operation_id,
    stable_cancel_operation_id, result, certainty
  } |
  QueryObserved {
    branch_key: MigrationRecoveryBranchKey,
    plan_id, stage_ref: MigrationStageRef, original_stable_operation_id,
    stable_query_operation_id,
    observed_state: NotStarted | InProgress | Applied | Failed | Unknown,
    certainty, evidence_ref?
  } |
  ReconciliationObserved {
    branch_key: MigrationRecoveryBranchKey,
    plan_id, stage_ref: MigrationStageRef, original_stable_operation_id,
    stable_reconcile_operation_id,
    query_evidence_ref, verification_evidence_refs,
    observed_state: NotStarted | Applied | Diverged | Unknown,
    certainty, evidence_ref?
}
```

`certainty`はDefinitelyApplied、DefinitelyNotApplied、OutcomeUnknownの閉じた値です。`QueryObserved`、`CancellationObserved`、`ReconciliationObserved`は排他的variantであり、Query結果にcancel resultまたはcancel operation IDを混入できません。

### SD-EVT-MIG-003 — MigrationRecoveryResolved

```text
MigrationRecoveryResolved {
  branch_key: MigrationRecoveryBranchKey,
  plan_id, stage_ref: MigrationStageRef,
  original_stable_operation_id, custody_id,
  result: DefinitelyApplied | DefinitelyNotApplied | StillUnknown,
  resolution:
    IntermediateStageApplied { exact_next_stage } |
    PlanTerminal(Completed | Failed | Restored | Quarantined),
  target_verification_ref?, restore_verification_ref?, evidence_refs
}
```

Ownerが一回限りのquery/cancel/reconcile evidenceを評価した結果です。中間DefinitelyAppliedは`IntermediateStageApplied`としてexact stageだけをAppliedにします。Completedはtarget verification、Restoredはrecovery point restore verificationを必須とし、StillUnknownはPlanTerminal(Quarantined)以外を構築できません。

### SD-EFX-MIG-001 — ExecuteWorkspaceMigrationOperation

```text
ExecuteWorkspaceMigrationOperation =
  InspectWorkspaceMigration {
    planned: InspectMigrationPlan,
    exact_plan_revision, exact_snapshot_ref, correlation
  } |
  CreateMigrationRecoveryPoint {
    planned: CreateMigrationRecoveryPointPlan,
    exact_plan_revision, exact_recovery_point_ref,
    exact_snapshot_revision, correlation
  } |
  VerifyMigrationRecoveryPoint {
    planned: VerifyMigrationRecoveryPointPlan,
    exact_plan_revision, exact_recovery_point_ref,
    exact_expected_digest, correlation
  } |
  ApplyMigrationStep {
    planned: ApplyMigrationStepPlan,
    exact_plan_revision, exact_step_id, exact_step_payload_ref,
    exact_dependency_event_refs, correlation
  } |
  VerifyMigrationTarget {
    planned: VerifyMigrationTargetPlan,
    exact_plan_revision, exact_target_version,
    exact_verification_contract, correlation
  } |
  RestoreMigrationRecoveryPoint {
    planned: RestoreMigrationRecoveryPointPlan,
    exact_plan_revision, exact_recovery_point_ref,
    exact_restore_contract, correlation
  }
```

六つのoperation固有Effectは相互代用できません。ApplyStepだけがstep payload/refとdependency evidenceを持ち、VerifyTargetだけがtarget verification、Restoreだけがrecovery point restoreを依頼します。pathとsecretを持ちません。

### SD-EFX-MIG-002 — QueryWorkspaceMigrationOperation

```text
QueryWorkspaceMigrationOperation {
  planned: QueryMigrationPlan,
  exact_branch_key, exact_plan_revision,
  exact_stage_ref, exact_original_operation_id,
  correlation
}
```

OutcomeUnknown操作の未着手、適用中、適用済み、失敗、unknownを照会します。stepを再実行しません。

### SD-EFX-MIG-003 — CancelWorkspaceMigrationOperation

```text
CancelWorkspaceMigrationOperation {
  planned: CancelMigrationPlan,
  exact_branch_key, exact_plan_revision,
  exact_stage_ref, exact_original_operation_id,
  exact_cancellation_policy_ref, correlation
}
```

未開始またはAdapterが取消可能と観測したexact operationだけを取消依頼します。Unsupported/OutcomeUnknownを正式結果に含め、rollbackやrestore成功を意味しません。

### SD-EFX-MIG-004 — AwaitWorkspaceMigrationDeadline

```text
AwaitWorkspaceMigrationDeadline {
  planned: AwaitMigrationDeadlinePlan,
  exact_branch_key?, exact_plan_revision,
  exact_stage_ref, exact_target_operation_id,
  anchor_mark, duration, exact_deadline_policy_ref, correlation
}
```

各step、verification、restore、query/cancel/reconcileのdeadlineを観測する不変Effectです。deadlineは未適用の証明ではありません。

### SD-EFX-MIG-005 — ReconcileWorkspaceMigrationOperation

```text
ReconcileWorkspaceMigrationOperation {
  planned: ReconcileMigrationPlan,
  exact_branch_key, exact_plan_revision,
  exact_stage_ref, exact_original_operation_id,
  exact_query_evidence_ref, exact_verification_evidence_refs,
  correlation
}
```

外部状態の照合だけを依頼します。step再実行、restore、schema公開を決めません。

### SD-MOD-MIG-001 — MigrationExecutionPayload

```text
MigrationPlannedPayload =
  InspectMigrationPlan {
    plan_id, snapshot_ref, stable_operation_id,
    management_correlation
  } |
  CreateMigrationRecoveryPointPlan {
    plan_id, recovery_point_ref, snapshot_revision,
    stable_operation_id, management_correlation
  } |
  VerifyMigrationRecoveryPointPlan {
    plan_id, recovery_point_ref, expected_digest,
    stable_operation_id, management_correlation
  } |
  ApplyMigrationStepPlan {
    plan_id, step_id, step_payload_ref,
    dependency_stage_refs, stable_operation_id,
    management_correlation
  } |
  VerifyMigrationTargetPlan {
    plan_id, target_version, verification_contract,
    stable_operation_id, management_correlation
  } |
  RestoreMigrationRecoveryPointPlan {
    plan_id, recovery_point_ref, restore_contract,
    stable_operation_id, management_correlation
  } |
  QueryMigrationPlan {
    branch_key: MigrationRecoveryBranchKey,
    plan_id, stage_ref: MigrationStageRef, original_stable_operation_id,
    stable_query_operation_id, management_correlation
  } |
  CancelMigrationPlan {
    branch_key: MigrationRecoveryBranchKey,
    plan_id, stage_ref: MigrationStageRef, original_stable_operation_id,
    cancellation_policy_ref, stable_cancel_operation_id,
    management_correlation
  } |
  ReconcileMigrationPlan {
    branch_key: MigrationRecoveryBranchKey,
    plan_id, stage_ref: MigrationStageRef, original_stable_operation_id,
    query_evidence_ref, verification_evidence_refs,
    stable_reconcile_operation_id, management_correlation
  } |
  AwaitMigrationDeadlinePlan {
    branch_key: None | MigrationRecoveryBranchKey,
    plan_id, stage_ref: MigrationStageRef, target_operation_id,
    deadline_stage,
    deadline_policy_ref, management_correlation
  }

MigrationDispatchPayload =
  InspectWorkspaceMigration |
  CreateMigrationRecoveryPoint |
  VerifyMigrationRecoveryPoint |
  ApplyMigrationStep |
  VerifyMigrationTarget |
  RestoreMigrationRecoveryPoint |
  QueryWorkspaceMigrationOperation |
  CancelWorkspaceMigrationOperation |
  ReconcileWorkspaceMigrationOperation |
  AwaitWorkspaceMigrationDeadline

MigrationResultPayload =
  InspectResolved |
  RecoveryPointCreated |
  RecoveryPointVerified |
  ApplyStepResolved |
  TargetVerified |
  RecoveryPointRestored |
  MigrationQueryObserved {
    branch_key, plan_id, stage_ref, original_stable_operation_id,
    stable_query_operation_id, observed_state, certainty, evidence_ref?
  } |
  MigrationCancelObserved {
    branch_key, plan_id, stage_ref, original_stable_operation_id,
    stable_cancel_operation_id, cancel_result, certainty
  } |
  MigrationReconcileObserved {
    branch_key, plan_id, stage_ref, original_stable_operation_id,
    stable_reconcile_operation_id, query_evidence_ref,
    observed_state, certainty, evidence_ref?
  } |
  MigrationDeadlineElapsed {
    branch_key?, plan_id, stage_ref, target_operation_id, deadline_stage,
    deadline_policy_ref, observed_mark
  }
```

| Effect | Planned variant | Dispatch variant | Result variant / owner Event |
| --- | --- | --- | --- |
| `SD-EFX-MIG-001` | `InspectMigrationPlan` | `InspectWorkspaceMigration` | `InspectResolved` |
| `SD-EFX-MIG-001` | `CreateMigrationRecoveryPointPlan` | `CreateMigrationRecoveryPoint` | `RecoveryPointCreated` |
| `SD-EFX-MIG-001` | `VerifyMigrationRecoveryPointPlan` | `VerifyMigrationRecoveryPoint` | `RecoveryPointVerified` |
| `SD-EFX-MIG-001` | `ApplyMigrationStepPlan` | `ApplyMigrationStep` | `ApplyStepResolved` |
| `SD-EFX-MIG-001` | `VerifyMigrationTargetPlan` | `VerifyMigrationTarget` | `TargetVerified` |
| `SD-EFX-MIG-001` | `RestoreMigrationRecoveryPointPlan` | `RestoreMigrationRecoveryPoint` | `RecoveryPointRestored` |
| `SD-EFX-MIG-002` | `QueryMigrationPlan` | `QueryWorkspaceMigrationOperation` | `MigrationQueryObserved` |
| `SD-EFX-MIG-003` | `CancelMigrationPlan` | `CancelWorkspaceMigrationOperation` | `MigrationCancelObserved` |
| `SD-EFX-MIG-004` | `AwaitMigrationDeadlinePlan` | `AwaitWorkspaceMigrationDeadline` | `MigrationDeadlineElapsed` |
| `SD-EFX-MIG-005` | `ReconcileMigrationPlan` | `ReconcileWorkspaceMigrationOperation` | `MigrationReconcileObserved` |

各dispatch Effectは対応するplanned value全体を`planned: XxxPlan`として埋め込みます。plan/step/payload/dependency、original operation、Recovery operation ID、Policy/evidence、Management correlationを選択コピーせず、result variantも同じoperation familyのidentityを返します。Inspect/CreateRP/VerifyRP/ApplyStep/VerifyTarget/Restore、Query、Cancel、Reconcileは相互代用できません。

### SD-PRT-MIG-001 — WorkspaceMigrationPort

Inspect、recovery point create/verify、ApplyStep、target verify、restoreを別Port method/型として実装し、query、cancel、reconcileも別methodで受け、stable operation IDと対応するtyped result variantを返します。Adapterは次stage、Workspaceがusableか、migrationがCompleted/Restoredかを決めません。

## Workspace migration Effect Graph

### SD-GPH-MIG-001 — WorkspaceMigrationGraph

```text
I Inspect
C CreateRecoveryPoint
V VerifyRecoveryPoint
S1..Sn ordered ApplyStep occurrences
T VerifyTarget
B RestoreRecoveryPoint [failure/recovery]
D per-stage deadline occurrences

normal dependencies: C<-I, V<-C, S1<-V, S(n+1)<-Sn, T<-Sn; Bはfailure/recovery factでguard
resources: normal migration operations claim WorkspaceMigration:Exclusive and declared logical assets;
  Q/X/R use the same WorkspaceMigration Recovery custody privileged claims
guards: all require ExecutionSubjectNotRevoked(ManagementSubject); each step requires exact predecessor owner fact

recovery_branch(key: MigrationRecoveryBranchKey) =
  QueryOnly {
    Q QueryWorkspaceMigrationOperation(key),
    R ReconcileWorkspaceMigrationOperation(key),
    dependencies: R<-Q terminal
  } |
  CancelAndQuery {
    Q QueryWorkspaceMigrationOperation(key),
    X CancelWorkspaceMigrationOperation(key),
    R ReconcileWorkspaceMigrationOperation(key),
    dependencies: R<-Q terminal, R<-X terminal
  }
```

各future factは不変`GuardFactDeclaration`と、lifecycleの唯一正本である`GuardFactRecord.status=Pending`として登録し、producer occurrenceとMIG owner Event kindを固定します。resource claimは順序に使いません。I/C/V/SnのDefinitelyAppliedは`SD-PER-MIG-003`でexact stageをApplied、`next_stage`を一段だけ進め、dependency成立時だけ次OccurrenceのGuard Factを満たします。中間成功からTを飛び越えたりCompletedにしません。Failure/DefinitelyNotAppliedは未dispatch子孫をrevokeしrestore Decisionへ進みます。OutcomeUnknown/deadlineまたはin-flight cancelは`SD-PER-MIG-004`がplan/stage/custody/scoped recovery generationからbranch keyとQ/X/R IDを決定論的に構成し、`SD-PER-EXE-004`のcustody移管と同時に一回だけ登録します。同custody/keyのduplicateは同値no-opであり、別recovery generationを割り当てて迂回しません。別stageは別scopeのrecovery generation/keyを持ち、先行stageのcustody terminal後に独立したbranchを登録できます。Q/X/Rはkeyごとに各最大一Occurrence・一attemptで、custody privileged claimだけを使います。Q/X/Rからstep成功を捏造せず、target verify成功後だけCompleted、restore検証成功後だけRestoredを公開します。R後も確定不能またはrestore OutcomeUnknownならplan、stage、custody、Workspace資源をQuarantinedへ同時終端します。

### SD-PER-MIG-001 — MigrationUoW

MIG lifecycle、全stage record、`next_stage`、closed Migration Occurrence/Attempt/pending/outbox、result inbox、verification Event refをState Snapshotへcommitします。各stageはstable operation IDでdedupeし、journal replayから実行しません。中間resultの適用は`SD-PER-MIG-003`へ委ねます。

### SD-PER-MIG-002 — MigrationRecoveryResolutionUoW

MIGとEXEのexpected revision、exact branch key/plan/stage/original operation/custody/recovery generation、一回限りのcancel/query/reconcile terminal inbox、`SD-RUL-MIG-002`、`SD-RUL-MIG-003` Decision、`SD-EVT-MIG-002`、`SD-EVT-MIG-003`を全CASします。`SD-TRN-MIG-003`はRecovery resolution ledgerだけを記録し、通常pathと同じ`SD-TRN-MIG-004`を正確に一回適用してexact stage/plan/next-stageを進めます。final target verifyだけをCompleted、restore verifyだけをRestored、StillUnknownをQuarantinedとし、`SD-PER-EXE-005`のcustody Active→Reconciled→ReleasedまたはQuarantined、元/recovery Occurrence終端、全lease release/quarantineを同じSnapshot revisionへcommitします。crash/duplicateは同じbranch/custody/inbox keyから全体を再開し、resolution ledgerだけ、MIG stageだけ、next_stageだけ、leaseだけ、custodyだけを先に確定しません。

### SD-PER-MIG-003 — MigrationStageAdvanceUoW

MIGとEXEのexpected revision、exact plan/current stage/stable operation、durable result inbox、全dependency Applied evidence、宣言済みnext-stage Guard Factを全CASします。`SD-TRN-MIG-001`はoperation result ledgerだけを記録し、`SD-RUL-MIG-003`の後に`SD-TRN-MIG-004`を正確に一回適用し、`SD-EVT-MIG-004`、次Occurrenceをreadyにする`SD-TRN-EXE-007`を同じSnapshot revisionへcommitします。中間DefinitelyAppliedは一stageだけAppliedにし、一段先だけをReadyにします。`SD-TRN-MIG-001`と`003`がstage/planを変更するcomposition、または`004`の二回適用を構築できません。crash/duplicate時にresult ledgerだけ、stage結果だけ、`next_stage`だけ、Guard Factだけを残さず、同じinbox keyから全体を再開します。

### SD-PER-MIG-004 — MigrationRecoveryBranchRegistrationUoW

MIGとEXEのexpected revision、exact plan/stage/original occurrence/attempt、stageスコープのcurrent recovery generation、active lease、OutcomeUnknownまたはin-flight cancellation handoffを全CASします。`SD-RUL-MIG-004`、`SD-EVT-MIG-005`、`SD-TRN-MIG-005`が`MigrationRecoveryBranchKey`、custody ID、Q/X/R occurrence IDを決定論的に固定し、branch ledger追加とscope別recovery generation一段advanceを行います。それらと`SD-PER-EXE-004`のcustody/lease移管、closed recovery Graph/Occurrences/pending/privileged claimsを同じSnapshot revisionへcommitします。同じoriginal occurrence/attempt/stageのduplicateは同じkeyを返し、新generationまたは二つ目のQ/X/Rを作りません。別stageはそのstage固有generationを使うため、先行stageのbranchと独立して登録できます。一つでも書込みに失敗すれば全棄却します。

### SD-REC-MIG-001 — WorkspaceMigrationRecovery

preflight/backup前Failureは旧状態を維持します。apply途中Failureはtargetを公開せずrestore Graphへ進みます。OutcomeUnknownは新旧どちらもusableと主張せずWorkspaceをquarantineし、restore後も再検証成功までusableにしません。

### SD-PRJ-MIG-001 — MigrationProjection

plan/source/target version、step、recovery point、verification、Failure/OutcomeUnknown/quarantineをlogical refで表示し、filesystem path、secret、backup materialを表示しません。
