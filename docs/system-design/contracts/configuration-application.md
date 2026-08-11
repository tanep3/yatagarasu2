# 設定文書・適用・権限のcanonical contract

この契約は、Ownerの設定文書を型検証し、外部永続化とCapability/Policy適用の完了を推測せず、新しいInteractionへだけ反映する境界を定めます。Configuration ContextはPolicy、grant、runtime binding、readiness、Effect pendingを所有しません。

## State・Command

### SD-CTX-CFG-001 — Configuration Context

typed設定文書、Layer/provenance、desired revision、atomic group別effective snapshot、apply lifecycleを唯一所有します。

### SD-STA-CFG-001 — ConfigurationDocumentState

```text
ConfigurationDocumentState {
  state_revision, schema_version,
  revisions: Map<ConfigurationRevisionId, ConfigurationRevisionRecord>,
  desired_revision,
  accepted_user_layer_digest,
  write_intents,
  retained_snapshot_uses: Map<ConfigurationRevisionUseId,
    ConfigurationRevisionUseRecord>
}

ConfigurationRevisionUseRecord {
  use_id, configuration_snapshot_ref, interaction_id,
  lifecycle: Acquired | ReleasePending | Released | Recovery,
  recovery_owner_ref?
}
```

`config.toml`はUser Layer入力文書でありDomain State正本ではありません。受理済みdigestがState Snapshotへcommitされて初めてdesired文書となります。

### SD-STA-CFG-002 — ConfigurationApplicationState

```text
ConfigurationApplicationState {
  applications: Map<ConfigurationApplicationId, ConfigurationApplication>,
  effective_groups: Map<AtomicConfigGroupId, EffectiveGroupBinding>,
  effective_snapshot_ref,
  pending_steps
}

ApplyMode = Immediate | NextInteraction | RestartAdapter | RestartRuntime

ConfigurationApplicationStep {
  step_id, desired_revision, atomic_group_id,
  apply_mode, activation_targets,
  lifecycle: Planned | AwaitingDocumentPersistence |
    AwaitingEffect | AwaitingRestart | AwaitingActivation |
    Applied | Failed | Cancelled | Recovering,
  effect_occurrence_refs
}
```

desired、effective、pendingは別identityです。mixed updateは一つのdesired revisionと、schemaで独立を宣言したatomic group別stepに分けます。effective snapshotは常に完全なschema-valid文書です。

### SD-CTX-AUT-001 — Authorization Policy Context

Owner standing delegation、SkillExecutionGrant、grant revision、activation/revocationを唯一所有します。Data transfer、Memory保存許可、CFG lifecycleを所有しません。

### SD-STA-AUT-001 — AuthorizationPolicyState

```text
AuthorizationPolicyState {
  state_revision,
  standing_delegation_revisions,
  grants: Map<StableSkillIdentity, SkillGrantRecord>
}

SkillGrantRecord {
  skill_identity, skill_version, grant_version,
  scopes, lifecycle: Staged | Active | Revoked,
  activation_generation
}
```

### SD-CMD-CFG-001 — UpdateConfiguration

```text
UpdateConfiguration {
  request_id, client_idempotency_key, owner_actor_ref,
  expected_desired_revision,
  typed_mutations, source: Web | CLI | Setup | Migration
}
```

Web/API AdapterはこのCommandへ変換し、filesystem、Policy State、Effect、Bootstrapを直接変更しません。

### SD-CMD-CFG-002 — CancelConfigurationApplication

exact application/stepの未dispatch occurrenceをrevokeし、in-flightはtyped cancel/recoveryへ渡します。desired revisionを暗黙rollbackしません。

### SD-CMD-CFG-003 — RevertConfiguration

元に戻す場合も新しいdesired revision/applicationを作ります。

## Event・Rule・Transition

### SD-EVT-CFG-001 — ConfigurationUpdateRejected

schema、safety、authorization、revision conflictの型付き拒否です。旧desired/effectiveを変更しません。

### SD-EVT-CFG-002 — DesiredConfigurationCommitted

User Layerのatomic persistenceとreadback digest検証後、新desired revisionをState Snapshotへ受理したEventです。

### SD-EVT-CFG-003 — ConfigurationApplicationPlanned

atomic group、apply mode、activation target、Effect Graph refを固定したEventです。

### SD-EVT-CFG-004 — ConfigurationApplicationStepResolved

stepのApplied/Failed/Cancelled/Recoveringと根拠Event refを区別します。

### SD-EVT-CFG-005 — EffectiveAtomicGroupActivated

Configuration Contextだけが発行できます。宣言した全activation targetの成功Event refとexpected revisionが同一UoWで成立し、全target ownerのactivation TransitionとCFG effective snapshotが原子的にcommitされた事実です。Runtime targetについては同じcommitの`SD-EVT-RBI-007`を必須にします。Application service、UoW、target owner、Bootstrap、Adapterは同名CFG Factを発行しません。

### SD-RUL-CFG-001 — ValidateConfigurationSchema

型、既定値、read-only、secret ref、apply mode、atomic group、activation targetをpureに検証します。同一atomic groupの異なるapply modeと未知必須値を拒否します。

### SD-RUL-CFG-002 — ResolveConfigurationLayers

BuiltIn Default、System、User、Active Profile、Environment、CLIの順で一つの値とsecretを含まないprovenanceを導きます。

### SD-RUL-CFG-003 — ValidateConfigurationSafety

許可Capability/mode、secret ref形式、Owner権限、保護asset、互換versionをpureに検証します。secret materialは読みません。

### SD-RUL-CFG-004 — PlanConfigurationApplication

validated desired documentをatomic group別stepへ変換し、apply modeを次の閉じた構造へ写します。

| Apply mode | 構造 |
| --- | --- |
| `Immediate` / `NextInteraction` | internal Policy/Profile owner固有Decision/Transition。外部Effectなし |
| `RestartAdapter` | `SD-RUL-RBI-008`が並行candidate probeを許可するexact Capability generationだけを対象とする`SD-GPH-RBI-001 BindingChange` |
| `RestartRuntime` | Yatagarasu全体runtimeを対象とする唯一のglobal `SD-GPH-RST-001` |

`RestartAdapter`をRST Graphへ、`RestartRuntime`を複数RBI Graphの集合へ置換しません。`SD-PRF-RBI-001.RequiresGlobalRestart`またはparallel proof未成立のtargetへ`RestartAdapter`が指定された場合はtyped `UnsupportedApplyMode`として計画を拒否します。Ownerがdesired設定で明示的に`RestartRuntime`を選んだ場合だけglobal restartを計画し、暗黙fallbackしません。generic ApplyTarget Effectを作らず、既存Interaction/Effectを書き換えません。

### SD-RUL-CFG-005 — ComposeEffectiveConfigurationSnapshot

Applied groupだけを完全なschema-valid snapshotへ合成します。各fieldのsource desired revisionとprovenanceを保持します。

### SD-RUL-CFG-007 — DecideAtomicGroupActivation

宣言済みatomic groupの全activation targetについて、exact configuration application／desired revision／atomic group、target集合の完全一致、各Ownerのsuccess Event、expected owner revisionをpureに検証します。RestartAdapter targetはさらにRCP owner上のpin済み`SD-PRF-RBI-001` revision/use、RegisteredCurrent、Passing proof、`SD-RUL-RBI-008`の許可、`Candidate.StagedReady`、exact candidate slot revision/Held holder/NamedInterval lease、`SD-EVT-RBI-006`、activation時点でもfreshなreadiness、expected previous effective generation、`SD-RUL-RBI-006`のOwner Decisionを必須にします。Immediate／NextInteractionのPolicy/Profile targetはそれぞれのOwner activation Decision、RestartRuntimeはexact `SD-EVT-RST-004.Completed` factを必須にします。一件でもprofile missing/Superseded/stale/Blocked、use欠損、slot不一致、未準備、Failure、OutcomeUnknown、Quarantined、readiness stale、別group、target欠落ならRejectし、部分activation Decisionを返しません。

### SD-TRN-CFG-001 — PrepareConfigurationDocumentWrite

`ConfigWriteIntent`、normalized document ref、old/new digest、management operation identityをConfiguration Document Stateへ登録します。

### SD-TRN-CFG-002 — CommitDesiredConfiguration

`PersistUserLayerDocument` terminal Successとreadback digest一致時だけdesired revisionとapplication planをcommitします。

### SD-TRN-CFG-003 — ApplyConfigurationStepResult

exact application/step、Effect occurrence/resultに相関する結果だけをapply lifecycleへ適用します。

### SD-TRN-CFG-004 — ApplyEffectiveAtomicGroupActivation

`SD-RUL-CFG-007`が許可した全target ownerのactivation Event refとexpected revisionを検証し、CFG effective group/snapshotだけを更新して`SD-EVT-CFG-005`を生成します。他Owner Stateを変更しません。Runtime／Policy／Profile Stateは同じ`SD-PER-CFG-004`内の各Owner固有Transitionが変更し、CFG Transitionが代行しません。

### SD-TRN-CFG-005 — CancelConfigurationApplicationTransition

desiredを暗黙rollbackせず、stepと未dispatch Effectのcancel/revoke lifecycleだけを進めます。

### SD-TRN-CFG-006 — ApplyConfigurationRevisionUse

exact effective snapshotとInteraction/Recovery correlationを持つRevisionUseをAcquired、ReleasePending、Released、Recoveryへ進めます。current revision変更でuseを無効化せず、未終端InteractionまたはRecovery責任未移管のuseをReleasedにしません。

### SD-TRN-CFG-007 — ApplyConfigurationPersistenceRecoveryResolution

exact write intent/target operation/custodyと`SD-RUL-CFG-006` Decisionに一致する`SD-EVT-CFG-007`だけを適用します。同値duplicateはno-op、異payload、別desired revision、custody terminal後のlate resultを隔離します。DefinitelyAppliedかつdigest一致の場合だけdesired finalize候補へ進め、StillUnknownで文書資源を再利用可能にしません。

### SD-TRN-AUT-001 — ApplyAuthorizationPolicyConfiguration

Owner/SkillCreatorの認可済みCommandからstanding delegation/grant revisionをexpected Authorization State revisionへ適用します。Skill自身、別Skill、LLM Proposalにgrant拡大を許しません。

### SD-MOD-CFG-001 — ConfigurationExecutionPayload

```text
ConfigurationPlannedPayload =
  PersistDocumentPlan { write_intent_ref, expected_old_digest, expected_new_digest } |
  AwaitConfigurationDeadlinePlan { application_step_id, deadline_policy_ref } |
  QueryPersistencePlan { write_intent_ref, stable_operation_id } |
  ReconcilePersistencePlan { write_intent_ref, observed_digest_ref } |
  CancelPersistencePlan { write_intent_ref, stable_operation_id }

ConfigurationDispatchPayload =
  PersistDocumentDispatch { logical_document_ref, normalized_blob_ref, exact_digests } |
  AwaitConfigurationDeadlineDispatch { anchor_mark, duration } |
  QueryPersistenceDispatch { logical_document_ref, exact_operation_id } |
  ReconcilePersistenceDispatch { logical_document_ref, exact_operation_id, expected_digest } |
  CancelPersistenceDispatch { logical_document_ref, exact_operation_id }

ConfigurationResultPayload =
  PersistenceObserved { observed_digest, operation_result, application_certainty } |
  ConfigurationDeadlineElapsed { application_step_id, observed_mark } |
  PersistenceQueryObserved { stable_operation_id, observed_state, observed_digest? } |
  PersistenceReconciled { stable_operation_id, reconciliation_result, certainty } |
  PersistenceCancelObserved { stable_operation_id, cancel_result, certainty }
```

planned payloadは論理参照だけを持ち、dispatch payloadはclaim時にexact revision/bindingを固定します。Resultは受付、適用、確実性を別値として返し、成功文字列へ圧縮しません。

## Effect・Port・Persistence

### SD-EFX-CFG-001 — PersistUserLayerDocument

```text
PersistUserLayerDocument {
  stable_operation_id, logical_config_document_ref,
  normalized_document_blob_ref,
  expected_old_digest, expected_new_digest,
  correlation: ManagementExecutionCorrelation
}
```

fsync、staged write、atomic rename、directory fsync、readbackをAdapterへ依頼する不変Effectです。実pathとsecret materialを持ちません。

### SD-EFX-CFG-002 — QueryConfigurationPersistence

OutcomeUnknownのexact stable operation IDとlogical document refについて、未着手、staged、renamed、durable、diverged、unknownを照会する不変Effectです。書込みを再実行しません。

### SD-EFX-CFG-003 — ReconcileConfigurationPersistence

queryで観測したdigestとexpected digestを照合し、既存内容の採用、旧desired維持、Owner判断待ちのいずれへ責任移管できるかをAdapterへ検証依頼します。新しい書込みを暗黙実行しません。

### SD-EFX-CFG-004 — CancelConfigurationPersistence

exact stable operation IDの未開始またはstaged操作だけを取消依頼します。rename/durable後のrollbackを意味せず、UnsupportedとOutcomeUnknownを正式結果に含めます。

### SD-EFX-CFG-005 — AwaitConfigurationOperationDeadline

Persist、query、reconcile、cancelのstageとdeadline policyを固定した不変Effectです。内部Policy/Profile適用と外部Capability適用のdeadlineをこのEffectへ混入しません。deadline到来は未適用の証明ではなく、OutcomeUnknown queryまたはRecoveryへ進める結果Eventです。

### SD-EVT-CFG-006 — ConfigurationPersistenceRecoveryObserved

query、reconcile、cancelの結果を、stable operation ID、observed digest、operation result、certainty付きで表します。Adapterはdesired/effectiveを決めません。

### SD-EVT-CFG-007 — ConfigurationPersistenceRecoveryResolved

exact write intent/target persistence operation/custodyについて、DefinitelyApplied、DefinitelyNotApplied、StillUnknownとRelease、Quarantine、採用evidence/digestを固定したCFG owner Eventです。StillUnknownはQuarantineだけを許します。DefinitelyAppliedでもexact expected digestが一致しない場合はFinalizeDesiredを許しません。

### SD-RUL-CFG-006 — ResolveConfigurationPersistenceRecovery

write intent、durable inbox、一回限りのquery/reconcile/cancel結果をpureに評価し、FinalizeDesired、KeepPreviousDesired、QuarantineDocumentのいずれかを返します。OutcomeUnknownからPersistや次照会を再生成せず、確定不能ならQuarantineDocumentへ閉じます。

### SD-PRT-CFG-001 — UserLayerConfigurationPort

logical refをprivate pathへ解決し、stable operation IDで文書永続化、readback、query、reconcile、cancelを実行します。resultはobserved digestとcertaintyを`PortResultEnvelope<ConfigurationResultPayload>`で返します。

## Effect Graph

### SD-GPH-CFG-001 — ConfigurationApplicationGraph

```text
P  PersistUserLayerDocument
D  AwaitConfigurationOperationDeadline
Q  QueryConfigurationPersistence [Recovery only]
R  ReconcileConfigurationPersistence [Recovery only]
C  CancelConfigurationPersistence [cancel path]

dependencies: D<-P dispatch intent, R<-Q terminal observation
guards:
  all nodes require ExecutionSubjectNotRevoked(management operation)
  R requires owner-issued PersistenceQueryObserved fact
resources:
  P/Q/R/C claim LogicalConfigDocument:Exclusive
```

Graph登録時にPersistenceQueryObserved等の未来factは不変`GuardFactDeclaration`と、lifecycleの唯一正本である`GuardFactRecord.status=Pending`として登録し、Occurrence由来ならproducer occurrenceとowner Event kindを固定します。PとDの競合winnerは一度だけ決め、deadline勝者は`SD-PER-EXE-004`でdocument leaseをRecovery custodyへ移しQ/C/Rを各最大一Occurrence・一attemptのprivileged claim付きで登録します。Cの成功からPのDefinitelyNotAppliedを捏造しません。P terminal Success/readback一致後、Immediate/NextInteractionはowner Decision/Transition、RestartAdapterは独立`SD-GPH-RBI-001`、RestartRuntimeは`SD-PER-CFG-007`が登録する唯一のglobal `SD-GPH-RST-001`へ進めます。Failure/DefinitelyNotAppliedは下流を作らず、OutcomeUnknownはQ→Rへ一度だけ進み、R後も不明ならdocumentをQuarantinedへ終端します。resource claimは順序を表しません。

### SD-PER-CFG-001 — PrepareConfigDocumentPersistenceUoW

API ledger、`ConfigWriteIntent`、normalized blob/ref、management Graph、`PersistUserLayerDocument` Occurrence/Attempt/DispatchIntent、durable pending/outbox、stable operation/correlationを一つのState Snapshot revisionへcommitします。これより前にfilesystemを変更しません。

### SD-PER-CFG-002 — DurableManagementResultInboxUoW

management resultをstable operation/occurrence/attempt/generationでdedupeし、EXE result EventとともにState SnapshotへcommitしてからAdapterへackします。

### SD-PER-CFG-003 — FinalizeDesiredConfigurationUoW

inbox内のSuccess、DefinitelyApplied、exact readback digestを検証し、desired revision、application steps、必要なmanagement GraphをState Snapshotへcommitします。rename後・finalize前crashはSnapshot inboxから冪等再開し、journal replayしません。

### SD-PER-CFG-004 — EffectiveAtomicGroupUoW

CFG、RCP、EXEと宣言された全target ownerのexpected revisionを全CASします。Immediate/NextInteractionの内部Policy/Profile targetは対象Ownerのpure Decision/Transition/Eventを、RestartAdapterは各Capability ownerのexact `Candidate.StagedReady`、candidate slot revision/Held holder/NamedInterval lease、RCP owner上のpin済み`SD-PRF-RBI-001` revision/use/RegisteredCurrent/Passing proof、`SD-RUL-RBI-008`、`SD-EVT-RBI-006`、activation時freshness、`SD-RUL-RBI-006`、owner固有`SD-TRN-*-001`を、RestartRuntimeは`SD-EVT-RST-004 RuntimeRestartResolved.Completed`から発行されたexact completion Factを検証します。`SD-RUL-CFG-007`が全targetを同じdesired revision/application/atomic group correlationで許可した場合だけ、各target owner Transition/Event、RestartAdapter candidateのEffective化と旧EffectiveのRetiring化、candidate slot `Held → Free`とNamedInterval slot lease release、各`SD-EVT-RBI-007`、`SD-TRN-CFG-004`、CFG effective snapshot、`SD-EVT-CFG-005`、そのexact Eventから導いたCFG-issued Guard Factの`SD-TRN-EXE-007`適用を同一State Snapshot revisionへcommitします。

同じcommit candidate上で、Retiringへ進む旧generationごとに`SD-RUL-RBI-007`を評価します。Useが0件なら、generation-derived identityの`SD-EVT-RBI-003 AllBindingUsesReleased`、runtime owner-issued Guard Fact、その`SD-TRN-EXE-007`適用、deterministic retirement Graph/Occurrence/pendingをactivationと同じSnapshot revisionへ登録します。Useが一件以上ならここではretirement Graphを作らず、最後のUseを解放する`SD-PER-RBI-001`へ委ねます。activationと同時に未使用な旧generationを、存在しない「最後のUse解放」待ちにしません。

一件でも未準備、Failure、OutcomeUnknown、Quarantined、candidate slot/holder/lease不一致、readiness stale、expected revision競合なら全書込みを棄却し、準備済みcandidateはStagedReady、slotはHeld、旧generationとCFG snapshotはeffectiveのまま保持します。外部操作をこのUoWから実行せず、UoWはFact issuerではありません。activationとcandidate admission/cleanup terminalは同じruntime owner/slot/RCP/EXE revisionをCASし、一方だけが勝ちます。activationと同時のzero-use判定と、並行する最後のUse解放も同じruntime owner/EXE revisionをCASし、`SD-PER-CFG-004`と`SD-PER-RBI-001`の勝者だけが同じgeneration-derived Event/Graph identityを登録します。敗者は再読込後に同値replay、異payloadならConflictです。crash後はapplication／desired revision／atomic group identityから全体を再開し、CFGだけ新snapshot、target AだけEffective、target Bだけ旧generation、candidate slotだけFree、NamedInterval leaseだけReleased、またはAllBindingUsesReleasedだけを構築できません。

### SD-PER-CFG-005 — ConfigurationRoutingRevisionUseAcquisitionComponent

Behavior固有の初期admission UoWへ合成するRevisionUse取得componentです。CFG、BRP、IRPのexpected revision、exact effective CFG snapshot、route Decisionがpinしたexact BRP/IRP revision、interaction/admission identityを全CASし、`SD-TRN-CFG-006`、`SD-TRN-BRP-002`、`SD-TRN-IRP-002`による三つのRevisionUse取得だけを一つのTransition compositionとして返します。INT/QLI admission、Behavior State、EXE lineage/Graphを変更せず、単独commitを禁止します。

`SD-PER-EXE-007`と各Behavior初期UoWが、このcomponentの三つのUse取得をINT/QLI/Behavior/EXE generation 0/Graph登録と同じState Snapshot revisionへ含めます。一つでもrevision欠損、stale、別interaction、競合なら初期admission全体を棄却します。crash後にCFG useだけ、BRP/IRP useだけ、INT/QLIだけ、lineage/Graphだけが残る状態を構築しません。active Interactionはpin済み旧refの存在/保持だけを検証し、current CFG更新で遡及拒否しません。

### SD-PER-CFG-006 — ConfigurationRoutingRevisionUseReleaseUoW

CFG、BRP、IRP、INT、EXEのexpected revisionとexact Interactionを全CASし、Interaction terminalまたはdurable Recovery責任移管を根拠に三つのRevisionUseを同時にReleasedまたはRecoveryへ進めます。部分releaseを許さず、crash後はSnapshot上の同じuse IDから再開します。

### SD-PER-CFG-007 — RuntimeRestartRegistrationUoW

CFG、RST、EXEのexpected revision、exact desired revision、configuration application、atomic group、`RestartRuntime` apply mode、未登録restartを全CASします。次のdeterministic identityを用います。

```text
restart_operation_id = Hash(
  configuration_application_id,
  desired_revision,
  atomic_group_id,
  target_runtime_generation
)
restart_graph_id = Hash(restart_operation_id, "global-runtime-restart-v1")
```

CFG stepの`AwaitingRestart`化、RST operation registration、`SD-GPH-RST-001`/Occurrences/pending、Management correlation、completion/failure Guard Fact declarationを同じSnapshot revisionへcommitします。同じidentity/同じpayloadは既存registrationを返し、同じidentity/異payloadはConflict、別API retry keyから同じapplication stepを再登録してもGraphを増やしません。部分commit、RestartAdapterへの誤登録、複数のglobal restart Graphを拒否します。

### SD-PER-CFG-008 — ConfigurationPersistenceRecoveryResolutionUoW

CFGとEXEのexpected revision、exact write intent/target operation/custody、Q/C/R terminal inbox、`SD-RUL-CFG-006` Decision、`SD-EVT-CFG-007`を全CASします。`SD-TRN-CFG-007`、必要ならdesired finalize候補、`SD-PER-EXE-005`のcustody Active→Reconciled→ReleasedまたはQuarantined、元/recovery Occurrence終端、document lease release/quarantineを同じSnapshot revisionへcommitします。crash/duplicateは同じcustody/inbox keyから全体を再開します。

### SD-REC-CFG-001 — ConfigurationPersistenceRecovery

Persist、query、reconcile、cancelのstable operation IDとdurable result inboxを正本に、OutcomeUnknownを照会します。DefinitelyAppliedとexact digest一致が得られるまでdesiredを進めず、DefinitelyNotAppliedなら旧desiredを維持します。`SD-PER-CFG-008`でcustody出口を確定し、diverged/unknownはOwner判断待ちでlogical document resourceをQuarantinedとして非再利用化し、自動再書込しません。

### SD-PRJ-CFG-001 — ConfigurationProjection

desired/effective/pending revision、atomic group、apply mode、restart scope、Layer provenance、typed Failureを表示します。secret本文を表示しません。

### SD-PRJ-AUT-001 — SkillAuthorizationProjection

Skill identity/version、grant version、Active/Revoked、scope summaryを表示し、secret、token、filesystem pathを表示しません。

### SD-FAIL-CFG-001 — ConfigurationFailure

SchemaInvalid、SafetyDenied、RevisionConflict、Unauthorized、PersistenceFailure、DocumentDiverged、BindingUnavailable、ReadinessStale、UnsupportedApplyMode、RestartRequired、OutcomeUnknownを閉じた分類とします。外部結果は`application_certainty: DefinitelyApplied | DefinitelyNotApplied | OutcomeUnknown`と`operation_result: Success | Failure | Cancelled | Timeout`を直交させ、原因と不確実性を一つの文字列へ潰しません。

## State Snapshot authorityとsecret

State Snapshotはcommit済みDomain StateのSource of Truthです。journalはaudit/Projectionを支えますが、StateやEffectをreplay生成しません。Snapshot破損時は検証済み旧Snapshot/Recovery Pointへ明示restoreし、どちらもなければRecovery停止します。

Domain/Application/Effectは`SecretRef`、`SecretPurpose`、`RequiredAccess`だけを持ち、material解決はAdapter privateです。config/diff/export、Command response、Failure、Event、Snapshot、journal、outbox/inbox、Projection/API/SSE、doctor、log/metric/trace、prompt/tool、Effect serialization、crash record、migration backup、install report、exception chainをcanary検査対象にします。
