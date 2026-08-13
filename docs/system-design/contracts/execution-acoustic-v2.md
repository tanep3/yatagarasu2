# Execution schema v2 — Acoustic pre-Interaction extension

この文書は、accepted Execution schema v1を変更せず、Interaction作成前のAcoustic sessionを同じExecution法則へ載せるversion 2契約です。v1のDesign ID、Version、definition hash、Pilot approvalを上書きまたは流用しません。ここにあるdraft definitionは`TR-WP01-ACOU-001`のarchitecture challengeとPrimary approvalを通るまで使用できません。

## Versioned vocabulary and subject

### SD-MOD-EXE-004 — ExecutionContractV2

```text
ExecutionSchemaVersion = V2

ReleaseExecutionVocabularyV2 {
  PlannedPayloadV2 = InjectV1(ReleaseExecutionVocabulary.PlannedPayload) |
    AcousticPlannedPayload,
  DispatchPayloadV2 = InjectV1(ReleaseExecutionVocabulary.DispatchPayload) |
    AcousticDispatchPayload,
  ResultPayloadV2 = InjectV1(ReleaseExecutionVocabulary.ResultPayload) |
    AcousticResultPayload,
  ResumeContributionV2 =
    InjectV1(ReleaseExecutionVocabulary.ResumeContribution)
}

AcousticPlannedPayload =
  OpenAcousticSourceSession | PlayWakePrompt |
  AwaitAcousticGuardBoundary | TranscribeRetainedAcousticSpans |
  CloseAcousticSourceSession | AwaitAcousticOperationDeadline |
  QueryAcousticSourceOperation | QueryWakePromptOperation |
  CancelAcousticSourceOperation | CancelWakePromptPlayback

AcousticDispatchPayload = AcousticPlannedPayload with {
  exact effective source/prompt/clock binding,
  pinned policy/profile/schema revisions,
  stable adapter operation identity,
  ExecutionCorrelationV2
}

AcousticResultPayload =
  AcousticSourceOperationResolved |
  WakePromptPlaybackResolved | AcousticGuardBoundaryElapsed |
  AcousticOperationDeadlineElapsed |
  AcousticSourceQueryResolved | WakePromptQueryResolved |
  AcousticSourceCancellationResolved |
  WakePromptCancellationResolved

ExecutionSubjectRefV2 =
  InjectV1(ExecutionSubjectRef) |
  AcousticSessionSubject {
    session_id,
    wake_candidate_event_id,
    source_epoch,
    acoustic_generation
  }
```

V1 variantのfield、tag、意味、result correlationを変更しません。V2 serializerはV1 variantを同じexternal schemaへ投影でき、Acoustic variantをV1 Adapterへ送信しません。Kernel／共通schedulerはsubject/payload variantの業務意味を分岐せず、identity、dependency、guard、resource、revisionだけを検証します。

`AcousticSessionSubject`はexact四field `(session_id, wake_candidate_event_id, source_epoch, acoustic_generation)`を持ち、Interaction IDを持ちません。Acoustic command commit後に作られるInteraction execution lineageとは別subjectであり、IDを相互転用しません。`SubmitInteraction`受理はAcoustic GraphをInteraction Graphへreparentしません。

### SD-STA-EXE-002 — ExecutionStateV2

```text
ExecutionSchemaOwnedState =
  V1WithMigrationControl {
    accepted_v1_state: ExecutionState,
    migration_control: ExecutionMigrationControlRecord
  } |
  V2 {
    state: ExecutionStateV2
  }

ExecutionStateV2 {
  schema_version: V2,
  execution_lineages: Map<ExecutionLineageId,
    ExecutionLineageRecordV2>,
  graphs: Map<GraphId, GraphRecordV2>,
  occurrences: Map<EffectOccurrenceId, OccurrenceRecordV2>,
  attempts: Map<DispatchAttemptId, DispatchAttemptV2>,
  resource_leases: Map<ResourceLeaseId, ResourceLeaseV2>,
  recovery_custodies: Map<RecoveryCustodyId, RecoveryCustodyRecordV2>,
  guard_facts: Map<GuardFactId, GuardFactRecordV2>,
  checkpoint_resume_requests: Map<CheckpointResumeRequestId,
    CheckpointResumeRequestRecordV2>,
  resume_commits: Map<ExecutionResumeCommitId,
    ExecutionResumeCommitRecordV2>,
  subject_revocations: Map<RevocationId, RevocationRecordV2>,
  migration_control: ExecutionMigrationControlRecord,
  v1_compatibility: V1CompatibilityRecord,
  acoustic_graph_extensions: Map<AcousticGraphExtensionId,
    AcousticGraphExtensionRecord>,
  state_revision
}

ExecutionLineageRecordV2 =
  InjectV1ExecutionLineageRecord { value: ExecutionLineageRecord }

GraphRecordV2 =
  InjectV1GraphRecord { value: GraphRecord } |
  NativeAcousticGraphRecordV2 {
  graph_id, subject: AcousticSessionSubject,
  occurrence_ids: Set<EffectOccurrenceId>,
  dependency_edges: Set<OccurrenceDependencyEdge>,
  guard_declaration_ids: Set<GuardFactId>,
  immutable_resource_declarations,
  graph_digest
}
OccurrenceRecordV2 =
  InjectV1OccurrenceRecord {
    value: OccurrenceRecord<ReleaseExecutionVocabulary.PlannedPayload>
  } |
  NativeAcousticOccurrenceRecordV2 {
  occurrence_id, graph_id, subject: AcousticSessionSubject,
  planned_payload: AcousticPlannedPayload, policy_refs,
  resource_claims: List<ResourceClaimV2>, deadline_pair_id?,
  lifecycle: Pending | Ready | Claimed | DispatchIntentCommitted |
    InFlight | Succeeded | Failed | OutcomeUnknown | Cancelled |
    Revoked | Quarantined,
  winning_result_ref?
}
DispatchAttemptV2 =
  InjectV1DispatchAttempt {
    value: DispatchAttempt<ReleaseExecutionVocabulary.DispatchPayload>
  } |
  NativeAcousticDispatchAttemptV2 {
  attempt_id, occurrence_id, subject: AcousticSessionSubject,
  dispatch_payload: AcousticDispatchPayload,
  binding_use, intent_identity, outbox_identity,
  lifecycle: Claimed | DispatchIntentCommitted | Published |
    ResultAccepted | OutcomeUnknown | CancelRequested | Terminal
}
ResourceLeaseV2 =
  InjectV1ResourceLease { value: ResourceLease } |
  NativeAcousticResourceLeaseV2 {
  lease_id, resource, mode, named_interval_ref?,
  holder_subject: AcousticSessionSubject,
  holder_occurrence_id, holder_fact_id?,
  lifecycle: Reserved | Held | Continued | ReleasePending |
    Released | RecoveryCustody | Quarantined
}
RecoveryCustodyRecordV2 =
  InjectV1RecoveryCustodyRecord { value: RecoveryCustodyRecord } |
  NativeAcousticRecoveryCustodyRecordV2 {
  custody_id, subject: AcousticSessionSubject, occurrence_id, attempt_id,
  resource_lease_ids, uncertain_operation_identity,
  query_occurrence_id?,
  lifecycle: Open | QueryCommitted | ReconciledDefinitelyApplied |
    ReconciledDefinitelyNotApplied | Quarantined | Closed
}
GuardFactRecordV2 =
  InjectV1GuardFactRecord { value: GuardFactRecord } |
  NativeAcousticGuardFactRecordV2 {
  guard_fact_id, graph_id, subject: AcousticSessionSubject,
  fact_type, declared_issuer_subject: AcousticSessionSubject,
  declared_issuer_event_type, source_owner_event_id?,
  lifecycle: Declared | Satisfied | Failed | OutcomeUnknown | Revoked
}
ExecutionRevocationTargetV2 =
  InjectV1(ExecutionRevocationTarget) |
  AcousticSessionTarget { subject: AcousticSessionSubject } |
  AcousticOccurrenceTarget {
    subject: AcousticSessionSubject, occurrence_id
  }
RevocationId = StableDigest
NativeRevocationId(target, issuer_event_id) = Hash(
  "execution-revocation-v2", canonical(target), issuer_event_id)
MigratedV1RevocationId(source_v1_target_key, source_event_id) = Hash(
  "v1-revocation", canonical(source_v1_target_key), source_event_id)
RevocationRecordV2 =
  InjectV1RevocationRecord {
    revocation_id,
    source_v1_target_key: ExecutionRevocationTarget,
    value: SubjectRevocationRecord
  } |
  NativeAcousticRevocationRecordV2 {
  revocation_id, target:
    AcousticSessionTarget | AcousticOccurrenceTarget,
  issuer_event_id, reason, expected_execution_revision,
  lifecycle: Committed | DescendantsRevoked |
    InFlightCancellationPending | RecoveryCustody | Terminal
}
CheckpointResumeRequestRecordV2 =
  InjectV1CheckpointResumeRequestRecord {
    resume_request_id,
    value: CheckpointResumeRequestRecord
  }
ExecutionResumeCommitRecordV2 =
  InjectV1ExecutionResumeCommitRecord {
    resume_commit_id,
    value: ExecutionResumeCommitRecord
  }
V1CompatibilityRecord {
  migration_operation_id, source_v1_snapshot_revision,
  source_v1_digest, active_v2_digest,
  injected_lineage_count, injected_graph_count,
  injected_occurrence_count, injected_attempt_count,
  injected_lease_count, injected_custody_count,
  injected_guard_fact_count, injected_resume_request_count,
  injected_resume_commit_count, injected_revocation_count,
  source_store_digest_by_store,
  inverse_projection_digest_by_store,
  activation_ingress_receipt: {
    apply_pause_watermark, apply_pause_prefix_digest,
    activation_sealed_watermark, activation_sealed_prefix_digest,
    first_v2_apply_sequence?,
    ingress_contract_version
  },
  dispatch_outbox_barrier_watermark,
  dispatch_outbox_barrier_digest,
  compatibility_schema_version,
  lifecycle: MigrationPrepared | V2Activated | CompatibilityRejected
}
ExecutionMigrationControlRecord {
  migration_operation_id?,
  lifecycle: V1Active | MigrationPaused | V2Active,
  active_reducer: V1 | MigrationPaused | V2,
  dispatch_admission_barrier: Open |
    ClosedForMigration { barrier_id, closed_at_control_revision } |
    ClosedForCatchUp { barrier_id, handoff_kind: AbortToV1 | ActivateV2 },
  v1_apply_pause: None | {
    source_v1_snapshot_revision,
    applied_through_sequence,
    applied_prefix_digest,
    paused_at_control_revision
  },
  committed_ingress_tail: {
    last_committed_sequence,
    committed_prefix_digest,
    append_tail_revision
  },
  sealed_cut: None | {
    cut_sequence, cut_prefix_digest,
    sealed_append_tail_revision,
    sealed_control_revision
  },
  domain_apply_cursor: {
    last_applied_sequence,
    applied_prefix_digest,
    reducer: V1 | V2
  },
  handoff: None |
    ActivatedV2 { event_id, from_pause_sequence,
      first_v2_unapplied_sequence?, activation_control_revision } |
    AbortedToV1 { event_id, from_pause_sequence,
      first_v1_unapplied_sequence?, abort_control_revision },
  result_ingress_conflicts:
    Map<ResultIngressConflictQuarantineId,
      ResultIngressConflictQuarantineRecord>,
  control_revision
}
ResultIngressConflictQuarantineId = StableDigest
ResultIngressConflictQuarantineRecord {
  quarantine_id,
  stable_result_inbox_key: ResultInboxKey,
  winner_ingress_sequence,
  winner_record_ref,
  winner_payload_fingerprint,
  conflicting_payload_fingerprint,
  conflicting_correlation_fingerprint,
  first_conflicting_event_id,
  first_conflicting_provenance_ref,
  recorded_control_revision,
  lifecycle: Quarantined
}
AcousticGraphExtensionRecord {
  extension_id, graph_id, subject: AcousticSessionSubject,
  contribution_kind, source_acoustic_event_ids,
  prior_graph_digest, resulting_graph_digest,
  added_occurrence_ids, added_dependency_edges,
  added_guard_fact_ids, added_resource_declarations,
  expected_acoustic_revision, committed_execution_revision,
  committed_event_id
}
ExecutionCorrelationV2 {
  schema_version: V2, graph_id, occurrence_id, attempt_id,
  subject: ExecutionSubjectRefV2, stable_operation_id,
  adapter_binding_generation
}
```

`InjectV1*`はaccepted V1 record全体をopaque complete valueとして保持し、fieldの抜粋再構成をしません。Native Acoustic variantとのclosed sumであり、unknown variantを許しません。全recordはmap keyと内部identityが一致し、Acoustic recordのsubjectはGraph／Occurrence／Attempt／lease／custody／revocation／extensionで四field完全一致します。

Native recordはtag変更せず、Occurrence／Attempt／Lease／Custody／Guard／Revocationの列挙済みlifecycleを単調に進めます。terminal／Released／Closedからの再開、別attemptへのwinning result付替え、別subjectへのlease／custody移送、同じ`RevocationId`への別target登録を拒否します。Injected recordのlifecycleはwrapper側へ複製せず、accepted complete valueのlifecycleだけを正とします。resume wrapperも同様に、requestとcommitそれぞれのaccepted lifecycleを保持します。

Occurrenceのmutable canonical storeはtop-level `occurrences`だけです。`NativeAcousticGraphRecordV2`と`AcousticGraphExtensionRecord`はIDs、topology、immutable declaration／commit factだけを保持し、Graph lifecycle、Occurrence lifecycle、attempt/result、planned payloadの複製ownerではありません。Graph terminal／revoked viewとGraph→Occurrence indexを実装する場合もtop-level Occurrence、revocation、extensionから再構築するProjection/cacheであり、State mutation authorityを持ちません。`InjectV1GraphRecord`だけはaccepted V1 complete valueをcompatibility目的でopaqueに保持し、Native V2 recordへfieldを抽出しません。

V1 resume requestとcommitは別map／別closed wrapperで、accepted `CheckpointResumeRequestRecord`と`ExecutionResumeCommitRecord`の全field、exact key、相互relationを保持します。未定義resume claim型へ統合しません。requestの`resume_commit_id?`は存在時に`resume_commits` exact keyを指し、commitのsource/replacement subject、lineage、checkpoint、restart epoch、resumed occurrence IDsは対応request／top-level recordsと一致します。

revocation canonical keyは`RevocationId`です。V1 target-key mapからは`Hash("v1-revocation", canonical_v1_target_key, source_event_id)`で決定論的に導き、wrapperへ元target keyとcomplete recordを保持します。V1 Projectionは元target keyをexact復元し、duplicate targetまたはhash collisionをConflictとして拒否します。

`ExecutionSchemaOwnedState`はmigration controlをV1 activation中からdurableに所有するschema envelopeです。V1側はaccepted complete `ExecutionState`とcontrol recordのclosed pair、V2側はcontrol recordを含む`ExecutionStateV2`であり、同一deploymentでmutableなV1 StateとV2 Stateを並立所有しません。V1→V2 activationは同じcontrol identity/valueをV2 snapshotへ移し、copyを二つ残しません。

`ExecutionMigrationControlRecord`は`SD-CTX-EXE-001`が唯一所有し、`lifecycle`と`active_reducer`の合法組は`(V1Active,V1) | (MigrationPaused,MigrationPaused) | (V2Active,V2)`だけです。`MigrationPaused`は明示的なno-Domain-apply modeであり、V1／V2 reducerのどちらも裏で動きません。barrier、pause、tail、sealed cut、apply cursor、handoff、conflict quarantineをprocess memoryやdeployment scriptへ所有移管しません。

`committed_ingress_tail`はschema-neutral durable ingressのcommit済みprefixをExecution owner Stateへ相関するcontrol factです。sequenceはwinner recordとtail updateが同じUoWでcommitされる瞬間だけ割り当て、予約／先行採番／欠番を許しません。`1..last_committed_sequence`は全てdurable winner recordが存在するgap-free contiguous prefixです。storage engine、log implementation、transaction APIは固定しません。

`V1CompatibilityRecord.activation_ingress_receipt`、dispatch outbox barrier fields、`lifecycle`はactivation時のimmutable compatibility receiptであり、current barrier、tail、apply cursor、active reducerのmutation authorityを持ちません。current controlは`ExecutionMigrationControlRecord`だけです。

外部resultのdurable ingress ledgerはmutableなV1／V2 Domain Stateではなく、`SD-PER-EXE-002`のstable inbox identityをschema-neutral containerで保持するapplication persistence境界です。migration中もAdapter ingressを止めず、このledgerへのappend／dedupe／Conflict quarantineとcommit後ackを継続しますが、Domain Transitionへのapplyは停止します。したがってPython worker、Adapter、migration processはExecution State ownerになりません。

## Pure contribution and atomic extension

### SD-EVT-EXE-009 — AcousticGraphContributionCommitted

```text
AcousticGraphContributionCommitted {
  event_id, extension_id,
  graph_id, acoustic_session_subject: AcousticSessionSubject,
  contribution_kind,
  prior_graph_digest, resulting_graph_digest,
  added_occurrence_ids, added_dependency_edges,
  added_guard_fact_ids, added_resource_declarations,
  source_acoustic_event_ids,
  expected_execution_revision,
  execution_schema_version: V2
}
```

Execution ownerがGraph extensionを一度commitした事実です。Effect開始、Adapter結果、Acoustic State mutationを意味しません。

### SD-RUL-EXE-007 — ValidateAcousticGraphContribution

Acoustic ownerのclosed contribution value、exact V2 subject／Graph、expected revision、source owner Events、new immutable planned payloads、dependency edges、declared guard facts、resource claims、deadline pairsをpureに検証します。

次を全て満たす場合だけ`AcceptExtension`を返します。

- extension IDと全Occurrence／Guard Fact IDが決定論的で未登録。
- source Acoustic Eventsが同じsession／source epoch／policy/profile pinsを持ち、Acoustic expected revisionと一致。
- payloadはcontribution時点ですべて確定し、future span、future cursor、current Policy lookup、closureを含まない。
- producer→consumer edgeとGuard Fact declarationが完全で、self edge／descendant producer／cycleがない。
- named lease continuationは`existing_lease_id`、resource、mode、`named_interval_ref`、Owner-issued holder factと、`holder_ref`のAcousticSessionSubject四field全体が`GraphRecordV2.subject`、`OccurrenceRecordV2.subject`、`ResourceLeaseV2.holder_subject`へexact一致。
- operation nodeにはpin済みbounded deadline occurrenceまたは既存の終端境界が一件だけ対応する。
- terminalまたはrevoked Graph、別subject、V1 schemaへAcoustic variantを追加しない。

Kernelは`AddGuardWait | AddTranscription | AddClose | AddRecovery`の意味を判断せず、closed variantごとの構造不変条件だけを検証します。

### SD-TRN-EXE-016 — ExtendAcousticEffectGraph

`SD-RUL-EXE-007.AcceptExtension`とexact `SD-EVT-EXE-009`をexpected V2 revisionへ一度適用し、新規Occurrence、Guard Fact declaration、immutable extension recordを同時登録します。既存`GraphRecordV2`を書き換えず、effective topologyはinitial Graph declarationとgraph IDで束ねたextension recordsの順序付きunionです。attempt、lease取得、dispatch intent、outboxを作りません。同じextension ID／同じdigestはno-op、異payloadはConflictです。

### SD-PER-EXE-008 — DurableAcousticGraphExtensionUoW

Acoustic expected revision、Execution V2 expected revision、source Acoustic owner Events、pure contribution、`SD-RUL-EXE-007`、`SD-EVT-EXE-009`、`SD-TRN-EXE-016`を一つのSnapshot revisionへcommitします。一件でもCAS競合、stale pin、revocation、cycle、lease mismatchがあれば全書込みを棄却します。

commit後の通常`SD-RUL-EXE-001/002`だけがeffective topology projectionを読みready／claimを決め、durable intent後だけdispatcherへ公開します。Graph contributor、Acoustic reducer、KernelはEffectを直接実行しません。crash後は同じextension ID／digestから全体を再開し、Occurrenceだけ、factだけ、Acoustic progressだけを残しません。

## Snapshot migration and compatibility

### SD-MOD-EXE-005 — ExecutionSnapshotV1ToV2Migration

```text
ExecutionSnapshotV1ToV2Plan {
  source_snapshot_revision,
  source_schema_version: V1,
  target_schema_version: V2,
  v1_snapshot_digest,
  deterministic_v2_snapshot_digest,
  lineage_injections: Map<ExecutionLineageId,
    InjectV1ExecutionLineageRecord>,
  graph_injections: Map<GraphId, InjectV1GraphRecord>,
  occurrence_injections: Map<EffectOccurrenceId,
    InjectV1OccurrenceRecord>,
  attempt_injections: Map<DispatchAttemptId,
    InjectV1DispatchAttempt>,
  lease_injections: Map<ResourceLeaseId, InjectV1ResourceLease>,
  custody_injections: Map<RecoveryCustodyId,
    InjectV1RecoveryCustodyRecord>,
  guard_fact_injections: Map<GuardFactId,
    InjectV1GuardFactRecord>,
  resume_request_injections: Map<CheckpointResumeRequestId,
    InjectV1CheckpointResumeRequestRecord>,
  resume_commit_injections: Map<ExecutionResumeCommitId,
    InjectV1ExecutionResumeCommitRecord>,
  revocation_injections: Map<RevocationId,
    InjectV1RevocationRecord>,
  v1_target_to_revocation_id:
    Map<ExecutionRevocationTarget, RevocationId>,
  source_record_count_by_store,
  target_record_count_by_store,
  source_store_digest_by_store,
  inverse_projection_digest_by_store,
  inbox_compatibility_digest,
  outbox_compatibility_digest,
  result_ingress_cut: {
    apply_pause_watermark,
    apply_pause_prefix_digest,
    activation_sealed_watermark,
    activation_sealed_prefix_digest,
    pending_v1_result_keys_digest,
    ingress_contract_version
  },
  dispatch_outbox_barrier_watermark,
  dispatch_outbox_barrier_digest,
  migration_operation_id
}

MigrationStableResultIngressRecord {
  ingress_sequence,
  result_inbox_key: ResultInboxKey,
  source_execution_schema: V1,
  canonical_source_envelope: PortResultEnvelope<ReleaseExecutionVocabulary.ResultPayload>,
  canonical_payload_fingerprint,
  correlation_fingerprint,
  durable_status:
    Unapplied | AppliedV1 | AppliedV2InjectV1,
  ack_status: NotAcknowledged | Acknowledged
}

MigrationStableResultIngressCut {
  apply_pause_watermark,
  apply_pause_prefix_digest,
  activation_sealed_watermark,
  activation_sealed_prefix_digest,
  first_unapplied_sequence,
  append_only_chain_version
}
```

各injection valueはaccepted V1 recordの完全な値を一つだけ包みます。したがってOccurrenceの`occurrence_origin`、`planned_effect_spec`、dependencies、guard、resource claims、active attempt、result IDs、revoked reason、Attemptのgeneration／dispatcher／correlation／intent mark／dispatch effect、Leaseのscope／holder／release guard／recovery binding、Custodyのowner／privileged claims／全stage／reconciliation、Guardのdeclaration／source event／statusをlosslessに保持します。resume requestとresume commitも別storeのまま全fieldを保持し、`resume_commit_id`、replacement occurrence、source/replacement subject、lineage、checkpoint、restart epoch、resumed occurrence IDsのrelationを変えません。

全V1 subject/payload/resultを対応する`InjectV1` variantへ一対一で写します。revocationだけはV1 target keyから決定論的`RevocationId`を作り、元keyとcomplete `SubjectRevocationRecord`を同じwrapperへ保持します。外部Effectを再dispatchせず、AcousticSessionSubject、Acoustic target、Acoustic extensionを捏造しません。serialization tag変更時も旧digestと決定論的V2 digestをstoreごとに記録します。

migration開始時はdispatch／admissionを閉じ、V1 Domain result applyを`apply_pause_watermark`で停止します。すでにdispatch済みattemptのresult ingressは停止せず、同じ`ResultInboxKey`、完全なV1 correlation、canonical payload fingerprintを持つ`MigrationStableResultIngressRecord`としてappend-only ledgerへ保存し、保存commit後だけackします。`AppliedV1`でpause watermark以下のrecordはV1 snapshotへすでに反映済み、`Unapplied`はactivation後に処理すべきrecordであり、両者を再分類しません。

`activation_sealed_watermark`はappend-only ledgerのprefixを封印する論理cutです。migration UoWと同時に到着したresultはmonotonic sequenceによってcut以下またはcutより後のexact一方に属し、後続appendはsealed prefix digestを変更しません。cut後recordも同じledgerへdurable保存され、activation後scanへ含まれるため、migration transactionに間に合わないことをlossまたはFailureにしません。

prefix digestは各recordのimmutable `(ingress_sequence, ResultInboxKey, source_execution_schema, canonical_payload_fingerprint, correlation_fingerprint)`だけから作り、`durable_status`と`ack_status`を含めません。したがってackまたはapply lifecycleの単調更新は封印済みprefixを変えず、同key異payloadやsequence/keyの欠落だけがdigest driftになります。status／ackは各recordのexpected revisionで別途CASします。

同じ`ResultInboxKey`／同payload fingerprint／同correlation fingerprintはwinner recordへのidempotent duplicateであり、新sequence、tail revision、Domain apply、Conflict recordを作りません。同じkeyの異payloadまたは異correlationはwinnerを変更せず、`ResultIngressConflictQuarantineId = Hash("result-ingress-conflict-v1", stable_key, winner_fingerprint, conflicting_payload_fingerprint, conflicting_correlation_fingerprint)`の別recordだけを`result_ingress_conflicts`へ保存します。同じconflicting payload/correlationのtransport replayはevent/provenance metadataが違っても同IDのno-opで、最初のprovenanceをimmutableに保ちます。同ID異payloadはcontrol invariant violation、別conflicting digestまたはcorrelationは別IDです。winnerのpayload、status、ack、sequence、Event／outbox winnerをConflictで上書きしません。

### SD-RUL-EXE-008 — ValidateExecutionSnapshotV1ToV2Migration

source snapshotが`ExecutionMigrationControlRecord.lifecycle=MigrationPaused`、`active_reducer=MigrationPaused`、dispatch/admission barrier closedで、V1 Domain result applyがexact pause cursorで停止し、sealed cutが存在すること、全concrete V2 recordへの一対一InjectV1、map key＝内部identity、subject closure、pending intent/outbox/inbox key、resource/custody/revocation総数、Graph topology、result lifecycle、resume request/commit relation、compatibility digest mappingをpureに検証します。各storeについて`V1Projection(injection(value)) == value`をfield／tag／map keyまで比較し、revocationは元target-key projectionと導出`RevocationId`の一対一性も検証します。

さらに、apply pause watermark／prefix digest、activation sealed watermark／prefix digest、dispatch outbox barrier watermark／digestを検証します。pause以下の全inbox recordがexact一回`AppliedV1`でsource snapshotへ反映済み、pauseより後のrecordがV1へ未適用、sealed prefix内の全recordのkey／V1 correlation／payload fingerprint／ack stateがlossless、同key同payload duplicateが一identity、同key異payloadがConflict quarantineである場合だけ許可します。欠落、追加、duplicate、hash collision、unknown V1 variant、in-flight identity変更、Acoustic record混入、ack済みrecord欠落、unapplied resultのV1 mutation、outbox barrier後dispatchを拒否します。

### SD-RUL-EXE-009 — DecideExecutionMigrationControl

current `ExecutionMigrationControlRecord`、Execution expected revision、schema-neutral ingress winner／conflict records、V1/V2 snapshot digest、barrier evidence、requested control actionをpureに評価し、次のclosed Decisionのexact一つを返します。

```text
ExecutionMigrationControlDecision =
  AppendWinner { assigned_sequence, next_tail_revision,
    next_prefix_digest, winner_record } |
  ReplayWinner { winner_record_ref } |
  QuarantineConflict { quarantine_id, conflict_record } |
  PauseV1 { pause_sequence, pause_digest, barrier_id } |
  SealCut { cut_sequence, cut_digest, expected_append_tail_revision } |
  ActivateV2 { migration_plan_digest, sealed_cut,
    first_v2_unapplied_sequence? } |
  AbortToV1 { sealed_cut?, first_v1_unapplied_sequence? } |
  ApplyNextBufferedResult { expected_next_sequence,
    source_schema: V1, target_reducer: V1 | V2,
    inject_v1_correlation, next_apply_digest } |
  OpenBarrierAfterCatchUp { reducer: V1 | V2,
    caught_up_tail_revision } |
  IdempotentReplay { prior_event_id } |
  Reject(MigrationControlFailure)
```

`AppendWinner`はstable key未登録かつ`assigned_sequence=last_committed_sequence+1`の場合だけ返し、sequence reservationを返しません。同key同payload/correlationは`ReplayWinner`、同key異payload/correlationはimmutable winner ref付き`QuarantineConflict`です。`SealCut`はcurrent shared append-tail revisionとgap-free prefix digestをexact CAS inputに固定します。appendとsealが競合した場合、append commitが先ならそのwinnerはcut以下、seal commitが先ならappend retryはcut超の次sequenceとなり、reserved-before-seal／commit-after-sealでcut以下へ潜り込みません。

`PauseV1`は`V1Active/V1/Open`かつV1 apply cursorがcurrent committed tailへ追いついた場合だけ許可します。`ActivateV2`／`AbortToV1`は`MigrationPaused/MigrationPaused`からだけ許可し、target reducerを同じatomic handoffで一つだけ選びます。`ApplyNextBufferedResult`は`domain_apply_cursor+1`のcommitted winnerだけを許可し、missing、未commit、gap、別sequenceのovertakeを拒否します。`OpenBarrierAfterCatchUp`はapply cursorとCAS時点のcommitted tail sequence/digest/revisionが一致する場合だけ許可します。payloadのBehavior意味をKernelへ持ち込みません。

### SD-EVT-EXE-010 — ExecutionSnapshotV2Activated

source／target revisionとdigest、migration operation ID、全record count、apply pause／activation sealed inbox watermarkとprefix digest、dispatch outbox barrier watermark／digest、compatibility schema versionを持つExecution owner Eventです。Acoustic admission許可やruntime readiness、buffered resultの適用完了を単独では意味しません。

### SD-EVT-EXE-011 — ExecutionMigrationControlAdvanced

```text
ExecutionMigrationControlAdvanced {
  event_id, migration_operation_id,
  prior_control_revision, resulting_control_revision,
  action: WinnerAppended | ConflictQuarantined | V1Paused |
    IngressCutSealed | V2Activated | AbortedToV1 |
    BufferedResultApplied | BarrierOpened,
  active_reducer_before, active_reducer_after,
  append_tail_before, append_tail_after,
  apply_cursor_before, apply_cursor_after,
  sealed_cut_ref?, result_inbox_key?,
  conflict_quarantine_id?, owner_evidence_digest
}
```

Execution ownerがmigration controlの一合法edgeを確定した事実です。`active_reducer_before/after`はhandoffを監査しますが二reducerの同時有効化を表すvariantを持ちません。`WinnerAppended`はDomain apply、`V1Paused`はsnapshot migration成功、`V2Activated`はcatch-up/barrier openを意味しません。

### SD-TRN-EXE-018 — ApplyExecutionMigrationControl

`SD-RUL-EXE-009`のclosed Decisionとexact `SD-EVT-EXE-011`をexpected Execution／control revisionへ適用します。許可edgeは次だけです。

| Decision | Control edge | 同時に必要なmutation |
| --- | --- | --- |
| AppendWinner | same lifecycle/reducer、tail `n -> n+1` | winner record、gap-free prefix digest、tail revision |
| ReplayWinner | no-op | 保存済みwinner refだけを返す |
| QuarantineConflict | same lifecycle/reducer | 別Conflict ID/record。winner不変 |
| PauseV1 | `V1Active/V1 -> MigrationPaused/MigrationPaused` | barrier close、pause cursor/digest、handoff reset |
| SealCut | `MigrationPaused/MigrationPaused`のまま | exact tail revisionのimmutable sealed cut |
| ActivateV2 | `MigrationPaused/MigrationPaused -> V2Active/V2` | V2 snapshot/schema marker、activation handoff、catch-up barrier |
| AbortToV1 | `MigrationPaused/MigrationPaused -> V1Active/V1` | abort handoff、catch-up barrier。V2 snapshotなし |
| ApplyNextBufferedResult | target reducerのままcursor `n -> n+1` | inbox status、exact reducer mutation、owner Event／outbox |
| OpenBarrierAfterCatchUp | `V1Active/V1`または`V2Active/V2`のまま | current tail一致をCASしてbarrier Open |

append sequence、seal、pause、activation、abort、apply cursorを単独commitしません。terminal lifecycleからの逆行、二reducer、`MigrationPaused`でのDomain result apply、V1ActiveでのInjectV1 apply、V2ActiveでのV1 mutationを拒否します。同Decision/Event replayはsame resulting revision/digestならno-op、異payloadはConflictです。

### SD-TRN-EXE-017 — MigrateExecutionSnapshotV1ToV2

`SD-RUL-EXE-008`が許可したplanとexact `SD-EVT-EXE-010`だけからlossless V2 snapshot／schema marker candidateを構築します。source controlは必ず`MigrationPaused/MigrationPaused`かつsealed cut済みです。active reducer handoffはこのTransition単独では行わず、`SD-RUL-EXE-009.ActivateV2`、`SD-EVT-EXE-011`、`SD-TRN-EXE-018`と`SD-PER-EXE-009`で同じcommitにします。schema-neutral durable result ingressは継続し、途中snapshotをdispatch可能にしません。同plan replayはno-op、別digestはConflictです。V1 snapshotを破壊せずrollback artifactとして保持しますが、V2 activation後にV1 mutable ownerを再開しません。

activation後、pause watermarkより後の`Unapplied` V1 resultをingress sequence順に読み、`SD-RUL-EXE-009.ApplyNextBufferedResult`でsource envelopeのexact V1 subject／occurrence／attempt／attempt generation／stable adapter operationを`InjectV1` correlationとして検証してから、既存`SD-TRN-EXE-003 ApplyOccurrenceResult`のV2 compositionへ一度だけ渡します。Conflict quarantineはwinner sequenceを持たないためapply cursorを進めません。一部だけ失敗すれば全棄却し、新しいResult Event identityやV2-native targetを作りません。terminal、Failure、OutcomeUnknown、cancel、late resultはaccepted V1意味のまま元Injected occurrence／attempt／custody／outboxへ相関し、別Interaction、Acoustic subject、current attemptへ付け替えません。

### SD-PER-EXE-009 — ExecutionSnapshotV2ActivationUoW

`MigrationPaused/MigrationPaused` control、dispatch/admission barrier、V1 result-apply pause cursor、append-only inboxのsealed prefix watermark／digest、dispatch outbox watermark／digest、V1 snapshot、migration plan、V2 snapshot candidate、`SD-EVT-EXE-010`、`SD-RUL-EXE-009.ActivateV2`、`SD-EVT-EXE-011`、`SD-TRN-EXE-017/018`、schema markerをCASして原子的にcommitします。result ingress appendとackはこのUoWの外側で継続しますが、append-only sequenceとsealed prefixにより各recordはbarrier前／barrier中／activation commit raceのexact一側へ属します。UoWが見たsealed cut、control revision、prefix digest、apply cursorが変われば全体を棄却し、V2 snapshotだけ、schema markerだけ、active reducerだけ、cursorだけをcommitしません。

activation commit前にcrashした場合はdurable `MigrationPaused/MigrationPaused`へ戻り、abortまたはactivationを同じcontrol revisionから再決定します。commit後crashは`V2Active/V2`と`first_v2_apply_sequence=next_unapplied_after(apply_pause_watermark)`を復元し、同じinbox keysをInjectV1 correlationで再開します。ack済みでも未applyのrecordを失わず、apply済みrecordを再適用しません。outbox送信をmigration中に行わず、commit後は既存のsame stable intent identityだけを再開します。V1 reducerとV2 reducerを同時に有効化する状態は構築できません。

### SD-PER-EXE-010 — DurableExecutionMigrationControlUoW

次の各compositionは`ExecutionMigrationControlRecord.control_revision`と必要なExecution／inbox record revisionをCASし、全体なし／全体ありでcommitします。

- **Ingress append:** stable inbox keyのabsence、current append-tail revision、`SD-RUL-EXE-009.AppendWinner`、winner record、sequence `tail+1`、prefix digest、`SD-EVT-EXE-011`、`SD-TRN-EXE-018`を同時commitします。sequenceを先に予約／公開せず、append abort／CAS loserはrecordもsequenceも残しません。commit後だけack可能です。
- **Duplicate/conflict:** same key/same payload/correlationは保存済みwinnerを返すno-opです。異payload/correlationはstable `ResultIngressConflictQuarantineId`、winner ref、conflicting digest/provenance、owner Event、control map追加だけをcommitし、winnerとtailを変更しません。同一conflict replayは一recordです。
- **Pause:** barrier close、V1 apply cursor=current committed tail、pause digest、`V1Active/V1 -> MigrationPaused/MigrationPaused`、owner Eventを同時commitします。未適用winnerがあればpauseしません。
- **Seal:** current shared append-tail revision、gap-free prefix、cut sequence/digest、owner EventをCASします。racing appendが先にcommitすればseal retryはそれをcutへ含み、sealが先ならappend retryはcut超へだけcommitします。
- **Abort handoff:** `MigrationPaused/MigrationPaused -> V1Active/V1`、abort handoff、catch-up barrier、V1 apply cursor、owner Eventを同時commitし、V2 snapshot/schema mutationを一件も作りません。reducer handoff前後のgap／dual activeを作りません。
- **Buffered apply:** exact `cursor+1` winner、winner status `Unapplied`、target reducer、Execution expected revisionをCASします。V1ならaccepted V1 correlation、V2ならInjectV1 correlationを用い、inbox status、Domain mutation、result owner Event、Guard／custody／outbox contribution、apply cursor/digest、`SD-EVT-EXE-011`を同じcommitへ置きます。missing/uncommitted sequence、gap、後続overtake、conflict recordをwinnerとしてapplyすることを拒否します。
- **Barrier open:** apply cursor sequence/digestがCAS時点のcommitted tail sequence/digest/revisionへ追いついた場合だけcatch-up barrierをOpenへ進めます。racing appendが先ならCASを失い、new tailをapplyしてから再試行します。

V1Active ingressを通常適用する場合もappend winner、V1 Domain mutation、inbox `AppliedV1`、apply cursorを同じcompositionへ置けます。migration pause後はappend-only、activation/abort handoff後は選ばれた一reducerだけがbuffered applyを行います。journal replay、process restart、ackからsequenceまたはDomain Eventを再生成しません。

### SD-PRJ-EXE-001 — ExecutionV1CompatibilityView

V2内の全`InjectV1*` variantを、wrapper内のaccepted complete valueと元map keyへlosslessに投影します。resume request／commitはそれぞれ元の別mapへ戻し、relationを再構成しません。revocationは`source_v1_target_key`へ戻し、complete `SubjectRevocationRecord.target`とのexact一致を検証します。migration ingress viewはsource V1 envelope、stable inbox key、payload/correlation fingerprint、ack、`Unapplied | AppliedV1 | AppliedV2InjectV1`をwinner viewへ、ConflictQuarantine ID、winner ref、conflicting digest/provenanceを別conflict viewへ投影します。`AppliedV2InjectV1`をV1へ未適用として戻さず、Conflictをwinner resultへ畳みません。AcousticSessionSubject、AcousticSession/Occurrence revocation target、Acoustic lease/custody/extensionを含むrecordはrecord全体を`UnsupportedExecutionSchemaV2Variant`として拒否し、V1 recordへ部分投影しません。

### SD-PRF-EXE-001 — ExecutionV1V2RoundTripProofContract

固定V1 snapshot fixtureを少なくとも次の六組で作り、`projectV1(migrateV2(v1)) == v1`をserialized tag、全field、map key、store digestまで比較します。

1. active Graph、AwaitingClaim／Started Occurrence、active Attempt、NamedInterval lease、pending Guard。
2. Succeeded／Failed／Cancelled相当のterminal resultとreleased lease。
3. subject／lineage revocationとRevoked Occurrence。V2の`RevocationId`から元V1 target keyをexact復元する。
4. OutcomeUnknown attempt、Active RecoveryCustody、TransferredToRecoveryCustody／Quarantined lease、StillUnknown reconciliation。
5. `RecoveryPending`、`ReplacementRegistered`、`Claimed`を含むresume requestと、存在する場合の別map resume commit／replacement occurrence／lineage relation。
6. terminal resume、reconciled custody、複数result IDs、pending durable intent、inbox／outbox identityを含む混合集合。

各fixtureはmigration中にdispatch、query、cancel、lease releaseを一件も公開しないことも検証します。欠落field、別key、wrapperからの再構成、revocation collision、request/commit統合、Graph内Occurrence lifecycle複製をnegative fixtureとして拒否します。

加えて、migration result ingress fixtureを少なくとも次の表で検証します。

| Result arrival / failure point | Required outcome |
| --- | --- |
| barrier直前にingress/apply済み | pause watermark以下の`AppliedV1`としてV1 snapshotに一度だけ含み、V2で再applyしない |
| barrier成立後・plan作成前 | durable `Unapplied`、ack後crashでも保持し、activation後InjectV1で一度だけapply |
| append commitがseal CASより先 | append winnerをcut以下のlast contiguous recordへ含め、seal retryが新tail revision/digestを使用 |
| seal CASがappend attemptより先 | append attemptは旧tail CASを失い、retryでcut超の`tail+1`だけをcommit |
| reserved-before-seal／commit-afterの模擬 | sequence reservation API／Stateが存在せず構築不能。cut以下への後commitを拒否 |
| append record commit前abort／crash | record、sequence、tail、digestを全て残さず、同key retryが同じ次sequence候補を再計算 |
| append／seal CAS loser retry | shared append-tail revisionから再計算し、duplicate sequenceまたはcut driftなし |
| missing sequence／uncommitted record／gap | seal、activation、apply cursor advance、barrier openを全て拒否 |
| plan作成後・activation commit競合中 | sealed cutのsequence前後どちらか一方へ決定し、cut後でもV2 scanが失わない |
| activation commit直後・apply前crash | V2Activeと同じfirst sequenceから再開し、V1 mutationなし |
| apply commit直前／直後crash | inbox statusとInjected occurrence mutationを全体なし／全体ありにし、double applyなし |
| same key/same payload duplicate（barrier両側を含む） | same inbox identityのno-op、ack可能、二つ目のresult Event／terminalなし |
| same key/different payload | 別stable ConflictQuarantine ID/record、winner ref、conflicting digest/provenanceを残し、元winner／State／outbox／tailを変更しない |
| same conflict replay／別conflict | 同digest/correlationはevent metadataが違っても同ID no-op。同ID異payloadはinvariant。別digest/correlationは別IDでwinner不変 |
| late result／cancel result | exact InjectV1 occurrence／attempt／generationだけへ相関し、current workへ付替えない |
| OutcomeUnknown result | accepted V1 custody／no-auto-retry意味を保ち、activationを成功観測へ変換しない |
| migration abort before activation | reducerを`MigrationPaused -> V1`へatomic handoffし、durable recordを同じkeyでV1へ一度だけapply後catch-up CASでbarrier解除。V2 mutation／dual reducer／reducer gapなし |
| activation reducer handoff | `MigrationPaused -> V2`とsnapshot/schema markerをatomic commitし、V1 mutation／dual reducer／reducer gapなし |
| pending/sent outboxとresult race | barrier後に新dispatchせず、sent attemptのresultは保存。activation後もsame outbox/attempt identity |

全caseでingress commit前ackを拒否し、ack直後crashでもwinnerを復元します。ack済みresult loss、V1/V2 dual mutation、cursorとinbox／owner Event／outboxの部分commit、journalからのresult再生成、Acoustic variant生成をnegative fixtureにします。このProofはcontract test入力であり、実migrationのpassingやrelease readinessを主張しません。

### SD-FAIL-EXE-001 — ExecutionV2CompatibilityFailure

```text
ExecutionV2CompatibilityFailure =
  SnapshotMigrationConflict | UnsupportedV1Variant |
  V1RecordIdentityDrift | PendingOutboxIdentityDrift |
  V1RoundTripFieldDrift | V1ResumeRelationDrift |
  V1RevocationIdCollision | V1RevocationTargetDrift |
  V2RecordTypeMismatch | V2MapKeyIdentityMismatch |
  AcousticSubjectIdentityMismatch | V1PartialProjectionBlocked |
  ResultIngressCutConflict | ResultIngressDigestDrift |
  ResultIngressCorrelationDrift | ResultIngressPayloadConflict |
  ResultIngressAckBeforeDurability | V1V2DualResultMutation |
  ResultIngressSequenceGap | ResultIngressUncommittedOvertake |
  ResultIngressWinnerMutation | MigrationReducerHandoffConflict |
  RuntimeDoesNotSupportExecutionV2 |
  AcousticVariantSentToV1Adapter |
  DowngradeBlockedByV2Snapshot |
  DowngradeBlockedByAcousticRecord
```

## Rollout, recovery, and downgrade

Acoustic admissionは、V2 snapshot activation、V2-compatible runtime readiness、Acoustic source/profile/policy readinessを同じadmission viewで確認した後だけ許可します。V1 finite Conversation／Camera等はV2上でも`InjectV1`として継続し、外部schemaを変更しません。

V2 activation前crashはV1から再開し、activation後crashはconcrete V2 recordから再開します。migration barrier中もdispatch済みV1 attemptのresult ingressを継続し、Domain applyだけを停止します。activation後はpause watermarkより後のrecordをexact InjectV1 correlationへ一度だけapplyし、V1 mutable Stateを再開しません。Acoustic cancelは`ExecutionRevocationTargetV2`のexact AcousticSession/Occurrence target、recoveryは同じ四field subjectのRecoveryCustodyRecordV2へだけ接続し、別generation/sessionのleaseをreleaseしません。migration自体は外部Effectを作らず、既存V1 OutcomeUnknown custodyと移行中に到着したOutcomeUnknown resultはInjectV1 identityを保ちます。

V2 snapshot、Acoustic subject、Acoustic payload、Acoustic Graph extension recordのいずれかが存在する状態からV1 runtimeへdowngradeしません。rollbackには、Acoustic admission前かつV2 activation transactionを取り消せる明示的deployment window、または全V2 workをterminal化してOwner承認済みの別migration契約が必要です。本trancheは後者を設計・承認したと主張しません。

process、storage engine、serialization format、deployment commandは未決です。migration contractはDomain State ownerをprocessへ移しません。
