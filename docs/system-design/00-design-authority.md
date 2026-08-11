# 設計契約索引

この文書は、Design IDから唯一の正式定義を探すための索引です。意味の所有者、runtime catalog、登録順による解決機構ではありません。

## 三種類のauthorityを分ける

`owner`という一語で、文書、Domain State、runtime変更権限を混同しません。

| authority | 意味 |
| --- | --- |
| Contract write authority | canonical design contractを変更する責任。変更手続きとreview責任を表す |
| Domain State owner | そのStateを唯一所有するContext。State以外の契約では`N/A` |
| Runtime mutation authority | runtimeでそのState変更を確定できるTransition/reducer境界。AdapterやProjectionは持たない |

`Status`列はcanonical contract自体のlifecycleであり、Atomic Design Obligationの
Accounting／Design／Proof statusではありません。

`draft`は設計中であり、slice単体のarchitecture reviewには使用できますが、三本全体の
Design Pilot Gate PASSには使用できません。`accepted`は、参照するatomic obligationが
Design=`designed`、機械検査がpassing、architecture challengerのCritical／Highが解消し、
Primaryが承認した契約です。Pilot C完了後、三本の相互整合を再審査してから一括ではなく
参照契約ごとに`draft`から`accepted`へ昇格します。意味変更はVersionを上げて再審査し、
旧契約を`superseded`にします。`blocked-by-spike`と`blocked-by-owner`は契約自体を確定できない
場合に限り、Proofの同名状態とは区別します。

機械検査可能性のため、`SD-STA-*`のDomain State ownerには一つの`SD-CTX-*`だけを記載します。
Runtime mutation authorityにはcanonical `SD-TRN-*`だけを列挙します。Pilot Cで確定した
Policy configuration Transitionも例外なく正式なTransition IDで参照します。
Adapter、Projection、Port、Python workerをState ownerまたはmutation authorityにしません。
`SD-MOD-RBI-001`のcandidate slot mapは各Capabilityの`SpecificRuntimeState`へ埋め込まれ、
そのCapability StateのContextだけがslotの不在確認、初期生成、revision更新、終端を所有します。
RCP、CFG、EXEは同一UoWへ参加してもslot ownerにはなりません。

## 索引schema

| Design ID | 種別 | Canonical definition | Contract write authority | Domain State owner | Runtime mutation authority | Version | Status | Supersedes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| SD-CTX-EXE-001 | Context | [Execution Context](contracts/execution.md#sd-ctx-exe-001--execution-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-EXE-001 | State | [ExecutionState](contracts/execution.md#sd-sta-exe-001--executionstate) | Primary Sol + structural review | SD-CTX-EXE-001 | SD-TRN-EXE-001, SD-TRN-EXE-002, SD-TRN-EXE-003, SD-TRN-EXE-004, SD-TRN-EXE-005, SD-TRN-EXE-006, SD-TRN-EXE-007, SD-TRN-EXE-008, SD-TRN-EXE-009, SD-TRN-EXE-010, SD-TRN-EXE-011, SD-TRN-EXE-012, SD-TRN-EXE-013, SD-TRN-EXE-014, SD-TRN-EXE-015 | 1 | draft | — |
| SD-EVT-ING-001 | Event | [IngestedExternalEvent](contracts/execution.md#sd-evt-ing-001--ingestedexternalevent) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-EXE-001 | Event | [EffectExecutionStartedAccepted](contracts/execution.md#sd-evt-exe-001--effectexecutionstartedaccepted) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-EXE-002 | Event | [EffectExecutionFailed](contracts/execution.md#sd-evt-exe-002--effectexecutionfailed) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-EXE-003 | Event | [GuardFactRecorded](contracts/execution.md#sd-evt-exe-003--guardfactrecorded) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-EXE-001 | Rule | [DetermineReadyOccurrences](contracts/execution.md#sd-rul-exe-001--determinereadyoccurrences) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-EXE-002 | Rule | [DecideDispatchClaim](contracts/execution.md#sd-rul-exe-002--decidedispatchclaim) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-EXE-001 | Transition | [RegisterGraphAndPending](contracts/execution.md#sd-trn-exe-001--registergraphandpending) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
| SD-TRN-EXE-002 | Transition | [ApplyDispatchClaim](contracts/execution.md#sd-trn-exe-002--applydispatchclaim) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
| SD-TRN-EXE-003 | Transition | [ApplyOccurrenceResult](contracts/execution.md#sd-trn-exe-003--applyoccurrenceresult) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
| SD-TRN-EXE-004 | Transition | [RevokeExecutionSubjectDescendants](contracts/execution.md#sd-trn-exe-004--revokeexecutionsubjectdescendants) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
| SD-TRN-EXE-006 | Transition | [ReleaseResourceLease](contracts/execution.md#sd-trn-exe-006--releaseresourcelease) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
| SD-TRN-EXE-007 | Transition | [ApplyGuardFact](contracts/execution.md#sd-trn-exe-007--applyguardfact) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
| SD-TRN-EXE-008 | Transition | [ApplyCompetingOccurrenceWinner](contracts/execution.md#sd-trn-exe-008--applycompetingoccurrencewinner) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
| SD-PER-EXE-001 | Persistence | [DurableExecutionBoundary](contracts/execution.md#sd-per-exe-001--durableexecutionboundary) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-EXE-002 | Persistence | [DurableResultInbox](contracts/execution.md#sd-per-exe-002--durableresultinbox) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-MOD-EXE-001 | Module boundary | [DispatchClaimApplicationService](contracts/execution.md#sd-mod-exe-001--dispatchclaimapplicationservice) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CTX-PHY-001 | Context | [Physical Observation Context](contracts/camera-observation.md#sd-ctx-phy-001--physical-observation-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-PHY-001 | State | [PhysicalObservationState](contracts/camera-observation.md#sd-sta-phy-001--physicalobservationstate) | Primary Sol + structural review | SD-CTX-PHY-001 | SD-TRN-PHY-001, SD-TRN-PHY-002 | 1 | draft | — |
| SD-CTX-ART-001 | Context | [Artifact Context](contracts/camera-observation.md#sd-ctx-art-001--artifact-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-ART-001 | State | [ArtifactLifecycleState](contracts/camera-observation.md#sd-sta-art-001--artifactlifecyclestate) | Primary Sol + structural review | SD-CTX-ART-001 | SD-TRN-ART-001, SD-TRN-ART-002 | 1 | draft | — |
| SD-CTX-DAT-001 | Context | [Data Classification Policy Context](contracts/camera-observation.md#sd-ctx-dat-001--data-classification-policy-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-DAT-001 | State | [DataClassificationState](contracts/camera-observation.md#sd-sta-dat-001--dataclassificationstate) | Primary Sol + structural review | SD-CTX-DAT-001 | SD-TRN-DAT-001, SD-TRN-DAT-002 | 1 | draft | — |
| SD-CTX-PAP-001 | Context | [Physical Action Policy Context](contracts/camera-observation.md#sd-ctx-pap-001--physical-action-policy-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-PAP-001 | State | [PhysicalActionPolicyState](contracts/camera-observation.md#sd-sta-pap-001--physicalactionpolicystate) | Primary Sol + structural review | SD-CTX-PAP-001 | SD-TRN-PAP-001 | 1 | draft | — |
| SD-CTX-DEX-001 | Context | [Device Test Exclusion Context](contracts/camera-observation.md#sd-ctx-dex-001--device-test-exclusion-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-DEX-001 | State | [DeviceTestExclusionState](contracts/camera-observation.md#sd-sta-dex-001--devicetestexclusionstate) | Primary Sol + structural review | SD-CTX-DEX-001 | SD-TRN-DEX-001 | 1 | draft | — |
| SD-CMD-CAM-001 | Command | [StartCameraObservation](contracts/camera-observation.md#sd-cmd-cam-001--startcameraobservation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CMD-INT-001 | Command | [CancelRequested](contracts/camera-observation.md#sd-cmd-int-001--cancelrequested) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CMD-ART-001 | Command | [RequestArtifactDeletion](contracts/camera-observation.md#sd-cmd-art-001--requestartifactdeletion) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CMD-DEX-001 | Command | [OpenDeviceTestWindow](contracts/camera-observation.md#sd-cmd-dex-001--opendevicetestwindow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
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
| SD-RUL-CAM-002 | Rule | [BuildCameraDispatchEffect](contracts/camera-observation.md#sd-rul-cam-002--buildcameradispatcheffect) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-TIM-001 | Rule | [ResolveStartConfirmationRace](contracts/camera-observation.md#sd-rul-tim-001--resolvestartconfirmationrace) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-PHY-001 | Rule | [DeriveAssumedProgress](contracts/camera-observation.md#sd-rul-phy-001--deriveassumedprogress) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-DAT-001 | Rule | [DeriveAndAuthorizeData](contracts/camera-observation.md#sd-rul-dat-001--deriveandauthorizedata) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-ART-001 | Rule | [ValidateArtifactForInterpretation](contracts/camera-observation.md#sd-rul-art-001--validateartifactforinterpretation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-ART-002 | Rule | [DecideArtifactCleanup](contracts/camera-observation.md#sd-rul-art-002--decideartifactcleanup) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-REC-001 | Rule | [DecidePhysicalRecovery](contracts/camera-observation.md#sd-rul-rec-001--decidephysicalrecovery) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-DEX-001 | Rule | [AuthorizeReferenceDeviceDispatch](contracts/camera-observation.md#sd-rul-dex-001--authorizereferencedevicedispatch) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-PHY-001 | Transition | [RecordPhysicalEvidence](contracts/camera-observation.md#sd-trn-phy-001--recordphysicalevidence) | Primary Sol + structural review | N/A | SD-CTX-PHY-001 only | 1 | draft | — |
| SD-TRN-PHY-002 | Transition | [ApplyResourceRecoveryDecision](contracts/camera-observation.md#sd-trn-phy-002--applyresourcerecoverydecision) | Primary Sol + structural review | N/A | SD-CTX-PHY-001 only | 1 | draft | — |
| SD-TRN-ART-001 | Transition | [ReserveArtifact](contracts/camera-observation.md#sd-trn-art-001--reserveartifact) | Primary Sol + structural review | N/A | SD-CTX-ART-001 only | 1 | draft | — |
| SD-TRN-ART-002 | Transition | [ApplyArtifactResult](contracts/camera-observation.md#sd-trn-art-002--applyartifactresult) | Primary Sol + structural review | N/A | SD-CTX-ART-001 only | 1 | draft | — |
| SD-TRN-DAT-001 | Transition | [RecordClassificationDecision](contracts/camera-observation.md#sd-trn-dat-001--recordclassificationdecision) | Primary Sol + structural review | N/A | SD-CTX-DAT-001 only | 1 | draft | — |
| SD-TRN-EXE-005 | Transition | [ApplyStartConfirmationRace](contracts/camera-observation.md#sd-trn-exe-005--applystartconfirmationrace) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
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
| SD-PRJ-CAM-001 | Projection | [CameraObservationProjection](contracts/camera-observation.md#sd-prj-cam-001--cameraobservationprojection) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRF-PHY-001 | Profile contract | [PhysicalCapabilityProfile](contracts/camera-observation.md#sd-prf-phy-001--physicalcapabilityprofile) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-MOD-CAM-001 | Module boundary | [CameraObservationModuleBoundary](contracts/camera-observation.md#sd-mod-cam-001--cameraobservationmoduleboundary) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-MOD-DEX-001 | Module boundary | [ProtectedDeviceSendCoordinator](contracts/camera-observation.md#sd-mod-dex-001--protecteddevicesendcoordinator) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CTX-QLI-001 | Context | [Qualia Context](contracts/finite-conversation.md#sd-ctx-qli-001--qualia-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-QLI-001 | State | [QualiaState](contracts/finite-conversation.md#sd-sta-qli-001--qualiastate) | Primary Sol + structural review | SD-CTX-QLI-001 | SD-TRN-QLI-001, SD-TRN-QLI-002 | 1 | draft | — |
| SD-CTX-INT-001 | Context | [Interaction Context](contracts/finite-conversation.md#sd-ctx-int-001--interaction-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-INT-001 | State | [InteractionState](contracts/finite-conversation.md#sd-sta-int-001--interactionstate) | Primary Sol + structural review | SD-CTX-INT-001 | SD-TRN-INT-001, SD-TRN-INT-002 | 1 | draft | — |
| SD-CTX-CNV-001 | Context | [Conversation Context](contracts/finite-conversation.md#sd-ctx-cnv-001--conversation-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-CNV-001 | State | [ConversationState](contracts/finite-conversation.md#sd-sta-cnv-001--conversationstate) | Primary Sol + structural review | SD-CTX-CNV-001 | SD-TRN-CNV-001, SD-TRN-CNV-002, SD-TRN-CNV-003, SD-TRN-CNV-004, SD-TRN-CNV-005, SD-TRN-CNV-006, SD-TRN-CNV-007, SD-TRN-CNV-008, SD-TRN-CNV-009 | 1 | draft | — |
| SD-CTX-MEM-001 | Context | [Memory Context](contracts/finite-conversation.md#sd-ctx-mem-001--memory-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-MEM-001 | State | [MemoryState](contracts/finite-conversation.md#sd-sta-mem-001--memorystate) | Primary Sol + structural review | SD-CTX-MEM-001 | SD-TRN-MEM-001, SD-TRN-MEM-002, SD-TRN-MEM-003, SD-TRN-MEM-004, SD-TRN-MEM-005, SD-TRN-MEM-006, SD-TRN-MEM-007, SD-TRN-MEM-008, SD-TRN-MEM-009 | 1 | draft | — |
| SD-CTX-AGT-001 | Context | [Agent Session Context](contracts/finite-conversation.md#sd-ctx-agt-001--agent-session-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-AGT-001 | State | [AgentSessionState](contracts/finite-conversation.md#sd-sta-agt-001--agentsessionstate) | Primary Sol + structural review | SD-CTX-AGT-001 | SD-TRN-AGT-001, SD-TRN-AGT-002, SD-TRN-AGT-003, SD-TRN-AGT-004, SD-TRN-AGT-005, SD-TRN-AGT-006, SD-TRN-AGT-007, SD-TRN-AGT-008, SD-TRN-AGT-009, SD-TRN-AGT-010, SD-TRN-AGT-011, SD-TRN-AGT-012, SD-TRN-AGT-013 | 1 | draft | — |
| SD-CTX-NOT-001 | Context | [Notification Policy Context](contracts/finite-conversation.md#sd-ctx-not-001--notification-policy-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-NOT-001 | State | [NotificationPolicyState](contracts/finite-conversation.md#sd-sta-not-001--notificationpolicystate) | Primary Sol + structural review | SD-CTX-NOT-001 | SD-TRN-NOT-001 | 1 | draft | — |
| SD-CMD-INT-002 | Command | [SubmitInteraction](contracts/finite-conversation.md#sd-cmd-int-002--submitinteraction) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CMD-CNV-001 | Command | [StartFiniteConversation](contracts/finite-conversation.md#sd-cmd-cnv-001--startfiniteconversation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CMD-QLI-001 | Command | [ReturnToHomeRequested](contracts/finite-conversation.md#sd-cmd-qli-001--returntohomerequested) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CMD-MEM-001 | Command | [MemorizeRequested](contracts/finite-conversation.md#sd-cmd-mem-001--memorizerequested) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CMD-MEM-004 | Command | [RecallRequested](contracts/finite-conversation.md#sd-cmd-mem-004--recallrequested) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CMD-MEM-002 | Command | [DeleteMemoryRecordRequested](contracts/finite-conversation.md#sd-cmd-mem-002--deletememoryrecordrequested) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CMD-MEM-003 | Command | [ResetSemanticMemoryRequested](contracts/finite-conversation.md#sd-cmd-mem-003--resetsemanticmemoryrequested) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CMD-AGT-001 | Command | [ResetAgentThreadRequested](contracts/finite-conversation.md#sd-cmd-agt-001--resetagentthreadrequested) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CMD-AGT-002 | Command | [CompactAgentThreadRequested](contracts/finite-conversation.md#sd-cmd-agt-002--compactagentthreadrequested) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-CNV-001 | Event | [FiniteConversationStarted](contracts/finite-conversation.md#sd-evt-cnv-001--finiteconversationstarted) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-MEM-001 | Event | [SemanticMemoryRetrievalResolved](contracts/finite-conversation.md#sd-evt-mem-001--semanticmemoryretrievalresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-MEM-002 | Event | [MemorySaveResolved](contracts/finite-conversation.md#sd-evt-mem-002--memorysaveresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-MEM-003 | Event | [MemoryMutationResolved](contracts/finite-conversation.md#sd-evt-mem-003--memorymutationresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-AGT-001 | Event | [AgentTurnProgressed](contracts/finite-conversation.md#sd-evt-agt-001--agentturnprogressed) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-AGT-002 | Event | [AgentOutputProposed](contracts/finite-conversation.md#sd-evt-agt-002--agentoutputproposed) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-CNV-002 | Event | [ConversationResponseAccepted](contracts/finite-conversation.md#sd-evt-cnv-002--conversationresponseaccepted) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-OUT-001 | Event | [PresentationPublishResolved](contracts/finite-conversation.md#sd-evt-out-001--presentationpublishresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-AGT-003 | Event | [AgentCancellationResolved](contracts/finite-conversation.md#sd-evt-agt-003--agentcancellationresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-AGT-004 | Event | [AgentThreadResetResolved](contracts/finite-conversation.md#sd-evt-agt-004--agentthreadresetresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-AGT-005 | Event | [AgentThreadCompactionResolved](contracts/finite-conversation.md#sd-evt-agt-005--agentthreadcompactionresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-AGT-006 | Event | [AgentDeadlineElapsed](contracts/finite-conversation.md#sd-evt-agt-006--agentdeadlineelapsed) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-NOT-001 | Event | [ThinkingNoticeResolved](contracts/finite-conversation.md#sd-evt-not-001--thinkingnoticeresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-AUD-001 | Event | [SpeechPlaybackResolved](contracts/finite-conversation.md#sd-evt-aud-001--speechplaybackresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-DAT-002 | Event | [AuthorizedContentReadResolved](contracts/finite-conversation.md#sd-evt-dat-002--authorizedcontentreadresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-TOL-001 | Event | [ToolOperationResolved](contracts/finite-conversation.md#sd-evt-tol-001--tooloperationresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-TOL-002 | Event | [ToolCancellationResolved](contracts/finite-conversation.md#sd-evt-tol-002--toolcancellationresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-TOL-003 | Event | [ToolDeadlineElapsed](contracts/finite-conversation.md#sd-evt-tol-003--tooldeadlineelapsed) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-QLI-001 | Event | [QualiaTerminationResolved](contracts/finite-conversation.md#sd-evt-qli-001--qualiaterminationresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-INT-001 | Rule | [DecideInteractionAdmission](contracts/finite-conversation.md#sd-rul-int-001--decideinteractionadmission) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-MEM-001 | Rule | [PlanConversationRecall](contracts/finite-conversation.md#sd-rul-mem-001--planconversationrecall) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-MEM-002 | Rule | [SelectRecallRecords](contracts/finite-conversation.md#sd-rul-mem-002--selectrecallrecords) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-MEM-003 | Rule | [ResolveRecallFailure](contracts/finite-conversation.md#sd-rul-mem-003--resolverecallfailure) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-AGT-001 | Rule | [BindAgentTurn](contracts/finite-conversation.md#sd-rul-agt-001--bindagentturn) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-AGT-002 | Rule | [ValidateAgentProposal](contracts/finite-conversation.md#sd-rul-agt-002--validateagentproposal) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-AGT-003 | Rule | [DecideAgentCancellation](contracts/finite-conversation.md#sd-rul-agt-003--decideagentcancellation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-CNV-001 | Rule | [DecideAutoSave](contracts/finite-conversation.md#sd-rul-cnv-001--decideautosave) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-NOT-001 | Rule | [DecideThinkingNotice](contracts/finite-conversation.md#sd-rul-not-001--decidethinkingnotice) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-CNV-002 | Rule | [DecideConversationTermination](contracts/finite-conversation.md#sd-rul-cnv-002--decideconversationtermination) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-AGT-004 | Rule | [DecideThreadReset](contracts/finite-conversation.md#sd-rul-agt-004--decidethreadreset) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-CNV-003 | Rule | [BuildConversationDispatchEffect](contracts/finite-conversation.md#sd-rul-cnv-003--buildconversationdispatcheffect) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-CNV-004 | Rule | [BuildTerminalConversationPath](contracts/finite-conversation.md#sd-rul-cnv-004--buildterminalconversationpath) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-AGT-005 | Rule | [ValidateTransferAuthorization](contracts/finite-conversation.md#sd-rul-agt-005--validatetransferauthorization) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-AGT-006 | Rule | [ResolveAgentTerminalRace](contracts/finite-conversation.md#sd-rul-agt-006--resolveagentterminalrace) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-TOL-001 | Rule | [ResolveToolTerminalRace](contracts/finite-conversation.md#sd-rul-tol-001--resolvetoolterminalrace) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-TOL-002 | Rule | [ValidateSkillExecutionGrant](contracts/finite-conversation.md#sd-rul-tol-002--validateskillexecutiongrant) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-QLI-001 | Transition | [ApplyQualiaLifecycle](contracts/finite-conversation.md#sd-trn-qli-001--applyqualialifecycle) | Primary Sol + structural review | N/A | SD-CTX-QLI-001 only | 1 | draft | — |
| SD-TRN-INT-001 | Transition | [ApplyInteractionAdmission](contracts/finite-conversation.md#sd-trn-int-001--applyinteractionadmission) | Primary Sol + structural review | N/A | SD-CTX-INT-001 only | 1 | draft | — |
| SD-TRN-CNV-001 | Transition | [OpenConversationTurn](contracts/finite-conversation.md#sd-trn-cnv-001--openconversationturn) | Primary Sol + structural review | N/A | SD-CTX-CNV-001 only | 1 | draft | — |
| SD-TRN-CNV-002 | Transition | [AcceptConversationResponse](contracts/finite-conversation.md#sd-trn-cnv-002--acceptconversationresponse) | Primary Sol + structural review | N/A | SD-CTX-CNV-001 only | 1 | draft | — |
| SD-TRN-CNV-004 | Transition | [ConsumeProposalBudget](contracts/finite-conversation.md#sd-trn-cnv-004--consumeproposalbudget) | Primary Sol + structural review | N/A | SD-CTX-CNV-001 only | 1 | draft | — |
| SD-TRN-MEM-001 | Transition | [ApplyRecallResult](contracts/finite-conversation.md#sd-trn-mem-001--applyrecallresult) | Primary Sol + structural review | N/A | SD-CTX-MEM-001 only | 1 | draft | — |
| SD-TRN-MEM-002 | Transition | [ApplyMemorySaveResult](contracts/finite-conversation.md#sd-trn-mem-002--applymemorysaveresult) | Primary Sol + structural review | N/A | SD-CTX-MEM-001 only | 1 | draft | — |
| SD-TRN-MEM-003 | Transition | [BeginMemoryDelete](contracts/finite-conversation.md#sd-trn-mem-003--beginmemorydelete) | Primary Sol + structural review | N/A | SD-CTX-MEM-001 only | 1 | draft | — |
| SD-TRN-MEM-004 | Transition | [ApplyMemoryDeleteResult](contracts/finite-conversation.md#sd-trn-mem-004--applymemorydeleteresult) | Primary Sol + structural review | N/A | SD-CTX-MEM-001 only | 1 | draft | — |
| SD-TRN-MEM-005 | Transition | [CommitMemoryResetBarrier](contracts/finite-conversation.md#sd-trn-mem-005--commitmemoryresetbarrier) | Primary Sol + structural review | N/A | SD-CTX-MEM-001 only | 1 | draft | — |
| SD-TRN-MEM-006 | Transition | [ApplyMemoryResetResult](contracts/finite-conversation.md#sd-trn-mem-006--applymemoryresetresult) | Primary Sol + structural review | N/A | SD-CTX-MEM-001 only | 1 | draft | — |
| SD-TRN-MEM-007 | Transition | [BeginExplicitMemorySave](contracts/finite-conversation.md#sd-trn-mem-007--beginexplicitmemorysave) | Primary Sol + structural review | N/A | SD-CTX-MEM-001 only | 1 | draft | — |
| SD-TRN-MEM-008 | Transition | [ApplyExplicitMemorySaveResult](contracts/finite-conversation.md#sd-trn-mem-008--applyexplicitmemorysaveresult) | Primary Sol + structural review | N/A | SD-CTX-MEM-001 only | 1 | draft | — |
| SD-TRN-AGT-001 | Transition | [ApplyAgentBinding](contracts/finite-conversation.md#sd-trn-agt-001--applyagentbinding) | Primary Sol + structural review | N/A | SD-CTX-AGT-001 only | 1 | draft | — |
| SD-TRN-AGT-002 | Transition | [ApplyThreadResetBarrier](contracts/finite-conversation.md#sd-trn-agt-002--applythreadresetbarrier) | Primary Sol + structural review | N/A | SD-CTX-AGT-001 only | 1 | draft | — |
| SD-TRN-AGT-003 | Transition | [ApplyFreshContinuityBinding](contracts/finite-conversation.md#sd-trn-agt-003--applyfreshcontinuitybinding) | Primary Sol + structural review | N/A | SD-CTX-AGT-001 only | 1 | draft | — |
| SD-TRN-AGT-004 | Transition | [ApplyThreadCompactionResult](contracts/finite-conversation.md#sd-trn-agt-004--applythreadcompactionresult) | Primary Sol + structural review | N/A | SD-CTX-AGT-001 only | 1 | draft | — |
| SD-TRN-AGT-005 | Transition | [ApplyAgentRouteGap](contracts/finite-conversation.md#sd-trn-agt-005--applyagentroutegap) | Primary Sol + structural review | N/A | SD-CTX-AGT-001 only | 1 | draft | — |
| SD-TRN-AGT-006 | Transition | [ApplyAgentTerminalWinner](contracts/finite-conversation.md#sd-trn-agt-006--applyagentterminalwinner) | Primary Sol + structural review | N/A | SD-CTX-AGT-001 only | 1 | draft | — |
| SD-TRN-CNV-003 | Transition | [CompleteConversationTurn](contracts/finite-conversation.md#sd-trn-cnv-003--completeconversationturn) | Primary Sol + structural review | N/A | SD-CTX-CNV-001 only | 1 | draft | — |
| SD-EFX-MEM-001 | Effect | [RetrieveSemanticMemory](contracts/finite-conversation.md#sd-efx-mem-001--retrievesemanticmemory) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-MEM-002 | Effect | [SaveConversationMemory](contracts/finite-conversation.md#sd-efx-mem-002--saveconversationmemory) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-MEM-003 | Effect | [MutateSemanticMemory](contracts/finite-conversation.md#sd-efx-mem-003--mutatesemanticmemory) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-AGT-001 | Effect | [RequestAgentTurn](contracts/finite-conversation.md#sd-efx-agt-001--requestagentturn) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-AGT-002 | Effect | [RequestInference](contracts/finite-conversation.md#sd-efx-agt-002--requestinference) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-AGT-003 | Effect | [CancelAgentWork](contracts/finite-conversation.md#sd-efx-agt-003--cancelagentwork) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-AGT-004 | Effect | [BeginFreshExternalContinuity](contracts/finite-conversation.md#sd-efx-agt-004--beginfreshexternalcontinuity) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-AGT-005 | Effect | [CompactExternalContinuity](contracts/finite-conversation.md#sd-efx-agt-005--compactexternalcontinuity) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-AGT-006 | Effect | [AwaitAgentDeadline](contracts/finite-conversation.md#sd-efx-agt-006--awaitagentdeadline) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-NOT-001 | Effect | [EmitThinkingNotice](contracts/finite-conversation.md#sd-efx-not-001--emitthinkingnotice) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-OUT-001 | Effect | [PublishConversationPresentation](contracts/finite-conversation.md#sd-efx-out-001--publishconversationpresentation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-AUD-001 | Effect | [PlayNonStreamingSpeech](contracts/finite-conversation.md#sd-efx-aud-001--playnonstreamingspeech) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-DAT-001 | Effect | [ReadAuthorizedContent](contracts/finite-conversation.md#sd-efx-dat-001--readauthorizedcontent) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-TOL-001 | Effect | [ExecuteAuthorizedToolOperation](contracts/finite-conversation.md#sd-efx-tol-001--executeauthorizedtooloperation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-TOL-002 | Effect | [CancelAuthorizedToolOperation](contracts/finite-conversation.md#sd-efx-tol-002--cancelauthorizedtooloperation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-TOL-003 | Effect | [AwaitToolDeadline](contracts/finite-conversation.md#sd-efx-tol-003--awaittooldeadline) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-GPH-CNV-001 | Effect Graph | [FiniteConversationGraph](contracts/finite-conversation.md#sd-gph-cnv-001--finiteconversationgraph) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-GPH-MEM-001 | Effect Graph | [ExplicitRecallGraph](contracts/finite-conversation.md#sd-gph-mem-001--explicitrecallgraph) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRT-MEM-001 | Port | [SemanticMemoryPort](contracts/finite-conversation.md#sd-prt-mem-001--semanticmemoryport) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRT-AGT-001 | Port | [AgentSessionPort](contracts/finite-conversation.md#sd-prt-agt-001--agentsessionport) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRT-AGT-002 | Port | [ProviderInferencePort](contracts/finite-conversation.md#sd-prt-agt-002--providerinferenceport) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRT-NOT-001 | Port | [ThinkingNotificationPort](contracts/finite-conversation.md#sd-prt-not-001--thinkingnotificationport) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRT-OUT-001 | Port | [PresentationPublicationPort](contracts/finite-conversation.md#sd-prt-out-001--presentationpublicationport) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRT-AUD-001 | Port | [NonStreamingSpeechPort](contracts/finite-conversation.md#sd-prt-aud-001--nonstreamingspeechport) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRT-DAT-001 | Port | [AuthorizedContentPort](contracts/finite-conversation.md#sd-prt-dat-001--authorizedcontentport) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRT-TOL-001 | Port | [AuthorizedToolPort](contracts/finite-conversation.md#sd-prt-tol-001--authorizedtoolport) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-FAIL-CNV-001 | Failure | [FiniteConversationFailure](contracts/finite-conversation.md#sd-fail-cnv-001--finiteconversationfailure) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-REC-CNV-001 | Recovery | [FiniteConversationRecovery](contracts/finite-conversation.md#sd-rec-cnv-001--finiteconversationrecovery) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-REC-AGT-001 | Recovery | [AgentTurnRecovery](contracts/finite-conversation.md#sd-rec-agt-001--agentturnrecovery) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-REC-MEM-001 | Recovery | [MemoryRecovery](contracts/finite-conversation.md#sd-rec-mem-001--memoryrecovery) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-REC-AGT-002 | Recovery | [ThreadResetRecovery](contracts/finite-conversation.md#sd-rec-agt-002--threadresetrecovery) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-REC-OUT-001 | Recovery | [PresentationCommitRecovery](contracts/finite-conversation.md#sd-rec-out-001--presentationcommitrecovery) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-REC-NOT-001 | Recovery | [ThinkingNoticeRecovery](contracts/finite-conversation.md#sd-rec-not-001--thinkingnoticerecovery) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-REC-TOL-001 | Recovery | [ToolOperationRecovery](contracts/finite-conversation.md#sd-rec-tol-001--tooloperationrecovery) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-CNV-001 | Persistence | [DurableFiniteConversationBoundary](contracts/finite-conversation.md#sd-per-cnv-001--durablefiniteconversationboundary) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRJ-CNV-001 | Projection | [FiniteConversationProjection](contracts/finite-conversation.md#sd-prj-cnv-001--finiteconversationprojection) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRJ-MEM-001 | Projection | [SemanticMemoryProjection](contracts/finite-conversation.md#sd-prj-mem-001--semanticmemoryprojection) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRJ-AGT-001 | Projection | [AgentSessionProjection](contracts/finite-conversation.md#sd-prj-agt-001--agentsessionprojection) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRJ-QLI-001 | Projection | [QualiaProjection](contracts/finite-conversation.md#sd-prj-qli-001--qualiaprojection) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-MOD-CNV-001 | Module boundary | [FiniteConversationModuleBoundary](contracts/finite-conversation.md#sd-mod-cnv-001--finiteconversationmoduleboundary) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |

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
| SD-PER-EXE-003 | Persistence | [OwnerEventAndGuardFactUoW](contracts/execution.md#sd-per-exe-003--ownereventandguardfactuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CTX-CFG-001 | Context | [Configuration Context](contracts/configuration-application.md#sd-ctx-cfg-001--configuration-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-CFG-001 | State | [ConfigurationDocumentState](contracts/configuration-application.md#sd-sta-cfg-001--configurationdocumentstate) | Primary Sol + structural review | SD-CTX-CFG-001 | SD-TRN-CFG-001, SD-TRN-CFG-002, SD-TRN-CFG-006, SD-TRN-CFG-007 | 1 | draft | — |
| SD-STA-CFG-002 | State | [ConfigurationApplicationState](contracts/configuration-application.md#sd-sta-cfg-002--configurationapplicationstate) | Primary Sol + structural review | SD-CTX-CFG-001 | SD-TRN-CFG-003, SD-TRN-CFG-004, SD-TRN-CFG-005 | 1 | draft | — |
| SD-CTX-AUT-001 | Context | [Authorization Policy Context](contracts/configuration-application.md#sd-ctx-aut-001--authorization-policy-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-AUT-001 | State | [AuthorizationPolicyState](contracts/configuration-application.md#sd-sta-aut-001--authorizationpolicystate) | Primary Sol + structural review | SD-CTX-AUT-001 | SD-TRN-AUT-001 | 1 | draft | — |
| SD-CMD-CFG-001 | Command | [UpdateConfiguration](contracts/configuration-application.md#sd-cmd-cfg-001--updateconfiguration) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CMD-CFG-002 | Command | [CancelConfigurationApplication](contracts/configuration-application.md#sd-cmd-cfg-002--cancelconfigurationapplication) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CMD-CFG-003 | Command | [RevertConfiguration](contracts/configuration-application.md#sd-cmd-cfg-003--revertconfiguration) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-CFG-001 | Event | [ConfigurationUpdateRejected](contracts/configuration-application.md#sd-evt-cfg-001--configurationupdaterejected) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-CFG-002 | Event | [DesiredConfigurationCommitted](contracts/configuration-application.md#sd-evt-cfg-002--desiredconfigurationcommitted) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-CFG-003 | Event | [ConfigurationApplicationPlanned](contracts/configuration-application.md#sd-evt-cfg-003--configurationapplicationplanned) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-CFG-004 | Event | [ConfigurationApplicationStepResolved](contracts/configuration-application.md#sd-evt-cfg-004--configurationapplicationstepresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-CFG-005 | Event | [EffectiveAtomicGroupActivated](contracts/configuration-application.md#sd-evt-cfg-005--effectiveatomicgroupactivated) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-CFG-001 | Rule | [ValidateConfigurationSchema](contracts/configuration-application.md#sd-rul-cfg-001--validateconfigurationschema) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-CFG-002 | Rule | [ResolveConfigurationLayers](contracts/configuration-application.md#sd-rul-cfg-002--resolveconfigurationlayers) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-CFG-003 | Rule | [ValidateConfigurationSafety](contracts/configuration-application.md#sd-rul-cfg-003--validateconfigurationsafety) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-CFG-004 | Rule | [PlanConfigurationApplication](contracts/configuration-application.md#sd-rul-cfg-004--planconfigurationapplication) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-CFG-005 | Rule | [ComposeEffectiveConfigurationSnapshot](contracts/configuration-application.md#sd-rul-cfg-005--composeeffectiveconfigurationsnapshot) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-CFG-001 | Transition | [PrepareConfigurationDocumentWrite](contracts/configuration-application.md#sd-trn-cfg-001--prepareconfigurationdocumentwrite) | Primary Sol + structural review | N/A | SD-CTX-CFG-001 only | 1 | draft | — |
| SD-TRN-CFG-002 | Transition | [CommitDesiredConfiguration](contracts/configuration-application.md#sd-trn-cfg-002--commitdesiredconfiguration) | Primary Sol + structural review | N/A | SD-CTX-CFG-001 only | 1 | draft | — |
| SD-TRN-CFG-003 | Transition | [ApplyConfigurationStepResult](contracts/configuration-application.md#sd-trn-cfg-003--applyconfigurationstepresult) | Primary Sol + structural review | N/A | SD-CTX-CFG-001 only | 1 | draft | — |
| SD-TRN-CFG-004 | Transition | [ApplyEffectiveAtomicGroupActivation](contracts/configuration-application.md#sd-trn-cfg-004--applyeffectiveatomicgroupactivation) | Primary Sol + structural review | N/A | SD-CTX-CFG-001 only | 1 | draft | — |
| SD-TRN-CFG-005 | Transition | [CancelConfigurationApplicationTransition](contracts/configuration-application.md#sd-trn-cfg-005--cancelconfigurationapplicationtransition) | Primary Sol + structural review | N/A | SD-CTX-CFG-001 only | 1 | draft | — |
| SD-TRN-AUT-001 | Transition | [ApplyAuthorizationPolicyConfiguration](contracts/configuration-application.md#sd-trn-aut-001--applyauthorizationpolicyconfiguration) | Primary Sol + structural review | N/A | SD-CTX-AUT-001 only | 1 | draft | — |
| SD-EFX-CFG-001 | Effect | [PersistUserLayerDocument](contracts/configuration-application.md#sd-efx-cfg-001--persistuserlayerdocument) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRT-CFG-001 | Port | [UserLayerConfigurationPort](contracts/configuration-application.md#sd-prt-cfg-001--userlayerconfigurationport) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-CFG-001 | Persistence | [PrepareConfigDocumentPersistenceUoW](contracts/configuration-application.md#sd-per-cfg-001--prepareconfigdocumentpersistenceuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-CFG-002 | Persistence | [DurableManagementResultInboxUoW](contracts/configuration-application.md#sd-per-cfg-002--durablemanagementresultinboxuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-CFG-003 | Persistence | [FinalizeDesiredConfigurationUoW](contracts/configuration-application.md#sd-per-cfg-003--finalizedesiredconfigurationuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-CFG-004 | Persistence | [EffectiveAtomicGroupUoW](contracts/configuration-application.md#sd-per-cfg-004--effectiveatomicgroupuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-CFG-005 | Persistence | [ConfigurationRoutingRevisionUseAcquisitionComponent](contracts/configuration-application.md#sd-per-cfg-005--configurationroutingrevisionuseacquisitioncomponent) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRJ-CFG-001 | Projection | [ConfigurationProjection](contracts/configuration-application.md#sd-prj-cfg-001--configurationprojection) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRJ-AUT-001 | Projection | [SkillAuthorizationProjection](contracts/configuration-application.md#sd-prj-aut-001--skillauthorizationprojection) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-FAIL-CFG-001 | Failure | [ConfigurationFailure](contracts/configuration-application.md#sd-fail-cfg-001--configurationfailure) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-MOD-RBI-001 | Module boundary | [RuntimeBindingAlgebra](contracts/runtime-binding.md#sd-mod-rbi-001--runtimebindingalgebra) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CTX-SRC-001 | Context | [Source Runtime Context](contracts/runtime-binding.md#sd-ctx-src-001--source-runtime-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-SRC-001 | State | [SourceRuntimeState](contracts/runtime-binding.md#sd-sta-src-001--sourceruntimestate) | Primary Sol + structural review | SD-CTX-SRC-001 | SD-TRN-SRC-001 | 1 | draft | — |
| SD-TRN-SRC-001 | Transition | [ApplySourceRuntimeTransition](contracts/runtime-binding.md#sd-trn-src-001--applysourceruntimetransition) | Primary Sol + structural review | N/A | SD-CTX-SRC-001 only | 1 | draft | — |
| SD-CTX-WAK-001 | Context | [Wake Runtime Context](contracts/runtime-binding.md#sd-ctx-wak-001--wake-runtime-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-WAK-001 | State | [WakeRuntimeState](contracts/runtime-binding.md#sd-sta-wak-001--wakeruntimestate) | Primary Sol + structural review | SD-CTX-WAK-001 | SD-TRN-WAK-001 | 1 | draft | — |
| SD-TRN-WAK-001 | Transition | [ApplyWakeRuntimeTransition](contracts/runtime-binding.md#sd-trn-wak-001--applywakeruntimetransition) | Primary Sol + structural review | N/A | SD-CTX-WAK-001 only | 1 | draft | — |
| SD-CTX-STT-001 | Context | [STT Runtime Context](contracts/runtime-binding.md#sd-ctx-stt-001--stt-runtime-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-STT-001 | State | [SttRuntimeState](contracts/runtime-binding.md#sd-sta-stt-001--sttruntimestate) | Primary Sol + structural review | SD-CTX-STT-001 | SD-TRN-STT-001 | 1 | draft | — |
| SD-TRN-STT-001 | Transition | [ApplySttRuntimeTransition](contracts/runtime-binding.md#sd-trn-stt-001--applysttruntimetransition) | Primary Sol + structural review | N/A | SD-CTX-STT-001 only | 1 | draft | — |
| SD-CTX-SBR-001 | Context | [SBERT Runtime Context](contracts/runtime-binding.md#sd-ctx-sbr-001--sbert-runtime-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-SBR-001 | State | [SbertRuntimeState](contracts/runtime-binding.md#sd-sta-sbr-001--sbertruntimestate) | Primary Sol + structural review | SD-CTX-SBR-001 | SD-TRN-SBR-001 | 1 | draft | — |
| SD-TRN-SBR-001 | Transition | [ApplySbertRuntimeTransition](contracts/runtime-binding.md#sd-trn-sbr-001--applysbertruntimetransition) | Primary Sol + structural review | N/A | SD-CTX-SBR-001 only | 1 | draft | — |
| SD-CTX-DEV-001 | Context | [Device Runtime Context](contracts/runtime-binding.md#sd-ctx-dev-001--device-runtime-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-DEV-001 | State | [DeviceRuntimeState](contracts/runtime-binding.md#sd-sta-dev-001--deviceruntimestate) | Primary Sol + structural review | SD-CTX-DEV-001 | SD-TRN-DEV-001 | 1 | draft | — |
| SD-TRN-DEV-001 | Transition | [ApplyDeviceRuntimeTransition](contracts/runtime-binding.md#sd-trn-dev-001--applydeviceruntimetransition) | Primary Sol + structural review | N/A | SD-CTX-DEV-001 only | 1 | draft | — |
| SD-CTX-TTS-001 | Context | [TTS Runtime Context](contracts/runtime-binding.md#sd-ctx-tts-001--tts-runtime-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-TTS-001 | State | [TtsRuntimeState](contracts/runtime-binding.md#sd-sta-tts-001--ttsruntimestate) | Primary Sol + structural review | SD-CTX-TTS-001 | SD-TRN-TTS-001 | 1 | draft | — |
| SD-TRN-TTS-001 | Transition | [ApplyTtsRuntimeTransition](contracts/runtime-binding.md#sd-trn-tts-001--applyttsruntimetransition) | Primary Sol + structural review | N/A | SD-CTX-TTS-001 only | 1 | draft | — |
| SD-CTX-MBP-001 | Context | [Memory Provider Runtime Context](contracts/runtime-binding.md#sd-ctx-mbp-001--memory-provider-runtime-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-MBP-001 | State | [MemoryProviderRuntimeState](contracts/runtime-binding.md#sd-sta-mbp-001--memoryproviderruntimestate) | Primary Sol + structural review | SD-CTX-MBP-001 | SD-TRN-MBP-001 | 1 | draft | — |
| SD-TRN-MBP-001 | Transition | [ApplyMemoryProviderRuntimeTransition](contracts/runtime-binding.md#sd-trn-mbp-001--applymemoryproviderruntimetransition) | Primary Sol + structural review | N/A | SD-CTX-MBP-001 only | 1 | draft | — |
| SD-CTX-PRV-001 | Context | [Inference Provider Runtime Context](contracts/runtime-binding.md#sd-ctx-prv-001--inference-provider-runtime-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-PRV-001 | State | [InferenceProviderRuntimeState](contracts/runtime-binding.md#sd-sta-prv-001--inferenceproviderruntimestate) | Primary Sol + structural review | SD-CTX-PRV-001 | SD-TRN-PRV-001 | 1 | draft | — |
| SD-TRN-PRV-001 | Transition | [ApplyInferenceProviderRuntimeTransition](contracts/runtime-binding.md#sd-trn-prv-001--applyinferenceproviderruntimetransition) | Primary Sol + structural review | N/A | SD-CTX-PRV-001 only | 1 | draft | — |
| SD-CTX-DPF-001 | Context | [Physical Capability Profile Context](contracts/runtime-binding.md#sd-ctx-dpf-001--physical-capability-profile-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-DPF-001 | State | [PhysicalCapabilityProfileState](contracts/runtime-binding.md#sd-sta-dpf-001--physicalcapabilityprofilestate) | Primary Sol + structural review | SD-CTX-DPF-001 | SD-TRN-DPF-001, SD-TRN-DPF-002, SD-TRN-DPF-003 | 1 | draft | — |
| SD-TRN-DPF-001 | Transition | [RegisterPhysicalCapabilityProfileRevision](contracts/runtime-binding.md#sd-trn-dpf-001--registerphysicalcapabilityprofilerevision) | Primary Sol + structural review | N/A | SD-CTX-DPF-001 only | 1 | draft | — |
| SD-TRN-DPF-002 | Transition | [ActivatePhysicalCapabilityProfileRevision](contracts/runtime-binding.md#sd-trn-dpf-002--activatephysicalcapabilityprofilerevision) | Primary Sol + structural review | N/A | SD-CTX-DPF-001 only | 1 | draft | — |
| SD-TRN-DPF-003 | Transition | [ApplyPhysicalProfileRevisionUse](contracts/runtime-binding.md#sd-trn-dpf-003--applyphysicalprofilerevisionuse) | Primary Sol + structural review | N/A | SD-CTX-DPF-001 only | 1 | draft | — |
| SD-CTX-QPR-001 | Context | [Quality Profile Context](contracts/runtime-binding.md#sd-ctx-qpr-001--quality-profile-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-QPR-001 | State | [QualityProfileState](contracts/runtime-binding.md#sd-sta-qpr-001--qualityprofilestate) | Primary Sol + structural review | SD-CTX-QPR-001 | SD-TRN-QPR-001 | 1 | draft | — |
| SD-TRN-QPR-001 | Transition | [ApplyQualityProfileTransition](contracts/runtime-binding.md#sd-trn-qpr-001--applyqualityprofiletransition) | Primary Sol + structural review | N/A | SD-CTX-QPR-001 only | 1 | draft | — |
| SD-RUL-RBI-001 | Rule | [ValidateFreshRuntimeBinding](contracts/runtime-binding.md#sd-rul-rbi-001--validatefreshruntimebinding) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-RBI-002 | Rule | [DecideBindingUseRelease](contracts/runtime-binding.md#sd-rul-rbi-002--decidebindinguserelease) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-RBI-003 | Rule | [DecideBindingGenerationDrainCompletion](contracts/runtime-binding.md#sd-rul-rbi-003--decidebindinggenerationdraincompletion) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-RBI-001 | Event | [RuntimeBindingObserved](contracts/runtime-binding.md#sd-evt-rbi-001--runtimebindingobserved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-RBI-002 | Event | [RuntimeReadinessObserved](contracts/runtime-binding.md#sd-evt-rbi-002--runtimereadinessobserved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-RBI-003 | Event | [AllBindingUsesReleased](contracts/runtime-binding.md#sd-evt-rbi-003--allbindingusesreleased) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-RBI-001 | Effect | [MaterializeRuntimeBinding](contracts/runtime-binding.md#sd-efx-rbi-001--materializeruntimebinding) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-RBI-002 | Effect | [ProbeRuntimeBinding](contracts/runtime-binding.md#sd-efx-rbi-002--proberuntimebinding) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-RBI-003 | Effect | [CancelRuntimeBindingChange](contracts/runtime-binding.md#sd-efx-rbi-003--cancelruntimebindingchange) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-RBI-004 | Effect | [RetireRuntimeBinding](contracts/runtime-binding.md#sd-efx-rbi-004--retireruntimebinding) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRT-RBI-001 | Port | [RuntimeBindingPort](contracts/runtime-binding.md#sd-prt-rbi-001--runtimebindingport) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRT-RBI-002 | Port | [RuntimeProbePort](contracts/runtime-binding.md#sd-prt-rbi-002--runtimeprobeport) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-RBI-001 | Persistence | [FinalBindingUseReleaseAndRetirementUoW](contracts/runtime-binding.md#sd-per-rbi-001--finalbindingusereleaseandretirementuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRJ-RBI-001 | Projection | [RuntimeBindingProjection](contracts/runtime-binding.md#sd-prj-rbi-001--runtimebindingprojection) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRJ-RBI-002 | Projection | [ReadinessProjection](contracts/runtime-binding.md#sd-prj-rbi-002--readinessprojection) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CTX-BRP-001 | Context | [Behavior Routing Policy Context](contracts/routing-policy.md#sd-ctx-brp-001--behavior-routing-policy-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-BRP-001 | State | [BehaviorRoutingPolicyState](contracts/routing-policy.md#sd-sta-brp-001--behaviorroutingpolicystate) | Primary Sol + structural review | SD-CTX-BRP-001 | SD-TRN-BRP-001, SD-TRN-BRP-002 | 1 | draft | — |
| SD-CTX-IRP-001 | Context | [Inference Routing Policy Context](contracts/routing-policy.md#sd-ctx-irp-001--inference-routing-policy-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-IRP-001 | State | [InferenceRoutingPolicyState](contracts/routing-policy.md#sd-sta-irp-001--inferenceroutingpolicystate) | Primary Sol + structural review | SD-CTX-IRP-001 | SD-TRN-IRP-001, SD-TRN-IRP-002 | 1 | draft | — |
| SD-RUL-BRP-001 | Rule | [ResolveBehaviorRoute](contracts/routing-policy.md#sd-rul-brp-001--resolvebehaviorroute) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-IRP-001 | Rule | [ResolveInferenceRoute](contracts/routing-policy.md#sd-rul-irp-001--resolveinferenceroute) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-BRP-001 | Transition | [ApplyBehaviorRoutingPolicyConfiguration](contracts/routing-policy.md#sd-trn-brp-001--applybehaviorroutingpolicyconfiguration) | Primary Sol + structural review | N/A | SD-CTX-BRP-001 only | 1 | draft | — |
| SD-TRN-IRP-001 | Transition | [ApplyInferenceRoutingPolicyConfiguration](contracts/routing-policy.md#sd-trn-irp-001--applyinferenceroutingpolicyconfiguration) | Primary Sol + structural review | N/A | SD-CTX-IRP-001 only | 1 | draft | — |
| SD-PRJ-BRP-001 | Projection | [BehaviorRoutingProjection](contracts/routing-policy.md#sd-prj-brp-001--behaviorroutingprojection) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRJ-IRP-001 | Projection | [InferenceRoutingProjection](contracts/routing-policy.md#sd-prj-irp-001--inferenceroutingprojection) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-NOT-001 | Transition | [ApplyNotificationPolicyConfiguration](contracts/finite-conversation.md#sd-trn-not-001--applynotificationpolicyconfiguration) | Primary Sol + structural review | N/A | SD-CTX-NOT-001 only | 1 | draft | — |
| SD-TRN-MEM-009 | Transition | [ApplyMemoryPolicyConfiguration](contracts/finite-conversation.md#sd-trn-mem-009--applymemorypolicyconfiguration) | Primary Sol + structural review | N/A | SD-CTX-MEM-001 only | 1 | draft | — |
| SD-TRN-DAT-002 | Transition | [ApplyDataPolicyConfiguration](contracts/camera-observation.md#sd-trn-dat-002--applydatapolicyconfiguration) | Primary Sol + structural review | N/A | SD-CTX-DAT-001 only | 1 | draft | — |
| SD-TRN-PAP-001 | Transition | [ApplyPhysicalActionPolicyConfiguration](contracts/camera-observation.md#sd-trn-pap-001--applyphysicalactionpolicyconfiguration) | Primary Sol + structural review | N/A | SD-CTX-PAP-001 only | 1 | draft | — |
| SD-PER-CAM-001 | Persistence | [CameraPlanRegistrationUoW](contracts/camera-observation.md#sd-per-cam-001--cameraplanregistrationuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CTX-RST-001 | Context | [Runtime Control Context](contracts/migration-and-restart.md#sd-ctx-rst-001--runtime-control-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-RST-001 | State | [RuntimeRestartState](contracts/migration-and-restart.md#sd-sta-rst-001--runtimerestartstate) | Primary Sol + structural review | SD-CTX-RST-001 | SD-TRN-RST-001, SD-TRN-RST-002, SD-TRN-RST-003, SD-TRN-RST-004 | 1 | draft | — |
| SD-RUL-RST-001 | Rule | [DecideRuntimeRestartReadiness](contracts/migration-and-restart.md#sd-rul-rst-001--decideruntimerestartreadiness) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-RST-001 | Transition | [ApplyRuntimeRestartTransition](contracts/migration-and-restart.md#sd-trn-rst-001--applyruntimerestarttransition) | Primary Sol + structural review | N/A | SD-CTX-RST-001 only | 1 | draft | — |
| SD-EVT-RST-001 | Event | [RuntimeRecoveryPointVerified](contracts/migration-and-restart.md#sd-evt-rst-001--runtimerecoverypointverified) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-RST-002 | Event | [RuntimeRestartObserved](contracts/migration-and-restart.md#sd-evt-rst-002--runtimerestartobserved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-RST-001 | Effect | [CreateRuntimeRecoveryPoint](contracts/migration-and-restart.md#sd-efx-rst-001--createruntimerecoverypoint) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-RST-002 | Effect | [VerifyRuntimeRecoveryPoint](contracts/migration-and-restart.md#sd-efx-rst-002--verifyruntimerecoverypoint) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-RST-003 | Effect | [RequestRuntimeRestart](contracts/migration-and-restart.md#sd-efx-rst-003--requestruntimerestart) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-RST-004 | Effect | [QueryRuntimeRestartStatus](contracts/migration-and-restart.md#sd-efx-rst-004--queryruntimerestartstatus) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRT-RST-001 | Port | [RuntimeControlPort](contracts/migration-and-restart.md#sd-prt-rst-001--runtimecontrolport) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-RST-001 | Persistence | [RuntimeRestartUoW](contracts/migration-and-restart.md#sd-per-rst-001--runtimerestartuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-REC-RST-001 | Recovery | [RuntimeRestartRecovery](contracts/migration-and-restart.md#sd-rec-rst-001--runtimerestartrecovery) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CTX-MIG-001 | Context | [Workspace Migration Context](contracts/migration-and-restart.md#sd-ctx-mig-001--workspace-migration-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-MIG-001 | State | [MigrationState](contracts/migration-and-restart.md#sd-sta-mig-001--migrationstate) | Primary Sol + structural review | SD-CTX-MIG-001 | SD-TRN-MIG-001, SD-TRN-MIG-002, SD-TRN-MIG-003, SD-TRN-MIG-004, SD-TRN-MIG-005 | 1 | draft | — |
| SD-RUL-MIG-001 | Rule | [ValidateMigrationPlan](contracts/migration-and-restart.md#sd-rul-mig-001--validatemigrationplan) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-MIG-001 | Transition | [RecordMigrationOperationResult](contracts/migration-and-restart.md#sd-trn-mig-001--recordmigrationoperationresult) | Primary Sol + structural review | N/A | SD-CTX-MIG-001 only | 1 | draft | — |
| SD-EVT-MIG-001 | Event | [MigrationStepResolved](contracts/migration-and-restart.md#sd-evt-mig-001--migrationstepresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-MIG-001 | Effect | [ExecuteWorkspaceMigrationOperation](contracts/migration-and-restart.md#sd-efx-mig-001--executeworkspacemigrationoperation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRT-MIG-001 | Port | [WorkspaceMigrationPort](contracts/migration-and-restart.md#sd-prt-mig-001--workspacemigrationport) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-MIG-001 | Persistence | [MigrationUoW](contracts/migration-and-restart.md#sd-per-mig-001--migrationuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-REC-MIG-001 | Recovery | [WorkspaceMigrationRecovery](contracts/migration-and-restart.md#sd-rec-mig-001--workspacemigrationrecovery) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRJ-MIG-001 | Projection | [MigrationProjection](contracts/migration-and-restart.md#sd-prj-mig-001--migrationprojection) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-EXE-004 | Event | [GuardFactDeclared](contracts/execution.md#sd-evt-exe-004--guardfactdeclared) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-EXE-009 | Transition | [AdvanceGuardFactLifecycle](contracts/execution.md#sd-trn-exe-009--advanceguardfactlifecycle) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
| SD-TRN-BRP-002 | Transition | [ApplyBehaviorRoutingRevisionUse](contracts/routing-policy.md#sd-trn-brp-002--applybehaviorroutingrevisionuse) | Primary Sol + structural review | N/A | SD-CTX-BRP-001 only | 1 | draft | — |
| SD-TRN-IRP-002 | Transition | [ApplyInferenceRoutingRevisionUse](contracts/routing-policy.md#sd-trn-irp-002--applyinferenceroutingrevisionuse) | Primary Sol + structural review | N/A | SD-CTX-IRP-001 only | 1 | draft | — |
| SD-RUL-RTE-001 | Rule | [DecideRoutingRevisionUseRelease](contracts/routing-policy.md#sd-rul-rte-001--decideroutingrevisionuserelease) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-CFG-006 | Transition | [ApplyConfigurationRevisionUse](contracts/configuration-application.md#sd-trn-cfg-006--applyconfigurationrevisionuse) | Primary Sol + structural review | N/A | SD-CTX-CFG-001 only | 1 | draft | — |
| SD-MOD-CFG-001 | Module boundary | [ConfigurationExecutionPayload](contracts/configuration-application.md#sd-mod-cfg-001--configurationexecutionpayload) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-CFG-002 | Effect | [QueryConfigurationPersistence](contracts/configuration-application.md#sd-efx-cfg-002--queryconfigurationpersistence) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-CFG-003 | Effect | [ReconcileConfigurationPersistence](contracts/configuration-application.md#sd-efx-cfg-003--reconcileconfigurationpersistence) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-CFG-004 | Effect | [CancelConfigurationPersistence](contracts/configuration-application.md#sd-efx-cfg-004--cancelconfigurationpersistence) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-CFG-005 | Effect | [AwaitConfigurationOperationDeadline](contracts/configuration-application.md#sd-efx-cfg-005--awaitconfigurationoperationdeadline) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-CFG-006 | Event | [ConfigurationPersistenceRecoveryObserved](contracts/configuration-application.md#sd-evt-cfg-006--configurationpersistencerecoveryobserved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-CFG-006 | Rule | [ResolveConfigurationPersistenceRecovery](contracts/configuration-application.md#sd-rul-cfg-006--resolveconfigurationpersistencerecovery) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-GPH-CFG-001 | Effect Graph | [ConfigurationApplicationGraph](contracts/configuration-application.md#sd-gph-cfg-001--configurationapplicationgraph) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-CFG-006 | Persistence | [ConfigurationRoutingRevisionUseReleaseUoW](contracts/configuration-application.md#sd-per-cfg-006--configurationroutingrevisionusereleaseuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-REC-CFG-001 | Recovery | [ConfigurationPersistenceRecovery](contracts/configuration-application.md#sd-rec-cfg-001--configurationpersistencerecovery) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-AGT-007 | Event | [CodexAppServerRuntimeObserved](contracts/finite-conversation.md#sd-evt-agt-007--codexappserverruntimeobserved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-AGT-008 | Event | [AgentRuntimeBindingUseResolved](contracts/finite-conversation.md#sd-evt-agt-008--agentruntimebindinguseresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-AGT-007 | Rule | [ValidateCodexAppServerReadiness](contracts/finite-conversation.md#sd-rul-agt-007--validatecodexappserverreadiness) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-AGT-008 | Rule | [DecideAgentRuntimeBindingUseRelease](contracts/finite-conversation.md#sd-rul-agt-008--decideagentruntimebindinguserelease) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-AGT-007 | Transition | [ApplyCodexAppServerRuntimeObservation](contracts/finite-conversation.md#sd-trn-agt-007--applycodexappserverruntimeobservation) | Primary Sol + structural review | N/A | SD-CTX-AGT-001 only | 1 | draft | — |
| SD-TRN-AGT-008 | Transition | [ApplyAgentRuntimeBindingUse](contracts/finite-conversation.md#sd-trn-agt-008--applyagentruntimebindinguse) | Primary Sol + structural review | N/A | SD-CTX-AGT-001 only | 1 | draft | — |
| SD-EFX-AGT-007 | Effect | [ProbeCodexAppServerRuntime](contracts/finite-conversation.md#sd-efx-agt-007--probecodexappserverruntime) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-AGT-008 | Effect | [QueryCodexAppServerRuntimeOperation](contracts/finite-conversation.md#sd-efx-agt-008--querycodexappserverruntimeoperation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-REC-AGT-003 | Recovery | [CodexRuntimeBindingRecovery](contracts/finite-conversation.md#sd-rec-agt-003--codexruntimebindingrecovery) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-AGT-001 | Persistence | [AgentDispatchAuthorizationAndBindingUoW](contracts/finite-conversation.md#sd-per-agt-001--agentdispatchauthorizationandbindinguow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-AGT-002 | Persistence | [AgentRuntimeBindingUseReleaseUoW](contracts/finite-conversation.md#sd-per-agt-002--agentruntimebindingusereleaseuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-RST-002 | Rule | [PlanActiveWorkHandoff](contracts/migration-and-restart.md#sd-rul-rst-002--planactiveworkhandoff) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-RST-002 | Transition | [ApplyActiveWorkHandoff](contracts/migration-and-restart.md#sd-trn-rst-002--applyactiveworkhandoff) | Primary Sol + structural review | N/A | SD-CTX-RST-001 only | 1 | draft | — |
| SD-EVT-RST-003 | Event | [ActiveWorkHandoffCommitted](contracts/migration-and-restart.md#sd-evt-rst-003--activeworkhandoffcommitted) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-MOD-RST-001 | Module boundary | [RuntimeControlExecutionPayload](contracts/migration-and-restart.md#sd-mod-rst-001--runtimecontrolexecutionpayload) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-RST-005 | Effect | [AwaitRuntimeControlDeadline](contracts/migration-and-restart.md#sd-efx-rst-005--awaitruntimecontroldeadline) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-EXE-010 | Transition | [TransferResourceLeaseToRecoveryCustody](contracts/execution.md#sd-trn-exe-010--transferresourceleasetorecoverycustody) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
| SD-PER-EXE-004 | Persistence | [OutcomeUnknownRecoveryCustodyUoW](contracts/execution.md#sd-per-exe-004--outcomeunknownrecoverycustodyuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-MOD-RBI-002 | Module boundary | [RuntimeBindingExecutionPayload](contracts/runtime-binding.md#sd-mod-rbi-002--runtimebindingexecutionpayload) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-RBI-002 | Persistence | [NonCodexRuntimeDispatchAcquisitionUoW](contracts/runtime-binding.md#sd-per-rbi-002--noncodexruntimedispatchacquisitionuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-TOL-001 | Persistence | [ToolDispatchAuthorizationUoW](contracts/finite-conversation.md#sd-per-tol-001--tooldispatchauthorizationuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-RST-006 | Effect | [CancelRuntimeRestartRequest](contracts/migration-and-restart.md#sd-efx-rst-006--cancelruntimerestartrequest) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-RST-007 | Effect | [ReconcileRuntimeRestart](contracts/migration-and-restart.md#sd-efx-rst-007--reconcileruntimerestart) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-RST-003 | Rule | [ResolveRuntimeRestartUncertainty](contracts/migration-and-restart.md#sd-rul-rst-003--resolveruntimerestartuncertainty) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-GPH-RST-001 | Effect Graph | [RuntimeRestartGraph](contracts/migration-and-restart.md#sd-gph-rst-001--runtimerestartgraph) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-RST-002 | Persistence | [ActiveWorkHandoffAndQualiaRecoveryUoW](contracts/migration-and-restart.md#sd-per-rst-002--activeworkhandoffandqualiarecoveryuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-MIG-002 | Rule | [ResolveMigrationUncertainty](contracts/migration-and-restart.md#sd-rul-mig-002--resolvemigrationuncertainty) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-MIG-002 | Effect | [QueryWorkspaceMigrationOperation](contracts/migration-and-restart.md#sd-efx-mig-002--queryworkspacemigrationoperation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-MIG-003 | Effect | [CancelWorkspaceMigrationOperation](contracts/migration-and-restart.md#sd-efx-mig-003--cancelworkspacemigrationoperation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-MIG-004 | Effect | [AwaitWorkspaceMigrationDeadline](contracts/migration-and-restart.md#sd-efx-mig-004--awaitworkspacemigrationdeadline) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-MOD-MIG-001 | Module boundary | [MigrationExecutionPayload](contracts/migration-and-restart.md#sd-mod-mig-001--migrationexecutionpayload) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-GPH-MIG-001 | Effect Graph | [WorkspaceMigrationGraph](contracts/migration-and-restart.md#sd-gph-mig-001--workspacemigrationgraph) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-DPF-001 | Persistence | [PhysicalProfileRevisionUseReleaseUoW](contracts/runtime-binding.md#sd-per-dpf-001--physicalprofilerevisionusereleaseuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-RBI-004 | Rule | [ResolveRuntimeBindingUncertainty](contracts/runtime-binding.md#sd-rul-rbi-004--resolveruntimebindinguncertainty) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-RBI-004 | Event | [RuntimeBindingRecoveryObserved](contracts/runtime-binding.md#sd-evt-rbi-004--runtimebindingrecoveryobserved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-RBI-005 | Effect | [QueryRuntimeBindingOperation](contracts/runtime-binding.md#sd-efx-rbi-005--queryruntimebindingoperation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-RBI-006 | Effect | [ReconcileRuntimeBinding](contracts/runtime-binding.md#sd-efx-rbi-006--reconcileruntimebinding) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-RBI-007 | Effect | [AwaitRuntimeBindingDeadline](contracts/runtime-binding.md#sd-efx-rbi-007--awaitruntimebindingdeadline) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-GPH-RBI-001 | Effect Graph | [RuntimeBindingChangeGraph](contracts/runtime-binding.md#sd-gph-rbi-001--runtimebindingchangegraph) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-REC-RBI-001 | Recovery | [RuntimeBindingRecovery](contracts/runtime-binding.md#sd-rec-rbi-001--runtimebindingrecovery) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-EXE-005 | Event | [RecoveryCustodyResolved](contracts/execution.md#sd-evt-exe-005--recoverycustodyresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-EXE-003 | Rule | [DecideRecoveryCustodyResolution](contracts/execution.md#sd-rul-exe-003--deciderecoverycustodyresolution) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-EXE-011 | Transition | [ApplyRecoveryCustodyResolution](contracts/execution.md#sd-trn-exe-011--applyrecoverycustodyresolution) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
| SD-TRN-EXE-012 | Transition | [FinalizeRecoveryCustody](contracts/execution.md#sd-trn-exe-012--finalizerecoverycustody) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
| SD-PER-EXE-005 | Persistence | [RecoveryCustodyResolutionUoW](contracts/execution.md#sd-per-exe-005--recoverycustodyresolutionuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-AGT-009 | Event | [AgentTurnQueryObserved](contracts/finite-conversation.md#sd-evt-agt-009--agentturnqueryobserved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-AGT-010 | Event | [AgentTurnReconciliationObserved](contracts/finite-conversation.md#sd-evt-agt-010--agentturnreconciliationobserved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-AGT-011 | Event | [ThreadResetCancellationResolved](contracts/finite-conversation.md#sd-evt-agt-011--threadresetcancellationresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-AGT-012 | Event | [ThreadResetQueryObserved](contracts/finite-conversation.md#sd-evt-agt-012--threadresetqueryobserved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-AGT-013 | Event | [ThreadResetReconciliationObserved](contracts/finite-conversation.md#sd-evt-agt-013--threadresetreconciliationobserved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-AGT-009 | Rule | [ResolveAgentTurnUncertainty](contracts/finite-conversation.md#sd-rul-agt-009--resolveagentturnuncertainty) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-AGT-010 | Rule | [ResolveThreadResetUncertainty](contracts/finite-conversation.md#sd-rul-agt-010--resolvethreadresetuncertainty) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-TOL-003 | Rule | [ResolveToolOperationUncertainty](contracts/finite-conversation.md#sd-rul-tol-003--resolvetooloperationuncertainty) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-AGT-009 | Transition | [ApplyAgentTurnRecoveryObservation](contracts/finite-conversation.md#sd-trn-agt-009--applyagentturnrecoveryobservation) | Primary Sol + structural review | N/A | SD-CTX-AGT-001 only | 1 | draft | — |
| SD-TRN-AGT-010 | Transition | [ApplyThreadResetRecoveryObservation](contracts/finite-conversation.md#sd-trn-agt-010--applythreadresetrecoveryobservation) | Primary Sol + structural review | N/A | SD-CTX-AGT-001 only | 1 | draft | — |
| SD-EVT-AGT-014 | Event | [AgentTurnRecoveryResolved](contracts/finite-conversation.md#sd-evt-agt-014--agentturnrecoveryresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-AGT-011 | Transition | [ApplyAgentTurnRecoveryResolution](contracts/finite-conversation.md#sd-trn-agt-011--applyagentturnrecoveryresolution) | Primary Sol + structural review | N/A | SD-CTX-AGT-001 only | 1 | draft | — |
| SD-EVT-AGT-015 | Event | [ThreadResetRecoveryResolved](contracts/finite-conversation.md#sd-evt-agt-015--threadresetrecoveryresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-AGT-012 | Transition | [ApplyThreadResetRecoveryResolution](contracts/finite-conversation.md#sd-trn-agt-012--applythreadresetrecoveryresolution) | Primary Sol + structural review | N/A | SD-CTX-AGT-001 only | 1 | draft | — |
| SD-EVT-TOL-006 | Event | [ToolOperationRecoveryResolved](contracts/finite-conversation.md#sd-evt-tol-006--tooloperationrecoveryresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-CNV-006 | Transition | [ApplyToolRecoveryResolution](contracts/finite-conversation.md#sd-trn-cnv-006--applytoolrecoveryresolution) | Primary Sol + structural review | N/A | SD-CTX-CNV-001 only | 1 | draft | — |
| SD-TRN-CNV-005 | Transition | [ApplyToolRecoveryObservation](contracts/finite-conversation.md#sd-trn-cnv-005--applytoolrecoveryobservation) | Primary Sol + structural review | N/A | SD-CTX-CNV-001 only | 1 | draft | — |
| SD-EFX-AGT-009 | Effect | [QueryAgentTurnOperation](contracts/finite-conversation.md#sd-efx-agt-009--queryagentturnoperation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-AGT-010 | Effect | [ReconcileAgentTurnOperation](contracts/finite-conversation.md#sd-efx-agt-010--reconcileagentturnoperation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-AGT-011 | Effect | [CancelThreadResetOperation](contracts/finite-conversation.md#sd-efx-agt-011--cancelthreadresetoperation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-AGT-012 | Effect | [QueryThreadResetOperation](contracts/finite-conversation.md#sd-efx-agt-012--querythreadresetoperation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-AGT-013 | Effect | [ReconcileThreadResetOperation](contracts/finite-conversation.md#sd-efx-agt-013--reconcilethreadresetoperation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-TOL-004 | Effect | [QueryAuthorizedToolOperation](contracts/finite-conversation.md#sd-efx-tol-004--queryauthorizedtooloperation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-TOL-005 | Effect | [ReconcileAuthorizedToolOperation](contracts/finite-conversation.md#sd-efx-tol-005--reconcileauthorizedtooloperation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-TOL-004 | Event | [ToolOperationQueryObserved](contracts/finite-conversation.md#sd-evt-tol-004--tooloperationqueryobserved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-TOL-005 | Event | [ToolOperationReconciliationObserved](contracts/finite-conversation.md#sd-evt-tol-005--tooloperationreconciliationobserved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-GPH-AGT-001 | Effect Graph | [AgentTurnRecoveryGraph](contracts/finite-conversation.md#sd-gph-agt-001--agentturnrecoverygraph) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-GPH-AGT-002 | Effect Graph | [ThreadResetRecoveryGraph](contracts/finite-conversation.md#sd-gph-agt-002--threadresetrecoverygraph) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-GPH-TOL-001 | Effect Graph | [ToolOperationRecoveryGraph](contracts/finite-conversation.md#sd-gph-tol-001--tooloperationrecoverygraph) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-CFG-007 | Event | [ConfigurationPersistenceRecoveryResolved](contracts/configuration-application.md#sd-evt-cfg-007--configurationpersistencerecoveryresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-CFG-007 | Transition | [ApplyConfigurationPersistenceRecoveryResolution](contracts/configuration-application.md#sd-trn-cfg-007--applyconfigurationpersistencerecoveryresolution) | Primary Sol + structural review | N/A | SD-CTX-CFG-001 only | 1 | draft | — |
| SD-PER-CFG-007 | Persistence | [RuntimeRestartRegistrationUoW](contracts/configuration-application.md#sd-per-cfg-007--runtimerestartregistrationuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-CFG-008 | Persistence | [ConfigurationPersistenceRecoveryResolutionUoW](contracts/configuration-application.md#sd-per-cfg-008--configurationpersistencerecoveryresolutionuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-RBI-005 | Event | [RuntimeBindingRecoveryResolved](contracts/runtime-binding.md#sd-evt-rbi-005--runtimebindingrecoveryresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-RBI-003 | Persistence | [RuntimeBindingRecoveryResolutionUoW](contracts/runtime-binding.md#sd-per-rbi-003--runtimebindingrecoveryresolutionuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-RST-004 | Event | [RuntimeRestartResolved](contracts/migration-and-restart.md#sd-evt-rst-004--runtimerestartresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-RST-003 | Transition | [ApplyRuntimeRestartResolution](contracts/migration-and-restart.md#sd-trn-rst-003--applyruntimerestartresolution) | Primary Sol + structural review | N/A | SD-CTX-RST-001 only | 1 | draft | — |
| SD-PER-RST-003 | Persistence | [RuntimeRestartResolutionUoW](contracts/migration-and-restart.md#sd-per-rst-003--runtimerestartresolutionuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-MIG-002 | Event | [MigrationRecoveryObserved](contracts/migration-and-restart.md#sd-evt-mig-002--migrationrecoveryobserved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-MIG-002 | Transition | [ApplyMigrationRecoveryObservation](contracts/migration-and-restart.md#sd-trn-mig-002--applymigrationrecoveryobservation) | Primary Sol + structural review | N/A | SD-CTX-MIG-001 only | 1 | draft | — |
| SD-EVT-MIG-003 | Event | [MigrationRecoveryResolved](contracts/migration-and-restart.md#sd-evt-mig-003--migrationrecoveryresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-MIG-003 | Transition | [RecordMigrationRecoveryResolution](contracts/migration-and-restart.md#sd-trn-mig-003--recordmigrationrecoveryresolution) | Primary Sol + structural review | N/A | SD-CTX-MIG-001 only | 1 | draft | — |
| SD-EFX-MIG-005 | Effect | [ReconcileWorkspaceMigrationOperation](contracts/migration-and-restart.md#sd-efx-mig-005--reconcileworkspacemigrationoperation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-MIG-002 | Persistence | [MigrationRecoveryResolutionUoW](contracts/migration-and-restart.md#sd-per-mig-002--migrationrecoveryresolutionuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-QLI-001 | Rule | [DecideQualiaRecovery](contracts/finite-conversation.md#sd-rul-qli-001--decidequaliarecovery) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-QLI-002 | Event | [QualiaRecoveryDecided](contracts/finite-conversation.md#sd-evt-qli-002--qualiarecoverydecided) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-QLI-002 | Transition | [ApplyQualiaRecoveryDecision](contracts/finite-conversation.md#sd-trn-qli-002--applyqualiarecoverydecision) | Primary Sol + structural review | N/A | SD-CTX-QLI-001 only | 1 | draft | — |
| SD-RUL-AGT-011 | Rule | [AdmitExplicitContinuityRestart](contracts/finite-conversation.md#sd-rul-agt-011--admitexplicitcontinuityrestart) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-AGT-016 | Event | [ExplicitContinuityRestartAdmitted](contracts/finite-conversation.md#sd-evt-agt-016--explicitcontinuityrestartadmitted) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-AGT-013 | Transition | [BeginExplicitContinuityRestart](contracts/finite-conversation.md#sd-trn-agt-013--beginexplicitcontinuityrestart) | Primary Sol + structural review | N/A | SD-CTX-AGT-001 only | 1 | draft | — |
| SD-PER-AGT-003 | Persistence | [ExplicitContinuityRestartUoW](contracts/finite-conversation.md#sd-per-agt-003--explicitcontinuityrestartuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-RST-004 | Rule | [DecideActiveWorkHandoffRelease](contracts/migration-and-restart.md#sd-rul-rst-004--decideactiveworkhandoffrelease) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-RST-005 | Event | [ActiveWorkHandoffResolved](contracts/migration-and-restart.md#sd-evt-rst-005--activeworkhandoffresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-RST-004 | Transition | [ApplyActiveWorkHandoffResolution](contracts/migration-and-restart.md#sd-trn-rst-004--applyactiveworkhandoffresolution) | Primary Sol + structural review | N/A | SD-CTX-RST-001 only | 1 | draft | — |
| SD-PER-RST-004 | Persistence | [ActiveWorkHandoffReleaseUoW](contracts/migration-and-restart.md#sd-per-rst-004--activeworkhandoffreleaseuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-MIG-003 | Rule | [DecideMigrationStageAdvance](contracts/migration-and-restart.md#sd-rul-mig-003--decidemigrationstageadvance) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-MIG-004 | Event | [MigrationStageAdvanced](contracts/migration-and-restart.md#sd-evt-mig-004--migrationstageadvanced) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-MIG-004 | Transition | [AdvanceMigrationStage](contracts/migration-and-restart.md#sd-trn-mig-004--advancemigrationstage) | Primary Sol + structural review | N/A | SD-CTX-MIG-001 only | 1 | draft | — |
| SD-PER-MIG-003 | Persistence | [MigrationStageAdvanceUoW](contracts/migration-and-restart.md#sd-per-mig-003--migrationstageadvanceuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-MOD-EXE-002 | Module boundary | [ResumeContributionContract](contracts/execution.md#sd-mod-exe-002--resumecontributioncontract) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-EXE-006 | Event | [ExecutionResumePlanCommitted](contracts/execution.md#sd-evt-exe-006--executionresumeplancommitted) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-EXE-004 | Rule | [ValidateExecutionResumePlan](contracts/execution.md#sd-rul-exe-004--validateexecutionresumeplan) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-EXE-013 | Transition | [ApplyExecutionResumePlan](contracts/execution.md#sd-trn-exe-013--applyexecutionresumeplan) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
| SD-EVT-CNV-003 | Event | [FiniteConversationResumed](contracts/finite-conversation.md#sd-evt-cnv-003--finiteconversationresumed) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-CNV-005 | Rule | [BuildFiniteConversationResumeContribution](contracts/finite-conversation.md#sd-rul-cnv-005--buildfiniteconversationresumecontribution) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-CNV-007 | Transition | [ApplyFiniteConversationResumeCheckpoint](contracts/finite-conversation.md#sd-trn-cnv-007--applyfiniteconversationresumecheckpoint) | Primary Sol + structural review | N/A | SD-CTX-CNV-001 only | 1 | draft | — |
| SD-PER-MIG-004 | Persistence | [MigrationRecoveryBranchRegistrationUoW](contracts/migration-and-restart.md#sd-per-mig-004--migrationrecoverybranchregistrationuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-MIG-004 | Rule | [PlanMigrationRecoveryBranchRegistration](contracts/migration-and-restart.md#sd-rul-mig-004--planmigrationrecoverybranchregistration) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-MIG-005 | Event | [MigrationRecoveryBranchRegistered](contracts/migration-and-restart.md#sd-evt-mig-005--migrationrecoverybranchregistered) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-MIG-005 | Transition | [RegisterMigrationRecoveryBranch](contracts/migration-and-restart.md#sd-trn-mig-005--registermigrationrecoverybranch) | Primary Sol + structural review | N/A | SD-CTX-MIG-001 only | 1 | draft | — |
| SD-MOD-EXE-003 | Module boundary | [ExecutionLineageAndResumeProvenance](contracts/execution.md#sd-mod-exe-003--executionlineageandresumeprovenance) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-EXE-007 | Event | [CheckpointResumeClaimResolved](contracts/execution.md#sd-evt-exe-007--checkpointresumeclaimresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-EXE-005 | Rule | [DecideCheckpointResumeClaimOutcome](contracts/execution.md#sd-rul-exe-005--decidecheckpointresumeclaimoutcome) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-EXE-014 | Transition | [ApplyCheckpointResumeClaimOutcome](contracts/execution.md#sd-trn-exe-014--applycheckpointresumeclaimoutcome) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
| SD-PER-EXE-006 | Persistence | [ResumeAwareNormalDispatchClaimComposition](contracts/execution.md#sd-per-exe-006--resumeawarenormaldispatchclaimcomposition) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-CNV-004 | Event | [FiniteConversationSafeProgressReached](contracts/finite-conversation.md#sd-evt-cnv-004--finiteconversationsafeprogressreached) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-CNV-006 | Rule | [BuildNextFiniteConversationSafeCheckpoint](contracts/finite-conversation.md#sd-rul-cnv-006--buildnextfiniteconversationsafecheckpoint) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-CNV-008 | Transition | [RegisterNextFiniteConversationSafeCheckpoint](contracts/finite-conversation.md#sd-trn-cnv-008--registernextfiniteconversationsafecheckpoint) | Primary Sol + structural review | N/A | SD-CTX-CNV-001 only | 1 | draft | — |
| SD-PER-CNV-002 | Persistence | [FiniteConversationSafeProgressCheckpointUoW](contracts/finite-conversation.md#sd-per-cnv-002--finiteconversationsafeprogresscheckpointuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-MOD-RST-002 | Module boundary | [RestartHandoffEpoch](contracts/migration-and-restart.md#sd-mod-rst-002--restarthandoffepoch) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-RBI-005 | Rule | [ValidateRuntimeBindingCandidateStaging](contracts/runtime-binding.md#sd-rul-rbi-005--validateruntimebindingcandidatestaging) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-RBI-006 | Rule | [ValidateStagedRuntimeCandidateActivation](contracts/runtime-binding.md#sd-rul-rbi-006--validatestagedruntimecandidateactivation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-RBI-006 | Event | [RuntimeBindingCandidateStaged](contracts/runtime-binding.md#sd-evt-rbi-006--runtimebindingcandidatestaged) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-RBI-007 | Event | [RuntimeBindingGenerationActivated](contracts/runtime-binding.md#sd-evt-rbi-007--runtimebindinggenerationactivated) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-RBI-004 | Persistence | [RuntimeBindingCandidateStagingUoW](contracts/runtime-binding.md#sd-per-rbi-004--runtimebindingcandidatestaginguow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-CFG-007 | Rule | [DecideAtomicGroupActivation](contracts/configuration-application.md#sd-rul-cfg-007--decideatomicgroupactivation) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-EXE-008 | Event | [InitialExecutionLineageAdmitted](contracts/execution.md#sd-evt-exe-008--initialexecutionlineageadmitted) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-EXE-006 | Rule | [ValidateInitialExecutionLineageAdmission](contracts/execution.md#sd-rul-exe-006--validateinitialexecutionlineageadmission) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-EXE-015 | Transition | [InitializeExecutionLineage](contracts/execution.md#sd-trn-exe-015--initializeexecutionlineage) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
| SD-PER-EXE-007 | Persistence | [InitialInteractionExecutionAdmissionComposition](contracts/execution.md#sd-per-exe-007--initialinteractionexecutionadmissioncomposition) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-CNV-005 | Event | [FiniteConversationResumeClaimRejected](contracts/finite-conversation.md#sd-evt-cnv-005--finiteconversationresumeclaimrejected) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-CNV-007 | Rule | [MapFiniteConversationResumeClaimRejection](contracts/finite-conversation.md#sd-rul-cnv-007--mapfiniteconversationresumeclaimrejection) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-CNV-009 | Transition | [ApplyFiniteConversationResumeClaimRejection](contracts/finite-conversation.md#sd-trn-cnv-009--applyfiniteconversationresumeclaimrejection) | Primary Sol + structural review | N/A | SD-CTX-CNV-001 only | 1 | draft | — |
| SD-TRN-INT-002 | Transition | [ApplyInteractionTerminalResult](contracts/finite-conversation.md#sd-trn-int-002--applyinteractionterminalresult) | Primary Sol + structural review | N/A | SD-CTX-INT-001 only | 1 | draft | — |
| SD-PER-CNV-003 | Persistence | [FiniteConversationResumeClaimRejectionUoW](contracts/finite-conversation.md#sd-per-cnv-003--finiteconversationresumeclaimrejectionuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRF-RBI-001 | Profile contract | [RuntimeCandidateProbeCapabilityProfile](contracts/runtime-binding.md#sd-prf-rbi-001--runtimecandidateprobecapabilityprofile) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-RBI-007 | Rule | [DecidePostActivationGenerationDrain](contracts/runtime-binding.md#sd-rul-rbi-007--decidepostactivationgenerationdrain) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-RBI-008 | Rule | [AuthorizeRuntimeCandidateProbeStrategy](contracts/runtime-binding.md#sd-rul-rbi-008--authorizeruntimecandidateprobestrategy) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CTX-RCP-001 | Context | [Runtime Candidate Probe Profile Context](contracts/runtime-binding.md#sd-ctx-rcp-001--runtime-candidate-probe-profile-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-RCP-001 | State | [RuntimeCandidateProbeProfileState](contracts/runtime-binding.md#sd-sta-rcp-001--runtimecandidateprobeprofilestate) | Primary Sol + structural review | SD-CTX-RCP-001 | SD-TRN-RCP-001, SD-TRN-RCP-002, SD-TRN-RCP-003, SD-TRN-RCP-004, SD-TRN-RCP-005 | 1 | draft | — |
| SD-EVT-RCP-001 | Event | [RuntimeCandidateProbeProfileRegistered](contracts/runtime-binding.md#sd-evt-rcp-001--runtimecandidateprobeprofileregistered) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-RCP-002 | Event | [RuntimeCandidateProbeProfileProofPassed](contracts/runtime-binding.md#sd-evt-rcp-002--runtimecandidateprobeprofileproofpassed) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-RCP-001 | Rule | [ValidateRuntimeCandidateProbeProfileRegistration](contracts/runtime-binding.md#sd-rul-rcp-001--validateruntimecandidateprobeprofileregistration) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-RCP-002 | Rule | [DecideRuntimeCandidateProbeProfileProofPromotion](contracts/runtime-binding.md#sd-rul-rcp-002--decideruntimecandidateprobeprofileproofpromotion) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-RCP-003 | Rule | [DecideRuntimeCandidateProbeProfileRetention](contracts/runtime-binding.md#sd-rul-rcp-003--decideruntimecandidateprobeprofileretention) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-RCP-001 | Transition | [RegisterRuntimeCandidateProbeProfileRevision](contracts/runtime-binding.md#sd-trn-rcp-001--registerruntimecandidateprobeprofilerevision) | Primary Sol + structural review | N/A | SD-CTX-RCP-001 only | 1 | draft | — |
| SD-TRN-RCP-002 | Transition | [ApplyRuntimeCandidateProbeProfileProofPromotion](contracts/runtime-binding.md#sd-trn-rcp-002--applyruntimecandidateprobeprofileproofpromotion) | Primary Sol + structural review | N/A | SD-CTX-RCP-001 only | 1 | draft | — |
| SD-TRN-RCP-003 | Transition | [ApplyRuntimeCandidateProbeProfileRevisionUse](contracts/runtime-binding.md#sd-trn-rcp-003--applyruntimecandidateprobeprofilerevisionuse) | Primary Sol + structural review | N/A | SD-CTX-RCP-001 only | 1 | draft | — |
| SD-TRN-RCP-004 | Transition | [CollectRuntimeCandidateProbeProfileRevision](contracts/runtime-binding.md#sd-trn-rcp-004--collectruntimecandidateprobeprofilerevision) | Primary Sol + structural review | N/A | SD-CTX-RCP-001 only | 1 | draft | — |
| SD-PER-RCP-001 | Persistence | [RuntimeCandidateProbeProfileRevisionUseUoW](contracts/runtime-binding.md#sd-per-rcp-001--runtimecandidateprobeprofilerevisionuseuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-MOD-RCP-001 | Module boundary | [RuntimeCandidateProbeProfileIngressContract](contracts/runtime-binding.md#sd-mod-rcp-001--runtimecandidateprobeprofileingresscontract) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CMD-RCP-001 | Command | [ProvisionRuntimeCandidateProbeProfileSeed](contracts/runtime-binding.md#sd-cmd-rcp-001--provisionruntimecandidateprobeprofileseed) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-CMD-RCP-002 | Command | [AdministerRuntimeCandidateProbeProfile](contracts/runtime-binding.md#sd-cmd-rcp-002--administerruntimecandidateprobeprofile) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-RCP-003 | Event | [RuntimeCandidateProbeProfileIngressRejected](contracts/runtime-binding.md#sd-evt-rcp-003--runtimecandidateprobeprofileingressrejected) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-RCP-004 | Event | [RuntimeCandidateProbeProfileIngressCommitted](contracts/runtime-binding.md#sd-evt-rcp-004--runtimecandidateprobeprofileingresscommitted) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-RCP-004 | Rule | [AuthorizeRuntimeCandidateProbeProfileIngress](contracts/runtime-binding.md#sd-rul-rcp-004--authorizeruntimecandidateprobeprofileingress) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-RCP-005 | Rule | [ValidateRuntimeCandidateProbeProofEvidence](contracts/runtime-binding.md#sd-rul-rcp-005--validateruntimecandidateprobeproofevidence) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-RCP-005 | Transition | [ApplyRuntimeCandidateProbeProfileIngressRecord](contracts/runtime-binding.md#sd-trn-rcp-005--applyruntimecandidateprobeprofileingressrecord) | Primary Sol + structural review | N/A | SD-CTX-RCP-001 only | 1 | draft | — |
| SD-PER-RCP-002 | Persistence | [RuntimeCandidateProbeProfileSeedProvisioningUoW](contracts/runtime-binding.md#sd-per-rcp-002--runtimecandidateprobeprofileseedprovisioninguow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-RCP-003 | Persistence | [RuntimeCandidateProbeProfileAdministrationUoW](contracts/runtime-binding.md#sd-per-rcp-003--runtimecandidateprobeprofileadministrationuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PRT-RCP-001 | Port | [RuntimeCandidateProbeProfileAdministrationIngress](contracts/runtime-binding.md#sd-prt-rcp-001--runtimecandidateprobeprofileadministrationingress) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-RBI-009 | Rule | [DecideRuntimeBindingCandidateKnownFailure](contracts/runtime-binding.md#sd-rul-rbi-009--decideruntimebindingcandidateknownfailure) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-RBI-008 | Event | [RuntimeBindingCandidateRejected](contracts/runtime-binding.md#sd-evt-rbi-008--runtimebindingcandidaterejected) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-RBI-005 | Persistence | [RuntimeBindingCandidateKnownFailureUoW](contracts/runtime-binding.md#sd-per-rbi-005--runtimebindingcandidateknownfailureuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-RBI-010 | Rule | [ResolveRuntimeBindingCandidateCleanup](contracts/runtime-binding.md#sd-rul-rbi-010--resolveruntimebindingcandidatecleanup) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-RBI-009 | Event | [RuntimeBindingCandidateCleanupPlanned](contracts/runtime-binding.md#sd-evt-rbi-009--runtimebindingcandidatecleanupplanned) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EFX-RBI-008 | Effect | [CleanupRuntimeBindingCandidate](contracts/runtime-binding.md#sd-efx-rbi-008--cleanupruntimebindingcandidate) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-RBI-006 | Persistence | [RuntimeBindingCandidateCleanupResolutionUoW](contracts/runtime-binding.md#sd-per-rbi-006--runtimebindingcandidatecleanupresolutionuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-RBI-010 | Event | [RuntimeBindingCandidateAdmissionResolved](contracts/runtime-binding.md#sd-evt-rbi-010--runtimebindingcandidateadmissionresolved) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-PER-RBI-007 | Persistence | [RuntimeBindingCandidateRegistrationUoW](contracts/runtime-binding.md#sd-per-rbi-007--runtimebindingcandidateregistrationuow) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
