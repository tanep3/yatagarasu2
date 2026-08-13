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
  compatibility_schema_version,
  lifecycle: MigrationPrepared | V2Activated | CompatibilityRejected
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

同一deploymentでmutableなV1 StateとV2 Stateを並立所有しません。snapshot lifecycleは`V1Active | MigratingToV2 | V2Active`の一つだけで、ownerは引き続き`SD-CTX-EXE-001`だけです。

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
  migration_operation_id
}
```

各injection valueはaccepted V1 recordの完全な値を一つだけ包みます。したがってOccurrenceの`occurrence_origin`、`planned_effect_spec`、dependencies、guard、resource claims、active attempt、result IDs、revoked reason、Attemptのgeneration／dispatcher／correlation／intent mark／dispatch effect、Leaseのscope／holder／release guard／recovery binding、Custodyのowner／privileged claims／全stage／reconciliation、Guardのdeclaration／source event／statusをlosslessに保持します。resume requestとresume commitも別storeのまま全fieldを保持し、`resume_commit_id`、replacement occurrence、source/replacement subject、lineage、checkpoint、restart epoch、resumed occurrence IDsのrelationを変えません。

全V1 subject/payload/resultを対応する`InjectV1` variantへ一対一で写します。revocationだけはV1 target keyから決定論的`RevocationId`を作り、元keyとcomplete `SubjectRevocationRecord`を同じwrapperへ保持します。外部Effectを再dispatchせず、AcousticSessionSubject、Acoustic target、Acoustic extensionを捏造しません。serialization tag変更時も旧digestと決定論的V2 digestをstoreごとに記録します。

### SD-RUL-EXE-008 — ValidateExecutionSnapshotV1ToV2Migration

source snapshotがV1Activeでdispatch admissionを閉じていること、全concrete V2 recordへの一対一InjectV1、map key＝内部identity、subject closure、pending intent/outbox/inbox key、resource/custody/revocation総数、Graph topology、result lifecycle、resume request/commit relation、compatibility digest mappingをpureに検証します。各storeについて`V1Projection(injection(value)) == value`をfield／tag／map keyまで比較し、revocationは元target-key projectionと導出`RevocationId`の一対一性も検証します。欠落、追加、duplicate、hash collision、unknown V1 variant、in-flight identity変更、Acoustic record混入を拒否します。

### SD-EVT-EXE-010 — ExecutionSnapshotV2Activated

source／target revisionとdigest、migration operation ID、全record count、compatibility schema versionを持つExecution owner Eventです。Acoustic admission許可やruntime readinessを単独では意味しません。

### SD-TRN-EXE-017 — MigrateExecutionSnapshotV1ToV2

`SD-RUL-EXE-008`が許可したplanとexact `SD-EVT-EXE-010`だけを、一つのoffline migration transactionで`V1Active -> MigratingToV2 -> V2Active`へ適用します。途中snapshotをdispatch可能にせず、同plan replayはno-op、別digestはConflictです。V1 snapshotを破壊せずrollback artifactとして保持しますが、V2 activation後にV1 mutable ownerを再開しません。

### SD-PER-EXE-009 — ExecutionSnapshotV2ActivationUoW

dispatch/admission barrier、V1 snapshot、migration plan、V2 snapshot、activation Event、schema markerを原子的にcommitします。crash前commitはV1Active、commit後はV2Activeのどちらかだけを復元します。outbox送信をmigration中に行わず、commit後は同じstable intent identityから再開します。

### SD-PRJ-EXE-001 — ExecutionV1CompatibilityView

V2内の全`InjectV1*` variantを、wrapper内のaccepted complete valueと元map keyへlosslessに投影します。resume request／commitはそれぞれ元の別mapへ戻し、relationを再構成しません。revocationは`source_v1_target_key`へ戻し、complete `SubjectRevocationRecord.target`とのexact一致を検証します。AcousticSessionSubject、AcousticSession/Occurrence revocation target、Acoustic lease/custody/extensionを含むrecordはrecord全体を`UnsupportedExecutionSchemaV2Variant`として拒否し、V1 recordへ部分投影しません。

### SD-PRF-EXE-001 — ExecutionV1V2RoundTripProofContract

固定V1 snapshot fixtureを少なくとも次の六組で作り、`projectV1(migrateV2(v1)) == v1`をserialized tag、全field、map key、store digestまで比較します。

1. active Graph、AwaitingClaim／Started Occurrence、active Attempt、NamedInterval lease、pending Guard。
2. Succeeded／Failed／Cancelled相当のterminal resultとreleased lease。
3. subject／lineage revocationとRevoked Occurrence。V2の`RevocationId`から元V1 target keyをexact復元する。
4. OutcomeUnknown attempt、Active RecoveryCustody、TransferredToRecoveryCustody／Quarantined lease、StillUnknown reconciliation。
5. `RecoveryPending`、`ReplacementRegistered`、`Claimed`を含むresume requestと、存在する場合の別map resume commit／replacement occurrence／lineage relation。
6. terminal resume、reconciled custody、複数result IDs、pending durable intent、inbox／outbox identityを含む混合集合。

各fixtureはmigration中にdispatch、query、cancel、lease releaseを一件も公開しないことも検証します。欠落field、別key、wrapperからの再構成、revocation collision、request/commit統合、Graph内Occurrence lifecycle複製をnegative fixtureとして拒否します。このProofはcontract test入力であり、実migrationのpassingやrelease readinessを主張しません。

### SD-FAIL-EXE-001 — ExecutionV2CompatibilityFailure

```text
ExecutionV2CompatibilityFailure =
  SnapshotMigrationConflict | UnsupportedV1Variant |
  V1RecordIdentityDrift | PendingOutboxIdentityDrift |
  V1RoundTripFieldDrift | V1ResumeRelationDrift |
  V1RevocationIdCollision | V1RevocationTargetDrift |
  V2RecordTypeMismatch | V2MapKeyIdentityMismatch |
  AcousticSubjectIdentityMismatch | V1PartialProjectionBlocked |
  RuntimeDoesNotSupportExecutionV2 |
  AcousticVariantSentToV1Adapter |
  DowngradeBlockedByV2Snapshot |
  DowngradeBlockedByAcousticRecord
```

## Rollout, recovery, and downgrade

Acoustic admissionは、V2 snapshot activation、V2-compatible runtime readiness、Acoustic source/profile/policy readinessを同じadmission viewで確認した後だけ許可します。V1 finite Conversation／Camera等はV2上でも`InjectV1`として継続し、外部schemaを変更しません。

V2 activation前crashはV1から再開し、activation後crashはconcrete V2 recordから再開します。Acoustic cancelは`ExecutionRevocationTargetV2`のexact AcousticSession/Occurrence target、recoveryは同じ四field subjectのRecoveryCustodyRecordV2へだけ接続し、別generation/sessionのleaseをreleaseしません。migration自体は外部Effectを作らず、既存V1 OutcomeUnknown custodyはInjectV1 identityを保ちます。

V2 snapshot、Acoustic subject、Acoustic payload、Acoustic Graph extension recordのいずれかが存在する状態からV1 runtimeへdowngradeしません。rollbackには、Acoustic admission前かつV2 activation transactionを取り消せる明示的deployment window、または全V2 workをterminal化してOwner承認済みの別migration契約が必要です。本trancheは後者を設計・承認したと主張しません。

process、storage engine、serialization format、deployment commandは未決です。migration contractはDomain State ownerをprocessへ移しません。
