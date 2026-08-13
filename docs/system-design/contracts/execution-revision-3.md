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
V2PublicationFenceStatusR3 =
  ClaimedForSend { publisher_selection_id, publication_attempt_id } |
  DefinitelyNotSent { evidence_digest } |
  TransportAcked { transport_ack_digest } |
  OutcomeUnknownCustody { custody_id, recovery_operation_id? } |
  HandedOffPublication { r3_outbox_id, r3_custody_id? }
PublicationGenerationR3 = PositiveU64
PublicationClaimIdR3 { dispatch_intent_id, generation: PublicationGenerationR3 }
V2PublicationPortEnvelopeR3 {
  publication_claim_id: PublicationClaimIdR3, publication_generation,
  publisher_selection_id, publication_attempt_id,
  v2_outbox_id, v2_outbox_revision, dispatch_intent_id, stable_operation_id,
  dispatch_capability_evidence_ref, profile_version, evidence_digest,
  idempotency_class, immutable_payload_digest, fence_revision
}
V2PublicationPortResultR3 {
  publication_claim_id: PublicationClaimIdR3, publication_generation,
  publisher_selection_id, publication_attempt_id,
  dispatch_intent_id, stable_operation_id, result, evidence_digest
}
```

delivery statusはoutbox transport custodyだけを表し、Occurrence/Attemptの外部実行success/failure/terminalを表しません。
`TransportAcknowledged`後もexecution lifecycleはresult Eventが来るまで独立です。Idempotentはexact stable operationだけ再publish可、
ReconcileBeforeRepeatはQuery/Reconcileの確定後だけ、NonIdempotentはunknown後のblind resendを禁止しcustodyへ移します。
別intent、別operation、payload変更による再送は全classで禁止です。
idempotency classはtrusted Configuration/Capability Profile ownerがversioned evidenceとして発行し、dispatch claim時にpinします。
Adapter、transport、Provider、LLM proposalの自己申告は入力にできません。claimからpublish/recovery決定までevidence revision/digestを
CASし、racing profile変更は旧attemptのclassを変更せず、新attemptだけがnew evidenceを使用します。
V2 publication Portはdurable `ClaimedForSend` commit後の完全な`V2PublicationPortEnvelopeR3`だけを受け、同identityの
`V2PublicationPortResultR3`だけを返します。pre-readしたoutbox、claimなしintent、別publisher/attempt/evidenceでsendできません。

### SD-MOD-EXE-010 — MigrationControlR3

```text
MigrationAttemptPhaseR3 =
  PauseRequested { command_id, expected_v2_revision } |
  V2PausedAtCut { cut, sealed_watermarks, source_digest } |
  CandidateValidated { cut, candidate_digest, mapping_digest } |
  RetrySameCut { cut, retry_generation, failure } |
  Aborted { abort_event_id, v2_resume_cursor } |
  Activated { activation_event_id, r3_state_revision }
MigrationActionR3 = RequestPause | SealPausedCut | ValidateCandidate |
  RetryCandidate | AbortPause | ActivateR3
```

closed edgeは次の表だけです。Event `resulting_control`も表のvariant名をexactに用います。

| Prior | Action / Decision | Resulting control |
| --- | --- | --- |
| `Absent` | `RequestPause / PauseRequested` | `PauseRequested` |
| `PauseRequested` | `SealPausedCut / PausedAtCut` | `V2PausedAtCut` |
| `PauseRequested` | `AbortPause / AbortToV2CatchUp` | `Aborted` |
| `V2PausedAtCut` | `ValidateCandidate / CandidateIsValid` | `CandidateValidated` |
| `V2PausedAtCut` | `RetryCandidate / RetryAtSameCut` | `RetrySameCut` |
| `V2PausedAtCut` | `AbortPause / AbortToV2CatchUp` | `Aborted` |
| `RetrySameCut` | `ValidateCandidate / CandidateIsValid` | `CandidateValidated` |
| `RetrySameCut` | `RetryCandidate / RetryAtSameCut` | `RetrySameCut`（generation+1） |
| `RetrySameCut` | `AbortPause / AbortToV2CatchUp` | `Aborted` |
| `CandidateValidated` | `ActivateR3 / Activate` | `Activated` |
| `CandidateValidated` | `RetryCandidate / RetryAtSameCut` | `RetrySameCut` |
| `CandidateValidated` | `AbortPause / AbortToV2CatchUp` | `Aborted` |

上記以外のstate/action/result tripleは構築不能です。`AbortPause`はEventにabort reason/resume cursorを持ち、state名を
増やしません。`SD-STA-EXE-004`がmigration coordination phaseだけのsole ownerです。accepted V2 Stateはoperational data/tail/inbox/
apply cursorのsole owner、`SD-STA-EXE-005`はR3-migration用V2 phase/gate/apply authorizationのsole ownerで責務は重複しません。
Aborted/Activatedはterminalでoutgoing edgeを持ちません。

### SD-MOD-EXE-011 — OrderedResultCatchUpR3

```text
CatchUpReducerR3 = R3Reducer
OrderedResultCatchUpR3 =
  BarrierOpen { reducer, applied_sequence, applied_prefix_digest,
    observed_tail: CanonicalIngressTailSnapshotR3 } |
  CatchUpRequired { reducer, next_sequence, applied_prefix_digest,
    target_tail: CanonicalIngressTailSnapshotR3, dispatch_barrier: Closed }
```

このtypeはR3Active後だけmutableです。preactivationのpause、V2 authorization、abort catch-upは
`SD-MOD-EXE-012`だけが追加するV2-for-R3 operational controlを用い、R3 tail/inbox/gateを作りません。
ActivateR3はlatest V2 tupleから`R3Reducer/CatchUpRequired`を作ります。AbortPauseはaccepted V2 data ownerを維持し、
`SD-PER-EXE-019`のV2 reducer catch-upを用いるためR3 catch-upを作りません。
R3Active後のnew ingressはR3 canonical tailへappendし、target tailを単調追随します。
`applied_sequence == committed tail`かつprefix digest一致がCAS時点でも成立した時だけBarrierOpenです。
`target_tail`/`observed_tail`はcanonical tailから読んだsnapshot identityでmutable ownerではありません。唯一のtail ownerは
`ExecutionStateR3.canonical_ingress_tail`です。
R3Active後のadmission/dispatch gate唯一ownerは`result_catch_up`です。R3 pure authorizationは
`activation_marker is R3Active AND catch-up is BarrierOpen AND reducer is R3Reducer`だけがAllow、それ以外はDenyです。preactivationのauthorizationは
`SD-RUL-EXE-021`がnew V2-for-R3 gateから決め、R3 catch-up Ruleを併用しません。

| Phase | Mutable tail / inbox / gate / reducer owner |
| --- | --- |
| preactivation `V2RunningForR3` | accepted V2 State owns data; `SD-STA-EXE-005` view owns R3-migration authorization |
| `V2PauseRequestedForR3/V2PausedForR3` | accepted V2 State owns data; `SD-STA-EXE-005` gates dispatch/apply closed |
| `V2CatchingUpAfterAbortForR3` | accepted V2 State owns data/cursor; `SD-STA-EXE-005` gate remains closed; V2 reducer only |
| `AbortedToV2Running` | accepted V2 State owns data; new control gate open; V2 dispatch/apply authorized |
| atomic `ActivateR3` commit | exact `V2PausedForR3` tuple is CAS source; `HandedOffToR3` and R3 State commit together |
| postcommit `R3Active/CatchUpRequired` | R3 canonical tail/inbox/result_catch_up/PER-013/018 only; R3 reducer; gate closed |
| `R3Active/BarrierOpen` | R3 only; R3 reducer; dispatch/admission allowed |

### SD-MOD-EXE-012 — V2ForR3OperationalPauseContractR3

accepted `SD-MOD-EXE-004`のV1→V2 migration controlをactive V2→R3 pause/abortへ流用しません。本definitionはRevision 3だけが
追加するversioned extension contractで、accepted V2 Stateのrecord意味を変更せず、R3 migration中のV2 dispatch/apply authorization、
pause cut、abort catch-up、handoffだけを閉じます。

```text
V2ForR3OperationalViewR3 =
  V2RunningForR3 { extension_state_revision, publication_fence_revision,
    publication_claims_digest, source_v2_revision, tail, inbox_revision, apply_cursor } |
  V2PauseRequestedForR3 { migration_attempt_id, gate: Closed,
    apply: Stopped, pause_cursor, observed_tail } |
  V2PausedForR3 { migration_attempt_id, gate: Closed, apply: Stopped,
    cut, source_v2_revision, tail, inbox_revision, apply_cursor,
    sealed_prefix_digest, outbox_watermark } |
  V2CatchingUpAfterAbortForR3 { migration_attempt_id, gate: Closed,
    reducer: V2, abort_start_cursor, observed_tail } |
  AbortedToV2Running { migration_attempt_id, gate: Open,
    reducer: V2, applied_cursor, observed_tail } |
  HandedOffToR3 { migration_attempt_id, activation_event_id,
    source_v2_revision, handed_off_tail, handed_off_inbox_revision }
```

`V2RunningForR3`はdurable control recordがまだ無いactive V2 Stateから導くcanonical read viewです。他variantは
`SD-STA-EXE-005`のdurable recordです。tail/inbox/apply cursor値はaccepted V2 Stateのnon-authoritative snapshotであり、
そのownerを複製しません。extension gateとphaseだけを`SD-STA-EXE-005`が所有します。

closed edgeは次だけです。

| Prior view | Operation / Decision | Resulting view |
| --- | --- | --- |
| `V2RunningForR3` | `RequestPause / CloseV2ForR3Gates` | `V2PauseRequestedForR3` |
| `AbortedToV2Running` | new attempt `RequestPause / CloseV2ForR3Gates` | `V2PauseRequestedForR3` |
| `V2PauseRequestedForR3` | `SealPausedCut / SealExactV2Cut` | `V2PausedForR3` |
| `V2PauseRequestedForR3` | `AbortPause / StartV2AbortCatchUp` | `V2CatchingUpAfterAbortForR3` |
| `V2PausedForR3` | `AbortPause / StartV2AbortCatchUp` | `V2CatchingUpAfterAbortForR3` |
| `V2CatchingUpAfterAbortForR3` | `ApplyExactNextV2 / ApplyNextV2Winner` | `V2CatchingUpAfterAbortForR3` |
| `V2CatchingUpAfterAbortForR3` | `OpenV2AfterAbort / OpenAtExactTail` | `AbortedToV2Running` |
| `V2PausedForR3` | `ActivateR3 / HandOffExactV2Tuple` | `HandedOffToR3` |

candidate validation/retryは`SD-STA-EXE-004`だけを変更し、operational viewは`V2PausedForR3`のままです。
`HandedOffToR3`はterminalです。append-only ingressはhandoff前まで許可されますが、各appendはexact extension revisionとaccepted V2
tail revisionをCASします。dispatch/admissionは`V2RunningForR3|AbortedToV2Running`かつgate Openだけ、normal Domain applyは同variantだけ、
abort catch-up applyは`V2CatchingUpAfterAbortForR3`のexact-nextだけです。それ以外はdenyです。
RequestPauseは全latest head claimが`DefinitelyNotSent|TransportAcked|OutcomeUnknownCustody`のclosed statusである場合だけ進めます。
`ClaimedForSend`が一件でもあればpause/activateをdenyし、claimを消去・暗黙ackしません。Activateはclosed claim全件とaccepted V2 outboxの
exact revision/status/custodyとimmutable old-generation historyをR3へmaterializeし、各latest head claimだけを
`HandedOffPublication`へ閉じます。

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
  canonical_ingress_tail: CanonicalIngressTailR3,
  result_inbox, dispatch_outbox, activation_marker,
  result_catch_up: OrderedResultCatchUpR3
}
CanonicalIngressTailR3 {
  ingress_stream_id, last_sequence, prefix_digest, append_tail_revision
}
CanonicalIngressTailSnapshotR3 {
  ingress_stream_id, last_sequence, prefix_digest, append_tail_revision
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

このmutable operational StateはActivateR3 commit後だけ存在します。preactivation candidateはimmutable validation valueであり、
`SD-STA-EXE-004`のcoordination recordから参照されてもtail/inbox/gate/reducerをmutateできません。

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

### SD-STA-EXE-004 — ExecutionMigrationAttemptStateR3

```text
ExecutionMigrationAttemptRecordR3 {
  migration_attempt_id, attempt_generation, retry_generation,
  phase: MigrationAttemptPhaseR3,
  source_v2_control_revision, source_v2_control_digest,
  source_v2_gate_revision, source_v2_gate_digest,
  source_v2_tail_revision, source_v2_tail_sequence, source_v2_tail_digest,
  source_v2_inbox_revision, source_v2_inbox_winner_set_digest,
  candidate_digest?, operational_mapping_digest?,
  originating_command_id, latest_command_id, latest_event_id,
  attempt_revision
}
ExecutionMigrationAttemptStateR3 {
  attempts: Map<MigrationAttemptId, ExecutionMigrationAttemptRecordR3>
}
```

このStateはpreactivationからdurableですがmigration coordinationだけを所有します。V2 operational tail/inbox/gate/control/reducer、
R3 operational Stateのいずれも所有・複製しません。一attemptのmutable recordは一つ、terminal Aborted/Activated後はimmutableです。
State ownerは`SD-CTX-EXE-001`、mutationは`SD-TRN-EXE-025`だけです。

### SD-STA-EXE-005 — V2ForR3OperationalControlStateR3

```text
V2ForR3OperationalControlRecordR3 {
  control_id, migration_attempt_id, attempt_generation,
  phase: V2PauseRequestedForR3 | V2PausedForR3 |
    V2CatchingUpAfterAbortForR3 | AbortedToV2Running | HandedOffToR3,
  dispatch_admission_gate: Open | Closed,
  domain_apply_authorization: NormalV2 | Stopped | AbortCatchUpExactNext | HandedOff,
  source_v2_state_revision, source_v2_tail_revision,
  observed_tail_sequence, observed_tail_digest,
  source_v2_inbox_revision, observed_inbox_winner_set_digest,
  observed_apply_cursor_sequence, observed_apply_prefix_digest,
  cut?, abort_start_cursor?, activation_event_id?,
  latest_command_id, latest_event_id, control_revision
}
V2PublicationFenceClaimR3 {
  publication_claim_id: PublicationClaimIdR3, prior_claim_id?,
  publication_generation, v2_outbox_id, expected_v2_outbox_revision,
  dispatch_intent_id, stable_operation_id,
  dispatch_capability_evidence_ref, profile_version, evidence_digest,
  idempotency_class, immutable_payload_digest,
  publisher_selection_id, publication_attempt_id,
  status: V2PublicationFenceStatusR3,
  latest_event_id, claim_revision
}
V2PublicationGenerationHeadR3 {
  dispatch_intent_id, latest_generation, latest_claim_id,
  head_revision
}
V2ForR3OperationalControlStateR3 {
  state_revision, publication_fence_revision,
  active_control?: V2ForR3OperationalControlRecordR3,
  publication_heads: Map<DispatchIntentId, V2PublicationGenerationHeadR3>,
  publication_claims: Map<PublicationClaimIdR3, V2PublicationFenceClaimR3>
}
```

このStateはR3 migration extensionのphase/gate/apply authorizationだけを所有します。accepted V2 Stateがtail、inbox、Domain state、
apply cursor、outboxのsole mutable ownerで、record内のsource/observed tupleはCAS用snapshotです。`active_control` absentかつaccepted V2が
activeでR3 handoff未成立の場合だけ`V2RunningForR3` read viewを導出できます。曖昧なabsence、複数active control、別attemptのrecord reuseを
拒否します。publication claimはmigration phaseとは別fieldですが同じ`state_revision`をCASし、RequestPause/Activateと一winnerになります。
accepted V2 outboxがpayload/delivery statusのowner、STA005 `publication_heads`がintentごとのlatest generationのsole owner、claim mapが
send authorization/custody fenceとimmutable generation historyのownerで、同status/generationを二重所有しません。generationは1から
gap-freeに増え、headだけがlatestです。new head commit後、全old claim recordは永久immutableです。accepted outbox statusはlatest head claim
statusのcanonical projectionと一致し、不一致はConflictです。
ownerは`SD-CTX-EXE-001`、mutationは`SD-TRN-EXE-028/029`だけです。

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
  command_id, migration_attempt_id, expected_attempt_revision,
  expected_attempt_generation, action: MigrationActionR3, expected_control_revision,
  expected_source_revision, expected_cut?, expected_candidate_digest?, reason?
}
```

各actionは`SD-STA-EXE-004` attemptのexact一phase（RequestPauseだけAbsent）をtargetとし、restart時もidentityを推測生成しません。

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

migration attempt/generation/retry generation、command/action、prior/resulting phase、attempt revision、source V2 control/gate/tail/inbox
expected revisions/digests、cut/candidate/mapping digest、sealed watermarks、abort/activation evidenceを完全相関するExecution owner Eventです。
pauseやcandidate validationを
activation successへ昇格しません。

### SD-EVT-EXE-019 — OrderedResultCatchUpAdvancedR3

reducer、prior/resulting catch-up variant、exact next sequence/winner key、winner payload/correlation digest、prior/resulting applied
prefix sequence/digest、observed/target/committed tail sequence/digest、Domain owner Event refs、guard/custody/outbox contribution refs、
dispatch barrier statusを完全相関します。append acknowledgement、result success、barrier openを相互に昇格しません。

### SD-EVT-EXE-020 — V2ForR3OperationalControlAdvancedR3

migration attempt/generation、operation、prior/resulting `SD-MOD-EXE-012` view、control expected/resulting revision、dispatch/apply gate、
accepted V2 State/tail/inbox/apply cursor expected/resulting revision/sequence/digest、cut、winner key、command/Event correlationを固定する
Execution owner Eventです。pauseは既存resultのapply完了を意味せず、abort requestはcatch-up完了を意味せず、catch-up完了はR3 activationを意味しません。

### SD-EVT-EXE-021 — V2PublicationFenceAdvancedR3

publication claim ID `(intent,generation)`、prior/new claim ID、prior/resulting head generation/revision、publisher selection/attempt、V2 outbox/intent/stable operation、
prior/resulting fence status、STA005 state/fence revision、
accepted V2 outbox expected/resulting revision/status、pinned dispatch evidence ref/version/digest/idempotency class、transport result、custody、
R3 handoff identityを完全相関するExecution owner Eventです。claim commitはsend/ack、transport ackはexecution terminalを意味しません。

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
evidence ref/profile version/digest、`SD-RUL-EXE-020.AllowAdmissionDispatch`、stable IDsをpureに評価し、
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

exact attempt record/revision/generation、latest `SD-STA-EXE-005` control/gateとaccepted V2 tail/inbox tuple、migration Command、cut、
candidate validation、crash markerをpureに評価し、
`Pause | Validate | Retry | Abort | Activate | RestorePriorState | Duplicate | Conflict`のexact一つを返します。crash restoreはdurable
prior attempt phaseとsame command/event identityだけから決まり、same command/same payloadはDuplicate、same identity/different payloadは
Conflictです。表外edge、generation skip、別attempt reuse、暗黙pause/resume/activateを返しません。

### SD-RUL-EXE-018 — MaterializeV2OperationalStateR3

complete V2 snapshotとaudit injectionから、全active/pending source identityをexact一つのR3 graph/occurrence/attempt/lease/guard/
custody/resume/inbox/outbox identityへpureに写します。lifecycle、binding_use、generation、winner、outbox statusを維持し、active leasesを
physical identity/capacity evidence/occupancyへ写します。bijection、one mutable representation、occupancy conservationが成立しなければ
`RejectMigration`です。terminal historyはaudit-onlyでもよいですがactive/pending recordをaudit-onlyにできません。
pending attempt/outboxはtrusted dispatch capability evidence ref/version/digestも保存し、mapping conservationへ含めます。
V2 `committed_ingress_tail`のstream identity、last sequence、prefix digest、tail revisionをR3 `canonical_ingress_tail`へlosslessに
materializeし、V2 tail recordをaudit-onlyにします。二mutable tail owner、sequence/digest normalization、unmapped tailを拒否します。

### SD-RUL-EXE-019 — DecideNamedIntervalLeaseUseR3

exact named interval、lease、holder/fact、terminal set、expected use count、replay identityをpureに評価し、
`ContinueOnce | ReplayNoOp | ReleaseAfterAllTerminal | Conflict | KeepActive`を返します。holder追加はuse countをexact一増やし、
全holder terminal前のreleaseと同continuation replayによる二重増加を拒否します。

### SD-RUL-EXE-020 — DecideOrderedResultCatchUpR3

catch-up state、chosen reducer、durable inboxのgap-free winner sequence、current committed tail revision/digest、exact Domain snapshotをpureに
評価し、`ApplyExactNext | FollowAdvancedTail | OpenBarrier | DuplicateAlreadyApplied | MissingNextSequence | ConflictWinner |
OutcomeUnknownRequiresCustody | StaleTail`のexact一つを返します。next sequence以外、missing/uncommitted/conflict quarantineを
winnerとして適用しません。new tailが先行すればOpenBarrierはCASを失い、target追随後に再評価します。R3 operational identityだけを用います。
tail inputは唯一owner `canonical_ingress_tail`のcomplete snapshotであり、catch-up record内snapshotをauthoritative tailにしません。
R3 activation markerとcatch-up variant/reducerからcanonical authorization式どおり`AllowAdmissionDispatch | Deny`も返します。
`R3Active + BarrierOpen + R3Reducer`以外は常にDenyです。preactivationのV2 gate判断はこのRuleのinputでもoutputでもありません。

### SD-RUL-EXE-021 — DecideV2ForR3OperationalControlR3

`SD-MOD-EXE-012` exact view、`SD-STA-EXE-004/005` revision/attempt/generation、accepted V2 Stateのexact
tail/inbox/apply cursor/outbox snapshot、operation identityをpureに評価し、次のexact一Decisionを返します。

```text
CloseV2ForR3Gates | SealExactV2Cut | AllowIngressAppend |
StartV2AbortCatchUp | ApplyNextV2Winner | FollowAdvancedV2Tail |
OpenAtExactTail | HandOffExactV2Tuple |
AllowV2Dispatch | AllowNormalV2Apply | Deny | Duplicate | Conflict
```

RequestPauseは`V2RunningForR3|AbortedToV2Running`だけ、Sealはexact tail/cursor tupleだけ、Activateは
`V2PausedForR3 + CandidateValidated`だけを許可します。Abort catch-upはaccepted V2 inboxの
`apply_cursor+1` committed winnerだけを選び、gap/conflict/OutcomeUnknownを飛ばしません。OpenはCAS時点のcursor prefixとlatest tail
sequence/digest/revision一致だけです。appendはhandoff前だけ許可し、pause/abort中もtailへgap-free追加できます。
V2 dispatchとnormal applyは`V2RunningForR3|AbortedToV2Running`かつgate Openのexact control revisionだけでAllowです。

### SD-RUL-EXE-022 — DecideV2PublicationFenceR3

STA005 exact state/fence revisionとoperational view、publication claim map、accepted V2 outbox revision/status、immutable intent/operation/payload、
pinned dispatch evidence、publisher selection/attempt、Port result、R3 handoff mapをpureに評価し、次のexact一Decisionを返します。

```text
ClaimPublication | DenyClosedFence | WaitForClaimResolution |
RearmNextPublicationGeneration |
MarkDefinitelyNotSent | MarkTransportAcked | RequireOutcomeUnknownCustody |
RetryExactIdempotentOperation | QueryOrReconcileBeforeRepeat |
HandOffClosedPublication | RouteLatePublicationToR3 |
Duplicate | Conflict
```

initial claimは`V2RunningForR3|AbortedToV2Running`、gate Open、intent head/claim generation 1 absence、outbox publish-eligible、evidence一致の
場合だけ許可します。re-armは`V2RunningForR3/Open | AbortedToV2Running/Open`で共通の同一法則を用い、latest head
`(intent,g)`のclaimが`DefinitelyNotSent`、old claim revision/status、
head revision、`(intent,g+1)` absence、STA005 state/fence revision、accepted outbox/evidenceがexact一致する場合だけ
`RearmNextPublicationGeneration`を返します。new claimはsame stable operation/payload/evidenceを保持しgenerationだけをexact一増やします。
running/aborted viewによる分岐差を持ちません。`TransportAcked|OutcomeUnknownCustody|HandedOffPublication`、old non-head claim、
generation gap/overflowからre-armを返しません。
commit済みclaimなしsend、pause後pre-read、別publisher/attempt/operation/payloadを拒否します。`ClaimedForSend`は送信済みかもしれないため、
crash後Idempotentだけsame stable operation/claim/attemptをretryでき、ReconcileBeforeRepeatはQuery/Reconcile後だけ、NonIdempotent unknownは
`RequireOutcomeUnknownCustody`だけです。same new claim/same payload replayは`Duplicate`、same `(intent,generation)`の異payload/evidenceは
`Conflict`です。HandedOff後のack/resultはR3 mappingが一意なら`RouteLatePublicationToR3`、それ以外はConflictです。

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

`SD-TRN-EXE-025`がclosed edge `CandidateValidated + ActivateR3 → Activated`へ進める同じactivation compositionの中でのみ、
candidate operational maps/occupancy、audit injection、schema marker、reducer handoffをmaterializeします。単独呼出し可能な
activation transitionではありません。V2 snapshotはimmutable audit artifactで、R3後にV2 ownerを再開しません。

### SD-TRN-EXE-023 — ApplyDispatchPublicationR3

Publication EventとRecovery Decisionだけからoutbox delivery statusを単調適用し、unknown時はexact custodyを作ります。
Occurrence/Attempt terminal、lease release、別send identityを変更しません。同event replayはno-op、相関/payload差はConflictです。

### SD-TRN-EXE-024 — ApplyExecutionCancellationR3

Cancellation Decision/Eventだけからundispatched revocation、descendant revocation、またはin-flight全leaseの同一custody移管をatomic適用します。
ConfirmedStopped/DefinitelyNotApplied evidenceなしにleaseをreleaseせず、subset custody、generation跨ぎ、二重cancel winnerを拒否します。

### SD-TRN-EXE-025 — ApplyExecutionMigrationR3

`SD-MOD-EXE-010`表のprior/action/result、`SD-RUL-EXE-017` Decision、`SD-EVT-EXE-018`だけからattempt recordをexact一edge
進めます。Absent→PauseRequestedの作成、pause/seal、validation、retry、terminal Aborted/Activated、crash restoreを適用します。
activation edgeだけは`SD-TRN-EXE-022` materializationと同じUoWで、片方だけをcommitできません。
operational V2 mutationはaccepted V2 Transitionが同compositionで行い、このTransitionはcoordination recordだけをmutateします。
Activate edgeだけがR3 operational Stateをmaterializeし、Abort edgeはattemptをAbortedにしてV2 catch-upへ進みます。

### SD-TRN-EXE-026 — ApplyNamedIntervalLeaseUseR3

`SD-RUL-EXE-019` Decision、expected lease revision/use count、continuationまたはholder-terminal Event identityだけからholder map、
terminal holder set、use count、lease/occupancy lifecycleを変更します。ContinueOnceはcount+1、ReplayNoOpは無変更、KeepActiveは
lease維持、ReleaseAfterAllTerminalだけがlease/occupancyを同時releaseします。単独commitせずdispatch claimまたはresult inbox
compositionに必ず含まれます。

### SD-TRN-EXE-027 — ApplyOrderedResultCatchUpR3

`SD-RUL-EXE-020` Decisionと`SD-EVT-EXE-019`だけから、exact next winnerのDomain mutation、Occurrence/Attempt、guard、custody、
lease/occupancy、outbox contribution、inbox applied status、applied cursor/prefix digestを一段進めます。FollowAdvancedTailはtarget tail
だけ、OpenBarrierはcatch-up完了とdispatch barrierだけを変更します。cursor-only、Domain-only、wrong reducer、gap越しapplyを拒否します。
R3 gate mutationはActivate materialization時のClosed作成とcatch-up完了Openの二経路だけです。

### SD-TRN-EXE-028 — ApplyV2ForR3OperationalControlR3

`SD-RUL-EXE-021` Decisionと`SD-EVT-EXE-020`だけから`SD-MOD-EXE-012`表のexact一edgeを適用します。
RequestPauseはcontrol作成/closed gates/apply stop、Sealはexact cut、AbortはV2 catch-up開始、catch-up stepはobserved snapshot、
Openはgate Open、Activateは`HandedOffToR3`を決定論的に作ります。accepted V2 tail/inbox/Domain/apply cursorはこのTransitionが
直接変更せず、`SD-PER-EXE-019`内でaccepted V2 owner Transitionとcompositionします。同Event replayはresulting revision/digest一致なら
no-op、異payload、stale tuple、表外edgeはConflictです。RequestPause/Abort/Activateで`SD-TRN-EXE-025`との片側commitを許しません。

### SD-TRN-EXE-029 — ApplyV2PublicationFenceR3

`SD-RUL-EXE-022` Decisionと`SD-EVT-EXE-021`だけからSTA005 initial/re-arm publication claimを作成します。re-armは
`PublicationClaimId(intent,g+1)`を作ってheadを同commitで進め、prior claimを一切変更しません。
`ClaimedForSend -> DefinitelyNotSent|TransportAcked|OutcomeUnknownCustody`、exact reconciliation/late ackによる
`OutcomeUnknownCustody -> DefinitelyNotSent|TransportAcked`、各closed statusから`HandedOffPublication`への合法edgeだけを適用します。
status transitionとhandoffはlatest head claimだけに許可し、nonterminal `ClaimedForSend`からのhandoffはできません。
claim creation/transitionごとにSTA005 state/fence revisionとclaim revisionを進めます。accepted V2 outbox status、R3 outbox/custody/inboxは
直接変更せず`SD-PER-EXE-020`のowner compositionだけが変更します。同identity/same payload replayはno-op、異payload、status逆行、
claim削除、old generation mutation、HandedOff後のV2 mutationはConflictです。

## Persistence、migration、proof

### SD-PER-EXE-011 — DurableTopologyR3UoW

Behavior owner Event、expected graph revision、topology validation/Event/Transitionを全CASします。crash/replayはsame topology identity/
canonical digestから全体を再開し、occurrenceだけ、guardだけ、extensionだけを残しません。

### SD-PER-EXE-012 — DurableDispatchClaimR3UoW

occurrence expected revision、各physical keyのoccupancy revisionまたはcompare-not-exists、capacity evidence revision、dispatch
capability evidence ref/profile version/digest、authorization/binding view、stable intent key absenceを一transaction predicateにします。
`result_catch_up` exact revision/BarrierOpen/reducerとR3 activation markerをCASし、canonical authorizationがDenyならclaimをcommitしません。
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

責務はcanonical winnerのappend/sequence/prefix digestとack、およびBarrierOpen時のsteady-state same-UoW applyです。barrier closed中は
winnerを`Unapplied`でappendするだけでDomain mutationを行わず、順序適用は`SD-PER-EXE-018`だけが所有します。barrier statusと
inbox applied statusのCASにより、同winnerを両UoWが適用できません。

new winner appendはstable canonical inbox key absenceとexact prior `canonical_ingress_tail` stream identity/revision/last sequence/prefix digestを
同じUoWでCASし、winner sequence=`last_sequence+1`、new prefix digest、tail revision+1をgap-freeにcommitします。parallel appendは一winner、
loserはnew tailから再決定します。commit前crashはwinner/tailとも0、commit後crashは保存済みkey/sequenceからreplayします。
same key/same payload duplicateとsame key/different payload conflict quarantineはcanonical tailを一切変更しません。
このUoWはR3 operational StateがactiveでR3がsole mutable ownerの場合だけ使用できます。pause/preactivation/abort後のV2 ownershipでは
`SD-PER-EXE-019`だけがnew control revisionとaccepted V2 data revisionを同時CASします。

### SD-PER-EXE-014 — V2ToR3ActivationUoW

`SD-PER-EXE-019`のActivate branchとして、`SD-STA-EXE-004/005`、`SD-CMD-EXE-002`、`SD-EVT-EXE-018/020`、
`SD-RUL-EXE-017/021`、`SD-TRN-EXE-025/028`とR3 materializationを一compositionでCASします。

```text
Absent --RequestPause--> PauseRequested --SealPausedCut--> V2PausedAtCut
V2PausedAtCut | RetrySameCut --ValidateCandidate--> CandidateValidated
V2PausedAtCut | RetrySameCut | CandidateValidated --RetryCandidate--> RetrySameCut
PauseRequested | V2PausedAtCut | RetrySameCut | CandidateValidated --AbortPause--> Aborted
CandidateValidated --ActivateR3--> Activated
```

各transitionはcommand/event、source/destination revision、sealed watermarks、attempt number、failure reasonをdurable記録します。
pause中もschema-neutral ingressを受けcut後tailへ封印します。activation前crashはtyped stateからsame cutをretryまたはexplicit abortして
V2へ戻り、activation commit後crashはR3 activeとsame first-unapplied sequenceから再開します。hidden pause、implicit resume、dual owner、
barrier後V2 dispatch、R3→V2 downgradeを拒否します。
RequestPauseはattempt record creation/PauseRequested Event/Transitionとnew `V2PauseRequestedForR3` control/gate/apply-stopを原子commitします。片側だけを
作らず、duplicate same commandはno-op、異payloadはConflictです。Seal/Validate/Retryはattempt revision/generationとlatest expected V2
tupleをCASし、crashはdurable prior/resulting phaseからrestoreします。

Abortはattempt `Aborted` terminal Event/Transitionとnew `V2CatchingUpAfterAbortForR3` controlを同commitし、R3 operational Stateを作りません。
commit前crashはprior attempt/V2 pause state、commit後crashはAborted/V2 catch-up stateから再開します。

activation compositionはsource/cut/control revisions、latest exact V2 committed ingress tail revision/sequence/digest、inbox map revision/
winner set digest、gate/control revision、sealed cursorsに加え、`SD-RUL-EXE-014` injection validation、
`SD-RUL-EXE-018` accepted materialization Decision、全audit injection、source→operational maps、Graph/Occurrence/attempt/outbox、
active lease capacity evidence、pending dispatch capability evidence、全V2 outbox/publication fence claim/status/custody、resource occupancy、
schema marker、`SD-EVT-EXE-015/018/020/021`、
source `V2PausedForR3` control revision、`CandidateValidated` attempt revision/generation、`SD-TRN-EXE-022/025/028`、
全publication claim `HandedOffPublication`、control terminal `HandedOffToR3`、attempt terminal `Activated`、reducer handoffを一つの
CAS/commitへ置きます。validation-only、map-only、occupancy-only、control-only、attempt-terminal-only、
activation-only commitを禁止し、一要素でもstale/invalidなら全体を変更しません。
V2 committed ingress tailからlossless materializeしたR3 canonical tail recordも同じactivation commitへ含めます。
同時にlatest V2 inbox winners/statusとclosed gate/cursorをR3 inbox/CatchUpRequiredへ一括materializeし、V2側をaudit-onlyにします。
racing V2 appendが先にcommitすればactivation CASは必ず失敗してlatest V2 tupleからcandidate/activationをretryし、winnerを落としません。
ActivateR3 handoffはR3Reducer、next sequence、applied prefix digest、latest exact V2 tail snapshotを持つ`CatchUpRequired`を同commitで
作り、R3 dispatch/admission barrierを閉じたままにします。AbortPauseはR3 State/catch-up/tail/inboxを作りません。

### SD-PER-EXE-015 — DurableDispatchPublicationR3UoW

exact outbox status/intent/operation、pinned dispatch capability evidence ref/version/digestとidempotency class、publication EventをCASし、
delivery statusまたはcustodyを一度commitしてからackします。
V2 handoff後のlate publication resultはmaterialized `publication_claim_id/publisher_selection_id/publication_attempt_id/intent/operation`が
一意一致する場合だけR3 outbox/custodyへ適用し、V2 statusを更新しません。
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

### SD-PER-EXE-018 — DurableOrderedResultCatchUpR3UoW

catch-up revision、chosen reducer、exact next inbox winner/status、payload/correlation、Domain expected revision、guard/custody/lease/
occupancy/outbox revisions、applied prefix sequence/digest、唯一owner `canonical_ingress_tail`のstream identity/revision/last sequence/
prefix digest、`SD-RUL-EXE-020`、
`SD-EVT-EXE-019`、`SD-TRN-EXE-027`を一CASでcommitします。apply前crashはUnapplied exact next、commit後crashはadvanced cursorから
restartします。new ingressが先にtailを進めればapplyは可能ですがbarrier open CASは失いtarget tailを追随します。missing、duplicate、
conflict、OutcomeUnknownはtyped Decisionどおり停止/隔離/custody化しcursorを飛ばしません。CAS時点でapplied prefixとcommitted tailが
一致した場合だけBarrierOpenをcommitし、その後にのみchosen reducerのnew dispatch/admissionを再開します。
CatchUpRequiredのtarget/observed snapshotをCAS ownerとして更新せず、Decision/Transitionがcanonical tail snapshotを読み直します。
OpenBarrierはexact canonical tail revision/sequence/digestもCASするため、racing appendが先なら必ず失敗してtail追随へ戻ります。
このUoWもR3Active後だけです。AbortPause後のV2 catch-upへ適用せず、`SD-PER-EXE-019`を用います。

### SD-PER-EXE-019 — DurableV2ForR3OperationalControlR3UoW

`SD-STA-EXE-004/005`、`SD-RUL-EXE-017/021`、`SD-EVT-EXE-018/020`、`SD-TRN-EXE-025/028`と、
accepted V2 State ownerのexact data Transitionをoperation別に一つのCAS/commitへcompositionします。accepted `SD-RUL-EXE-009`の
V1→V2 pause/abort Decisionや`SD-PER-EXE-010`のV1→V2 pause/abort branchは呼びません。accepted definitionsから再利用するのは
V1由来injected record correlation、stable inbox key、gap-free append、V2 result Transitionの既存意味だけです。

- **RequestPause:** derived `V2RunningForR3`または`AbortedToV2Running`、accepted V2 state/tail/inbox/apply cursor、new attempt identity absenceを
  CASし、STA005 publication fence revision、全head/claim digest、全latest headがclosed statusであることも検証して、
  `SD-STA-EXE-004.PauseRequested`作成と`SD-STA-EXE-005.V2PauseRequestedForR3`作成、dispatch/admission gate close、normal apply stopを
  atomic commitします。片側commit、nonterminal publication claim、pause後V2 dispatch/normal apply/publicationを拒否します。
- **Ingress append:** handoff前のexact control revision/read view、stable inbox key absence、accepted V2 tail revision/sequence/digestをCASし、
  winner recordとtail+1/prefix digest/revisionを同commitします。pause/append、seal/append、abort-open/append、activate/append raceは一winnerで、
  loserはlatest tupleからretryします。duplicate/conflictはtail/control不変です。
- **V2 dispatch / normal apply:** R3 extension有効中のaccepted V2 dispatch/admissionまたはnormal result applyは、既存owner mutationに
  `SD-RUL-EXE-021.AllowV2Dispatch|AllowNormalV2Apply`とexact `SD-STA-EXE-005` revision（derived running viewではcontrol absence token）を
  必ず追加CASします。RequestPauseとracing dispatch/applyは一方だけがcommitし、pause commit後は新dispatchもnormal applyも0件です。
- **Seal:** `V2PauseRequestedForR3`とlatest V2 tail/inbox/apply cursor/outbox tupleをCASし、immutable cut、
  `V2PausedForR3`、`SD-STA-EXE-004.V2PausedAtCut`を同commitします。
- **Abort:** `V2PauseRequestedForR3|V2PausedForR3`とnonterminal attemptをCASし、controlを
  `V2CatchingUpAfterAbortForR3`、attemptをterminal `Aborted`へ同commitします。R3 operational Stateは作りません。その後各stepは
  accepted V2 exact next committed winner、Domain mutation、inbox applied status、apply cursor/prefix digest、control revision/Eventを同commitし、
  commit前後crash/replayでskip/double applyしません。latest exact tailまで追いついたCASだけが`AbortedToV2Running`とgate Openを同commitします。
- **Activate:** exact `V2PausedForR3` control revision、`CandidateValidated` attempt、latest accepted V2 state/tail/inbox/apply cursor/outbox tuple、
  STA005 publication fence revision/全head/claim history、R3 materialization candidateをCASし、全claim/outbox/custodyをR3へmaterializeして、
  各latest headだけを`HandedOffPublication`、controlを`HandedOffToR3`、attemptを`Activated`へ進め、`SD-TRN-EXE-022`のR3 operational State/CatchUpRequiredを
  同commitします。partial handoff、post-handoff V2 append/dispatch/apply、racing appendの脱落を拒否します。

全branchはsame command/Event/same payload replayをno-op、same identity/different payloadまたはstale revisionをConflictとします。
restartはdurable control/attempt phaseとaccepted V2 exact tupleだけから再決定し、process-local pauseやimplicit reducer switchを使いません。

### SD-PER-EXE-020 — DurableV2PublicationFenceR3UoW

- **Initial publication claim:** exact STA005 state/fence revisionと`V2RunningForR3|AbortedToV2Running/Open`、intent head absence、
  `PublicationClaimId(intent,1)` absence、accepted V2 outbox
  revision/status、intent/operation/payload digest、pinned dispatch evidence、publisher selection/attempt identity、`SD-RUL-EXE-022`、
  `SD-EVT-EXE-021`、`SD-TRN-EXE-029`を一CASでcommitします。commit後の`ClaimedForSend` envelopeだけをPortへ渡します。
- **Re-arm next generation:** `V2RunningForR3/Open | AbortedToV2Running/Open`の両方へ同じpredicateを適用し、exact head `(intent,g)` revision、
  latest claim revision/status `DefinitelyNotSent`、
  `(intent,g+1)` absence、STA005 state/fence revision、accepted V2 outbox revision/status、same operation/payload/evidenceを一CASし、
  new `ClaimedForSend(intent,g+1)`とhead generation+1を同commitします。old claimは変更しません。parallel re-armは一winner、
  same new claim/same payload replayはno-op、異payload/evidenceはConflictです。
- **Transport/recovery resolution:** exact STA005 state/fence/head/latest-claim revision、accepted V2 outbox revision/status、Port result/evidence、custody、
  owner Event/Transitionを一CASし、`DefinitelyNotSent|TransportAcked|OutcomeUnknownCustody`へ一度だけ進めてからackします。
  send後/status前crashは`ClaimedForSend`からclass別Ruleを再評価し、NonIdempotentをblind resendしません。
- **Pause race:** RequestPauseは同じSTA005 state/fence revisionと全head/claim digestをCASします。claim/re-armが先ならpauseはstaleか
  `WaitForClaimResolution`となり、全latest headがclosed statusへ収束するまで進みません。pauseが先ならgate Closed後のclaim/re-arm/sendは0件です。
- **Activation race/handoff:** Activateはexact STA005 head/claim history、accepted V2 outbox全revision/status/custody、V2→R3 mappingをCASし、
  historyをR3へmaterializeしてlatest headだけを`HandedOffPublication`とR3 identityへ同commitします。`ClaimedForSend`が残るactivation、
  claim-only/status-only/handoff-only commit、同intentのV2/R3二send authorizationを拒否します。
- **Late ingress:** HandedOff後のtransport ack/recovery resultは`SD-RUL-EXE-022.RouteLatePublicationToR3`とmaterialized identityで
  `SD-PER-EXE-015`へ、execution resultはcanonical delivery identityで`SD-PER-EXE-013`へ入れます。STA005/V2 outboxを変更せず、
  V2 ownerを復活させません。duplicateはno-op、different payload/correlationはR3 quarantineです。

publisher pre-read、claim/re-arm-before-pause、send-before-status crash、ack/pause/activate raceの全てで同じstate/fence/outbox revision predicateが
one-winnerを決めます。Port/Adapterはclaim、gate、outbox、custody、execution lifecycleをmutateしません。

### SD-PRJ-EXE-002 — ExecutionV2CompatibilityViewR3

各`InjectedV2RecordR3`をsource store/key/tag/complete valueへ逆投影します。R3-native variantは部分投影せず
`UnsupportedR3Variant`です。Projectionはread-only proofでState owner/dispatch sourceではありません。

### SD-PRF-EXE-002 — V2ToR3RoundTripProof

V2全storeの全variant/field fixtureで`projectV2(injectR3(v2)) == v2`をbyte-for-byte比較します。lineage、resume request/commit、
V1 receipt、binding_use、named interval/holder fact、Failed guard、empty claims/leases、native Acoustic initial+multiple extension、pending/
started/terminal attempt、custody、control、unapplied ingress/inbox、全outbox statusを含みます。pause/abort/retry/activate全crash stateと
barrier raceも検証します。pause中ack済みwinnerをActivateR3後はR3、AbortPause後は`SD-PER-EXE-019`でexact sequence適用し、new ingress tail race、
apply前後crash、restart、missing/conflict/OutcomeUnknown、barrier open CASを検証します。parallel append one-winner、append commit前後
crash/replay、gap拒否、duplicate/conflict tail不変、tail advanceとOpenBarrier race、pause append vs activation one-winner、activation crash、
pause vs V2 dispatch/normal apply one-winner、abort exact-next catch-up/open race、no R3 post-handoff operational State mutable preactivation
（coordination attemptとV2-for-R3 controlだけは存在）、全closed publication claim/outbox/custodyのlossless handoffを含みます。

### SD-PRF-EXE-003 — ResourceAndDispatchProofR3

同physical identityの異profile/versionが競合すること、Exclusive/Shared、capacity境界、duplicate、多claim一件失敗、named continuation/
recovery privileged mismatch、same-key one winner、nonconflicting parallel、phantom insertをtable-drivenに検証します。さらにclaim/commit/
publish/ack/cancel全crash、idempotency三class、publisher pre-read vs pause/activate、claim-before-pause、send-before-status crash、ack race、
NonIdempotent unknown、initial V2Running claim→DefinitelyNotSent→g+1 publish、running/aborted共通law、parallel re-arm/pause one-winner、
same `(intent,g+1)` replay対different payload/evidence conflict、
TransportAcked/OutcomeUnknownCustody/HandedOffからのre-arm拒否、handoff後late ack/resultでsubset lease、二intent、二重send、blind resend、
意味edge生成がないことを検証します。
これはproof contractでありpassingを主張しません。

### SD-PRF-EXE-004 — ActiveV2OperationalizationProofR3

全active/pending V2 variant fixtureについてsource→operational identityが一対一、audit injectionがimmutable、mutable lifecycle ownerが
operational mapだけであることを検証します。V2 active Exclusive/Shared/named/custody leaseとracing R3-native claimを同occupancyへ載せ、
conflict、capacity conservation、profile mapping failure、restart replayを検証します。audit-only pending work、二重result apply、
lease reservation loss、V2 committed tailのsequence/digest/revision driftをnegative fixtureにします。

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
  MigrationControlConflict | V2ForR3AuthorizationConflict | V2PublicationFenceConflict |
  UnclaimedV2OutboxSend | LateV2MutationAfterHandoff | MigrationBarrierConflict |
  PrematureV2Resume | CatchUpSequenceGap |
  CatchUpPrefixConflict | CatchUpReducerMismatch | PrematureDispatchBarrierOpen | DualExecutionOwner |
  DowngradeForbidden | CanonicalEncodingConflict | DigestCollisionQuarantined
```

## Ports、recovery、non-goals

dispatch/cancel/query/reconcile/timer Portはimmutable envelopeを受け、occurrence/attempt/generation/stable operation/intentを完全相関した
result Eventだけを返します。Adapter、publisher、timerはready、semantic completion、lease release、custody resolutionを決めません。
V2 publication Portもcommit済みpublication claim/publisher selection/publication attempt/fence revision/evidenceを完全相関し、
pre-read outboxやclaim未commit envelopeをsendしません。late resultのV2/R3 routeはCore Ruleがmaterialized mappingから決めます。
OutcomeUnknown、deadline、cancel、non-idempotent publish uncertaintyでは全claim leaseを同じcustodyへ移し、exact
`RecoveryPrivileged(Query|Cancel|Reconcile)`だけをadmitします。ownerのDefinitelyApplied/DefinitelyNotApplied/ConfirmedStoppedだけが
release候補、StillUnknownはQuarantinedです。subset解放、blind retry、通常claimによる横取りはありません。

未決: fairness/priority、具体capacity値、storage/transaction engine、process/IPC、timer製品、lease timeout数値。
non-goal: accepted V1/V2変更、Yatagarasu 3製品、runtime plugin、Behavior固有workflow、public UI、production実装、passing proof、commit。
