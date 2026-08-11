# カメラ移動・撮影・画像解釈のcanonical contract

`SD-PRF-PHY-001`のProfile revisionは`SD-CTX-DPF-001`が唯一所有します。Camera、CFG、Bootstrap、AdapterはProfile本文を所有せず、revision refとread viewだけを利用します。

この文書はPilot AのBehavior固有契約です。[共通Execution契約](execution.md)へplanned/dispatch/result payloadを寄与します。TC70とC210はProfile／Adapter／Bootstrapの名前であり、Domain型には現れません。

## 閉じたCamera値

```text
CameraGuardFactKind = DispatchIntentCommitted |
  ExecutionStarted | MotionProgressAllowed |
  ArtifactAvailable | DataTransferAuthorized |
  DeviceTestLeaseValid | DeviceSendPermitValid |
  ResultPurposeMatches

RequestedSurface = WebProjection | Text | Voice
OutputDelivery = Surface(RequestedSurface) |
  AuthorizedArtifactReference(ArtifactRef)

MonotonicMark { clock_epoch_id, tick }
EvidenceRef { evidence_id, evidence_kind, provenance }
ContentClassificationBinding {
  classes, schema_version, derivation_policy_version
}
TransferAuthorizationBinding {
  subject_artifact_id, subject_artifact_revision,
  content_binding_digest,
  purpose, processing_location, transfer_direction,
  destination_class, authorization_revision, policy_version
}
ArtifactRef { artifact_id, revision, provenance, content_classification_binding }

TextArtifact { text, language, provenance }
DomainFieldKey = OpaqueValidatedKey(DomainObservationSchemaId)
ObservationScalar = Text | Number | Boolean | Null
StructuredObservation {
  schema_id: DomainObservationSchemaId,
  fields: Map<DomainFieldKey, ObservationScalar>,
  provenance
}
ImageMediaContract {
  allowed_encoding: NonEmptySet<Jpeg | Png>,
  color_space: Srgb,
  dimension_policy: AnyPositive | AtMost(width, height),
  integrity_algorithm: Sha256
}
ImageMediaObservation {
  encoding: Jpeg | Png,
  color_space: Srgb,
  width: PositiveInteger, height: PositiveInteger,
  content_length: NonZeroByteCount,
  integrity_digest: Sha256Digest
}
CameraPresentationPayload =
  CameraInterpretation {
    body: TextArtifact | StructuredObservation,
    inference_basis
  }
InferenceBasis {
  artifact_ref, physical_evidence_refs,
  physical_assessment, assessment_policy_version,
  fixed_at_occurrence
}

TypedPortFailure = MotionPortFailure | TimerPortFailure |
  CapturePortFailure | ArtifactStoreFailure |
  InferenceFailure | DeviceExclusionFailure

MotionPortFailure = Unsupported | AuthenticationRejected |
  ConnectionUnavailable | ProtocolRejected | MalformedResponse
TimerPortFailure = ClockUnavailable | EpochChanged | RegistrationRejected
CapturePortFailure = SourceUnavailable | DecodeFailed | EmptyFrame |
  MaterializationFailed
ArtifactStoreFailure = RevisionConflict | WriteFailed | DeleteFailed |
  ContentMissing | IntegrityMismatch
InferenceFailure = RouteUnavailable | RequestRejected | InvalidResponse |
  ProviderFailure | TransferRejected
DeviceExclusionFailure = LegacyReleaseFailed |
  ExclusiveAccessUnavailable | PermitRejected |
  Y2ReleaseFailed | LegacyRestoreFailed |
  LegacyFunctionVerificationFailed | CorrelationMismatch
DataPolicyFailure = UnknownClass | EmptyClassSet | ConflictingClass |
  MissingAuthorization | PartialAuthorization | RevokedAuthorization

CameraResultPayload =
  MotionPortResult(MotionResultPayload) |
  TimerPortResult(TimerResultPayload) |
  CapturePortResult(CaptureResultPayload) |
  InferencePortResult(InferenceResultPayload) |
  ArtifactDeletePortResult(ArtifactDeleteResultPayload) |
  DeviceExclusionPortResult(DeviceTestExclusionResult)

OutcomeBasis<F> = Failure(F) |
  Evidence(EvidenceRef) |
  FailureWithEvidence(F, EvidenceRef)
MotionResultPayload = Observed(EvidenceRef) |
  NotApplied(OutcomeBasis<MotionPortFailure>) |
  OutcomeUnknown(OutcomeBasis<MotionPortFailure>)
TimerResultPayload = Elapsed(MonotonicMark) |
  Failed(TimerPortFailure) | TimingAnchorInvalidated
CaptureResultPayload = Materialized {
    artifact_id, expected_revision,
    requested_media: ImageMediaContract,
    observed_media: ImageMediaObservation,
    provenance
  } | NotApplied(OutcomeBasis<CapturePortFailure>) |
  OutcomeUnknown(OutcomeBasis<CapturePortFailure>)
InferenceResultPayload = Succeeded(
  Presentation<CameraPresentationPayload>, provider_provenance
) |
  Failed(InferenceFailure) | Cancelled | CancelUnsupported |
  OutcomeUnknown(OutcomeBasis<InferenceFailure>)
ArtifactDeleteResultPayload = Deleted | DefinitelyNotApplied |
  Failed(ArtifactStoreFailure) |
  OutcomeUnknown(OutcomeBasis<ArtifactStoreFailure>)
```

IDはopaque valueです。解析、大小比較、生成順から業務判断をしません。Camera Ruleが導いた事実は`CameraGuardFactKind`付きの共通`GuardFactRef`へ変換し、Executionへ登録します。`OutcomeBasis`は空variantを持たず、全Port結果を根拠付きDomain Eventへ全域変換できます。`Materialized`は`observed_media`が`requested_media`を満たし、digest検証済みの場合だけ生成できます。不一致または検証不能は`OutcomeUnknown`としてArtifact cleanup／Recoveryへ渡します。

## ContextとState

```text
CameraPlannedPayload =
  PlannedRelativeMotion {
    device_id, resource_id, motion,
    candidate_profile_ref, correlation
  } |
  PlannedStartConfirmationDeadline {
    target_motion_occurrence_id,
    start_confirmation_policy_ref, correlation
  } |
  PlannedSettleWindow {
    target_motion_occurrence_id,
    started_event_ref_required: true,
    settle_policy_ref, correlation
  } |
  PlannedCapture {
    device_id, artifact_id, expected_reserved_revision,
    requested_media: ImageMediaContract,
    candidate_profile_ref, correlation
  } |
  PlannedImageInterpretation {
    artifact_id, expected_available_revision,
    output_purpose, requested_surfaces: NonEmptySet<RequestedSurface>,
    candidate_route_refs, correlation
  } |
  PlannedArtifactDeletion {
    artifact_id, expected_revision, reason, correlation
  } |
  PlannedDeviceTestExclusion {
    operation: LegacyRelease | AcquireExclusiveAccess |
      ReleaseY2Access | RestoreLegacy | VerifyLegacyFunction,
    planned_correlation: PlannedDeviceExclusionCorrelation
  }

PlannedDeviceExclusionCorrelation {
  barrier_id, test_run_id, device_id, profile_ref,
  y2_access_generation
}

CameraDispatchPayload = RequestRelativeMotion |
  AwaitStartConfirmationDeadline | AwaitSettleWindow |
  CaptureImage | RequestImageInterpretation |
  DeleteArtifact | ManageDeviceTestExclusion
```

Camera Graphは`PlannedEffectSpec<CameraPlannedPayload>`を登録し、Cameraのpure dispatch Ruleが`DispatchEffect<CameraDispatchPayload>`を生成します。settleはStarted Event後、画像解釈はAvailable Artifactと転送許可後でなければdispatch payloadにできません。

### SD-CTX-PHY-001 — Physical Observation Context

要求とは別に、物理evidenceと現在assessment、資源再利用状態を唯一所有します。

### SD-STA-PHY-001 — PhysicalObservationState

```text
PhysicalObservationRecord {
  occurrence_id, resource_id,
  requested_relative_motion,
  evidence: NonEmptyList<PhysicalEvidence>,
  current_assessment,
  assessment_policy_version,
  successor_basis_refs
}

PhysicalObservationState {
  observations: Map<OccurrenceId, PhysicalObservationRecord>,
  resource_recovery: Map<ResourceKey, ResourceRecoveryState>
}

PhysicalCertainty = Observed | Assumed |
                    DefinitelyNotApplied | OutcomeUnknown

ResourceRecoveryState = ImmediatelyReusable |
  ReusableAfterCooldown(not_before) |
  ReusableAfterReconciliation |
  OwnerConfirmationRequired | Unavailable
```

相対移動から絶対姿勢を作りません。Assumedは後着の有効なObserved／DefinitelyNotApplied evidenceより弱く、強いevidence同士の矛盾はOutcomeUnknownです。last-write-winsを禁止します。後着evidenceは既dispatch Effectを未実行に書き換えません。

### SD-CTX-ART-001 — Artifact Context

論理Artifact ID、revision、lifetime、hold、dependent occurrence、削除状態を唯一所有します。分類schemaや転送許可を所有しません。filesystem pathやstorage locatorをDomain Stateへ保持しません。

### SD-STA-ART-001 — ArtifactLifecycleState

```text
ArtifactRecord {
  artifact_id, revision,
  lifecycle,
  content_classification_binding?,
  media_contract?, media_observation?, provenance?,
  lifetime: Temporary | RetainedUntil(expiry) | OwnerManaged,
  dependent_occurrences,
  holds,
  created_by_occurrence
}

ArtifactLifecycle = Reserved | Writing | Available |
  DeletePending | Deleting | Deleted | DeleteFailed |
  DeleteOutcomeUnknown | Quarantined
```

分類bindingはData Classification Policy Contextが確定した不変snapshotです。Artifact Contextはその意味を変更しません。

### SD-CTX-DAT-001 — Data Classification Policy Context

分類schema、導出Policy version、分類済みauthorization viewを唯一所有します。Artifact、Provider、capture Adapterは所有しません。

### SD-STA-DAT-001 — DataClassificationState

```text
DataClassificationState {
  schema_version,
  derivation_policy_version,
  authorization_revision,
  authorizations: Set<DataTransferAuthorization>,
  decisions: Map<ArtifactId, ClassificationDecisionRecord>
}

ContentClass = Image | Audio | Transcript |
  Conversation | Memory | Artifact | Unknown
ContentClassSet = NonEmptySet<ContentClass>

ClassificationDecisionRecord {
  artifact_id, artifact_revision,
  content_binding: ContentClassificationBinding,
  decided_at_revision
}
```

capture画像の導出結果は`{Image, Artifact}`です。派生・結合では入力分類をunionします。分類bindingは内容の性質だけを固定し、移送許可を含みません。移送時は最新のauthorization viewからoperation単位の`TransferAuthorizationBinding`を作り、dispatch claimへ固定します。Unknown、空、矛盾、部分許可は拒否します。

### SD-CTX-PAP-001 — Physical Action Policy Context

Assumed進行、開始確認、physical retry、資源Recoveryのversion付き方針を唯一所有します。意味routingのDecision Policy Contextとは別です。機種別数値はProfileが持ちます。

### SD-STA-PAP-001 — PhysicalActionPolicyState

```text
PhysicalActionPolicyState {
  assumed_progress_policy,
  start_confirmation_policy,
  physical_retry_policy,
  physical_recovery_policy
}
```

### SD-CTX-DEX-001 — Device Test Exclusion Context

基準実機を別runtimeと安全に排他利用するtest leaseを唯一所有します。製品名や具体handleはProfile／Adapterへ閉じます。

### SD-STA-DEX-001 — DeviceTestExclusionState

```text
DeviceTestExclusionState {
  protected_devices: Map<DeviceId, DeviceSafetyBinding>,
  barrier_id, test_run_id, device_id, profile_ref,
  phase: Closed | Acquiring | Open | RevokingY2 |
         RestoringLegacy | VerifiedClosed | Failed,
  legacy_release_evidence?, exclusive_access_evidence?,
  window?, y2_access_generation?,
  cleanup_plan_ref, restoration_evidence?,
  send_permits: Map<DeviceSendPermitId, SendPermitState>
}

DeviceSafetyBinding { device_id, barrier_required: true, policy_version }
LegacyAssetBoundary {
  boundary_id: LegacyAssetBoundaryId,
  access_policy: ReadEvidenceOnly | NoAccess
}
SendPermitState {
  permit_id, barrier_id, test_run_id, device_id,
  profile_ref, y2_access_generation, attempt_id,
  expires_at, lifecycle: Issued | Consumed | Revoked
}
```

## Command

### SD-CMD-CAM-001 — StartCameraObservation

意味routingとQualia admission後の要求です。raw textやSBERT scoreを含めません。

```text
StartCameraObservation {
  interaction_id, qualia_session_id,
  device_id,
  motions: NonEmptyList<RelativeMotion>,
  output_purpose: ViewPurpose,
  requested_surfaces: NonEmptySet<RequestedSurface>,
  configuration_snapshot_version
}

RelativeMotion {
  axis: Horizontal | Vertical,
  direction: Negative | Positive,
  amount: RelativeStep
}
```

各motionは別Occurrenceです。同じ右移動を集約しません。RelativeStepは絶対角度ではなく、ProfileがAdapter表現へ変換します。

### SD-CMD-INT-001 — CancelRequested

```text
CancelRequested { interaction_id, source, requested_event_id }
```

停止済みの事実ではありません。

### SD-CMD-ART-001 — RequestArtifactDeletion

```text
RequestArtifactDeletion {
  artifact_id, expected_revision,
  reason: InteractionTerminal | CaptureFailed | Cancelled |
          AbandonedReservation | RecoveryCleanup
}
```

### SD-CMD-DEX-001 — OpenDeviceTestWindow

```text
OpenDeviceTestWindow {
  test_run_id, device_id, profile_ref,
  requested_window, cleanup_plan_ref
}
```

`AbortDeviceTestWindow`と`CloseDeviceTestWindow`は同じContextへ入る別variantです。

## Event

### SD-EVT-PHY-001 — PhysicalActionResolved

```text
PhysicalActionResolved {
  occurrence_id, attempt_id,
  result: Observed(EvidenceRef) |
          DefinitelyNotApplied(OutcomeBasis<MotionPortFailure>) |
          OutcomeUnknown(OutcomeBasis<MotionPortFailure>),
  adapter_event_ref
}
```

時間経過だけでObservedを返しません。

### SD-EVT-PHY-002 — PhysicalProgressAssumed

```text
PhysicalProgressAssumed {
  motion_occurrence_id, settle_occurrence_id,
  started_event_id, settle_event_id,
  policy_binding, assumed_at
}
```

Coreの純粋Ruleが導くDomain Eventであり、Adapterは生成しません。

### SD-EVT-TIM-001 — SettleWindowElapsed

```text
SettleWindowElapsed {
  settle_occurrence_id, motion_occurrence_id,
  anchor_mark, observed_mark,
  profile_binding
}
```

同じclock epochでduration＋marginを満たした場合だけ有効です。

### SD-EVT-TIM-002 — StartConfirmationDeadlineElapsed

Started Eventの期限が先に来た事実です。開始されなかった証明ではないためOutcomeUnknownとRecoveryを生成します。

### SD-EVT-ART-001 — ArtifactReserved

```text
ArtifactReserved { artifact_id, revision, lifetime, created_by_occurrence }
```

### SD-EVT-DAT-001 — ContentClassificationDecided

```text
ContentClassificationDecided {
  artifact_id, artifact_revision,
  decision: Classified(ContentClassificationBinding) | Denied(DataPolicyFailure)
}
```

### SD-EVT-ART-002 — ArtifactAvailable

```text
ArtifactAvailable {
  occurrence_id,
  artifact_ref: ArtifactRef,
  requested_media: ImageMediaContract,
  observed_media: ImageMediaObservation,
  provenance
}
```

予約、分類、capture結果を検証した後だけ生成します。pathやstorage locatorを含みません。

### SD-EVT-ART-005 — ArtifactContentMaterialized

```text
ArtifactContentMaterialized {
  artifact_id, expected_revision,
  occurrence_id, attempt_id, generation,
  requested_media: ImageMediaContract,
  observed_media: ImageMediaObservation,
  provenance, integrity_evidence
}
```

ImageCapturePortが返すraw result Eventです。これ自体は有効ArtifactRefではありません。Artifact予約とData分類Decisionを検証したDomain Ruleが`SD-EVT-ART-002`を導きます。

### SD-EVT-ART-003 — ArtifactCaptureFailed

```text
ArtifactCaptureFailed {
  occurrence_id, attempt_id, generation,
  artifact_id, expected_revision,
  basis: OutcomeBasis<CapturePortFailure>,
  physical_outcome: DefinitelyNotApplied | OutcomeUnknown
}
```

### SD-EVT-ART-004 — ArtifactDeleteResult

```text
ArtifactDeleteResult {
  artifact_id, expected_revision,
  occurrence_id, attempt_id, generation,
  result: Deleted(new_revision)
    | DefinitelyNotApplied(reason)
    | Failed(ArtifactStoreFailure)
    | OutcomeUnknown(recovery_ref)
}
```

### SD-EVT-INF-001 — ImageInterpretationResolved

```text
ImageInterpretationResolved {
  occurrence_id, attempt_id,
  result: Succeeded {
    presentation: Presentation<CameraPresentationPayload>,
    artifact_ref, output_purpose,
    inference_route_binding,
    evidence_refs, provider_provenance,
    inference_basis
  } | Failed(InferenceFailure) |
      Cancelled | CancelUnsupported |
      OutcomeUnknown(recovery_ref)
}
```

### SD-EVT-INT-001 — CancellationAccepted

Interaction Contextが取消要求を受理した事実です。Effect取消結果や物理結果ではありません。

### SD-EVT-DEX-001 — DeviceTestExclusionResult

```text
DeviceExclusionCorrelation {
  barrier_id, test_run_id, device_id, profile_ref,
  y2_access_generation, attempt_id
}

DeviceTestExclusionOutcome =
  LegacyReleased(EvidenceRef) |
  ExclusiveAccessAcquired(EvidenceRef, generation) |
  Y2AccessReleased(EvidenceRef) |
  LegacyRestored(EvidenceRef) |
  LegacyFunctionVerified(EvidenceRef) |
  NotApplied {
    stage, basis: OutcomeBasis<DeviceExclusionFailure>
  } |
  OutcomeUnknown {
    stage, basis: OutcomeBasis<DeviceExclusionFailure>, recovery_ref?
  }

DeviceTestExclusionResult {
  correlation: DeviceExclusionCorrelation,
  outcome: DeviceTestExclusionOutcome
}
```

全結果はwrapper型により`DeviceExclusionCorrelation`を必須にし、別window／generationのlate resultを現在barrierへ適用しません。

## Rule、Decision、Transition

### SD-RUL-CAM-001 — PlanCameraObservation

Command、Capability view、configuration snapshot、Profile candidate、Policy viewだけを読みます。I/Oを行いません。未対応、未ready、Profile／Policy欠落を型付き拒否し、受理時は`SD-DEC-CAM-001`を返します。

### SD-DEC-CAM-001 — CameraObservationPlan

```text
CameraObservationPlan = Rejected(CameraObservationFailure) |
  Accepted {
    graph, artifact_reservation_decision,
    configuration_snapshot_version,
    candidate_profile_refs, policy_refs
  }
```

commit候補は読取りviewと同じexpected revisionを必ず持ちます。

```text
CameraPlanCommitCandidate {
  decision: CameraObservationPlan,
  accepted_admission_identity,
  interaction_id, qualia_session_id,
  behavior_identity, behavior_version,
  initial_execution_subject,
  expected_interaction_state_revision,
  expected_qualia_state_revision,
  expected_configuration_snapshot_record_generation,
  exact_pinned_configuration_snapshot_ref,
  expected_dpf_state_revision,
  expected_physical_profile_record_generation,
  exact_physical_profile_revision_ref,
  expected_qpr_state_revision,
  expected_quality_profile_record_generation,
  exact_quality_profile_revision_ref,
  expected_artifact_state_revision,
  expected_execution_state_revision,
  graph, planned_effect_specs, artifact_reservation_decision
}
```

`ArtifactId`は`interaction_id + graph_id + capture ordinal`から純粋なtyped constructorで導出し、同じPlanの再評価で変化させません。外部乱数やfilesystem pathをID生成に使いません。

Profile/QPRのRevisionUseはInteraction admissionでは取得しません。`StartCameraObservation`のplan後、`SD-PER-CAM-001`でexact Profile/QPR revisionとGraphを同時に固定します。

### SD-RUL-CAM-002 — BuildCameraDispatchEffect

`CameraPlannedPayload`、確定済みevidence、Artifact revision、Profile／Policy snapshot、Data authorization、DEX permit、Application取得のdispatch mark、共通attempt IDをpureに評価し、完全な`CameraDispatchPayload`または型付き拒否を返します。物理資源が`ImmediatelyReusable`でない場合も拒否します。開始確認Effectにはdispatch mark、DEX correlationにはattempt IDを束縛し、後付けを禁止します。

### SD-RUL-TIM-001 — ResolveStartConfirmationRace

moveのStarted Eventとdeadline Eventを同じExecution revision上で評価します。先にcommitされたStartedはdeadline occurrenceをrevokeしsettleを許可します。先にcommitされたdeadlineはmoveをOutcomeUnknown／Recoveringにし、後着Startedをlate evidenceとしてRecoveryへだけ相関します。

### SD-RUL-PHY-001 — DeriveAssumedProgress

Started ingest mark、settle Event、blocking evidence、固定済みPolicyを評価します。同一clock epochかつ時間条件成立時だけ`PhysicalProgressAssumed`を返します。epoch不一致、Started欠落、Failure、DefinitelyNotApplied、OutcomeUnknownでは返しません。

### SD-RUL-DAT-001 — DeriveAndAuthorizeData

capture provenanceから`{Image, Artifact}`を導出し、全分類をunionしてall-of authorizationを評価します。Adapterが申告した分類を確定値として採用しません。転送guardは`subject_artifact_id`、`subject_artifact_revision`、`content_binding_digest`が対象Artifactと不変の分類bindingに一致し、全分類が同じauthorization revisionで許可された場合だけ成立します。

### SD-RUL-ART-001 — ValidateArtifactForInterpretation

Available、revision一致、hold有効、分類authorization済み、未削除、要求captureとの相関を確認します。

### SD-RUL-ART-002 — DecideArtifactCleanup

Interaction terminalまたはdurable Recovery handoff、dependent occurrenceなし、holdなし、Temporaryをすべて満たす場合だけ削除Decisionを返します。

### SD-RUL-REC-001 — DecidePhysicalRecovery

OutcomeUnknownを自動retryしません。初期Pilotのphysical retryはNoneです。retry可否と資源再利用状態を別Decisionとして返します。

### SD-RUL-DEX-001 — AuthorizeReferenceDeviceDispatch

DEX Stateの`protected_devices`に未登録なら通常admissionへ進みます。登録済みdeviceはProfileの自己申告でbarrierを無効化できません。Open、device/profile/test run/generation一致、release/exclusive evidence、window内をすべて要求し、実送信直前用の単回`DeviceSendPermit` Decisionを返します。

### SD-TRN-PHY-001 — RecordPhysicalEvidence

evidenceをappendし、version付きprecedence Ruleでassessmentを再計算します。後着evidenceで履歴を上書きしません。

### SD-TRN-PHY-002 — ApplyResourceRecoveryDecision

Physical Observation Contextの`resource_recovery`だけを変更します。Execution leaseとDEX phaseを変更しません。SchedulerはこのStateを正本として読み、`OwnerConfirmationRequired`または`Unavailable`を使うclaimを拒否します。

### SD-TRN-ART-001 — ReserveArtifact

Artifact ContextのStateだけへReservedを適用します。`SD-PER-EXE-001`のUnit of Workは、このTransitionと`SD-TRN-EXE-001`の二つの出力を原子的にcommitします。一方だけを公開しません。

### SD-TRN-ART-002 — ApplyArtifactResult

Started captureを`Reserved -> Writing`、Started deleteを`DeletePending -> Deleting`へ進め、capture、classification、delete結果をrevision／occurrence／attempt／generation一致時だけ適用します。分類決定はせず、Data bindingを参照します。同一delete attemptの同一terminal結果はreplayし、revision不一致はConflictです。

### SD-TRN-DAT-001 — RecordClassificationDecision

分類導出とauthorization DecisionをData Classification Stateだけへ適用し、決定EventをArtifact／Executionへ渡します。Provider、Skill、FetcherはこのStateを変更しません。

### SD-TRN-DAT-002 — ApplyDataPolicyConfiguration

CFGのatomic group activation候補が持つtyped data Policy revisionをexpected Data State revisionへ純粋に適用します。CFG State、Skill grant、Artifact Stateを変更しません。

### SD-TRN-PAP-001 — ApplyPhysicalActionPolicyConfiguration

Assumed進行、開始確認、physical retry、resource Recoveryのversion付きPolicy revisionをexpected Physical Action Policy State revisionへ純粋に適用します。`PhysicalCapabilityProfile`の数値とdevice bindingは変更しません。

### SD-TRN-EXE-005 — ApplyStartConfirmationRace

`SD-RUL-TIM-001`のDecisionだけを適用します。Started勝者ならdeadlineをrevokeし、deadline勝者ならmoveと未dispatch子孫をRecovering／Revokedへ進めます。後着Eventで勝敗を反転しません。

### SD-PER-CAM-001 — CameraPlanRegistrationUoW

`CameraPlanCommitCandidate`が固定したCFG、BRP、IRP、INT、QLI、pin済みCFG snapshot record、DPF、QPR、ART、EXEのexpected revisionを一つのState Snapshot transactionで全CASします。全て成功した場合だけ、`SD-PER-CFG-005`と`SD-PER-EXE-007`を合成し、exact CFG/BRP/IRP RevisionUse、`SD-RUL-EXE-006`、`SD-EVT-EXE-008`、`SD-TRN-EXE-015`によるgeneration 0のinitial lineage/subject、Interaction/Qualia admission、exact Profile/QPRの`RevisionUse(ExecutionGraph)`、Camera Plan、Artifact reservation、`SD-TRN-EXE-001`による初期Graph、PlannedEffectSpec、`OccurrenceOrigin.InitialAdmission`、pending leaseを同一Snapshot revisionへcommitします。

同じadmission identityと同じinteraction/session/Behavior/revision binding/Graph digestの再送は既存結果を返し、二つ目のlineage、Graph、Artifact、RevisionUseを作りません。同じlineageまたはadmission identityを異なるpayloadへ再利用した場合はConflictです。一つでもCASが競合した場合は全書込みを棄却します。Plan read後のCFG/BRP/IRPまたはProfile/QPR GC、ART reservation、EXE Graph登録とのraceで、CFG useだけ、BRP/IRP useだけ、lineageだけ、Profile/QPR Useだけ、Artifactだけ、Graph/pendingだけを残しません。Interaction admissionはCamera Profile/QPR Useを先行取得しません。Graph terminalまたはdurable Recoveryへの責任移管後にだけUseを解放します。

### SD-TRN-DEX-001 — ApplyDeviceTestExclusionResult

排他phase、evidence、send permitを更新します。expiry／abortでは未消費permitをrevokeして新規dispatchを禁止し、Y2解放、cleanup、legacy復帰・確認へ進めます。未復帰はFailed Eventを出し、Physical Observation Contextへresource quarantine Decisionを渡します。

## Policy

### SD-POL-PHY-001 — AssumedProgressPolicy

どのlogical capability／Profileでsettle後Assumedを後続guardが許せるかを閉じた値で宣言します。既定denyです。

### SD-POL-PHY-002 — StartConfirmationPolicy

dispatch後にStartedを待つ単調durationと期限切れのOutcomeUnknown／Recovery handoffを宣言します。数値未測定Profileはrelease-readyではありません。

### SD-POL-REC-001 — PhysicalRecoveryPolicy

DefinitelyNotAppliedだけを将来の明示Policyでretry候補にできます。OutcomeUnknownは自動retry禁止です。資源再利用の五値をcertaintyと別に返します。

### SD-POL-DAT-001 — DataClassificationPolicy

capture分類の導出、派生union、all-of transfer authorization、Unknown fail-closedを定義します。

### SD-POL-ART-001 — ArtifactCleanupPolicy

Temporary成果物のhold、dependent occurrence、terminal／handoffを評価し、無言削除や参照中削除を禁止します。

### SD-POL-DEX-001 — ReferenceDeviceExclusionPolicy

保護device登録、動的test lease、単回send permit、expiry、abort、cleanup、legacy復帰確認を定めます。保護device登録は安全設定であり、device Profileの値では解除できません。Bootstrap起動時の一回限りのpreconditionでもありません。

Y2 Adapter／test harnessは`LegacyAssetBoundary`を越えてY1 repository、runtime、configuration、dataへ書込みません。排他取得はhandle/session解放とtransport／物理排他の証拠で行い、Y1資産の書換えで実現しません。

## Effect

この節の型はdispatch時に全値が固定された`DispatchEffect`です。Graphが保持する`PlannedEffectSpec`とは区別し、Adapterによる遅延補完やdispatch後の書換えを許しません。

### SD-EFX-PHY-001 — RequestRelativeMotion

```text
RequestRelativeMotion {
  device_id, resource_id, motion,
  effective_profile_binding,
  correlation
}
```

### SD-EFX-TIM-001 — AwaitSettleWindow

Startedの`MonotonicMark`、duration、margin、Profile bindingを持ちます。

### SD-EFX-TIM-002 — AwaitStartConfirmationDeadline

dispatch intentのmark、timeout、Policy bindingを持ちます。

### SD-EFX-CAP-001 — CaptureImage

予約先Artifact ID／revision、device、capture Profile、correlationを持ちます。有効ArtifactRefを先取りしません。

### SD-EFX-INF-001 — RequestImageInterpretation

Available ArtifactRef、OutputPurpose、effective route、ContentClassificationBinding、operation単位のTransferAuthorizationBinding、InferenceBasis、correlationを持ちます。

### SD-EFX-ART-001 — DeleteArtifact

Artifact ID、expected revision、削除reasonを持ちます。pathを持ちません。

### SD-EFX-DEX-001 — ManageDeviceTestExclusion

legacy release、exclusive access取得、Y2解放、legacy restore、function verificationの閉じたoperationと完全な`DeviceExclusionCorrelation`を持ちます。

## Effect Graph

### SD-GPH-CAM-001 — CameraObservationGraph

```text
M1 --dispatch--> D1(start deadline)
M1 --started; revoke D1--> S1(settle)
D1 --elapsed before started--> OutcomeUnknown / Recovery
S1 --elapsed + AssumedPolicy allow--> M2 ...
Mn --started; revoke Dn--> Sn
Sn --AssumedPolicy allow--> C(capture)
C  --ArtifactAvailable + Data authorized--> I(interpret)
I  --purpose-valid success--> Projection
terminal/handoff + no dependents/holds --> Delete temporary Artifact
```

- 各M、D、Sは別Occurrenceです。
- Graph登録時に、`DispatchIntentCommitted`、`PhysicalProgressAssumed`、`ArtifactAvailable`、`DataAuthorized`、`PurposeValid`を不変`GuardFactDeclaration`と、lifecycleの唯一正本である`GuardFactRecord.status=Pending`として登録します。Occurrence由来factはproducer occurrenceとCamera/PHY/ART/DAT owner Event kindを固定し、Policy/State由来factは`OwnerStateDerived`を明示します。未宣言factとsource不明を拒否します。
- Dのguardは`DispatchIntentCommitted(M, attempt)`です。Startedとdeadlineの競合は`SD-RUL-TIM-001`と`SD-TRN-EXE-005`で同じrevision列へ直列化します。
- DefinitelyNotApplied、Failure、OutcomeUnknownは未dispatch子孫をrevokeします。
- late blocking evidenceは現在assessmentを更新します。既dispatch子孫を未実行にせず、取消可能なら別Cancel Effect、不能ならRecoveryへ渡します。
- successor dispatch時の`InferenceBasis`を固定します。後着evidenceで前提が無効になればProjectionを新revisionの`PremiseInvalidated`／Recoveringへ進め、既Eventを改変しません。
- visual-frame区間leaseは最初のmove claimからcapture terminal／Recovery handoffまで他Graphの競合を防ぎます。意味順序には使いません。
- 複数resourceは正規化したResourceKey順に一つのclaim Decisionで全件取得し、一件でも競合すれば一件も取得しません。releaseは各leaseの閉じた`release_guard`をTransitionが評価します。
- dependency cycle、self edge、別Graph edge、guard/result型不一致に加え、producerがconsumer自身またはdescendantになるfuture factをcommit前に拒否します。

## Port

すべてのCamera Adapterは、共通実行契約の
`PortResultEnvelope<CameraResultPayload>`で結果をEvent ingressへ戻します。
Port例外を直接applicationへ投げず、Cameraの閉じたpayloadへ正規化します。
共通envelope、安定したAdapter操作ID、ack条件は
[execution.md](execution.md)だけが定義し、この契約では再定義しません。

### SD-PRT-PHY-001 — RelativeMotionPort

Occurrence／attempt付きEffectを受け、Started、DefinitelyNotApplied、OutcomeUnknown、typed FailureのDomain Eventへ正規化します。protected deviceでは、`SD-MOD-DEX-001`が消費済みにした単回`DeviceSendPermit`を必須とし、Adapter自身はpermit Stateやclose/abortとの順序を所有しません。Observedを返すにはProfileが要求するevidenceが必要です。

### SD-PRT-TIM-001 — MonotonicTimerPort

同じclock epochのmarkだけを比較し、elapsedまたはtyped Failureを返します。restart後epochが変わればwall clock補完せずTimingAnchorInvalidated／OutcomeUnknownです。

### SD-PRT-CAP-001 — ImageCapturePort

device captureと予約Artifactへの初回materializationを行う唯一のwrite境界です。Started、`SD-EVT-ART-005`、DefinitelyNotApplied、Failure、OutcomeUnknownを完全なcorrelation付きで返します。pathや分類決定を返しません。

### SD-PRT-INF-001 — ImageInterpretationPort

Available ArtifactRefとData bindingを受け、成功、Failure、Cancel、CancelUnsupported、OutcomeUnknownを返します。Provider schemaをDomainへ漏らしません。

### SD-PRT-ART-001 — ArtifactContentPort

Artifact ID／revisionでread/deleteします。captureの初回writeは行いません。deleteはattempt IDをidempotency keyとして、成功、DefinitelyNotApplied、Failure、OutcomeUnknownを完全なcorrelation付きで返します。locator mappingはAdapter private stateです。

### SD-PRT-DEX-001 — DeviceTestExclusionPort

legacy runtimeと物理／transport排他の外部操作を行い、`SD-EVT-DEX-001`へ正規化します。

## Failure

### SD-FAIL-CAM-001 — CameraObservationFailure

CapabilityUnavailable、UnsupportedMotion、ProfileInvalid、PolicyDenied、ResourceBusy、DispatchConflict、PhysicalDefinitelyNotApplied、PhysicalOutcomeUnknown、StartConfirmationTimeout、TimingAnchorInvalidated、TimerFailure、CaptureFailure、ArtifactInvalid、DataClassificationDenied、TransferDenied、InferenceRouteUnavailable、InterpretationFailure、Cancelled、PersistenceFailure、ExclusionBarrierClosedを閉じた分類とします。stage、occurrence、attempt、diagnostic refを持ち、未解析例外文字列をProjectionへ出しません。

## Recoveryと永続化

### SD-REC-PHY-001 — PhysicalActionRecovery

- dispatch intent commit前は送信しません。
- intent commit後に送信有無を証明できないcrashはOutcomeUnknownで自動再送しません。
- cancel後のdispatch済みmoveはnon-cancellableとして追跡し、子孫だけをrevokeします。
- 旧session／generationの遅い結果は旧Recoveryへだけ相関します。
- clock epoch変更時はsettleをAssumedへ進めません。
- resource reuseとphysical certaintyを別々に回復します。

### SD-REC-ART-001 — ArtifactCleanupRecovery

Reserved orphan、capture失敗、cancel、terminal後temporary artifactをcleanup候補にします。hold／dependent occurrenceがあれば削除しません。Delete OutcomeUnknownは再送せず照合／Owner判断へ渡します。

### SD-REC-DEX-001 — DeviceTestExclusionRecovery

window expiry、abort、process crashで新規dispatchを止め、Y2 access解放、cleanup、legacy復帰、機能確認を継続します。復帰未確認ならresourceをquarantineします。

| Effect class | intent後・結果前crash | DefinitelyNotApplied | OutcomeUnknown |
| --- | --- | --- | --- |
| Relative motion | 自動再送せず照合/Recovery | 初期は再送なし。将来明示Policyのみ | 再送禁止、resource Recovery |
| Timer | 同一clock epochとtimer tokenを照合。証明不能ならinvalidated | 明示的に再登録可能と証明したPolicyだけ | Assumedを作らずRecovery |
| Capture/materialize | Artifact ID/revision/integrityを照合。blind retry禁止 | 初期は再送なし | cleanup/reconciliation、blind retry禁止 |
| Inference | provider operation IDを照合またはcancel。新requestを自動生成しない | 初期は再送なし | late result隔離、Recovery |
| Artifact delete | logical ID/revisionで存在照合。blind retry禁止 | 削除不要の終端としてPolicy評価 | Deletedを主張せずRecovery |
| Device exclusion | barrier stage/generationを照合し同じRecoveryを継続 | stage固有Policyで次手を決める | 新規device dispatch禁止、legacy復帰Recovery |

API request idempotency、EffectOccurrence recovery、Port attempt idempotencyは別keyです。初期Pilotは上表で明示したもの以外の自動retryを行いません。

## Projection

### SD-PRJ-CAM-001 — CameraObservationProjection

```text
CameraObservationProjection {
  revision, interaction_id,
  stage: Accepted | Moving | Settling | Capturing |
    Interpreting | Completed | PremiseInvalidated |
    Cancelled | Failed | Recovering,
  requested_motions,
  physical_certainty?, inference_basis?,
  artifact_ref?, output_purpose,
  presentation?, failure?, recovery_state?,
  causal_timestamps, missing_measurement_reasons
}
```

Assumedを移動完了確認済みと表示せず、取消受理を物理停止と表示しません。path、secret、Provider raw responseを含めません。

## Profile

### SD-PRF-PHY-001 — PhysicalCapabilityProfile

```text
PhysicalCapabilityProfile {
  profile_id, version,
  supported_relative_motions,
  motion_translation_parameters,
  expected_action_duration, settle_margin,
  start_confirmation_timeout,
  start_confirmation_semantics,
  resource_claims,
  recovery_policy_binding,
  measurement_evidence_ref,
  release_readiness
}
```

TC70は第一基準、C210は同じschemaの第二基準Profileです。数値、firmware、protocol、Tapo API、WorkingTimeはProfile／Adapterだけに置きます。候補ProfileはInteractionのconfiguration snapshotから選び、`SD-TRN-EXE-002`のdispatch claimでeffective bindingをOccurrenceへ固定します。

Profile本文とrevision lifecycleの唯一Ownerは`SD-CTX-DPF-001`です。CFG snapshotはrevision refだけを持ち、`SD-RUL-CAM-001`はDPF/QPR read viewからcandidateを選びます。`SD-PER-CAM-001`がそのcandidateとQPR useをGraphと同時固定し、`SD-RUL-CAM-002`はcurrent Profileへ差し替えず、同じretained candidate revisionをdispatch用effective bindingへ変換します。Profile更新は既存Interaction／Occurrenceへ遡及しません。

## 実装責務

### SD-MOD-CAM-001 — CameraObservationModuleBoundary

- Rust Domain: 値、Rule、Policy、Transition、Graph validation、Failure。
- Rust application: Unit of Work、dispatch claim、scheduler、Recovery、Projection。
- Port: motion、timer、capture、inference、artifact content、test exclusion。
- Adapter: TC70/C210、Clock、store、Provider、legacy runtime連携。
- Python worker: 画像推論結果だけを返し、State／Graph／route／Artifactを所有しない。
- Bootstrap: concrete AdapterとProfile binding。動的test leaseを一回限りの起動条件へ隠さない。

### SD-MOD-DEX-001 — ProtectedDeviceSendCoordinator

保護deviceごとに一つのapplication actorとして、送信要求、window close、abort、expiryを同じmailbox順へ直列化します。このactorはDomain Stateを所有せず、各messageでDEX Stateを読み、pure Ruleを評価し、`SD-TRN-DEX-001`によるpermitの`Consumed`化をdurable commitしてから、その同じactor turnで`SD-PRT-PHY-001`を呼びます。close／abort／expiryは後続messageとして処理されるため、permit検証と送信の間へ割り込みません。

`Consumed` commit後・実送信前にprocessがcrashした場合は、送信有無を推測せずOutcomeUnknownとして扱い、自動再送しません。actor、Port、AdapterはDEX Stateを直接変更しません。`LegacyAssetBoundaryId`から実pathへの対応はDEX Adapterのprivate configurationであり、Domain StateやEventへ露出しません。

permitを`Consumed`へcommitした単調時刻がwindow内なら、その一回は`in-flight`として許可済みです。Port call中にwindow期限を越えても作用を取り消したとは主張せず、expiry messageは次の送信を禁止して現在attemptを追跡します。consume前に期限を越えたpermitは拒否します。この境界がTC70で成立することは実機race spikeで確認します。

IPC、process数、storage engine、Web更新transportはこの契約の意味を変えない限りPilot Gateを止めません。
