# Execution Revision 3 canonical contract

Execution Revision 3（R3）はYatagarasu 2内部のExecution契約改訂です。製品`Yatagarasu 3`ではありません。
accepted V1/V2のDesign ID、Version、definition、Approval setを変更せず、active V2を完全値として包む
new versioned/superseding contractです。この文書のdefinitionは`TR-WP01-PER-GRAPH-001`のreview-pendingであり、
accepted昇格、production readiness、passing proofを表しません。

## Schema、State、閉じたtopology

### SD-MOD-EXE-006 — ExecutionContractR3

```text
ExecutionContractRevision = R3
ExecutionSubjectR3 = InjectV2Subject { source_key, complete_value: ExecutionSubjectRefV2 }
PlannedPayloadR3 = InjectV2Planned { source_key, complete_value: PlannedPayloadV2 }
DispatchPayloadR3 = InjectV2Dispatch { source_key, complete_value: DispatchPayloadV2 }
ResultPayloadR3 = InjectV2Result { source_key, complete_value: ResultPayloadV2 }
```

R3 release語彙はcompile時に閉じたsumです。runtime plugin、文字列catalog、登録順resolverを持ちません。
V2値はtag、未知fieldを含むcomplete serialized valueとsource keyをlosslessに包み、製品、transport、process、
ProviderをCoreへ漏らしません。

### SD-MOD-EXE-007 — ResourceConflictAlgebraR3

```text
PhysicalResourceIdentityR3 { resource_class, logical_scope }
ResourceCapacityEvidenceR3 {
  evidence_id, physical_identity, profile_id, profile_version,
  mode_support, shared_capacity: PositiveQuantity, unit,
  source: PinnedConfigurationRevision | CapabilityProfileRevision,
  source_revision, canonical_digest
}
ResourceClaimR3 =
  AcquireExclusive { physical_identity, evidence_ref, quantity: ExactlyOne } |
  AcquireShared { physical_identity, evidence_ref, quantity: PositiveQuantity } |
  ContinueNamedInterval {
    physical_identity, evidence_ref, existing_lease_id, mode, quantity,
    named_interval_id, holder_subject, holder_fact_id,
    expected_lease_use_count, next_lease_use_count
  } |
  RecoveryPrivileged {
    physical_identity, custody_id, original_lease_ids: NonEmptySet<ResourceLeaseId>,
    permission: Query | Cancel | Reconcile, target_operation_id
  }
ResourceClaimSetR3 =
  InjectedV2Claims { complete_value: List<ResourceClaimV2> } |
  NativeR3Claims { claims: NonEmptyMap<PhysicalResourceIdentityR3, ResourceClaimR3> }
```

物理競合identityは`resource_class+logical_scope`だけです。profile/versionはcapacity/modeの証拠であってidentityでは
ありません。同じ物理identityを異なるprofile/version/evidenceでclaimしたcandidateは別resourceとして並行させず
`CapacityProfileMismatch`で拒否します。同じoccurrenceの同一physical identity重複も暗黙合算せず拒否します。

ExclusiveはExclusive/Sharedと非互換です。Sharedは同一evidence/version/unitで、active occupancy quantityとcandidate
quantityの和がpinned capacity以下の場合だけ互換です。capacityはExecutionが推測せず、ConfigurationまたはCapability
Profileのpin済みrevisionだけをsourceにします。zero、negative、overflow、missing/stale evidenceを拒否します。

`ContinueNamedInterval`はexact lease、physical identity、evidence、mode、quantity、interval、holder subject、owner-issued
holder fact、current use countが一致し、`next=current+1`のときだけ既存capacityを継続します。同じcontinuation identity replayは
use countを増やさないno-op、別holder/fact/countはConflictです。named intervalのterminal owner Eventと全holder terminalだけが
lease releaseを許可し、途中holder完了、単一consumer完了、replayでは解放しません。`RecoveryPrivileged`はexact custodyが所有する全original lease、
target operation、Query/Cancel/Reconcile permissionを照合し、通常capacityを新規取得しません。一occurrenceのclaimは
all-or-noneです。resource claimはadmissionだけでdependency、FIFO、priority、意味順序を作りません。

`InjectedV2Claims`はV2で合法なemptyをそのまま保持します。R3-nativeの新規dispatch candidateだけは
`NativeR3Claims`かつnon-emptyを要求します。この段階別不変条件をmigration recordへ遡及適用しません。

### SD-MOD-EXE-008 — ClosedEffectTopologyR3

```text
OccurrenceDependencyEdgeR3 { producer_occurrence_id, consumer_occurrence_id }
GuardExprR3 = All(NonEmptyList<GuardExprR3>) |
  Any(NonEmptyList<GuardExprR3>) |
  DependencyTerminal(EffectOccurrenceId) |
  GuardFactSatisfied(GuardFactId) |
  SubjectNotRevoked(ExecutionSubjectR3)
GuardFactDeclarationR3 {
  fact_id, graph_id, consumer_occurrence_ids: NonEmptySet<EffectOccurrenceId>,
  issuer: OwnerContextEvent { owner_context_id, owner_event_kind, issuer_revision },
  source: OccurrenceProduced { producer_occurrence_id } |
    ExternalObservationProduced { stable_operation_id } |
    OwnerStateDerived { source_state_revision }
}
GuardFactStatusR3 = Declared | Pending | Satisfied | Failed | Revoked | OutcomeUnknown
GraphTopologyR3 {
  graph_id, subject, initial_declaration,
  extensions: OrderedMap<GraphExtensionId, ImmutableGraphExtensionR3>,
  effective_digest
}
```

initialとextensionはimmutable declarationです。effective topologyは同一graph/subject、連続するprior/resulting digestを
持つinitial+extensionsのunionです。extensionは新しいoccurrenceだけをconsumerとして追加でき、既存occurrenceをproducer
として参照できます。既登録occurrenceへのdependency、`DependencyTerminal`、guard consumer、resource claim、deadline、
payload、issuer/sourceの追加・変更は禁止です。特にAdmitted/Claimed/Dispatched後の前提を遡及変更しません。

cycle graphはexplicit dependency edge、全`DependencyTerminal(producer)`→consumer、OccurrenceProduced factのproducer→全consumer
を同じdirected graphへ展開します。self edge、consumer descendantをproducerにするguard、別Graph/unknown consumerを拒否します。
External/OwnerState sourceは架空のoccurrence edgeを作りません。extension順はdigest chain再構成順でsemantic orderではありません。

canonical digestはfield順、sum tag、length prefix、integer width、Unicode normalization、map/set sortを固定する
`ExecutionR3CanonicalEncoding-v1`のbytesへ衝突耐性hashを適用します。algorithm/version/domain separatorもdigest identityの
一部です。collisionまたは異encoding同digestの証拠は`DigestCollisionQuarantined`で処理し、同値replayにしません。

### SD-MOD-EXE-009 — DispatchDeliveryContractR3

```text
DispatchIdempotencyClassR3 =
  IdempotentByStableOperation |
  ReconcileBeforeRepeat |
  NonIdempotentNoBlindRepeat
DispatchDeliveryStatusR3 = CommittedUnpublished |
  PublishAttemptedUnknown | PublishedAwaitingTransportAck | TransportAcknowledged
DispatchPublicationResultR3 = DefinitelyNotPublished | TransportAcknowledged |
  PublishFailedDefinitelyNotSent | PublishOutcomeUnknown
DispatchCapabilityEvidenceR3 {
  evidence_id, capability_profile_id, profile_version, source_owner,
  idempotency_class, stable_operation_namespace, effective_revision,
  canonical_digest
}
```

delivery statusはoutbox transport custodyだけを表し、Occurrence/Attemptの外部実行success/failure/terminalを表しません。
`TransportAcknowledged`後もexecution lifecycleはresult Eventが来るまで独立です。Idempotentはexact stable operationだけ再publish可、
ReconcileBeforeRepeatはQuery/Reconcileの確定後だけ、NonIdempotentはunknown後のblind resendを禁止しcustodyへ移します。
別intent、別operation、payload変更による再送は全classで禁止です。
idempotency classはtrusted Configuration/Capability Profile ownerがversioned evidenceとして発行し、dispatch claim時にpinします。
Adapter、transport、Provider、LLM proposalの自己申告は入力にできません。claimからpublish/recovery決定までevidence revision/digestを
CASし、racing profile変更は旧attemptのclassを変更せず、新attemptだけがnew evidenceを使用します。

### SD-MOD-EXE-010 — MigrationControlR3

```text
MigrationControlR3 =
  V2Active { control_revision } |
  PauseRequested { command_id, expected_v2_revision } |
  V2PausedAtCut { cut, sealed_watermarks, source_digest } |
  CandidateValidated { cut, candidate_digest, mapping_digest } |
  RetrySameCut { cut, retry_generation, failure } |
  R3Active { activation_event_id, first_unapplied_sequence }
MigrationActionR3 = RequestPause | SealPausedCut | ValidateCandidate |
  RetryCandidate | AbortPause | ActivateR3
```

closed edgeは次の表だけです。Event `resulting_control`も表のvariant名をexactに用います。

| Prior | Action / Decision | Resulting control |
| --- | --- | --- |
| `V2Active` | `RequestPause / PauseRequested` | `PauseRequested` |
| `PauseRequested` | `SealPausedCut / PausedAtCut` | `V2PausedAtCut` |
| `PauseRequested` | `AbortPause / AbortToV2Active` | `V2Active` |
| `V2PausedAtCut` | `ValidateCandidate / CandidateIsValid` | `CandidateValidated` |
| `V2PausedAtCut` | `RetryCandidate / RetryAtSameCut` | `RetrySameCut` |
| `V2PausedAtCut` | `AbortPause / AbortToV2Active` | `V2Active` |
| `RetrySameCut` | `ValidateCandidate / CandidateIsValid` | `CandidateValidated` |
| `RetrySameCut` | `RetryCandidate / RetryAtSameCut` | `RetrySameCut`（generation+1） |
| `RetrySameCut` | `AbortPause / AbortToV2Active` | `V2Active` |
| `CandidateValidated` | `ActivateR3 / Activate` | `R3Active` |
| `CandidateValidated` | `RetryCandidate / RetryAtSameCut` | `RetrySameCut` |
| `CandidateValidated` | `AbortPause / AbortToV2Active` | `V2Active` |

上記以外のstate/action/result tripleは構築不能です。`AbortPause`はEventにabort reason/resume cursorを持ち、state名を
増やしません。各stateはreducer/admission/ingress/apply cursor権限を一意に定め、`R3Active`からoutgoing edgeはありません。

### SD-STA-EXE-003 — ExecutionStateR3

```text
InjectedV2RecordR3<T> { source_store, source_key, complete_value: T }
ExecutionStateR3 {
  revision: R3, state_revision,
  v2_audit_injection: {
    execution_lineages, graphs, occurrences, attempts, resource_leases,
    recovery_custodies, guard_facts, checkpoint_resume_requests, resume_commits,
    revocations, migration_control, v1_compatibility_receipts,
    acoustic_graph_extensions, result_ingress, result_inbox, dispatch_outbox
  }: Map<SourceKey, InjectedV2RecordR3<CompleteV2Value>>,
  v2_operational_mapping: Map<V2SourceIdentity, R3OperationalIdentity>,
  graphs: Map<GraphId, GraphTopologyR3>,
  occurrences: Map<EffectOccurrenceId, OccurrenceRecordR3>,
  attempts: Map<DispatchAttemptId, DispatchAttemptR3>,
  leases: Map<ResourceLeaseId, ResourceLeaseR3>,
  resource_occupancy: Map<PhysicalResourceIdentityR3, ResourceOccupancyR3>,
  guard_facts, revocations, recovery_custodies,
  result_inbox, dispatch_outbox, migration_control
}
ResourceOccupancyR3 {
  physical_identity, occupancy_revision, capacity_evidence_ref,
  active_lease_ids, exclusive_holder?, shared_quantity, custody_ids
}
OccurrenceRecordR3 {
  occurrence_id, graph_id, subject, origin: InjectedV2 | NativeR3,
  planned_effect, dependencies, guard, resource_claim_set, deadline_spec?,
  lifecycle, active_attempt_id?, terminal_result_ref?
}
DispatchAttemptR3 {
  attempt_id, occurrence_id, attempt_generation, binding_use,
  immutable_dispatch_effect,
  dispatch_capability_evidence_ref, dispatch_capability_profile_version,
  dispatch_capability_evidence_digest, idempotency_class, stable_adapter_operation_id,
  dispatch_intent_id, lease_ids, lifecycle
}
ResourceLeaseR3 {
  lease_id, occurrence_id, attempt_id, complete_claim,
  named_interval_id?, lease_use_count, holders: Map<HolderSubject, HolderFactId>,
  terminal_holder_ids, custody_id?, lifecycle
}
RecoveryCustodyR3 {
  custody_id, occurrence_id, attempt_id, attempt_generation,
  stable_operation_id, all_lease_ids, allowed_actions, lifecycle
}
```

各V2 store/valueはsource store/key/tag/全fieldをaudit/compat用`InjectedV2RecordR3`へ一対一で保存します。lineage、resume request/commit、
V1 compatibility receipt、attempt `binding_use`、named interval/holder fact、guard `Failed`、empty claims/leasesを含み、
normalize、merge、splitしません。V2 injected attemptはempty lease set可、R3-native committed dispatchはnon-emptyです。

audit injectionはmutable lifecycleを持たずdispatch/readiness/result適用のsourceになりません。active/pending V2 Graph、Occurrence、
attempt、lease、guard、custody、revocation、resume、inbox/outboxは`v2_operational_mapping`でexact一つのR3 operational recordへ変換し、
source identityを保持します。一つのV2 identityに複数R3 identity、audit recordとoperational recordの二重reducer、unmapped pending workを
拒否します。V2 active leaseはcanonical physical identityとtrusted V2 profile/config revisionからcapacity evidenceを作り、
`resource_occupancy`へactive quantity/exclusive holder/custodyをmaterializeします。R3-native claimはこのoccupancyと同じalgebra/CASで競合し、
migration leaseを予約外・別key・無容量扱いしません。evidenceを一意に導出できないactive V2 leaseはactivationを拒否します。
active V2 outbox/attemptもtrusted V2 binding/profile revisionからexact dispatch capability evidence ref/version/digestへ対応付け、
idempotency classを現在profileから再推測しません。一意にpinできないpending outboxはactivationを拒否します。

Occurrence lifecycleは`occurrences`、attemptは`attempts`、lease/occupancy/custody/outboxはそれぞれのmapが唯一ownerです。
Graph/Projectionへ複製ownerを置きません。一Occurrenceのactive attemptは最大一つ、同値Effectも別Occurrenceです。
全R3 stateのownerは`SD-CTX-EXE-001`だけです。

## Command、Event、Rule、Transition

### SD-CMD-EXE-001 — CancelExecutionRequestedR3

```text
CancelExecutionRequestedR3 {
  command_id, requester_subject, reason,
  target: ExactAttempt { occurrence_id, attempt_id, attempt_generation,
    stable_operation_id, dispatch_intent_id } |
    ExactUndispatchedOccurrence { occurrence_id, expected_occurrence_revision },
  expected_execution_revision, requested_actions: Revoke | Cancel | QueryThenReconcile
}
```

曖昧なcurrent/latest target、外部停止成功の仮定、adapter直接mutationを許しません。

### SD-CMD-EXE-002 — AdvanceExecutionMigrationR3

```text
AdvanceExecutionMigrationR3 {
  command_id, action: MigrationActionR3, expected_control_revision,
  expected_source_revision, expected_cut?, expected_candidate_digest?, reason?
}
```

各actionは`MigrationControlR3`のexact一状態だけをtargetとし、restart時も新command identityを推測生成しません。

### SD-EVT-EXE-012 — ExecutionTopologyCommittedR3

initial/extension identity、prior/resulting canonical digest、added occurrences/edges/guards/resources、source owner Events、
expected/resulting revisionを固定するowner Eventです。ready、claim、dispatch、外部成功を意味しません。

### SD-EVT-EXE-013 — DispatchClaimCommittedR3

exact occurrence/attempt/generation、全lease、各physical occupancy expected/resulting revision、immutable Effect digest、dispatch
capability evidence ref/profile version/digestとidempotency class、stable operation/intent/outbox identity、expected/resulting
occurrence revisionを固定します。外部送信を意味しません。

### SD-EVT-EXE-014 — ExecutionDeadlineResolvedR3

```text
ExecutionDeadlineResolvedR3 {
  deadline_id, deadline_occurrence_id, deadline_attempt_id,
  deadline_attempt_generation, deadline_timer_operation_id,
  target_occurrence_id, target_attempt_id, target_attempt_generation,
  target_stable_operation_id, result_event_id,
  result: DeadlineElapsed | TimerDefinitelyNotApplied | TimerOutcomeUnknown,
  winner: TargetTerminal | DeadlineWon | RecoveryRequired,
  clock_domain, timer_epoch, evidence_refs
}
```

完全相関しないdeadlineはConflictです。Elapsedはtarget外部作用の失敗、停止、未適用を意味しません。

### SD-EVT-EXE-015 — ExecutionR3Activated

exact source V2 revision/digest、sealed ingress/inbox/outbox watermarks/digests、migration plan/destination digest、全store count、
activation control revisionを持つowner Eventです。新dispatchまたはpending成功を意味しません。

### SD-EVT-EXE-016 — DispatchPublicationResolvedR3

intent、occurrence、attempt/generation、stable operation、idempotency class、publisher delivery-attempt ID、prior/resulting delivery
status、typed publication result、evidenceを完全相関します。transport ackをexecution terminalへ昇格しません。

### SD-EVT-EXE-017 — ExecutionCancellationResolvedR3

cancel command、target occurrence/attempt/generation/operation/intent、custody、全lease IDs、adapter cancel/query operation identity、
result `ConfirmedStopped | AlreadyTerminal | Unsupported | FailedDefinitelyNotApplied | OutcomeUnknown`、evidenceを完全相関します。

### SD-EVT-EXE-018 — ExecutionMigrationAdvancedR3

migration command/action、prior/resulting closed control、source/cut/candidate/mapping digest、sealed watermarks、reducer authority、
apply cursor、retry generation、abort/activation evidenceを完全相関するExecution owner Eventです。pauseやcandidate validationを
activation successへ昇格しません。

### SD-RUL-EXE-010 — ValidateClosedTopologyR3

initial/extensionをpureに検証し、identity、consumer refs、全三種類のcausal edge、issuer/source/status、claim algebra、
canonical digest chain、acyclicity、既存consumer不変が成立する場合だけ`AcceptTopology`を返します。一件でも不正なら全体拒否です。

### SD-RUL-EXE-011 — DetermineReadyOccurrencesR3

effective topology、occurrence lifecycle、dependency terminal set、guard fact snapshot、revocation snapshotだけをinputにし、全dependency
terminal、closed guard true、subject activeなら`SemanticallyReady`を返すpure Ruleです。capacity、lease、occupancy、scheduler順をinputに
含めません。resource admissionは別の`SD-RUL-EXE-012`だけが決めます。

### SD-RUL-EXE-012 — DecideAtomicDispatchClaimR3

SemanticallyReady occurrence、native/injected stage、exact occurrence revision、next attempt/generation、Behavior authorization/
`binding_use`、全physical identity occupancy revisionまたはcompare-not-exists token、capacity evidence revision、dispatch capability
evidence ref/profile version/digest、stable IDsをpureに評価し、
`ClaimAll | ResourceBlocked | Reject`を返します。全keysをcanonical順にvalidateするphantom-safe multi-key CAS predicateを生成します。
同一identity同時claimは一winner、互いに非競合なkey集合はglobal state revisionを共有せず並行commitできます。

### SD-RUL-EXE-013 — ClassifyExecutionDeadlineR3

deadline/target双方のoccurrence、attempt、generation、operation、deadline ID、timer epoch、terminal inbox winner、cancel/custodyをpureに
照合し、`TargetTerminalWins | DeadlineWinsRequireRecovery | TimerFailure | TimerUnknownRequireRecovery | Duplicate | Conflict`のexact一つを
返します。late resultを別attemptへ付け替えません。

### SD-RUL-EXE-014 — ValidateV2ToR3Migration

active V2の全store/key/valueとtyped migration controlをpureに検証します。lineage、graph、occurrence、attempt、`binding_use`、
empty/nonempty claim/lease、named interval/holder fact、guard全variant（`Failed`含む）、extension、revocation、custody、resume request/commit、
V1 receipt、migration control、ingress/inbox/outboxを各exact一つのinjective R3 recordへ写し、loss/add/merge/split/identity変更を拒否します。

### SD-RUL-EXE-015 — DecideDispatchRecoveryR3

publication result、idempotency class、outbox prior status、exact operation、custodyをpureに評価します。Idempotentだけexact stable
operation replay、ReconcileBeforeRepeatはQuery/Reconcile確定後だけrepeat、NonIdempotent unknownは`RequireRecoveryCustody`だけを返します。
Transport ackはoutbox deliveryだけを進め、execution terminalを返しません。

### SD-RUL-EXE-016 — DecideExecutionCancellationR3

exact cancel target、occurrence/attempt/revocation/outbox/inbox/custody/all leases snapshotをpureに評価します。undispatchedはdurable revoke、
in-flightは全leaseを一custodyへ移したCancel/Query/Reconcile Effect、terminalはno-op、mismatchはConflictを返します。
OutcomeUnknownをStoppedへ昇格しません。

### SD-RUL-EXE-017 — DecideExecutionMigrationR3

closed control、exact migration Command、V2 source/cut、ingress/outbox cursors、candidate validation、crash markerをpureに評価し、
`Pause | Validate | Retry | Abort | Activate | RestorePriorState | Duplicate | Conflict`のexact一つを返します。crash restoreはdurable
prior controlとsame command/event identityだけから決まり、暗黙pause/resume/activateを返しません。

### SD-RUL-EXE-018 — MaterializeV2OperationalStateR3

complete V2 snapshotとaudit injectionから、全active/pending source identityをexact一つのR3 graph/occurrence/attempt/lease/guard/
custody/resume/inbox/outbox identityへpureに写します。lifecycle、binding_use、generation、winner、outbox statusを維持し、active leasesを
physical identity/capacity evidence/occupancyへ写します。bijection、one mutable representation、occupancy conservationが成立しなければ
`RejectMigration`です。terminal historyはaudit-onlyでもよいですがactive/pending recordをaudit-onlyにできません。
pending attempt/outboxはtrusted dispatch capability evidence ref/version/digestも保存し、mapping conservationへ含めます。

### SD-RUL-EXE-019 — DecideNamedIntervalLeaseUseR3

exact named interval、lease、holder/fact、terminal set、expected use count、replay identityをpureに評価し、
`ContinueOnce | ReplayNoOp | ReleaseAfterAllTerminal | Conflict | KeepActive`を返します。holder追加はuse countをexact一増やし、
全holder terminal前のreleaseと同continuation replayによる二重増加を拒否します。

### SD-GPH-EXE-001 — ExecutionRecoveryGraphR3

```text
OutcomeUnknown source occurrence
  -> Query recovery occurrence [RecoveryPrivileged(Query)]
  -> Cancel recovery occurrence [RecoveryPrivileged(Cancel)] when policy permits
  -> Reconcile recovery occurrence [RecoveryPrivileged(Reconcile)]
  -> typed owner result / custody remains quarantined
```

各recovery actionはnormal R3 topologyへ新Occurrenceとして登録され、dependency/guard/cycle validation、semantic readiness、atomic claim、
attempt/generation、all leases、immutable Effect、trusted capability evidence、stable intent/outboxを通常UoWで通ります。
RecoveryPrivilegedはcapacity bypassではなくexact custody authorizationです。Application/AdapterがimperativeにEffect送信する経路はありません。

### SD-TRN-EXE-019 — RegisterOrExtendTopologyR3

accepted topology Eventだけをexpected graph revisionへ適用し、initial/extensionと全new occurrence/guardをatomic登録します。
既存occurrenceは変更せず、attempt/lease/outboxを作りません。同identity/digest replayはno-op、異payloadはConflictです。

### SD-TRN-EXE-020 — ApplyAtomicDispatchClaimR3

ClaimAll/Eventだけからoccurrence claim、attempt/generation、全lease、全occupancy、immutable Effect、stable intent/outbox
`CommittedUnpublished`とpinned dispatch capability evidence tupleを一度適用します。ContinueNamedIntervalを含む場合は
`SD-RUL-EXE-019.ContinueOnce|ReplayNoOp`と`SD-TRN-EXE-026`を同compositionへ含めます。

### SD-TRN-EXE-021 — ApplyResultOrDeadlineR3

durable inbox winnerと完全相関したnormal/deadline resultだけを一度適用します。一terminal winnerを維持し、Failure、deadline、
OutcomeUnknownをtyped lifecycle/custodyへ進めます。named holder terminal時は`SD-RUL-EXE-019`と
`SD-TRN-EXE-026.KeepActive|ReleaseAfterAllTerminal`を同compositionへ含めます。

### SD-TRN-EXE-022 — ActivateExecutionR3

`SD-TRN-EXE-025`がclosed edge `CandidateValidated + ActivateR3 → R3Active`へ進める同じactivation compositionの中でのみ、
candidate operational maps/occupancy、audit injection、schema marker、reducer handoffをmaterializeします。単独呼出し可能な
activation transitionではありません。V2 snapshotはimmutable audit artifactで、R3後にV2 ownerを再開しません。

### SD-TRN-EXE-023 — ApplyDispatchPublicationR3

Publication EventとRecovery Decisionだけからoutbox delivery statusを単調適用し、unknown時はexact custodyを作ります。
Occurrence/Attempt terminal、lease release、別send identityを変更しません。同event replayはno-op、相関/payload差はConflictです。

### SD-TRN-EXE-024 — ApplyExecutionCancellationR3

Cancellation Decision/Eventだけからundispatched revocation、descendant revocation、またはin-flight全leaseの同一custody移管をatomic適用します。
ConfirmedStopped/DefinitelyNotApplied evidenceなしにleaseをreleaseせず、subset custody、generation跨ぎ、二重cancel winnerを拒否します。

### SD-TRN-EXE-025 — ApplyExecutionMigrationR3

`SD-MOD-EXE-010`表のprior/action/result、`SD-RUL-EXE-017` Decision、`SD-EVT-EXE-018`だけからclosed controlをexact一edge
進めます。PauseRequested→V2PausedAtCutを含むpause/seal、validation、retry、abort、activation/crash restoreを適用します。
activation edgeだけは`SD-TRN-EXE-022` materializationと同じUoWで、片方だけをcommitできません。

### SD-TRN-EXE-026 — ApplyNamedIntervalLeaseUseR3

`SD-RUL-EXE-019` Decision、expected lease revision/use count、continuationまたはholder-terminal Event identityだけからholder map、
terminal holder set、use count、lease/occupancy lifecycleを変更します。ContinueOnceはcount+1、ReplayNoOpは無変更、KeepActiveは
lease維持、ReleaseAfterAllTerminalだけがlease/occupancyを同時releaseします。単独commitせずdispatch claimまたはresult inbox
compositionに必ず含まれます。

## Persistence、migration、proof

### SD-PER-EXE-011 — DurableTopologyR3UoW

Behavior owner Event、expected graph revision、topology validation/Event/Transitionを全CASします。crash/replayはsame topology identity/
canonical digestから全体を再開し、occurrenceだけ、guardだけ、extensionだけを残しません。

### SD-PER-EXE-012 — DurableDispatchClaimR3UoW

occurrence expected revision、各physical keyのoccupancy revisionまたはcompare-not-exists、capacity evidence revision、dispatch
capability evidence ref/profile version/digest、authorization/binding view、stable intent key absenceを一transaction predicateにします。
storage contractはpredicate range/key lockingまたはserializable
index validationでphantom insertも検出します。attempt/generation、全lease/occupancy、immutable Effect、stable operation/intent/outboxを
一UoWでcommitし、commit後だけpublisherへ可視化します。global revision CASで非競合keysを直列化しません。

### SD-PER-EXE-013 — DurableResultAndDeadlineInboxR3

```text
ResultInboxKeyR3 {
  adapter_identity, stable_adapter_operation_id,
  occurrence_id, attempt_id, attempt_generation, result_phase
}
```

commit後だけackします。同key同payload/correlationはno-op、異payloadはwinner不変のConflict quarantineです。normal/deadlineは同じ
terminal winner CASへ参加し、inbox、occurrence/attempt、guard、全lease/occupancy/custodyを全体なし/ありでcommitします。
`result_event_id`、delivery attempt ID、transport envelope IDはaudit metadataでdedupe keyに含めません。別event IDのsame canonical
delivery identity/same payloadはreplay no-op、different payload/correlationはquarantineです。

### SD-PER-EXE-014 — V2ToR3ActivationUoW

`SD-MOD-EXE-010`のclosed control、`SD-CMD-EXE-002`、`SD-EVT-EXE-018`、`SD-RUL-EXE-017`、
`SD-TRN-EXE-025`を一UoWでCASします。

```text
V2Active --RequestPause--> PauseRequested --SealPausedCut--> V2PausedAtCut
V2PausedAtCut | RetrySameCut --ValidateCandidate--> CandidateValidated
V2PausedAtCut | RetrySameCut | CandidateValidated --RetryCandidate--> RetrySameCut
PauseRequested | V2PausedAtCut | RetrySameCut | CandidateValidated --AbortPause--> V2Active
CandidateValidated --ActivateR3--> R3Active
```

各transitionはcommand/event、source/destination revision、sealed watermarks、attempt number、failure reasonをdurable記録します。
pause中もschema-neutral ingressを受けcut後tailへ封印します。activation前crashはtyped stateからsame cutをretryまたはexplicit abortして
V2へ戻り、activation commit後crashはR3 activeとsame first-unapplied sequenceから再開します。hidden pause、implicit resume、dual owner、
barrier後V2 dispatch、R3→V2 downgradeを拒否します。

activation compositionはsource/cut/control revisions、sealed cursorsに加え、`SD-RUL-EXE-014` injection validation、
`SD-RUL-EXE-018` accepted materialization Decision、全audit injection、source→operational maps、Graph/Occurrence/attempt/outbox、
active lease capacity evidence、pending dispatch capability evidence、resource occupancy、schema marker、`SD-EVT-EXE-015/018`、
`SD-TRN-EXE-022/025`、reducer handoffを一つのCAS/commitへ置きます。validation-only、map-only、occupancy-only、control-only、
activation-only commitを禁止し、一要素でもstale/invalidなら全体を変更しません。

### SD-PER-EXE-015 — DurableDispatchPublicationR3UoW

exact outbox status/intent/operation、pinned dispatch capability evidence ref/version/digestとidempotency class、publication EventをCASし、
delivery statusまたはcustodyを一度commitしてからackします。
publisher crash前後はclass別Ruleを再評価します。NonIdempotent/unknownはblind publishせずQuery/Reconcile custodyだけ、Idempotentも同じ
stable operation以外を送れません。TransportAcknowledgedとexecution terminalは別field/owner transitionなのでshadow/divergenceしません。

### SD-PER-EXE-016 — DurableCancellationR3UoW

cancel command inbox、exact target/revision/generation、revocation、outbox/result winner、全lease/occupancy、custodyと
`SD-GPH-EXE-001` recovery topology contributionを一CASでcommitします。cancel/query/reconcile Effectを直接送信せず、new recovery
Occurrenceが`SD-PER-EXE-011/012`の通常topology/claim UoWを通った後だけoutboxへ到達します。subset revoke/custody/release、
imperative bypass、custodyなしRecoveryPrivileged claimを拒否します。

### SD-PER-EXE-017 — DurableNamedIntervalLeaseUseR3UoW

ContinueNamedInterval claim時はoccurrence/attempt、exact lease revision/use count、holder fact、occupancy、全claim、Event、
`SD-RUL-EXE-019`、`SD-TRN-EXE-020/026`をdispatch claim UoWへ統合します。holder terminal時はdurable inbox winner、全holder
terminal snapshot、lease/use-count/occupancy、Event、`SD-RUL-EXE-019`、`SD-TRN-EXE-021/026`をresult UoWへ統合します。
同continuation replayはno-op、stale count/holder mismatchは全体Conflict、全holder terminal前のreleaseは全体rejectです。

### SD-PRJ-EXE-002 — ExecutionV2CompatibilityViewR3

各`InjectedV2RecordR3`をsource store/key/tag/complete valueへ逆投影します。R3-native variantは部分投影せず
`UnsupportedR3Variant`です。Projectionはread-only proofでState owner/dispatch sourceではありません。

### SD-PRF-EXE-002 — V2ToR3RoundTripProof

V2全storeの全variant/field fixtureで`projectV2(injectR3(v2)) == v2`をbyte-for-byte比較します。lineage、resume request/commit、
V1 receipt、binding_use、named interval/holder fact、Failed guard、empty claims/leases、native Acoustic initial+multiple extension、pending/
started/terminal attempt、custody、control、unapplied ingress/inbox、全outbox statusを含みます。pause/abort/retry/activate全crash stateと
barrier raceも検証します。

### SD-PRF-EXE-003 — ResourceAndDispatchProofR3

同physical identityの異profile/versionが競合すること、Exclusive/Shared、capacity境界、duplicate、多claim一件失敗、named continuation/
recovery privileged mismatch、same-key one winner、nonconflicting parallel、phantom insertをtable-drivenに検証します。さらにclaim/commit/
publish/ack/cancel全crash、idempotency三class、deadline/late resultでsubset lease、二intent、blind resend、意味edge生成がないことを検証します。
これはproof contractでありpassingを主張しません。

### SD-PRF-EXE-004 — ActiveV2OperationalizationProofR3

全active/pending V2 variant fixtureについてsource→operational identityが一対一、audit injectionがimmutable、mutable lifecycle ownerが
operational mapだけであることを検証します。V2 active Exclusive/Shared/named/custody leaseとracing R3-native claimを同occupancyへ載せ、
conflict、capacity conservation、profile mapping failure、restart replayを検証します。audit-only pending work、二重result apply、
lease reservation lossをnegative fixtureにします。

### SD-FAIL-EXE-002 — ExecutionR3Failure

```text
ExecutionR3Failure = TopologyCycle | SelfCausalGuard | UnknownConsumer |
  ExistingOccurrenceMutation | GuardIssuerMismatch | ResourceIdentityConflict |
  CapacityProfileMismatch | CapacityEvidenceStale | InvalidClaimQuantity |
  DuplicateOccurrenceResourceClaim | PartialClaimForbidden | OccupancyCASConflict |
  NamedIntervalUseConflict | PrematureNamedIntervalRelease |
  DispatchIdentityConflict | IdempotencyEvidenceConflict | BlindResendForbidden | DeliveryStatusConflict |
  ResultDeliveryIdentityConflict |
  DeadlineCorrelationConflict | CancellationCorrelationConflict |
  OutcomeUnknownCustodyRequired | CustodyLeaseSetMismatch |
  V2RecordLoss | V2RecordIdentityDrift | V2RoundTripDrift |
  V2OperationalMappingConflict | DualMutableRepresentation | OccupancyMaterializationConflict |
  MigrationControlConflict | MigrationBarrierConflict | DualExecutionOwner |
  DowngradeForbidden | CanonicalEncodingConflict | DigestCollisionQuarantined
```

## Ports、recovery、non-goals

dispatch/cancel/query/reconcile/timer Portはimmutable envelopeを受け、occurrence/attempt/generation/stable operation/intentを完全相関した
result Eventだけを返します。Adapter、publisher、timerはready、semantic completion、lease release、custody resolutionを決めません。
OutcomeUnknown、deadline、cancel、non-idempotent publish uncertaintyでは全claim leaseを同じcustodyへ移し、exact
`RecoveryPrivileged(Query|Cancel|Reconcile)`だけをadmitします。ownerのDefinitelyApplied/DefinitelyNotApplied/ConfirmedStoppedだけが
release候補、StillUnknownはQuarantinedです。subset解放、blind retry、通常claimによる横取りはありません。

未決: fairness/priority、具体capacity値、storage/transaction engine、process/IPC、timer製品、lease timeout数値。
non-goal: accepted V1/V2変更、Yatagarasu 3製品、runtime plugin、Behavior固有workflow、public UI、production実装、passing proof、commit。
