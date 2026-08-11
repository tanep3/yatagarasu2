# 有限Conversation・外部Thread・SemanticMemoryのcanonical contract

この文書はPilot Bの唯一の正式定義です。初期Conversationを、一入力・一最終応答・Home復帰の有限な振る舞いとして設計します。外部Threadは複数Interactionを越えられますが、YatagarasuのConversationまたはMemoryではありません。

Pilot Aで定義済みのExecution Context、EffectOccurrence、dispatch attempt、durable result inbox、取消後のrevocationを再利用し、ここでは再定義しません。Codex固有operation、SemanticMemoryの通信方式、Provider schemaはAdapterへ閉じます。

## 閉じた共通値

```text
ExecutionAttemptGeneration = OpaqueMonotonic<ExecutionAttemptScope>
MemoryStorageGeneration = OpaqueMonotonic<MemoryStoreScope>
ExternalContinuityGeneration = OpaqueMonotonic<AgentContinuityScope>
ProtectedExternalThreadId = SecretOpaqueId

AgentTurnTarget =
  PersistentThread {
    exact_thread_id: ProtectedExternalThreadId,
    continuity_generation: ExternalContinuityGeneration
  } |
  NoExternalContinuity

ConversationInput {
  interaction_id, input_identity,
  original_user_utterance, accepted_language,
  source: Voice | Web | Api,
  configuration_snapshot_version
}

RecallPurpose = Summarize | ExistenceConfirm |
  TopicSearch | Compare | Contextualize

RecallPolicyBinding {
  purpose: NormalConversation | Explicit(RecallPurpose),
  recent_count, semantic_count,
  policy_version, configuration_snapshot_version
}

RecallFailurePolicy =
  ContinueNormalConversationWithoutMemory |
  ReturnExplicitRecallUnavailable

MemoryProvenance {
  logical_record_id, source_kind,
  source_revision, created_at_ref,
  compatibility_origin: NativeY2 | PreExistingCompatibleStore
}

MemoryCandidate {
  logical_record_id,
  storage_generation: MemoryStorageGeneration,
  content_ref: AuthorizedContentRef,
  score?, source_set: Recent | Semantic,
  provenance: MemoryProvenance
}

SelectedMemory {
  logical_record_id, content_ref: AuthorizedContentRef, provenance,
  selected_from: Recent | Semantic,
  conflict_reason: None | RecentPreferred
}

RecallSelection = Selected(List<SelectedMemory>) |
  Empty | Disabled | Revoked |
  ContinueWithoutMemory(MemoryFailure) |
  ExplicitRecallUnavailable(MemoryFailure)

AuthorizedContentRef {
  subject_id, subject_revision, content_digest,
  content_classes: NonEmptySet<ContentClass>,
  authorization_id, authorization_revision
}

AuthorizedContentMaterializationRef {
  materialization_id, subject_id, subject_revision,
  content_digest, content_classes,
  authorization_id, authorization_revision,
  expires_at_monotonic_ref
}

TransferAuthorizationBinding {
  authorization_id, authorization_revision,
  allowed_content_classes: Set<ContentClass>,
  allowed_destination, decision_digest
}

AgentTurnCorrelation {
  execution: ExecutionCorrelation,
  binding_id
}

AdmittedInteractionBinding {
  interaction_id, qualia_session_id,
  input_identity,
  request_ledger_binding,
  admission_decision_revision
}

ConversationPresentationPayload =
  FinalResponse {
    text, language, provenance
  } |
  RecallResult {
    purpose: RecallPurpose,
    body, memory_provenance: NonEmptyList<MemoryProvenance>
  } |
  RecallEmpty { purpose, policy_version } |
  RecallUnavailable {
    purpose, failure_class, retry_allowed
  } |
  RecallFailure { purpose, failure_class, retry_allowed } |
  ConversationFailure { failure_class }

ConversationPresentation = Presentation<ConversationPresentationPayload>

MemoryFailure = ConnectionUnavailable | AuthenticationRejected |
  RequestRejected | InvalidResponse | StorageUnavailable |
  Timeout | OutcomeUnknown

AgentFailure = RouteUnavailable | ConnectionUnavailable |
  ProtocolMismatch | RequestRejected | InvalidResponse |
  ExternalThreadDeleted | ResumeMismatch | PermissionDenied |
  TimedOut | OutcomeUnknown

PublicationFailure = ProjectionUnavailable | RevisionConflict |
  InvalidPresentation | OutcomeUnknown

DataAuthorizationFailure = UnknownClass | PartialAuthorization |
  MissingAuthorization | RevokedAuthorization |
  SubjectRevisionMismatch | DigestMismatch | DestinationRejected

ContentReadFailure = ContentUnavailable | MaterializationExpired |
  IntegrityMismatch | StorageUnavailable

ToolFailure = CapabilityUnavailable | GrantRejected | InputRejected |
  ExternalOperationFailed | TimedOut

TypedToolResultRef {
  result_id, capability_id, operation_kind,
  schema_version, content_ref?, provenance
}

ToolResultInputBinding {
  result_ref: TypedToolResultRef,
  content_materialization: None | AuthorizedContentMaterializationRef,
  transfer_authorization: TransferAuthorizationBinding,
  accepted_by_event_id
}

FailureBasis<F> {
  failure: F,
  evidence_refs: List<EvidenceRef>
}

ConversationPlannedPayload =
  PlannedRecall | PlannedAgentTurn | PlannedAgentCancel |
  PlannedAgentQuery | PlannedAgentReconcile | PlannedAgentDeadline |
  PlannedMemorySave | PlannedMemoryMutation |
  PlannedThinkingNotice | PlannedPresentationCommit |
  PlannedSpeech | PlannedFreshContinuity | PlannedCompaction |
  PlannedThreadResetCancel | PlannedThreadResetQuery |
  PlannedThreadResetReconcile |
  PlannedContentRead | PlannedToolOperation |
  PlannedToolCancel | PlannedToolQuery | PlannedToolReconcile |
  PlannedToolDeadline

ConversationDispatchPayload =
  RetrieveSemanticMemory | RequestAgentTurn | RequestInference |
  CancelAgentWork | QueryAgentTurnOperation |
  ReconcileAgentTurnOperation | AwaitAgentDeadline |
  SaveConversationMemory |
  MutateSemanticMemory | EmitThinkingNotice |
  PublishConversationPresentation | PlayNonStreamingSpeech |
  BeginFreshExternalContinuity | CompactExternalContinuity |
  CancelThreadResetOperation | QueryThreadResetOperation |
  ReconcileThreadResetOperation |
  ReadAuthorizedContent | ExecuteAuthorizedToolOperation |
  CancelAuthorizedToolOperation | QueryAuthorizedToolOperation |
  ReconcileAuthorizedToolOperation | AwaitToolDeadline

ConversationResultPayload =
  SemanticMemoryRetrievalResolved | MemorySaveResolved |
  MemoryMutationResolved | AgentTurnProgressed | AgentOutputProposed |
  AgentCancellationResolved | AgentTurnQueryObserved |
  AgentTurnReconciliationObserved | AgentDeadlineElapsed |
  AgentThreadResetResolved | AgentThreadCompactionResolved |
  ThreadResetCancellationResolved | ThreadResetQueryObserved |
  ThreadResetReconciliationObserved |
  ThinkingNoticeResolved | PresentationPublishResolved |
  SpeechPlaybackResolved | AuthorizedContentReadResolved |
  ToolOperationResolved | ToolCancellationResolved |
  ToolOperationQueryObserved | ToolOperationReconciliationObserved |
  ToolDeadlineElapsed
```

`RecallSelection`のFailure variantは空根拠を持ちません。通常会話の`ContinueWithoutMemory`は別Memory Providerへのfallbackではなく、選択記憶を0件に固定して同じInteractionを続行するPolicy結果です。明示Recallの`RecallUnavailable`はYatagarasuが決定論的に作り、LLMへ取得失敗を回答させません。

三種類のgenerationは型が異なり、相互代用できません。`AgentTurnTarget`も、
Thread IDなしの継続指定や、Thread ID付き`NoExternalContinuity`を構築できない直和型です。
`AuthorizedContentRef`は本文ではなく、分類と許可revisionを固定した参照です。
実本文は`ReadAuthorizedContent`を経由してだけ解決し、dispatch時に許可失効を再検証します。

Pilot Bは共通実行契約へ、上記三つの閉じたpayload集合をrelease vocabularyとして登録します。
したがってConversation Effectも、Camera Effectと同じ`ExecutionState`、
`PlannedEffectSpec<ConversationPlannedPayload>`、
`DispatchEffect<ConversationDispatchPayload>`、
`PortResultEnvelope<ConversationResultPayload>`で実行されます。

## ContextとState

### SD-CTX-QLI-001 — Qualia Context

現在の非Home sessionのidentityとLifecycleだけを唯一所有します。Conversation本文、Memory、Effect Graph、外部Threadを所有しません。

### SD-STA-QLI-001 — QualiaState

```text
QualiaState {
  current: None | QualiaSession {
    session_id, behavior_identity, behavior_version,
    lifecycle: Starting | Active | Terminating | Recovering,
    start_reason, termination_reason?,
    policy_bindings, profile_bindings,
    behavior_state_ref: OpaqueOwnedStateRef,
    active_recovery_epoch?: RestartHandoffEpoch,
    recovery_history: Map<RestartHandoffEpoch,
      QualiaRecoveryDecisionRecord>
  }
}

QualiaRecoveryDecision =
  ResumeFromCheckpoint {
    safe_checkpoint_ref,
    resume_contribution: BehaviorResumeContribution
  } |
  AwaitOwnerDecision { unresolved_owner_refs } |
  TerminateToHome { terminal_handoff_evidence_refs } |
  QuarantineResource {
    recovery_custody_refs, quarantine_resolution_event_refs
  }

QualiaRecoveryDecisionRecord {
  decision, restart_operation_id, active_work_handoff_id,
  restart_epoch,
  source_evidence_refs, decided_event_id
}
```

`Home`は`current=None`です。`OpaqueOwnedStateRef`はContext名とsession/correlationだけを持ち、State値、reducer、dispatch handleを持ちません。

### SD-CTX-INT-001 — Interaction Context

入力受理、Interaction lifecycle、取消受理、API request-idempotency ledgerを唯一所有します。Execution attemptやConversation本文を所有しません。

### SD-STA-INT-001 — InteractionState

```text
InteractionRecord {
  interaction_id, qualia_session_id, input_identity,
  lifecycle: Admitted | Running | Cancelling |
    Terminal | Recovering,
  cancellation?, terminal_result?
}

RequestLedgerEntry {
  client_key, payload_fingerprint,
  replayable_result,
  admission_result: Rejected | AcceptedNoEffect | Accepted,
  lifecycle: Recorded | InProgress | Terminal,
  interaction_id?
}

InteractionState {
  interactions: Map<InteractionId, InteractionRecord>,
  request_ledger: Map<ClientIdempotencyKey, RequestLedgerEntry>
}
```

voice入力はserver-assigned `input_identity`を持ちます。API client key、Execution attempt ID、Recovery keyを相互代用しません。`admission_result`は同じ入力を受理した結果、`lifecycle`は受理後の仕事の進行状態であり、独立に永続化・replayします。

### SD-CTX-CNV-001 — Conversation Context

原利用者発話と、Policyが受理した最終応答の正本を唯一所有します。raw Agent delta、SemanticMemory index、外部Thread本文を所有しません。

### SD-STA-CNV-001 — ConversationState

```text
ConversationTurnRecord {
  turn_id, interaction_id, qualia_session_id,
  original_user_utterance,
  accepted_final_response?, final_presentation_ref?,
  recall_selection_ref?, agent_binding_ref?,
  absolute_deadline_binding,
  proposal_budget_remaining,
  resume_checkpoint_refs,
  resume_claim_rejection_refs,
  resume_generation,
  tool_recoveries: Map<ToolRecoveryId, ToolRecoveryRecord>,
  lifecycle: Open | ResponseAccepted |
    Completed | Failed | Cancelled,
  provenance
}

ToolRecoveryRecord {
  recovery_id, custody_id, proposal_id,
  original_occurrence_id, original_attempt_id,
  target_adapter_operation_id,
  observation_refs,
  lifecycle: Recovering | Resolved | Quarantined
}

ConversationState {
  turns: Map<ConversationTurnId, ConversationTurnRecord>,
  resume_checkpoints: Map<BehaviorCheckpointId,
    ConversationResumeCheckpointRecord>
}

BehaviorCheckpointGeneration =
  OpaqueMonotonic<(ConversationTurnId, QualiaSessionId)>

ConversationResumeCheckpointRecord {
  checkpoint_ref, checkpoint_generation,
  turn_id, qualia_session_id,
  execution_subject: InteractionExecutionSubject,
  source_progress_event_ref,
  checkpoint_digest,
  pinned_conversation_revision, pinned_execution_revision,
  completed_node_digests,
  resumeable_node_digests,
  lifecycle: Available | Consumed | Invalidated
}

FiniteConversationResumeContribution {
  common: ResumeContribution<FiniteConversation>,
  turn_id, expected_turn_lifecycle: Open | ResponseAccepted,
  expected_resume_generation, next_resume_generation
}
```

raw Proposalを最終応答として保存しません。reflex commandはConversation/Memoryではなく構造化operations logへだけ残します。Finite ConversationはAvailableなcheckpoint、一致するdigest/revision、exact current execution subject、復旧責任確定を満たす場合だけ`FiniteConversationResumeContribution`を寄与できます。最終応答が未受理ならその生成nodeをresume対象にできます。最終応答が受理済みなら応答digestをpinし、生成／受理nodeを完了済みとして除外し、Presentation、Memory保存等の明示された残作業だけをresumeできます。

### SD-CTX-MEM-001 — Memory Context

Yatagarasuのlogical Memory record、保存・削除・reset状態、取得attemptと選択結果、generation、Recall/auto-save Policyを唯一所有します。外部検索engine、index、cache、connectionは所有しません。

### SD-STA-MEM-001 — MemoryState

```text
MemoryRecord {
  logical_record_id,
  storage_generation: MemoryStorageGeneration,
  content_ref: AuthorizedContentRef, provenance,
  pending_mutation: None | MemoryMutationBinding,
  lifecycle: SavePending | Available | DeletePending |
    Deleted | Failed | OutcomeUnknown
}

MemoryMutationBinding {
  mutation_operation_id,
  operation: ExplicitSave | DeleteRecord,
  expected_generation: MemoryStorageGeneration
}

MemoryResetBarrier {
  stable_reset_operation_id,
  retired_generation: MemoryStorageGeneration,
  replacement_generation: MemoryStorageGeneration,
  lifecycle: Committed | Requested | Terminal | Recovery
}

RecallAttempt {
  recall_attempt_id, interaction_id,
  purpose, query_ref, policy_binding,
  lifecycle: Planned | Requested | Resolved | Recovery,
  selection?
}

MemoryState {
  generation: MemoryStorageGeneration,
  availability: Enabled | Disabled | Revoked,
  records: Map<LogicalMemoryRecordId, MemoryRecord>,
  recall_attempts: Map<RecallAttemptId, RecallAttempt>,
  reset_barrier: None | MemoryResetBarrier,
  normal_policy: recent=0, semantic=3,
  purpose_policies
}
```

resetはgeneration barrierを進めます。旧generationのlate save/delete結果でrecordを復活させません。外部storeに既存recordが見えてもimportとは表示せずprovenanceを保持します。

### SD-CTX-AGT-001 — Agent Session Context

外部binding、接続状態、correlation、外部turnごとの耐久Binding、Thread reset barrier、compaction状態を唯一所有します。外部Thread本文、Conversation本文、Provider内部Stateを所有しません。

### SD-STA-AGT-001 — AgentSessionState

```text
AgentSessionState {
  app_server_runtime: CodexAppServerRuntimeState,
  continuity_binding: None | ExternalContinuityBinding {
    external_thread_id: ProtectedExternalThreadId,
    generation: ExternalContinuityGeneration,
    status: Opaque | Compacted | RouteGapPresent |
      RebindRequired | Retired
  },
  turn_bindings: Map<AgentTurnBindingId, AgentTurnBinding>,
  runtime_binding_uses: Map<BindingUseId, AgentRuntimeBindingUseRecord>,
  recovery_observations: Map<RecoveryCustodyId, AgentRecoveryObservationRef>,
  reset_barriers: Map<ResetBarrierId, ThreadResetBarrier>,
  current_reset_barrier_ref: None | ResetBarrierId,
  compaction?
}

CodexAppServerRuntimeState {
  runtime_generation: CodexAppServerRuntimeGeneration,
  lifecycle: Disconnected | Initializing | Ready | Degraded |
    Retiring | Recovery,
  readiness: None | CodexAppServerReadinessObservation,
  protocol_binding,
  supervisor_operation_ref?
}

CodexAppServerReadinessObservation {
  runtime_generation: CodexAppServerRuntimeGeneration,
  probe_generation: CodexAppServerProbeGeneration,
  observed_mark, valid_until_mark,
  codex_version, schema_version, protocol, result
}

AgentRuntimeBindingUseRecord {
  binding_use_id,
  runtime_generation: CodexAppServerRuntimeGeneration,
  agent_turn_binding_id, effect_occurrence_id, attempt_id,
  lifecycle: Acquired | ReleasePending | Released | Recovery | Quarantined
}

AgentTurnBinding {
  binding_id, interaction_id,
  binding_generation: AgentTurnBindingGeneration,
  runtime_generation: CodexAppServerRuntimeGeneration,
  continuity_generation: ExternalContinuityGeneration | Absent,
  execution_attempt_generation: ExecutionAttemptGeneration,
  target: AgentTurnTarget,
  external_operation_id: OpaqueExternalOperationId | Absent,
  correlation: AgentTurnCorrelation,
  lifecycle: Planned | Requested | Started |
    Terminal | Interrupted | Recovery | Quarantined,
  pinned_route, pinned_profile, pinned_protocol,
  selected_memory_binding,
  transfer_authorization: TransferAuthorizationBinding,
  deadline_binding
}

ThreadResetBarrier {
  reset_id, stable_reset_operation_id,
  retired_generation: ExternalContinuityGeneration,
  replacement_generation: ExternalContinuityGeneration,
  lifecycle: Preparing | Committed |
    FreshContinuityPending | Completed | Recovery |
    NotAppliedAwaitingExplicitRestart | Quarantined
}
```

`CodexAppServerRuntimeGeneration`、`ExternalContinuityGeneration`、`AgentTurnBindingGeneration`、`ExecutionAttemptGeneration`は別のnewtypeであり、相互変換constructorを持ちません。app-server restartはruntime generation、Thread resetはcontinuity generation、新しいturnはAgentTurnBinding generation、外部Effectの再attemptはExecution attempt generationだけを進めます。

`current_reset_barrier_ref`は現在進行中、または最新のbarrierへのindexであり、過去recordの置き換えではありません。fresh Owner commandは新しいmap entryを追加し、prior terminal barrierを保持したままcurrent refだけを更新します。late resultはexact reset IDのrecordへ照合し、prior resultをcurrent barrierへ適用しません。

Codex dispatch claimはAGT revision、exact runtime generation、fresh readinessをCASし、`AgentRuntimeBindingUseRecord`とEXE dispatch intentを同一UoWでcommitします。Retiring、Degraded、staleなruntimeへの新規Useを拒否し、turn terminalまたはdurable Recovery handoffと同時にUseを解放します。Codex app-serverのruntime binding/readinessを`SD-CTX-PRV-001`へ重複登録しません。

Thread本文の完全性を表す`Full`状態は置きません。Thread IDはsecret同等に保護し、Projection、通常log、auditへ平文表示しません。
通常の有限ConversationがHomeへ戻っても`continuity_binding`を維持します。
Threadを切るのはOwnerの明示reset、外部Thread消失、またはPolicyが確定したRebindだけです。
したがってHome復帰はSemanticMemory、Conversation正本、Codex Threadのいずれも消去しません。

### SD-CTX-NOT-001 — Notification Policy Context

ThinkingNoticeのenabled、silent、wording、channel、Policy versionを唯一所有します。再生結果、Conversation lifecycle、Agent lifecycleを所有しません。

### SD-STA-NOT-001 — NotificationPolicyState

```text
ThinkingNoticePolicy {
  mode: Enabled | Silent | Disabled,
  wording, channel: VoiceOnly,
  policy_version
}
```

ThinkingNoticeの再生lifecycle/resultは共通`ExecutionState`のnotice occurrenceが所有します。
Notification Policy Contextにdelivery Stateは置かず、Web表示はresult EventからProjectionを再構築します。

### SD-TRN-NOT-001 — ApplyNotificationPolicyConfiguration

ThinkingNoticeのenabled、silent、wording、channelのversion付きPolicy revisionをexpected Notification Policy State revisionへ純粋に適用します。通知delivery、Conversation、Execution occurrenceを変更しません。

## Command

### SD-CMD-INT-002 — SubmitInteraction

API/Webではclient idempotency keyとpayload fingerprintを必須にし、voiceではserver-assigned identityを使います。

### SD-CMD-CNV-001 — StartFiniteConversation

```text
StartFiniteConversation {
  input: ConversationInput,
  resolved_behavior, route_candidate,
  qualia_policy_version
}
```

### SD-CMD-QLI-001 — ReturnToHomeRequested

音声とWebはsource以外が同じCommandを生成します。Home要求受理、Agent取消結果、音声停止、Qualia終了を同一視しません。

### SD-CMD-MEM-001 — MemorizeRequested

明示保存であり、Conversation auto-saveとは別目的、別idempotency keyです。

### SD-CMD-MEM-004 — RecallRequested

```text
RecallRequested {
  input: ConversationInput,
  admitted_interaction: AdmittedInteractionBinding,
  purpose: RecallPurpose,
  recall_policy_version
}
```

`SubmitInteraction`のAccepted DecisionとQualia/Interactionのatomic open後だけ生成できる正式Commandです。
raw音声/APIから直接生成しません。通常会話の事前記憶取得とは別Graphを作り、
取得失敗時にLLMへ処理を渡しません。

### SD-CMD-MEM-002 — DeleteMemoryRecordRequested

logical record IDとexpected generationを持ちます。Thread resetを暗黙生成しません。

### SD-CMD-MEM-003 — ResetSemanticMemoryRequested

Memory generation barrierを要求します。Conversation履歴とThreadを削除しません。

### SD-CMD-AGT-001 — ResetAgentThreadRequested

Ownerだけが開始できます。初回resetだけでなく、`NotAppliedAwaitingExplicitRestart`後の明示restartにも使用し、新しいreset IDとstable operation IDを要求します。prior barrier IDとcurrent barrier refを指定し、SemanticMemoryとConversationを削除せず、旧Threadへ新turnを送らないbarrierを追加します。

### SD-CMD-AGT-002 — CompactAgentThreadRequested

active turn中は初期PolicyでBusyです。成功しても全文保持を主張しません。

## Event

### SD-EVT-CNV-001 — FiniteConversationStarted

Qualia、Interaction、Conversation turn、初期Graphが同じUnit of Workで登録された事実です。

### SD-EVT-QLI-002 — QualiaRecoveryDecided

exact session/restart/handoff/restart epochについて、`ResumeFromCheckpoint | AwaitOwnerDecision | TerminateToHome | QuarantineResource`の一つと、そのcheckpoint、全target recovery owner terminal/handoff evidence、custody/quarantine evidenceを固定したQLI owner Eventです。ResumeFromCheckpointはBehavior ownerが発行した閉じた`BehaviorResumeContribution`とそのdigestを必須にします。別epochの遅延Eventは現在sessionのrecoveryを変更しません。

### SD-EVT-CNV-003 — FiniteConversationResumed

exact turn/session、restart epoch、source/replacement execution subject、checkpoint digest、old/new resume generation、適用した`FiniteConversationResumeContribution`とExecution resume commit refを固定したCNV owner Eventです。Agent応答成功、Effect完了、Qualia Activeを単独で意味しません。

### SD-EVT-CNV-004 — FiniteConversationSafeProgressReached

```text
FiniteConversationSafeProgressReached {
  turn_id, qualia_session_id,
  execution_subject: InteractionExecutionSubject,
  conversation_resume_generation,
  progress_point:
    RecallSelectionFixedBeforeAgentClaim |
    FinalResponseAcceptedBeforePresentationAndMemory |
    PresentationPublishedBeforeRemainingTerminalWork,
  completed_node_digests,
  remaining_resumeable_node_digests,
  pinned_result_refs
}
```

Finite Conversation ownerが、Behavior versionで宣言した安全な進行点へ実際に到達した事実です。Resume直後、clock経過、Graph生成順、Adapter受付から自動生成しません。受理済み最終応答を持つprogress pointは応答digestを`pinned_result_refs`へ固定し、Agent生成／応答受理nodeをcompletedへ含めます。

### SD-EVT-CNV-005 — FiniteConversationResumeClaimRejected

```text
FiniteConversationResumeClaimRejected {
  turn_id, qualia_session_id,
  resume_request_id, resume_commit_id,
  replacement_execution_subject,
  replacement_occurrence_id,
  source_execution_event_ref: SD-EVT-EXE-007.Rejected,
  failure: ResumeClaimRejected { typed_reason },
  presentation_ref, terminal_result_ref
}
```

EXE ownerが確定した恒久的claim拒否を、有限Conversation ownerが会話の意味へ写したEventです。EXE Eventと全correlationが一致しない入力、一時的Busy／CAS競合、`Claimed`結果からは生成できません。新しいcheckpoint、Agent/Tool Effect、置換Occurrenceを作った事実ではありません。

### SD-EVT-MEM-001 — SemanticMemoryRetrievalResolved

```text
SemanticMemoryRetrievalResolved {
  recall_attempt_id, interaction_id,
  execution: ExecutionCorrelation,
  storage_generation: MemoryStorageGeneration,
  result: Retrieved(List<MemoryCandidate>) | Empty |
    Failed(FailureBasis<MemoryFailure>) |
    OutcomeUnknown(FailureBasis<MemoryFailure>)
}
```

### SD-EVT-MEM-002 — MemorySaveResolved

```text
MemorySaveResolved {
  logical_record_id, storage_generation,
  execution: ExecutionCorrelation,
  result: Saved(MemoryProvenance) | Rejected(MemoryFailure) |
    Failed(FailureBasis<MemoryFailure>) |
    OutcomeUnknown(FailureBasis<MemoryFailure>)
}
```

### SD-EVT-MEM-003 — MemoryMutationResolved

```text
MemoryMutationResolved =
  ExplicitSaveResolved {
    mutation_operation_id, logical_record_id, storage_generation, result
  } |
  DeleteResolved {
    mutation_operation_id, logical_record_id, storage_generation, result
  } |
  ResetResolved {
    stable_reset_operation_id,
    retired_generation, replacement_generation, result
  }
```

`result`はSucceeded、DefinitelyNotApplied、Failed、OutcomeUnknownの閉じた値です。
deleteとresetをsave結果で代用しません。

### SD-EVT-AGT-001 — AgentTurnProgressed

Startedまたはbounded summarized progressを返します。raw deltaを無制限journalへ保存しません。

### SD-EVT-AGT-002 — AgentOutputProposed

```text
AgentOutput = FinalResponseProposed(PresentationProposal) |
  ToolOperationProposed(TypedOperationProposal) |
  Failed(FailureBasis<AgentFailure>) |
  Cancelled | CancelUnsupported |
  OutcomeUnknown(FailureBasis<AgentFailure>)

AgentOutputProposed {
  binding_id, correlation: AgentTurnCorrelation, agent_output,
  provider_provenance
}
```

Proposalは最終応答またはCommandではありません。

`TypedOperationProposal`は次の閉じた値です。

```text
TypedOperationProposal = ToolCapabilityProposal {
  proposal_id, capability_id, operation_kind,
  typed_input_ref: AuthorizedContentRef,
  requested_authorization: TransferAuthorizationBinding
}

ProposalPolicyDecision =
  RejectProposal(reason) |
  AcceptFinalResponse(ConversationPresentation) |
  ApproveGraphContribution(
    NonEmptyList<PlannedEffectSpec<ConversationPlannedPayload>>
  )
```

Agent Adapterは提案を実行せず、このEventを返すだけです。許可された提案だけを
Domain Ruleが新しいplanned Effectへ変換し、通常のPolicy、resource claim、dispatchを通します。

### SD-EVT-CNV-002 — ConversationResponseAccepted

Policy検証済みの一つの最終`ConversationPresentation`をConversation正本へ受理した事実です。

### SD-EVT-OUT-001 — PresentationPublishResolved

成功、Failure、OutcomeUnknownを持ちます。Projectionが存在するだけでは外部配達成功を意味しません。

### SD-EVT-AGT-003 — AgentCancellationResolved

```text
AgentCancellationResolved {
  binding_id, binding_generation, execution_attempt_generation,
  exact_target_adapter_operation_id, stable_cancel_operation_id,
  result: Cancelled | Unsupported | RejectedStale | Failed,
  certainty: DefinitelyApplied | DefinitelyNotApplied | OutcomeUnknown
}
```

Provider停止を捏造しません。

### SD-EVT-AGT-004 — AgentThreadResetResolved

FreshContinuityBound、Failed、OutcomeUnknown、RebindRequiredを区別します。旧Threadを新Threadとして再利用しません。

### SD-EVT-AGT-005 — AgentThreadCompactionResolved

Compacted、Busy、Failed、OutcomeUnknown、RebindRequiredを区別します。

### SD-EVT-AGT-006 — AgentDeadlineElapsed

exact Bindingとattemptの応答期限が到来した事実です。wall clockの推測や別turnの期限を流用しません。

### SD-EVT-AGT-007 — CodexAppServerRuntimeObserved

```text
CodexAppServerRuntimeObserved =
  ProbeObserved {
    exact_runtime_generation, exact_probe_generation,
    result: ProcessReachable | ProtocolInitialized | SchemaCompatible |
      WorkspaceBound | Ready | Degraded | Unavailable,
    observed_mark, valid_until_mark, evidence_ref
  } |
  ProbeOperationQueryObserved {
    exact_runtime_generation, exact_probe_generation,
    exact_target_probe_operation_id,
    observed_state: NotStarted | InProgress | Completed | Failed | Unknown,
    certainty: DefinitelyApplied | DefinitelyNotApplied | OutcomeUnknown,
    evidence_ref?
  }
```

AGT owner Eventであり、Adapterのinitialize handshake通知そのものではありません。`ProbeObserved`だけがreadiness候補になり、`ProbeOperationQueryObserved`をReadyへ読み替えません。このEventにAgent turn targetは存在せず、turn照会は`SD-EVT-AGT-009`だけが表します。

### SD-EVT-AGT-008 — AgentRuntimeBindingUseResolved

exact BindingUseについてAcquired、ReleasePending、Released、Recoveryを、Agent turn/Execution terminalまたはRecovery handoff根拠付きで表します。

### SD-EVT-AGT-009 — AgentTurnQueryObserved

```text
AgentTurnQueryObserved {
  binding_id, binding_generation, execution_attempt_generation,
  exact_target_adapter_operation_id, stable_query_operation_id,
  observed_state: NotStarted | Running | Completed | Failed | Unknown,
  certainty: DefinitelyApplied | DefinitelyNotApplied | OutcomeUnknown,
  evidence_ref?
}
```

### SD-EVT-AGT-010 — AgentTurnReconciliationObserved

```text
AgentTurnReconciliationObserved {
  binding_id, binding_generation, execution_attempt_generation,
  exact_target_adapter_operation_id, stable_reconcile_operation_id,
  query_evidence_ref, provider_evidence_refs,
  observed_state: NotStarted | Running | Completed | Failed | Diverged | Unknown,
  certainty: DefinitelyApplied | DefinitelyNotApplied | OutcomeUnknown,
  evidence_ref?
}
```

### SD-EVT-AGT-014 — AgentTurnRecoveryResolved

```text
AgentTurnRecoveryResolved {
  binding_id, binding_generation, execution_attempt_generation,
  exact_target_adapter_operation_id, custody_id,
  result: DefinitelyApplied | DefinitelyNotApplied | StillUnknown,
  binding_terminal: Terminal | Interrupted | Quarantined,
  binding_use_terminal: Released | Quarantined,
  evidence_refs
}
```

`DefinitelyApplied`はexact completed turn evidenceがある場合だけ`Terminal`へ、`DefinitelyNotApplied`は`Interrupted`へ、`StillUnknown`は`Quarantined`へ対応します。Conversation responseの採用は別Ruleであり、このEventから捏造しません。

### SD-EVT-AGT-011 — ThreadResetCancellationResolved

```text
ThreadResetCancellationResolved {
  reset_id, retired_generation, replacement_generation,
  exact_target_reset_operation_id, stable_cancel_operation_id,
  result: Cancelled | Unsupported | RejectedStale | Failed,
  certainty: DefinitelyApplied | DefinitelyNotApplied | OutcomeUnknown
}
```

fresh Thread成立を意味しません。

### SD-EVT-AGT-012 — ThreadResetQueryObserved

```text
ThreadResetQueryObserved {
  reset_id, retired_generation, replacement_generation,
  exact_target_reset_operation_id, stable_query_operation_id,
  observed_state: NotStarted | InProgress | FreshContinuityBound |
    Failed | Unknown,
  certainty: DefinitelyApplied | DefinitelyNotApplied | OutcomeUnknown,
  evidence_ref?
}
```

query自身が新Threadを作りません。

### SD-EVT-AGT-013 — ThreadResetReconciliationObserved

```text
ThreadResetReconciliationObserved {
  reset_id, retired_generation, replacement_generation,
  exact_target_reset_operation_id, stable_reconcile_operation_id,
  query_evidence_ref, continuity_probe_evidence_refs,
  observed_state: NotStarted | FreshContinuityBound | Diverged | Unknown,
  certainty: DefinitelyApplied | DefinitelyNotApplied | OutcomeUnknown,
  evidence_ref?
}
```

reset completionを決定しません。

### SD-EVT-AGT-015 — ThreadResetRecoveryResolved

exact reset/custodyについて`DefinitelyApplied | DefinitelyNotApplied | StillUnknown`と、`Completed | NotAppliedAwaitingExplicitRestart | Quarantined`のbarrier terminalを固定するOwner Eventです。FreshContinuityBound evidenceのないDefinitelyAppliedを拒否し、DefinitelyNotAppliedは`NotAppliedAwaitingExplicitRestart`、StillUnknownはQuarantinedだけを許します。旧Thread復活を意味しません。

### SD-EVT-AGT-016 — ExplicitContinuityRestartAdmitted

Ownerの`SD-CMD-AGT-001`、terminalなprior reset、fresh reset ID/stable operation ID、次replacement generationを固定したEventです。prior barrierや旧Threadを再利用しません。

### SD-EVT-NOT-001 — ThinkingNoticeResolved

```text
ThinkingNoticeResolved {
  notice_occurrence_id, playback_occurrence_id,
  execution: ExecutionCorrelation,
  result: Played | Suppressed | Failed | OutcomeUnknown
}
```

通知intentと実際の再生結果を分け、最終回答の音声と相関を取り違えません。

### SD-EVT-AUD-001 — SpeechPlaybackResolved

final speech occurrenceについてStarted、CompletedAssumed、Cancelled、Failed、OutcomeUnknownを返します。利用者が聞いた事実は生成しません。

### SD-EVT-DAT-002 — AuthorizedContentReadResolved

```text
AuthorizedContentReadResolved {
  execution: ExecutionCorrelation,
  result: Materialized(AuthorizedContentMaterializationRef) |
    Rejected(DataAuthorizationFailure) |
    Failed(ContentReadFailure) | OutcomeUnknown(ContentReadFailure)
}
```

subject revision、digest、全content class、authorization revisionを照合した結果です。
未知分類、複合分類の一部不許可、失効済み許可はRejectedです。
本文を通常Event、journal、Projectionへ埋め込みません。

### SD-EVT-TOL-001 — ToolOperationResolved

```text
ToolOperationResolved {
  proposal_id, capability_id,
  execution: ExecutionCorrelation,
  result: Succeeded(TypedToolResultRef) |
    DefinitelyNotApplied(ToolFailure) |
    Failed(ToolFailure) | Cancelled |
    CancelUnsupported | OutcomeUnknown(ToolFailure)
}
```

Tool結果は新しいAgent turnへ渡せる型付き参照であり、Commandや最終応答ではありません。

### SD-EVT-TOL-002 — ToolCancellationResolved

```text
ToolCancellationResolved {
  proposal_id, capability_id,
  original_occurrence_id, original_attempt_id,
  exact_target_adapter_operation_id, stable_cancel_operation_id,
  result: Cancelled | Unsupported | RejectedStale | Failed,
  certainty: DefinitelyApplied | DefinitelyNotApplied | OutcomeUnknown
}
```

### SD-EVT-TOL-003 — ToolDeadlineElapsed

exact tool occurrence/attemptとConversation absolute deadlineに相関した期限到来Eventです。

### SD-EVT-TOL-004 — ToolOperationQueryObserved

```text
ToolOperationQueryObserved {
  proposal_id, capability_id,
  original_occurrence_id, original_attempt_id,
  exact_target_adapter_operation_id, stable_query_operation_id,
  observed_state: NotStarted | Running | Completed | Failed | Unknown,
  certainty: DefinitelyApplied | DefinitelyNotApplied | OutcomeUnknown,
  evidence_ref?
}
```

### SD-EVT-TOL-005 — ToolOperationReconciliationObserved

```text
ToolOperationReconciliationObserved {
  proposal_id, capability_id,
  original_occurrence_id, original_attempt_id,
  exact_target_adapter_operation_id, stable_reconcile_operation_id,
  query_evidence_ref, tool_evidence_refs,
  observed_state: NotStarted | Completed | Failed | Diverged | Unknown,
  certainty: DefinitelyApplied | DefinitelyNotApplied | OutcomeUnknown,
  evidence_ref?
}
```

### SD-EVT-TOL-006 — ToolOperationRecoveryResolved

exact turn/proposal/original occurrence/attempt/target operation/custodyについて、`DefinitelyApplied | DefinitelyNotApplied | StillUnknown`と`Resolved | Quarantined`を固定するConversation owner Eventです。StillUnknownはQuarantinedだけを許し、Tool successや次Agent readyを意味しません。

### SD-EVT-QLI-001 — QualiaTerminationResolved

TerminationCompleted、TerminationPending、TerminationFailed、TerminationOutcomeUnknownを区別します。

## Rule、Decision、Transition

### SD-RUL-INT-001 — DecideInteractionAdmission

Qualia view、Interaction ledger、Behavior Policy、Capability/Safety resultをpureに評価し、Accepted、Busy、Rejected、IdempotentReplay、Conflictを返します。Policy拒否をFallback Conversationで迂回しません。

### SD-RUL-MEM-001 — PlanConversationRecall

通常Conversationはversion付き`recent=0`、`semantic=3`を固定します。目的別Policyは明示Recallだけ上書きします。Disabled、Revoked、NotApplicableをFailureと区別します。

### SD-RUL-MEM-002 — SelectRecallRecords

recentとsemanticの重複はlogical record IDで一回にし、recentを優先して競合理由を残します。空結果、Failure、保存拒否を別のDecisionにします。

### SD-RUL-MEM-003 — ResolveRecallFailure

通常Conversationは`ContinueNormalConversationWithoutMemory`により記憶0件を固定して続行します。明示Recallは`ReturnExplicitRecallUnavailable`によりLLM Effectを作らず、決定論的`RecallUnavailable` Presentationを返します。

### SD-RUL-AGT-001 — BindAgentTurn

route/profile/protocol、型付き`AgentTurnTarget`、selected Memory、transfer authorization、deadline、完全なExecution correlationをdispatch前に固定します。自動fallback、暗黙new Thread、`--last`相当を禁止します。

### SD-RUL-AGT-002 — ValidateAgentProposal

取消、binding/各型generation、Presentation schema、Policy、権限revision、absolute deadline、
proposal budgetをpureに検証し、閉じた`ProposalPolicyDecision`を返します。
`ApproveGraphContribution`だけがplanned Effectを追加でき、Agentが返したtool表現を直接dispatchしません。
budget枯渇またはdeadline到来後はtyped Failureへ収束させ、新しいAgent/Tool Effectを追加しません。

### SD-RUL-AGT-003 — DecideAgentCancellation

exact current BindingにはInterruptExactBindingまたはCancelInferenceExactAttempt、stale BindingにはRejectedStale、未dispatchにはAcceptedNoEffectを返します。

### SD-RUL-CNV-001 — DecideAutoSave

受理済み最終応答と原発話の組だけをSave対象にします。Disabled、Revoked、reflex、最終応答なしはNoEffectです。

### SD-RUL-NOT-001 — DecideThinkingNotice

Memory selectionとroute固定後、voice会話かつmode=`Enabled`の場合だけ一度Emitします。`Silent`、`Disabled`、Web、SBERT反射、Homeでは型付きsuppression factを一度記録します。

### SD-RUL-CNV-002 — DecideConversationTermination

response generation terminal、最終またはFailure Projection publish、Memory save terminal／NoEffect／durable Recovery handoff、全取消対象のsettled/revoked、lease解放／Recovery移管を評価します。TTS heard completionを要求しません。

### SD-RUL-AGT-004 — DecideThreadReset

旧in-flight Bindingへcancel occurrenceを登録し、完了を待たずdurable Recoveryへ移管できた場合だけreset barrierを許可します。barrier後は旧generationを新turnに使用しません。
cancel完了待ちはresetの前提にしませんが、cancel intentと旧turnのRecovery所有権移管は必須です。

### SD-RUL-CNV-003 — BuildConversationDispatchEffect

`PlannedEffectSpec<ConversationPlannedPayload>`を、release vocabularyに登録済みの
`DispatchEffect<ConversationDispatchPayload>`へpureに変換します。取得、Agent、通知、publish、
音声、Memory mutation、Thread管理を中央の条件分岐へ集積しません。
Tool variantは必ず`SD-RUL-TOL-002`のcurrent grant Decisionを要求します。

### SD-RUL-CNV-004 — BuildTerminalConversationPath

Agent失敗、timeout、取消、invalid proposalを型付き`ConversationFailure`へ写し、
内部Projection commitと必要なRecovery handoffを持つ終端枝を作ります。
最終応答が受理されなかった枝ではauto-saveを生成しません。

### SD-RUL-CNV-005 — BuildFiniteConversationResumeContribution

exact Open/ResponseAccepted turn、session、Available checkpoint、checkpoint digest、checkpoint execution subject、pinned CNV/EXE revision、全対象RecoveryのDefinitelyNotAppliedまたはterminal evidence、resumeable node declarationをpureに検証し、`FiniteConversationResumeContribution`または型付きRejectを返します。Contributionはresume用`SD-RUL-CNV-005`／`SD-TRN-CNV-007`に加え、恒久claim拒否用`SD-RUL-CNV-007`／`SD-TRN-CNV-009`を閉じたrefとして持ち、`SD-RUL-EXE-004`が検証できる`ExecutionResumePlan`を全域的に含みます。未受理応答のcheckpointは宣言された生成nodeを対象にできます。受理済み応答のcheckpointはexact response digestをpinし、生成／受理nodeをcompletedとして除外し、Presentation、Memory保存等のremaining nodeだけを対象にします。checkpoint不在、stale revision、別execution subject、OutcomeUnknown、completed node再実行、未宣言nodeではContributionを構築しません。

### SD-RUL-CNV-006 — BuildNextFiniteConversationSafeCheckpoint

exact `SD-EVT-CNV-004`、Behavior versionのclosed progress-point宣言、current execution lineage generation、CNV/EXE revision、completed／remaining node digest、pinned resultをpureに検証します。未解決OutcomeUnknown／custody、現在subjectと異なるlate progress、二段checkpoint generation、完了済みEffectの再実行、受理済み応答を再生成するcandidateを拒否します。成立時だけ、同じturnの厳密に次の`BehaviorCheckpointGeneration`と決定論的checkpoint digestを返します。

### SD-RUL-CNV-007 — MapFiniteConversationResumeClaimRejection

exact Open/ResponseAccepted turn、current replacement subject、Contributionのrejection mapping、`SD-EVT-EXE-007.Rejected`、未消費のresume request、attempt／BindingUse／lease／intent／outbox不在をpureに照合します。成立時だけ`ConversationFailure.ResumeClaimRejected`、決定論的failure Presentation、turn `Failed`、Interaction terminal、Qualia termination、remaining descendants revokeを一つのclosed Decisionとして返します。同じEXE Eventのreplayは同じ結果、異payloadはConflictです。新checkpoint、再resume、別Provider fallback、拒否理由をLLMへ回答させるDecisionは返しません。

### SD-RUL-AGT-005 — ValidateTransferAuthorization

dispatch直前に、参照のsubject revision/digest、複合content classの全要素、宛先、
authorization revisionと失効状態をpureに検査します。未知分類、部分許可、古い許可は拒否します。

### SD-RUL-AGT-006 — ResolveAgentTerminalRace

同じAgentTurnBindingについて、Agent terminal resultとabsolute deadline resultを
同一のExecution/Agent Session revision上で比較します。

```text
AgentTerminalRaceDecision =
  AgentResultWins { accept_event_id, revoke_deadline_occurrence } |
  DeadlineWins { accept_event_id, interrupt_agent_occurrence } |
  AlreadyDecided { winner_event_id } |
  CorrelationRejected
```

先にCAS commitされた一方だけをwinnerとし、後着結果を元Bindingのlate evidenceへ隔離します。
成功とtimeoutの二つのPresentationを生成しません。

### SD-RUL-AGT-007 — ValidateCodexAppServerReadiness

`SD-EVT-AGT-007 ProbeObserved`のruntime generation、probe generation、freshness、Codex/schema/protocol version、Workspace binding、required app-server capabilityをpureに検証します。`ProbeOperationQueryObserved`、process接続、initialize handshakeだけをReadyにせず、stale、Degraded、schema不一致をdispatch可能にしません。

### SD-RUL-AGT-008 — DecideAgentRuntimeBindingUseRelease

Agent turn terminal、Execution attempt terminal、外部interrupt責任確定、またはdurable Recovery handoffをpureに検証します。OutcomeUnknownをRecovery責任なしでReleasedにしません。

### SD-RUL-AGT-009 — ResolveAgentTurnUncertainty

exact AgentTurnBinding/generations、target adapter operation、一回限りのcancel/query/reconcile evidenceをpureに評価し、DefinitelyApplied、DefinitelyNotApplied、Quarantineを返します。取消成功だけからturn未実行を導かず、Completed evidenceなしに最終応答を捏造しません。確定不能なら次照会を作らずQuarantineへ閉じます。

### SD-RUL-AGT-010 — ResolveThreadResetUncertainty

exact reset barrier、retired/replacement generation、target reset operation、一回限りのcancel/query/reconcileとcontinuity probe evidenceをpureに評価します。FreshContinuityBoundのexact evidenceだけをDefinitelyApplied、NotStartedをDefinitelyNotApplied、矛盾・UnknownをQuarantineへ進めます。DefinitelyNotAppliedは`NotAppliedAwaitingExplicitRestart`へ終端し、暗黙new Threadや次照会を作りません。

### SD-RUL-AGT-011 — AdmitExplicitContinuityRestart

Owner actor、`SD-CMD-AGT-001`、map上のexact prior barrier=`NotAppliedAwaitingExplicitRestart`、そのrecordを指すcurrent ref、fresh reset ID/stable operation ID、strictly next replacement generation、active turn不在をpureに検証します。`AdmitFreshReset`または型付き拒否を返し、旧Thread、prior barrierの上書き、prior operation ID、prior replacement generationの再利用を拒否します。

### SD-RUL-TOL-001 — ResolveToolTerminalRace

exact tool occurrenceのterminal resultとtool deadlineを同じExecution revisionで比較し、
ToolResultWins、DeadlineWins、AlreadyDecided、CorrelationRejectedを返します。
成功winnerだけが`ToolResultAccepted` factを発行できます。Failure、timeout、cancel、
OutcomeUnknownは型付きConversation Failure枝へ進み、次Agent occurrenceを作りません。

### SD-RUL-TOL-002 — ValidateSkillExecutionGrant

```text
ValidateSkillExecutionGrant(
  authorization_policy_view,
  typed_tool_proposal,
  planned_tool_effect,
  current_configuration_revision
) -> AuthorizedToolDispatchBinding | RejectedGrant
```

dispatch claim時のcurrent grantについて、stable Skill identity、version、Active status、
read/write root、network destination、secret参照、外部operation、副作用範囲をpureに全件照合します。
Proposal作成後にrevoked、version変更、scope不一致となった場合は
`DispatchEffect<ExecuteAuthorizedToolOperation>`を生成せず、typed Policy rejectionへ終端します。
Adapterの拒否は多層防御であり、Authorization Policyの判断を代行しません。

### SD-RUL-TOL-003 — ResolveToolOperationUncertainty

exact proposal/occurrence/attempt、target adapter operation、一回限りのcancel/query/reconcile evidence、現在のgrant/transfer revisionをpureに評価します。外部作用の事実はdispatch時にpinしたgrantで評価し、失効後の再dispatchは拒否します。DefinitelyApplied、DefinitelyNotApplied、Quarantineを返し、確定不能時に次照会を作らず、late successを現在turnへ接続しません。

### SD-RUL-QLI-001 — DecideQualiaRecovery

同じQualia sessionのRecovering State、exact active restart epoch、safe checkpoint、全target recovery ownerのterminalまたはdurable handoff evidence、全resource custody resolutionをpureに評価し、閉じた`QualiaRecoveryDecision`だけを返します。ResumeFromCheckpointはcheckpointに加え、exact behavior/session/version/current execution subjectに適合する`BehaviorResumeContribution`、そのpinned owner/EXE revisions、`SD-RUL-EXE-004`に適合するplanを必須とします。ContributionがなければResumeFromCheckpointを構築しません。未終端ownerがあればAwaitOwnerDecisionだけを許します。TerminateToHomeとQuarantineResourceは全責任がterminal ownerまたはdurable quarantineへ移管済みの場合だけ許します。別epochのhandoff evidenceはRejectし、後続epochへ適用しません。

### SD-TRN-QLI-001 — ApplyQualiaLifecycle

Home、Starting、Active、Terminating、Recoveringの許可表だけをQualia Stateへ適用します。同時に二sessionを非Homeへしません。restart handoffによるRecovering化ではexact `RestartHandoffEpoch`を`active_recovery_epoch`へ固定し、既存active epochの上書きと別epochの部分適用を拒否します。

### SD-TRN-QLI-002 — ApplyQualiaRecoveryDecision

exact Recovering session、exact `active_recovery_epoch`、`SD-EVT-QLI-002`だけを適用します。ResumeFromCheckpointは適合Contributionを持つ同じsessionをActiveへ戻し、active epochをclearしつつdecisionを`recovery_history`へ保持します。AwaitOwnerDecisionは同じepochでRecoveringを維持し、TerminateToHomeはTerminatingを経て`current=None`へ、QuarantineResourceは全指定resourceのdurable quarantine成立後だけTerminatingを経て`current=None`へ進めます。別session／別epoch、checkpointなしResume、ContributionなしResume、責任未移管Home、Homeからの復活を拒否します。このTransitionはactive-work handoff UoW内だけでcommitします。履歴を単一optional recordで上書きしないため、同じ有限Qualiaが後続restartで新epochへ再びRecoveringになれます。

### SD-TRN-CNV-007 — ApplyFiniteConversationResumeCheckpoint

`SD-RUL-CNV-005`が構築したexact Contributionと`SD-EVT-CNV-003`だけを適用します。Available checkpointをConsumedにし、turnのresume generationを一段進めます。original utterance、accepted response、proposal budgetを書き換えず、stale checkpoint、二重consume、別session／別execution subject、二段generation advanceを拒否します。`SD-PER-RST-004`外で単独commitしません。

### SD-TRN-CNV-008 — RegisterNextFiniteConversationSafeCheckpoint

`SD-RUL-CNV-006`とexact `SD-EVT-CNV-004`だけを適用し、新checkpointを`Available`として登録します。同じturnの古いAvailable checkpointは`Invalidated`へ進め、Consumed checkpointは履歴として保持します。一つのturn／current execution subjectにAvailableを二件作ること、late旧subject progressからcheckpointを作ること、resume適用そのものをsafe progressとみなすことを拒否します。Effect、Occurrence、attempt、dispatch intentを作りません。

### SD-TRN-CNV-009 — ApplyFiniteConversationResumeClaimRejection

`SD-RUL-CNV-007`とexact `SD-EVT-CNV-005`だけを適用し、Open/ResponseAccepted turnを`Failed`へ、全Available checkpointを`Invalidated`へ進め、failure Presentation refとsource EXE rejection refを固定します。同じsource Event/payloadはno-op、異payloadとterminal後の別結果はConflictです。新checkpoint、Effect、Occurrence、Memory auto-saveを作りません。QLI、INT、EXEを直接変更せず、`SD-PER-CNV-003`外のcommitを拒否します。

### SD-TRN-INT-001 — ApplyInteractionAdmission

Interaction Stateとrequest ledgerだけを変更します。admission結果とlifecycleを別fieldとして進め、
replay時も`Accepted`と`Terminal`を混同しません。

### SD-TRN-INT-002 — ApplyInteractionTerminalResult

Interaction ownerの型付きterminal Decisionだけを`Admitted/Running/Recovering/Cancelling → Terminal`へ一度適用し、`terminal_result`とrequest ledgerのreplayable terminal resultを同じidentityへ固定します。Qualia、Conversation、Executionを変更しません。同値replayはno-op、異なる二つのterminal resultはConflictです。

### SD-TRN-CNV-001 — OpenConversationTurn

Conversation Stateへ原発話、version付き有限proposal budget、absolute monotonic deadlineを持つOpen turnを登録します。同時に初期Graphのpinned revision、resumeable node digest、turn/session、initial execution subject、checkpoint generation 0を固定した決定論的`ConversationResumeCheckpointRecord(Available)`を登録します。turnだけ、checkpointだけをcommitしません。

### SD-TRN-CNV-002 — AcceptConversationResponse

検証済み最終応答だけを一度固定します。raw Agent Proposalやlate resultを適用しません。

### SD-TRN-CNV-004 — ConsumeProposalBudget

承認済みGraph contributionと追加Occurrence登録を同じUnit of Workでcommitし、budgetを一つ減らします。
拒否Proposal、duplicate、late resultでは減らしません。

### SD-TRN-MEM-001 — ApplyRecallResult

Memory Contextのattempt/selectionだけを変更します。Conversation、Agent Bindingを変更しません。

### SD-TRN-MEM-002 — ApplyMemorySaveResult

logical record/generation一致の結果だけを適用します。旧generationのlate resultはRecovery/auditへ隔離します。

### SD-TRN-MEM-003 — BeginMemoryDelete

expected `MemoryStorageGeneration`が一致するlogical recordだけをDeletePendingへ進め、
stable mutation operation IDを固定します。

### SD-TRN-MEM-004 — ApplyMemoryDeleteResult

record、generation、operation IDが一致する結果だけをDeleted／Failed／OutcomeUnknownへ進めます。

### SD-TRN-MEM-005 — CommitMemoryResetBarrier

外部reset送信前にreplacement generationをdurable commitし、旧generationをretireします。
`MemoryState.reset_barrier`へstable operation IDと両generationを固定します。
Conversation、SemanticMemory以外のlog、Agent Threadを変更しません。

### SD-TRN-MEM-006 — ApplyMemoryResetResult

stable reset operation IDとreplacement generationが一致する結果だけを適用します。
旧generationのlate save/delete結果は隔離し、recordを復活させません。

### SD-TRN-MEM-007 — BeginExplicitMemorySave

logical record、expected generation、stable mutation operation IDを持つSavePending recordを登録します。
Conversation auto-saveのoperation IDを再利用しません。

### SD-TRN-MEM-008 — ApplyExplicitMemorySaveResult

recordの`pending_mutation`、storage generation、operation IDが一致する
`ExplicitSaveResolved`だけをAvailable／Failed／OutcomeUnknownへ進めます。

### SD-TRN-MEM-009 — ApplyMemoryPolicyConfiguration

normal retrievalの`recent/semantic`、purpose別Recall、auto-saveのversion付きPolicy revisionをexpected Memory State revisionへ純粋に適用します。logical Memory record、外部store generation、Agent Threadを変更せず、既存InteractionがpinしたPolicy refへ遡及しません。

### SD-TRN-AGT-001 — ApplyAgentBinding

Agent Session StateのBinding lifecycleだけを変更します。外部本文とConversationを変更しません。

### SD-TRN-AGT-002 — ApplyThreadResetBarrier

旧generation退役とfuture turn禁止を適用します。SemanticMemoryとConversationを変更しません。

### SD-TRN-AGT-003 — ApplyFreshContinuityBinding

commit済みbarrier、stable reset operation ID、replacement generationが一致する
`FreshContinuityBound`だけを新しいexact Thread bindingとして一度適用します。
crash後のduplicate resultから二つ目のThreadを作りません。

### SD-TRN-AGT-004 — ApplyThreadCompactionResult

active turnなし、exact continuity generation一致の場合だけCompacted／RouteGapPresent／
RebindRequiredを適用します。compactionを全文保持の証明にしません。

### SD-TRN-AGT-005 — ApplyAgentRouteGap

継続できないroute変更を`RouteGapPresent`として明示し、暗黙new Threadや別Provider fallbackを起こしません。

### SD-TRN-AGT-006 — ApplyAgentTerminalWinner

`SD-RUL-AGT-006`のwinnerをAgentTurnBindingへ適用します。
Agent勝利ならBindingをTerminalへ、deadline勝利ならInterrupted/Recoveryへ進めて
exact cancel occurrenceを登録します。同じUnit of Workで`SD-TRN-EXE-008`を適用し、
Execution側のloser occurrenceをrevoke／Recoveryへ進めます。一方のTransitionが他方のStateを変更しません。

### SD-TRN-AGT-007 — ApplyCodexAppServerRuntimeObservation

exact runtime generationとvariant correlationが一致する`SD-EVT-AGT-007`だけを適用します。`ProbeObserved`はexact probe generationのreadiness ledgerへ、`ProbeOperationQueryObserved`はexact target probe operationのRecovery evidenceへ進めます。別generationのlate probe/query、Adapter handshake、Supervisor PIDを直接Stateへ適用せず、query結果をReadyへ変換しません。

### SD-TRN-AGT-008 — ApplyAgentRuntimeBindingUse

exact runtime generation、AgentTurnBinding、Effect occurrence/attemptに相関するBindingUseをAcquired、ReleasePending、Released、Recoveryへ進めます。retiring generationへの新規Acquiredを拒否します。

### SD-TRN-AGT-009 — ApplyAgentTurnRecoveryObservation

exact Binding/generations/target operationに一致する`SD-EVT-AGT-003`、`009`、`010`だけを`recovery_observations`へ適用します。同値duplicateはno-op、異payload、別turn、旧generation、custody terminal後のlate resultは隔離します。Conversation responseを変更しません。

### SD-TRN-AGT-010 — ApplyThreadResetRecoveryObservation

exact reset barrier/retired/replacement generation/target reset operationに一致する`SD-EVT-AGT-011`〜`013`だけを適用します。reconciliation前にbarrierをCompletedへ進めず、旧Threadへ戻しません。

### SD-TRN-AGT-011 — ApplyAgentTurnRecoveryResolution

exact Binding、attempt、custodyに一致する`SD-EVT-AGT-014`だけを適用します。DefinitelyAppliedを`Terminal`、DefinitelyNotAppliedを`Interrupted`、StillUnknownを`Quarantined`へ進め、同じ結果に従い`AgentRuntimeBindingUseRecord`を`Released`または`Quarantined`へ進めます。Recoveryのまま残す、Quarantinedから復帰する、Conversation responseを変更する入力を拒否します。このTransitionは`SD-PER-EXE-005`のcross-owner UoW内だけでcommitします。

### SD-TRN-AGT-012 — ApplyThreadResetRecoveryResolution

exact reset barrier/custodyに一致する`SD-EVT-AGT-015`だけを適用し、fresh continuityの確定証拠があればCompleted、DefinitelyNotAppliedなら`NotAppliedAwaitingExplicitRestart`、StillUnknownならQuarantinedへ進めます。Recoveryへ戻すedge、旧Thread復活、別replacement generationへの適用を拒否し、`SD-PER-EXE-005`内だけでcustody/leaseと同時commitします。

### SD-TRN-AGT-013 — BeginExplicitContinuityRestart

`SD-RUL-AGT-011`が許可した`SD-EVT-AGT-016`だけを適用し、prior barrier map entryをterminalのまま保持してfresh barrierを別entryのPreparingとして登録し、current refをfresh IDへ進めます。新しいreplacement generationを予約し、旧Threadをcontinuity bindingへ戻しません。Graph/Occurrence登録は同じUoWで行い、barrierだけを先にcommitしません。

### SD-TRN-CNV-003 — CompleteConversationTurn

Conversation turnをCompleted/Failed/Cancelledへ進めます。QualiaをHomeへ変更しません。

### SD-TRN-CNV-005 — ApplyToolRecoveryObservation

exact turn/proposal/original occurrence/attempt/target adapter operationに一致する`SD-EVT-TOL-002`、`004`、`005`の参照だけを`ToolRecoveryRecord.observation_refs`へ適用します。同値duplicateはno-op、異payload、別turn、custody terminal後のlate resultは隔離し、後続Agent occurrenceをreadyにしません。

### SD-TRN-CNV-006 — ApplyToolRecoveryResolution

exact ToolRecovery/custodyに一致する`SD-EVT-TOL-006`だけを適用し、DefinitelyApplied/DefinitelyNotAppliedをResolved、StillUnknownをQuarantinedへ進めます。Recoveringへ戻すedgeとlate successによる次Agent ready化を拒否し、`SD-PER-EXE-005`内だけでcustody/leaseと同時commitします。


## Effect

### SD-EFX-AGT-007 — ProbeCodexAppServerRuntime

exact Codex app-server runtime generation、probe generation、required protocol/schema/Workspace capability、freshness policyを持つ不変Effectです。turnを開始せず、外部Threadを作りません。

### SD-EFX-AGT-008 — QueryCodexAppServerRuntimeOperation

exact runtime generation、probe generation、target probe operation IDだけを照会します。Agent turn targetは受け付けず、新turn、新Thread、process再起動を行いません。Agent turnのexact queryは`SD-EFX-AGT-009`だけが担います。

### SD-EFX-MEM-001 — RetrieveSemanticMemory

query ref、recent/semantic件数、Policy binding、`MemoryStorageGeneration`、
transfer authorization binding、Execution correlationを持ちます。

### SD-EFX-MEM-002 — SaveConversationMemory

原発話、受理済み最終応答、logical record ID、generation、authorization、correlationを持ちます。raw Proposalを持ちません。

### SD-EFX-MEM-003 — MutateSemanticMemory

```text
MemoryMutationOperation =
  ExplicitSave { logical_record_id, content_ref, expected_generation } |
  DeleteRecord { logical_record_id, expected_generation } |
  ResetGeneration {
    stable_reset_operation_id,
    retired_generation, replacement_generation
  }
```

上記の閉じたoperation、authorization、Execution correlationを持ちます。

### SD-EFX-AGT-001 — RequestAgentTurn

`PersistentThread` target用です。exact Threadとcontinuity generation、現在入力、
選択済みMemoryのmaterialization ref/provenance、pin済みroute/profile/protocol、transfer authorization、
winner確定済み`List<ToolResultInputBinding>`、deadline、Execution correlationを持ちます。
具体Thread operation名を持ちません。

### SD-EFX-AGT-002 — RequestInference

`NoExternalContinuity` target用です。Thread IDを持たず、現在入力と選択済みMemoryのmaterialization ref/provenance、
pin済みroute/profile/protocol、transfer authorization、winner確定済み
`List<ToolResultInputBinding>`、deadline、Execution correlationを持ちます。

### SD-EFX-AGT-003 — CancelAgentWork

```text
CancelAgentWork {
  target: InterruptExactBinding | CancelInferenceExactAttempt,
  binding_id, binding_generation, execution_attempt_generation,
  exact_target_adapter_operation_id,
  stable_cancel_operation_id, cancellation_policy_ref,
  correlation
}
```

取消対象と取消操作自身を分けます。

### SD-EFX-AGT-009 — QueryAgentTurnOperation

```text
QueryAgentTurnOperation {
  binding_id, binding_generation, execution_attempt_generation,
  exact_target_adapter_operation_id,
  stable_query_operation_id, correlation
}
```

new turn、new Thread、再送を行わず、元turnの外部状態だけを照会します。

### SD-EFX-AGT-010 — ReconcileAgentTurnOperation

```text
ReconcileAgentTurnOperation {
  binding_id, binding_generation, execution_attempt_generation,
  exact_target_adapter_operation_id,
  query_evidence_ref, provider_evidence_refs,
  stable_reconcile_operation_id, correlation
}
```

外部状態の検証だけを依頼し、最終応答採用やConversation終端を決めません。

### SD-EFX-AGT-004 — BeginFreshExternalContinuity

commit済みreset barrier、retired/replacement generation、stable reset operation ID、correlationを持ちます。旧Thread IDを継続対象にしません。

### SD-EFX-AGT-011 — CancelThreadResetOperation

exact reset barrier、retired/replacement generation、exact target reset operation ID、stable cancel operation ID、cancellation Policy、correlationを持ちます。取消成功を旧Thread復帰またはfresh Thread成立と解釈しません。

### SD-EFX-AGT-012 — QueryThreadResetOperation

exact reset barrier、retired/replacement generation、exact target reset operation ID、stable query operation ID、correlationを持ちます。new Threadを開始しません。

### SD-EFX-AGT-013 — ReconcileThreadResetOperation

exact reset barrier、retired/replacement generation、exact target reset operation ID、query evidence、continuity probe evidence、stable reconcile operation ID、correlationを持ちます。Completed Decisionを返しません。

### SD-EFX-AGT-005 — CompactExternalContinuity

active turnがないexact binding generationだけを対象にします。

### SD-EFX-AGT-006 — AwaitAgentDeadline

exact Agent binding、attempt、Conversation開始時に固定したabsolute monotonic deadline bindingを持ちます。期限到来後は
Agent failure pathをreadyにし、late成功を現Interactionの回答へ昇格しません。

### SD-EFX-NOT-001 — EmitThinkingNotice

canonical wording、VoiceOnly、Policy version、notice occurrence ID、専用playback occurrence ID、
Interaction/Execution correlationを持ちます。通知成功はAgent requestのguardではありません。

### SD-EFX-OUT-001 — PublishConversationPresentation

検証済みPresentation、expected projection revision、Execution correlationを持ちます。
これはYatagarasu内部のdurable read model commitであり、browserへのpush到達を意味しません。

### SD-EFX-AUD-001 — PlayNonStreamingSpeech

一つの完全な発話Artifact、canonical回答全文binding、duration/profile、correlationを持ちます。chunk、queue、backpressureを持ちません。

### SD-EFX-DAT-001 — ReadAuthorizedContent

`AuthorizedContentRef`と利用目的を受け、全content classに対する現行authorizationを
再検証してから、期限付きの不変materialization refを作ります。AdapterやSkillが参照を
直接pathへ展開することを禁止します。Agent Effectはこのrefだけを受け、Agent Adapterも
`AuthorizedContentPort`を介してだけ期限内の本文を解決します。

### SD-EFX-TOL-001 — ExecuteAuthorizedToolOperation

proposal ID、capability ID、閉じたoperation kind、typed input materialization ref、
dispatch claim時に`SD-RUL-TOL-002`が固定したcurrent Skill grant revision、transfer authorization、absolute deadline、
Execution correlationを固定します。Skill自身はgrantを拡大できません。

### SD-EFX-TOL-002 — CancelAuthorizedToolOperation

exact proposal/capability、tool occurrence/attempt、target adapter operation ID、stable cancel operation ID、cancel authorization、correlationを持ちます。停止不能を停止成功として返しません。

### SD-EFX-TOL-004 — QueryAuthorizedToolOperation

exact proposal/capability、original occurrence/attempt、target adapter operation ID、stable query operation ID、correlationを持ちます。toolを再実行しません。

### SD-EFX-TOL-005 — ReconcileAuthorizedToolOperation

exact proposal/capability、original occurrence/attempt、target adapter operation ID、query evidence、tool evidence、stable reconcile operation ID、correlationを持ちます。結果採用や次Agent turnを決めません。

### SD-EFX-TOL-003 — AwaitToolDeadline

exact tool occurrence/attemptとConversation absolute monotonic deadlineを持ちます。
deadline winner後のlate成功は次Agent turnをreadyにしません。

## Effect Graph

### SD-GPH-CNV-001 — FiniteConversationGraph

```text
FiniteConversationEffectGraph {
  M  RetrieveNormalMemory?       occurrence=recall_occ
  C  ReadAuthorizedMemory?       occurrence=content_read_occ
  N  EmitThinkingNotice?         occurrence=notice_occ
  A0 RequestAgent[0]             occurrence=agent_occ_0
  D0 AwaitAgentDeadline[0]       occurrence=deadline_occ_0
  Ik ReadAuthorizedToolInput[k]? occurrence=tool_input_occ_k
  Uk ApprovedToolOperation[k]?   occurrence=tool_occ_k
  TDk AwaitToolDeadline[k]?      occurrence=tool_deadline_occ_k
  TRk ReadAuthorizedToolResult[k]? occurrence=tool_result_read_occ_k
  Ak RequestAgent[k]             occurrence=agent_occ_k
  Dk AwaitAgentDeadline[k]       occurrence=deadline_occ_k
  P  CommitPresentation          occurrence=publish_occ
  S  SaveConversationMemory?     occurrence=save_occ
  V  PlayFinalSpeech?            occurrence=speech_occ

  edges:
    M -> C  [selected_non_empty]
    C -> A0 [AuthorizedMemoryMaterialized]
    Ik -> Uk [AuthorizedToolInputMaterialized]
    Uk -> TRk [ToolResultAcceptedWithContentRef]
    TRk -> Ak+1 [AuthorizedToolResultMaterialized]
    Uk -> Ak+1 [ToolResultAcceptedWithoutContentRef]

  guards:
    A0 requires MemoryInputReady
      AND ThinkingIntentCommittedOrSuppressed
      AND RouteFixed
    Dk requires AgentDispatchAccepted(Ak)
    Ik requires ApprovedGraphContribution(k)
    Uk requires AuthorizedToolInputMaterialized
      AND BeforeAbsoluteDeadline
    TDk requires ToolDispatchAccepted(Uk)
    TRk requires ToolResultAcceptedWithContentRef(Uk)
    Ak+1 requires ToolResultInputReady(Uk)
      AND ProposalBudgetRemaining
      AND BeforeAbsoluteDeadline
    P requires FinalPresentationCanonicalized
    S requires AcceptedFinalResponse AND AutoSaveApproved
    V requires AcceptedFinalResponse AND VoiceOutputApproved

  resources:
    N claims Exclusive(audio.output)
    V claims Exclusive(audio.output)
    Ak claims Exclusive(agent.binding)
    Uk claims declared capability resource claims
    thread reset/compaction claims Exclusive(agent.continuity_generation)
}
```

- Effect Graphへ登録するnodeはplanned Effect occurrenceだけです。`MemoryInputReady`、`ThinkingIntentCommittedOrSuppressed`、`RouteFixed`、`AgentDispatchAccepted`、`ApprovedGraphContribution`、`AuthorizedToolInputMaterialized`、`ToolResultAccepted`、`FinalPresentationCanonicalized`等のfuture factはGraph登録時に不変`GuardFactDeclaration`と、lifecycleの唯一正本である`GuardFactRecord.status=Pending`として登録し、Occurrence由来ならproducer occurrenceとowner Event kind、State/Policy由来なら`OwnerStateDerived` sourceを固定します。未宣言factとsource不明を拒否します。Domain Decision/Transition自体をOccurrenceに偽装しません。
- dynamic Graph contributionで追加するfact declarationも追加Occurrenceと同じUoWへcommitし、producerがconsumer自身またはdescendantになるcausal cycleを拒否します。
- MemoryがDisabled/Revoked/Empty/通常取得Failureなら、Content read Effectを作らず、選択0件を固定した
  `MemoryInputReady` factを発行します。Selectedなら`C`成功後だけ同factを発行します。
- `N`の再生成功は`A0`のguardではありません。通知intentのcommitまたは型付きsuppressionがguardです。
- Agent `Ak`とdeadline `Dk`は`SD-RUL-AGT-006`／`SD-TRN-AGT-006`で一方だけをwinnerにします。
- Tool `Uk`とdeadline `TDk`は`SD-RUL-TOL-001`／`SD-TRN-EXE-008`で一方だけをwinnerにします。
  Conversation cancel時はexact `CancelAuthorizedToolOperation`を作り、停止不能・不明はRecoveryへ渡します。
- Tool successがcontent refを含む場合は`TRk`で内容分類と転送許可を再検証し、
  `ToolResultInputBinding`を固定してからだけ`Ak+1`をreadyにします。本文なしの型付き結果は
  provenance/authorizationを固定した`ToolResultInputReady` factを直接発行します。
- `A0`のtool result listは空、`Ak+1`は直前のwinner tool result bindingを一件以上持ちます。
  persistent Threadであっても、外部Threadがtool結果を暗黙に知っているとは仮定しません。
- tool proposalを承認した場合、同じ`Ak`へ戻りません。新しい`Uk -> Ak+1`を前方追加し、
  occurrenceはすべて新規です。追加時にcycle検査し、固定proposal budgetを越えた追加を拒否するため、Graphは有限DAGです。
- AgentまたはToolの失敗、timeout、取消、invalid proposal、budget枯渇の全枝が型付きPresentationへ収束し、`P`をreadyにします。
- `P`は内部のdurable Projection commitです。browser push失敗でHomeを永久に止めませんが、内部commit失敗はRecovery移管なしにHomeへ進めません。
- final response未受理の枝は`S`を作りません。TTSはheard completionを要求しません。
- Cancel/Homeは未dispatch descendantsをrevokeし、dispatch済みAgent/audioをexact bindingで取消し、未確定結果をRecoveryへ移管してからInteraction terminalへ進みます。
- 別Interactionは別Graph/Occurrence/attemptを持ち、同じ外部Threadを使っても旧取消、未解決結果、Graphを再利用しません。

### SD-GPH-AGT-001 — AgentTurnRecoveryGraph

```text
C CancelAgentWork [cancel requested]
Q QueryAgentTurnOperation [OutcomeUnknown or cancel uncertainty]
R ReconcileAgentTurnOperation [query evidence後]

dependencies: R<-Q terminal observation
guards: all nodes require exact custody/original Binding/attempt;
  R requires AgentTurnQueryObserved owner fact
resources: C/Q/R use the same agent.binding Recovery custody privileged claims
```

`SD-PER-EXE-004`がoriginal Agent occurrence/attemptとresource leaseをcustodyへ移すのと同時にGraphを登録します。C/Q/Rは各最大一Occurrence・一attemptで、同じcustodyのprivileged claimでだけdispatchし、別turn、別generation、通常Agent requestはresourceを使えません。R後も確定不能なら`SD-EVT-AGT-014`をStillUnknown/Quarantinedとして導きます。`SD-PER-EXE-005`が`SD-TRN-AGT-009`、`SD-TRN-AGT-011`、BindingUse、custody出口を原子commitします。

### SD-GPH-AGT-002 — ThreadResetRecoveryGraph

```text
C CancelThreadResetOperation [cancel requested]
Q QueryThreadResetOperation [OutcomeUnknown]
R ReconcileThreadResetOperation [query + continuity probe evidence後]

dependencies: R<-Q terminal observation
guards: exact reset barrier, retired/replacement generation,
  target reset operation and Recovery custody
resources: C/Q/R use the same agent.continuity_generation custody privileged claims
```

reset送信不明または取消不明を`SD-PER-EXE-004`でcustodyへ移し、旧Threadにもreplacement Threadにも通常workをdispatchしません。C/Q/Rは各最大一Occurrence・一attemptです。DefinitelyNotAppliedは`NotAppliedAwaitingExplicitRestart`へ終端して旧Threadを復活させず、次のOwner `SD-CMD-AGT-001`だけを`SD-RUL-AGT-011`でadmitします。R後も確定不能なら`SD-EVT-AGT-015`と`SD-TRN-AGT-012`によりbarrier、custody、資源をQuarantinedへ原子終端します。

### SD-GPH-TOL-001 — ToolOperationRecoveryGraph

```text
C CancelAuthorizedToolOperation [cancel requested]
Q QueryAuthorizedToolOperation [OutcomeUnknown or cancel uncertainty]
R ReconcileAuthorizedToolOperation [query evidence後]

dependencies: R<-Q terminal observation
guards: exact proposal/original occurrence/attempt/target operation/custody
resources: C/Q/R use the same tool capability custody privileged claims
```

`SD-PER-EXE-004`が元Tool leaseをcustodyへ移し、C/Q/R Graphを同じUoWで各最大一Occurrence・一attemptとして登録します。Recovery Effectは新しいSkill実行ではなく、元dispatch時にpinしたgrant/authorizationとcustody権限だけを使います。R後も確定不能なら`SD-EVT-TOL-006`と`SD-TRN-CNV-006`によりToolRecovery、custody、資源をQuarantinedへ原子終端し、late successを現在turnや次Agent occurrenceへ接続しません。

### SD-GPH-MEM-001 — ExplicitRecallGraph

```text
ExplicitRecallEffectGraph {
  R RetrievePurposeMemory
  C ReadAuthorizedMemory?
  A RequestRecallAnswer?
  D AwaitRecallAnswerDeadline?
  P CommitRecallPresentation

  edges:
    R -> C [selected_non_empty]
    C -> A [AuthorizedMemoryMaterialized]

  guards:
    A requires ExplicitRecallSelectionReady
    D requires AgentDispatchAccepted(A)
    P requires RecallUnavailableBuilt
      OR RecallEmptyBuilt
      OR RecallResultBuilt
      OR RecallFailureBuilt
}
```

- `ExplicitRecallSelectionReady`、`AgentDispatchAccepted`、各Presentation built factもGraph登録時に不変`GuardFactDeclaration`と`GuardFactRecord.status=Pending`として登録し、Occurrence producerまたはOwnerStateDerived sourceとowner Event kindを固定します。
- `R` failure時はYatagarasuが決定論的`RecallUnavailable`を作り、`C/A/D`を一件も登録しません。
- EmptyもLLMへ渡しません。selected non-emptyだけが、目的、選択record、provenanceを固定してAgentへ進めます。
- selected branchでは`C`が本文とauthorizationを検証してから`A`をreadyにします。
- `A` successと`D` timeoutは通常Conversationと同じwinner Ruleを使います。Agent Failure、timeout、
  cancel、invalid proposalは`RecallFailure` Presentationへ収束し、Recovery handoff、Interaction terminal、Homeへ進みます。
- 初期Explicit Recallでtool proposalはPolicy拒否し、追加tool/Agent occurrenceを生成しません。
- Agentは選択されていない記憶を根拠にできず、`RecallResult`は一件以上のprovenanceを必須とします。
- Explicit RecallはConversation auto-saveを生成しません。

## Port

Pilot Bの全Adapter結果は共通実行契約の
`PortResultEnvelope<ConversationResultPayload>`でEvent ingressへ戻します。
例外をapplicationへ直接投げず、releaseで閉じた結果payloadへ正規化します。

### SD-PRT-MEM-001 — SemanticMemoryPort

Retrieve、Save、ExplicitSave、Delete、Resetを外部表現へ翻訳し、完全なcorrelation付き結果Eventだけを返します。Memory State、Conversation Stateを変更しません。

### SD-PRT-AGT-001 — AgentSessionPort

persistent external Thread能力を実装します。Port methodはruntime probe、runtime probe query、turn start、turn interrupt、turn query、turn reconcile、Thread reset cancel/query/reconcile、compactionを別々の型で受け、結果も`SD-EVT-AGT-007 ProbeOperationQueryObserved`と`SD-EVT-AGT-009 AgentTurnQueryObserved`へ分離します。Adapterだけが具体的なThread start/resumeへ翻訳します。long-lived process、initialize handshake、delta縮約はAdapter operational stateです。handshake成功はtransportが会話できた観測でしかなく、`SD-RUL-AGT-007`と`SD-TRN-AGT-007`を通ったDomain readinessではありません。外部tool call要求を実行せず、必ず`TypedOperationProposal`としてKernelへ戻します。

### SD-PRT-AGT-002 — ProviderInferencePort

外部継続文脈を持たない推論能力です。Thread IDを受けず、turn start/cancel/query/reconcileに対するStarted、bounded progress、Proposal、Failure、Cancelled、Unsupported、OutcomeUnknownとtyped recovery observationを返します。

### SD-PRT-NOT-001 — ThinkingNotificationPort

exact notice/playback occurrenceを再生表現へ翻訳し、`ThinkingNoticeResolved`だけを返します。
Agent requestを開始せず、final speech playbackを所有しません。

### SD-PRT-OUT-001 — PresentationPublicationPort

検証済みPresentationをWeb read modelへpublishし、成功、Failure、OutcomeUnknownを返します。Projectionを配達成功の代用にしません。

### SD-PRT-AUD-001 — NonStreamingSpeechPort

単一発話を再生し、Started、Cancel result、Failure、OutcomeUnknownを返します。heard completionをObservedとして捏造しません。

### SD-PRT-DAT-001 — AuthorizedContentPort

opaque content refを実本文へ解決する唯一のPortです。全content class、authorization revision、
宛先と用途を照合し、未知・一部不許可・失効を拒否します。filesystem pathをDomainへ返しません。

### SD-PRT-TOL-001 — AuthorizedToolPort

SkillCreator、Search、Fetch、その他の許可済みSkill operationを実行する境界です。
`ExecuteAuthorizedToolOperation`とexact元操作に対するcancel/query/reconcileだけを受け、grant外filesystem/network/外部副作用を拒否します。
結果、cancel、query、reconcile、timeoutを対応するtyped Eventとして返し、
WorldState、Conversation、Agent bindingを変更しません。

## FailureとRecovery

### SD-FAIL-CNV-001 — FiniteConversationFailure

Busy、PolicyRejected、CapabilityUnavailable、RecallUnavailable、AgentUnavailable、AgentRejected、InvalidProposal、ResumeClaimRejected、PublicationFailed、MemorySaveFailed、Cancelled、PersistenceFailure、RebindRequired、OutcomeUnknownを閉じた分類とします。

### SD-REC-CNV-001 — FiniteConversationRecovery

restart時のStarting/Active/Terminatingは同じsessionのRecoveringへ進め、初期有限Conversationを自動再開しません。pending/revoked Effectを再構成せずdurable recordから照合し、責任移管後にTerminating→Homeへ進みます。

### SD-REC-AGT-001 — AgentTurnRecovery

request intent後・external operation ID前のcrashで新request、新Thread、自動fallbackを作りません。
`SD-PER-EXE-004`で元leaseをcustodyへ移し、`SD-GPH-AGT-001`のC/Q/Rだけをprivileged dispatchします。stable Adapter operation IDを照会し、`SD-PER-EXE-005`で確定またはquarantineするまで通常Agent workへ資源を戻しません。late/duplicate resultは元Binding/custodyだけを更新します。turn B開始後のturn A result/cancelはBへ影響しません。

### SD-REC-MEM-001 — MemoryRecovery

save/delete/resetの送信有無不明をblind retryせずlogical ID/generationで照合します。reset barrier前のrecordと旧generation late resultを復活させません。

### SD-REC-AGT-002 — ThreadResetRecovery

旧turnへcancel要求を登録し、durable Recovery handoff後にreset barrierをcommitします。
fresh Thread開始は`stable_reset_operation_id`で一度だけです。確定前のcrashでは同じ操作IDを照会し、
`SD-PER-EXE-004`と`SD-GPH-AGT-002`へ移管して旧Threadへ戻らず、二つ目の暗黙new Threadも追加しません。`SD-PER-EXE-005`で採用された`FreshContinuityBound`だけが
replacement generationをCompletedへ進めます。SemanticMemoryとConversation正本は変更しません。

### SD-REC-AGT-003 — CodexRuntimeBindingRecovery

probe intent後のcrashは`SD-EFX-AGT-008`、turn intent後のcrashは`SD-EFX-AGT-009`で、それぞれ別のstable Adapter operation IDとEventを照会します。新turnや新Threadをblind retryせず、BindingUseはterminalまたはdurable handoffまでRecoveryとして保持し、旧generationのlate resultを新Bindingへ適用しません。

### SD-REC-OUT-001 — PresentationCommitRecovery

内部Projection commitは同じexpected revisionとoperation IDで照合します。browser接続やpush配達は
Projection cursorから再同期できるため、外部配達の失敗をConversation未完了とはしません。

### SD-REC-NOT-001 — ThinkingNoticeRecovery

通知再生が不明でもAgent処理を巻き戻しません。exact playback occurrenceをFailure／OutcomeUnknownへ
終端化またはRecovery移管し、final speechの音声guardへ流用しません。

### SD-REC-TOL-001 — ToolOperationRecovery

dispatch intent後のcrash、cancel unsupported、OutcomeUnknownをblind retryしません。
`SD-PER-EXE-004`で元leaseをcustodyへ移し、`SD-GPH-TOL-001`のC/Q/Rだけをprivileged dispatchします。stable Adapter operation IDとexact occurrence/attemptで照会し、`SD-PER-EXE-005`で確定またはquarantineします。late成功を現在Agent turnへ注入せず、grant revision失効後の再dispatchを禁止します。

## 永続化

### SD-PER-CNV-001 — DurableFiniteConversationBoundary

次の複合変更をそれぞれ一つのUnit of Workでcommitします。

- CFG/BRP/IRP RevisionUse、Qualia Starting、Interaction ledger Pending、Conversation Open、generation 0のinitial execution lineage/subject、初期Graph/pendingを`SD-PER-CFG-005`、`SD-PER-EXE-007`、`SD-RUL-EXE-006`、`SD-TRN-EXE-015`と原子合成。
- request ledgerのadmission結果と独立lifecycle。同じadmission identityと同じinteraction/session/Behavior/revision binding/Graph digestの重複入力は同じreplayable resultを返し、新RevisionUse/lineage/Graph/checkpointを作らない。同じlineageまたはadmission identityの異payloadはConflictとして全棄却する。
- Recall selection/Policy/provenance、route bindingをAgent dispatchより前に固定。
- selected Memory本文のcontent-read結果、全分類authorization revision、`MemoryInputReady` factをAgent dispatchより前に固定。
- AgentTurnBinding Planned/Requested、Execution dispatch intent、selected Memory binding、transfer authorization、deadline、external-thread resource lease。
- Agent terminal inbox適用、Binding terminal、Conversation response受理、publish/save/audio子Occurrence登録。
- Agent terminal/deadline race winner、loser revocationまたはinterrupt occurrenceを同一revisionで固定。
- Agent失敗／timeout／取消／invalid proposalの型付きFailure Presentationと終端子Occurrence登録。
- Agent proposalのPolicy Decisionと、承認時だけ追加されるtyped planned Effects。
- Tool input materialization、tool/deadline competing occurrence、grant/authorization binding、
  tool winnerまたはcancel/Recovery handoff。
- cancellation受理、descendant revocation、cancel occurrence登録。
- Memory save/delete result、logical record status、Occurrence terminalまたはdurable handoff。
- Explicit saveのpending mutation bindingと結果適用。
- Memory reset replacement generationの先行commit、stable reset operation ID、旧generation退役。
- Thread reset時の旧turn Recovery handoff、barrier、旧generation退役、fresh binding適用。
- compaction／route gap結果とcontinuity binding状態。
- 内部Projection revision/cursorとPresentation commit結果。
- Conversation terminal、Interaction terminal、request ledger terminal、Qualia Terminating/Home guard結果。

journal/Projection replayはEffect作成、ready化、dispatchを行いません。

### SD-PER-CNV-002 — FiniteConversationSafeProgressCheckpointUoW

CNVとEXEのexpected revision、current execution subject、exact `SD-EVT-CNV-004`、Behavior versionのprogress-point宣言、Graphのcompleted／remaining node digestを全CASします。会話進行のOwner Transition、`SD-RUL-CNV-006`、`SD-TRN-CNV-008`、新しいAvailable checkpoint、旧Available checkpointのInvalidated化を同じSnapshot revisionへcommitします。Resume直後、Adapter受付、clock経過だけでは生成せず、一件でもOutcomeUnknown／custody未解決、subject交代、revision競合があれば全棄却します。crash後はprogress Event identityとcheckpoint generationから全体を再開し、progressだけ、checkpointだけを残しません。

### SD-PER-CNV-003 — FiniteConversationResumeClaimRejectionUoW

CNV、QLI、INT、EXEのexpected revision、exact Contribution、`SD-EVT-EXE-007.Rejected`、resume request/commit/replacement subject/occurrenceを全CASします。`SD-RUL-CNV-007`、`SD-EVT-CNV-005`、`SD-TRN-CNV-009`、`SD-TRN-INT-002`、`SD-TRN-QLI-001`によるActive/RecoveringからTerminatingへの移行、`SD-TRN-EXE-004`による同lineageの未dispatch remaining descendants revoke、内部failure Projection cursorのdurable commitを一つのState Snapshot revisionへcommitします。これによりcommit後に`Qualia Active + Conversation Open/ResponseAccepted`を残しません。

同じcommitでHome最小条件が全て成立する場合はTerminatingから`current=None`まで進めます。in-flight作用またはRecovery custodyが残る場合はTerminatingを維持し、それらのterminal／durable handoff後に`SD-RUL-CNV-002`を再評価して同じterminal identityからHomeへ進めます。新checkpoint、再resume、Agent/Tool Effect、Memory auto-saveを作りません。crash後はsource EXE rejection Eventとterminal result identityからUoW全体を再開し、CNVだけFailed、INTだけTerminal、QLIだけActive、またはProjectionなしHomeを構築しません。

### SD-PER-AGT-001 — AgentDispatchAuthorizationAndBindingUoW

DAT、AGT、EXEのexpected revision、Agent requestに含める全content classのcurrent transfer authorization、fresh Codex runtime readiness、exact AgentTurnBinding、planned occurrenceを全CASします。Agent requestはSkill実行ではないためSkillExecutionGrantやAUT revisionを要求しません。全て成立した場合だけ`SD-TRN-AGT-001`と`SD-TRN-AGT-008`によるBinding/BindingUse取得、immutable Agent dispatch payload、EXE attempt/dispatch intent/outboxを同じState Snapshot revisionへcommitします。Resume provenanceがある場合は`SD-PER-EXE-006`を同じUoWへ合成し、resume requestを同時にClaimedまたは確定Rejectedへ進めます。一つでも失効・競合した場合は全書込みを棄却し、BindingUseだけ、dispatch intentだけ、transfer bindingだけ、resume requestだけClaimedを残しません。

### SD-PER-AGT-002 — AgentRuntimeBindingUseReleaseUoW

AGT、EXE、CNVのexpected revisionとexact turn/attempt/useを全CASし、`SD-RUL-AGT-008`が許可した場合だけ`SD-TRN-AGT-008`でReleasedまたはRecoveryへ進めます。terminal resultとrelease、またはRecovery handoffとuse移管を原子的にcommitし、crash後は同じBindingUse IDから再開します。Recovery出口はこのUoWを再利用せず、`SD-PER-EXE-005`が`SD-EVT-AGT-014`、`SD-TRN-AGT-011`、Binding、BindingUse、custody、leaseを同時にTerminal/Interrupted/QuarantinedかつReleased/Quarantinedへ終端します。

### SD-PER-AGT-003 — ExplicitContinuityRestartUoW

AGTとEXEのexpected revision、Owner command、map上のprior `NotAppliedAwaitingExplicitRestart` barrier、current ref、fresh reset/stable operation ID、next replacement generationを全CASします。`SD-RUL-AGT-011`、`SD-EVT-AGT-016`、`SD-TRN-AGT-013`、fresh reset Graph/Occurrences/pendingを同じSnapshot revisionへcommitします。prior barrier entryを保持し、fresh entry追加とcurrent ref更新を分離commitしません。late resultはexact prior IDへ隔離し、旧Thread、prior operation IDを再利用せず、crash/duplicate時はOwner command idempotency keyから全体を再開します。

### SD-PER-TOL-001 — ToolDispatchAuthorizationUoW

AUT、DAT、EXEのexpected revision、exact approved tool proposal、current Active SkillExecutionGrant、input/output全content classのcurrent transfer authorization、ready tool occurrenceを全CASします。全て成立した場合だけgrant/transfer bindingを固定した`SD-EFX-TOL-001` dispatch payload、EXE attempt/dispatch intent/outboxを同じSnapshot revisionへcommitします。Resume provenanceがある場合は`SD-PER-EXE-006`を同じUoWへ合成します。一つでもrevoked、scope不一致、unknown classification、競合なら全て棄却し、Tool Effectや外部副作用、resume requestだけClaimedを残しません。Agent BindingUseやCodex runtime readinessをTool dispatch条件へ混入しません。

Homeへ進むための最小条件は、(1) Interaction terminal、(2) 内部Projection cursorのdurable commit、
(3) 必須Occurrenceのterminal／revoked／durable Recovery handoff、(4) resource lease解放またはRecovery所有、
の全成立です。browser push到達とTTS heard completionは条件に含めません。

## Projection

### SD-PRJ-CNV-001 — FiniteConversationProjection

Interaction admission/lifecycle、Recall結果、route continuity、route gap、最終Presentation、Memory save状態、cancel結果、音声のAssumed/OutcomeUnknown、Failure/Recovery、revision/cursor/stale/gapを持ちます。Web clientはcursorを提示して差分を再取得でき、gapまたは期限切れなら同じrevisionを持つfull snapshotへ切り替えます。Projection生成はEffectを起動しません。

### SD-PRJ-MEM-001 — SemanticMemoryProjection

availability、Policy version、取得件数、Empty/Failure、save/delete/reset状態、provenance、既注入Threadから遡及消去できない制約を示します。Memory本文を通常一覧へ無制限表示しません。

### SD-PRJ-AGT-001 — AgentSessionProjection

continuity種別、Ready/Degraded/RebindRequired、route gap、compaction、reset/recoveryを示します。Thread ID、raw delta、secretを含めません。

### SD-PRJ-QLI-001 — QualiaProjection

Homeまたはcurrent session identity、behavior、Lifecycle、termination/recoveryを示します。Behavior State本文とGraphを所有しません。

## 実装責務

### SD-MOD-CNV-001 — FiniteConversationModuleBoundary

- Rust Domain: 上記State、Rule、Decision、Transition、Effect、Failure、Graph validation。
- Rust application: Unit of Work、Domain Decisionの適用、Recovery、Projection、ready EffectのPortへの配送。dispatch可否や外部操作内容を独自判断しない。
- Adapter: SemanticMemory、persistent Agent session、stateless Provider inference、Web publication、non-streaming speech。
- external process/Python: result Eventだけを返し、WorldState、Conversation、Memory、Agent bindingを所有しない。
- Bootstrap: concrete Adapter、route/profile/transport binding。Codex固有operationをKernelへ漏らさない。

transport、process数、Memory schema/search engine、storage engine、数値timeoutは、この契約の意味を変えない限りPilot Gateを止めません。
