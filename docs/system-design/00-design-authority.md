# 設計契約索引

この文書は、Design IDから唯一の正式定義を探すための索引です。意味の所有者、runtime catalog、登録順による解決機構ではありません。

## 三種類のauthorityを分ける

`owner`という一語で、文書、Domain State、runtime変更権限を混同しません。

| authority | 意味 |
| --- | --- |
| Contract write authority | canonical design contractを変更する責任。変更手続きとreview責任を表す |
| Domain State owner | そのStateを唯一所有するContext。State以外の契約では`N/A` |
| Runtime mutation authority | runtimeでそのState変更を確定できるTransition/reducer境界。AdapterやProjectionは持たない |

## 索引schema

| Design ID | 種別 | Canonical definition | Contract write authority | Domain State owner | Runtime mutation authority | Version | Status | Supersedes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| SD-CTX-EXE-001 | Context | [Execution Context](contracts/camera-observation.md#sd-ctx-exe-001--execution-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-EXE-001 | State | [ExecutionState](contracts/camera-observation.md#sd-sta-exe-001--executionstate) | Primary Sol + structural review | SD-CTX-EXE-001 | SD-TRN-EXE-001, SD-TRN-EXE-002, SD-TRN-EXE-003, SD-TRN-EXE-004, SD-TRN-EXE-005, SD-TRN-EXE-006 | 1 | draft | — |
| SD-CTX-PHY-001 | Context | [Physical Observation Context](contracts/camera-observation.md#sd-ctx-phy-001--physical-observation-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-PHY-001 | State | [PhysicalObservationState](contracts/camera-observation.md#sd-sta-phy-001--physicalobservationstate) | Primary Sol + structural review | SD-CTX-PHY-001 | SD-TRN-PHY-001, SD-TRN-PHY-002 | 1 | draft | — |
| SD-CTX-ART-001 | Context | [Artifact Context](contracts/camera-observation.md#sd-ctx-art-001--artifact-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-ART-001 | State | [ArtifactLifecycleState](contracts/camera-observation.md#sd-sta-art-001--artifactlifecyclestate) | Primary Sol + structural review | SD-CTX-ART-001 | SD-TRN-ART-001, SD-TRN-ART-002 | 1 | draft | — |
| SD-CTX-DAT-001 | Context | [Data Classification Policy Context](contracts/camera-observation.md#sd-ctx-dat-001--data-classification-policy-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-DAT-001 | State | [DataClassificationState](contracts/camera-observation.md#sd-sta-dat-001--dataclassificationstate) | Primary Sol + structural review | SD-CTX-DAT-001 | SD-TRN-DAT-001 | 1 | draft | — |
| SD-CTX-PAP-001 | Context | [Physical Action Policy Context](contracts/camera-observation.md#sd-ctx-pap-001--physical-action-policy-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-PAP-001 | State | [PhysicalActionPolicyState](contracts/camera-observation.md#sd-sta-pap-001--physicalactionpolicystate) | Primary Sol + structural review | SD-CTX-PAP-001 | Policy configuration transition（Pilot Cで定義） | 1 | draft | — |
| SD-CTX-DEX-001 | Context | [Device Test Exclusion Context](contracts/camera-observation.md#sd-ctx-dex-001--device-test-exclusion-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-DEX-001 | State | [DeviceTestExclusionState](contracts/camera-observation.md#sd-sta-dex-001--devicetestexclusionstate) | Primary Sol + structural review | SD-CTX-DEX-001 | SD-TRN-DEX-001 | 1 | draft | — |
| SD-CMD-CAM-001 | Command | [StartCameraObservation](contracts/camera-observation.md#sd-cmd-cam-001--startcameraobservation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CMD-INT-001 | Command | [CancelRequested](contracts/camera-observation.md#sd-cmd-int-001--cancelrequested) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CMD-ART-001 | Command | [RequestArtifactDeletion](contracts/camera-observation.md#sd-cmd-art-001--requestartifactdeletion) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CMD-DEX-001 | Command | [OpenDeviceTestWindow](contracts/camera-observation.md#sd-cmd-dex-001--opendevicetestwindow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-ING-001 | Event | [IngestedExternalEvent](contracts/camera-observation.md#sd-evt-ing-001--ingestedexternalevent) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-EXE-001 | Event | [EffectExecutionStartedAccepted](contracts/camera-observation.md#sd-evt-exe-001--effectexecutionstartedaccepted) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-EXE-002 | Event | [EffectExecutionFailed](contracts/camera-observation.md#sd-evt-exe-002--effectexecutionfailed) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-PHY-001 | Event | [PhysicalActionResolved](contracts/camera-observation.md#sd-evt-phy-001--physicalactionresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-PHY-002 | Event | [PhysicalProgressAssumed](contracts/camera-observation.md#sd-evt-phy-002--physicalprogressassumed) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-TIM-001 | Event | [SettleWindowElapsed](contracts/camera-observation.md#sd-evt-tim-001--settlewindowelapsed) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-TIM-002 | Event | [StartConfirmationDeadlineElapsed](contracts/camera-observation.md#sd-evt-tim-002--startconfirmationdeadlineelapsed) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-ART-001 | Event | [ArtifactReserved](contracts/camera-observation.md#sd-evt-art-001--artifactreserved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-DAT-001 | Event | [ContentClassificationDecided](contracts/camera-observation.md#sd-evt-dat-001--contentclassificationdecided) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-ART-002 | Event | [ArtifactAvailable](contracts/camera-observation.md#sd-evt-art-002--artifactavailable) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-ART-005 | Event | [ArtifactContentMaterialized](contracts/camera-observation.md#sd-evt-art-005--artifactcontentmaterialized) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-ART-003 | Event | [ArtifactCaptureFailed](contracts/camera-observation.md#sd-evt-art-003--artifactcapturefailed) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-ART-004 | Event | [ArtifactDeleteResult](contracts/camera-observation.md#sd-evt-art-004--artifactdeleteresult) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-INF-001 | Event | [ImageInterpretationResolved](contracts/camera-observation.md#sd-evt-inf-001--imageinterpretationresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-INT-001 | Event | [CancellationAccepted](contracts/camera-observation.md#sd-evt-int-001--cancellationaccepted) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-DEX-001 | Event | [DeviceTestExclusionResult](contracts/camera-observation.md#sd-evt-dex-001--devicetestexclusionresult) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-CAM-001 | Rule | [PlanCameraObservation](contracts/camera-observation.md#sd-rul-cam-001--plancameraobservation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-DEC-CAM-001 | Decision | [CameraObservationPlan](contracts/camera-observation.md#sd-dec-cam-001--cameraobservationplan) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-EXE-001 | Rule | [DetermineReadyOccurrences](contracts/camera-observation.md#sd-rul-exe-001--determinereadyoccurrences) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-EXE-002 | Rule | [DecideDispatchClaim](contracts/camera-observation.md#sd-rul-exe-002--decidedispatchclaim) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-TIM-001 | Rule | [ResolveStartConfirmationRace](contracts/camera-observation.md#sd-rul-tim-001--resolvestartconfirmationrace) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-PHY-001 | Rule | [DeriveAssumedProgress](contracts/camera-observation.md#sd-rul-phy-001--deriveassumedprogress) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-DAT-001 | Rule | [DeriveAndAuthorizeData](contracts/camera-observation.md#sd-rul-dat-001--deriveandauthorizedata) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-ART-001 | Rule | [ValidateArtifactForInterpretation](contracts/camera-observation.md#sd-rul-art-001--validateartifactforinterpretation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-ART-002 | Rule | [DecideArtifactCleanup](contracts/camera-observation.md#sd-rul-art-002--decideartifactcleanup) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-REC-001 | Rule | [DecidePhysicalRecovery](contracts/camera-observation.md#sd-rul-rec-001--decidephysicalrecovery) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-DEX-001 | Rule | [AuthorizeReferenceDeviceDispatch](contracts/camera-observation.md#sd-rul-dex-001--authorizereferencedevicedispatch) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-EXE-001 | Transition | [RegisterGraphAndPending](contracts/camera-observation.md#sd-trn-exe-001--registergraphandpending) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
| SD-TRN-EXE-002 | Transition | [ApplyDispatchClaim](contracts/camera-observation.md#sd-trn-exe-002--applydispatchclaim) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
| SD-TRN-EXE-003 | Transition | [ApplyOccurrenceResult](contracts/camera-observation.md#sd-trn-exe-003--applyoccurrenceresult) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
| SD-TRN-PHY-001 | Transition | [RecordPhysicalEvidence](contracts/camera-observation.md#sd-trn-phy-001--recordphysicalevidence) | Primary Sol + structural review | N/A | SD-CTX-PHY-001 only | 1 | draft | — |
| SD-TRN-PHY-002 | Transition | [ApplyResourceRecoveryDecision](contracts/camera-observation.md#sd-trn-phy-002--applyresourcerecoverydecision) | Primary Sol + structural review | N/A | SD-CTX-PHY-001 only | 1 | draft | — |
| SD-TRN-ART-001 | Transition | [ReserveArtifact](contracts/camera-observation.md#sd-trn-art-001--reserveartifact) | Primary Sol + structural review | N/A | SD-CTX-ART-001 only | 1 | draft | — |
| SD-TRN-ART-002 | Transition | [ApplyArtifactResult](contracts/camera-observation.md#sd-trn-art-002--applyartifactresult) | Primary Sol + structural review | N/A | SD-CTX-ART-001 only | 1 | draft | — |
| SD-TRN-DAT-001 | Transition | [RecordClassificationDecision](contracts/camera-observation.md#sd-trn-dat-001--recordclassificationdecision) | Primary Sol + structural review | N/A | SD-CTX-DAT-001 only | 1 | draft | — |
| SD-TRN-EXE-004 | Transition | [RevokeInteractionDescendants](contracts/camera-observation.md#sd-trn-exe-004--revokeinteractiondescendants) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
| SD-TRN-EXE-005 | Transition | [ApplyStartConfirmationRace](contracts/camera-observation.md#sd-trn-exe-005--applystartconfirmationrace) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
| SD-TRN-EXE-006 | Transition | [ReleaseResourceLease](contracts/camera-observation.md#sd-trn-exe-006--releaseresourcelease) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
| SD-TRN-DEX-001 | Transition | [ApplyDeviceTestExclusionResult](contracts/camera-observation.md#sd-trn-dex-001--applydevicetestexclusionresult) | Primary Sol + structural review | N/A | SD-CTX-DEX-001 only | 1 | draft | — |
| SD-POL-PHY-001 | Policy | [AssumedProgressPolicy](contracts/camera-observation.md#sd-pol-phy-001--assumedprogresspolicy) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-POL-PHY-002 | Policy | [StartConfirmationPolicy](contracts/camera-observation.md#sd-pol-phy-002--startconfirmationpolicy) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-POL-REC-001 | Policy | [PhysicalRecoveryPolicy](contracts/camera-observation.md#sd-pol-rec-001--physicalrecoverypolicy) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-POL-DAT-001 | Policy | [DataClassificationPolicy](contracts/camera-observation.md#sd-pol-dat-001--dataclassificationpolicy) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-POL-ART-001 | Policy | [ArtifactCleanupPolicy](contracts/camera-observation.md#sd-pol-art-001--artifactcleanuppolicy) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-POL-DEX-001 | Policy | [ReferenceDeviceExclusionPolicy](contracts/camera-observation.md#sd-pol-dex-001--referencedeviceexclusionpolicy) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-PHY-001 | Effect | [RequestRelativeMotion](contracts/camera-observation.md#sd-efx-phy-001--requestrelativemotion) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-TIM-001 | Effect | [AwaitSettleWindow](contracts/camera-observation.md#sd-efx-tim-001--awaitsettlewindow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-TIM-002 | Effect | [AwaitStartConfirmationDeadline](contracts/camera-observation.md#sd-efx-tim-002--awaitstartconfirmationdeadline) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-CAP-001 | Effect | [CaptureImage](contracts/camera-observation.md#sd-efx-cap-001--captureimage) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-INF-001 | Effect | [RequestImageInterpretation](contracts/camera-observation.md#sd-efx-inf-001--requestimageinterpretation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-ART-001 | Effect | [DeleteArtifact](contracts/camera-observation.md#sd-efx-art-001--deleteartifact) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-DEX-001 | Effect | [ManageDeviceTestExclusion](contracts/camera-observation.md#sd-efx-dex-001--managedevicetestexclusion) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-GPH-CAM-001 | Effect Graph | [CameraObservationGraph](contracts/camera-observation.md#sd-gph-cam-001--cameraobservationgraph) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRT-PHY-001 | Port | [RelativeMotionPort](contracts/camera-observation.md#sd-prt-phy-001--relativemotionport) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRT-TIM-001 | Port | [MonotonicTimerPort](contracts/camera-observation.md#sd-prt-tim-001--monotonictimerport) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRT-CAP-001 | Port | [ImageCapturePort](contracts/camera-observation.md#sd-prt-cap-001--imagecaptureport) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRT-INF-001 | Port | [ImageInterpretationPort](contracts/camera-observation.md#sd-prt-inf-001--imageinterpretationport) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRT-ART-001 | Port | [ArtifactContentPort](contracts/camera-observation.md#sd-prt-art-001--artifactcontentport) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRT-DEX-001 | Port | [DeviceTestExclusionPort](contracts/camera-observation.md#sd-prt-dex-001--devicetestexclusionport) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-FAIL-CAM-001 | Failure | [CameraObservationFailure](contracts/camera-observation.md#sd-fail-cam-001--cameraobservationfailure) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-REC-PHY-001 | Recovery | [PhysicalActionRecovery](contracts/camera-observation.md#sd-rec-phy-001--physicalactionrecovery) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-REC-ART-001 | Recovery | [ArtifactCleanupRecovery](contracts/camera-observation.md#sd-rec-art-001--artifactcleanuprecovery) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-REC-DEX-001 | Recovery | [DeviceTestExclusionRecovery](contracts/camera-observation.md#sd-rec-dex-001--devicetestexclusionrecovery) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-EXE-001 | Persistence | [DurableExecutionBoundary](contracts/camera-observation.md#sd-per-exe-001--durableexecutionboundary) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-EXE-002 | Persistence | [DurableResultInbox](contracts/camera-observation.md#sd-per-exe-002--durableresultinbox) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRJ-CAM-001 | Projection | [CameraObservationProjection](contracts/camera-observation.md#sd-prj-cam-001--cameraobservationprojection) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRF-PHY-001 | Profile contract | [PhysicalCapabilityProfile](contracts/camera-observation.md#sd-prf-phy-001--physicalcapabilityprofile) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-MOD-CAM-001 | Module boundary | [CameraObservationModuleBoundary](contracts/camera-observation.md#sd-mod-cam-001--cameraobservationmoduleboundary) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-MOD-EXE-001 | Module boundary | [DispatchClaimApplicationService](contracts/camera-observation.md#sd-mod-exe-001--dispatchclaimapplicationservice) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-MOD-DEX-001 | Module boundary | [ProtectedDeviceSendCoordinator](contracts/camera-observation.md#sd-mod-dex-001--protecteddevicesendcoordinator) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |

登録には次を要求します。

- Canonical definitionは、一つのfileと一つのanchorだけを指す。
- 同じDesign IDを複数箇所で定義しない。
- 同じStateを複数Contextへ登録しない。
- Design IDを変更せず意味をすり替えない。
- 意味変更は新versionまたは新Design IDとし、`Supersedes`で関係を示す。
- `draft`、`accepted`、`blocked-by-spike`、`blocked-by-owner`、`superseded`を区別する。
- 索引の存在をruntime discovery、routing priority、State mutation permissionの根拠にしない。

## Design ID

| Prefix | 対象 |
| --- | --- |
| `SD-SCN-*` | 観測可能scenario |
| `SD-CTX-*` | Context境界 |
| `SD-STA-*` | State |
| `SD-CMD-*` | Command |
| `SD-EVT-*` | Event |
| `SD-DEC-*` | Decision |
| `SD-RUL-*` | Rule |
| `SD-TRN-*` | Transition |
| `SD-POL-*` | Policy |
| `SD-PRF-*` | Profile contract |
| `SD-EFX-*` | Effect |
| `SD-GPH-*` | Effect Graph契約 |
| `SD-PRT-*` | Port |
| `SD-PRJ-*` | Projection |
| `SD-FAIL-*` | Failure |
| `SD-REC-*` | Recovery契約 |
| `SD-PER-*` | 永続化契約 |
| `SD-MOD-*` | 実装責務と依存方向 |

すべてのhelper、内部関数、DTOへIDを付けません。要件、外部境界、State所有、永続化、受入試験から参照される契約だけを登録します。

## State分類

Stateを所有者台帳へ登録する前に、次のどれかへ分類します。

| 分類 | 例 | 規則 |
| --- | --- | --- |
| Domain-owned State | Qualia lifecycle、Interaction取消、EffectOccurrence | 名前を持つContextが唯一所有する |
| Adapter operational state | audio raw buffer、socket接続、SDK session | Adapter内に閉じ、Domain Stateの事実へ昇格しない |
| External-owned state | Codex Thread本文、SemanticMemory serviceのmodel/index/cache/接続などの内部運用状態、Tapo内部姿勢 | 外部所有のままopaque ID、Observation、result Eventとして参照する |
| Derived Projection | Web read model、進行表示、revision/cursor | 正本事実、Rule入力、dispatch源にしない。provenance、再構築、stale、欠落、再同期を設計する |

Projectionのmaterialized viewとrevisionを保管する責任者は置けますが、それをDomain State ownerとは呼びません。

SemanticMemory serviceはYatagarasuの記憶を保存・検索する外部能力であり、Yatagarasuのlogical Memory record、保持・削除状態、Recall Policyの所有者ではありません。これらのDomain StateはMemory Contextが唯一所有し、SemanticMemory Adapterは要求の結果をEventとして返します。

## 初期状態

pilot設計開始時点では、個別Design IDは未登録です。縦断sliceのcanonical contractを作成した時点で一件ずつ登録します。未定義の概念を先に名前だけ登録し、巨大な中央catalogを作ることを避けます。
