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
Runtime mutation authorityにはcanonical `SD-TRN-*`だけを列挙します。Pilot Cで定義予定の
Policy configuration Transitionだけは、Pilot C完了まで明示的な予定表記を許します。
Adapter、Projection、Port、Python workerをState ownerまたはmutation authorityにしません。

## 索引schema

| Design ID | 種別 | Canonical definition | Contract write authority | Domain State owner | Runtime mutation authority | Version | Status | Supersedes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| SD-CTX-EXE-001 | Context | [Execution Context](contracts/execution.md#sd-ctx-exe-001--execution-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-EXE-001 | State | [ExecutionState](contracts/execution.md#sd-sta-exe-001--executionstate) | Primary Sol + structural review | SD-CTX-EXE-001 | SD-TRN-EXE-001, SD-TRN-EXE-002, SD-TRN-EXE-003, SD-TRN-EXE-004, SD-TRN-EXE-005, SD-TRN-EXE-006, SD-TRN-EXE-007, SD-TRN-EXE-008 | 1 | draft | — |
| SD-EVT-ING-001 | Event | [IngestedExternalEvent](contracts/execution.md#sd-evt-ing-001--ingestedexternalevent) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-EXE-001 | Event | [EffectExecutionStartedAccepted](contracts/execution.md#sd-evt-exe-001--effectexecutionstartedaccepted) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-EXE-002 | Event | [EffectExecutionFailed](contracts/execution.md#sd-evt-exe-002--effectexecutionfailed) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-EVT-EXE-003 | Event | [GuardFactRecorded](contracts/execution.md#sd-evt-exe-003--guardfactrecorded) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-EXE-001 | Rule | [DetermineReadyOccurrences](contracts/execution.md#sd-rul-exe-001--determinereadyoccurrences) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-RUL-EXE-002 | Rule | [DecideDispatchClaim](contracts/execution.md#sd-rul-exe-002--decidedispatchclaim) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-TRN-EXE-001 | Transition | [RegisterGraphAndPending](contracts/execution.md#sd-trn-exe-001--registergraphandpending) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
| SD-TRN-EXE-002 | Transition | [ApplyDispatchClaim](contracts/execution.md#sd-trn-exe-002--applydispatchclaim) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
| SD-TRN-EXE-003 | Transition | [ApplyOccurrenceResult](contracts/execution.md#sd-trn-exe-003--applyoccurrenceresult) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
| SD-TRN-EXE-004 | Transition | [RevokeInteractionDescendants](contracts/execution.md#sd-trn-exe-004--revokeinteractiondescendants) | Primary Sol + structural review | N/A | SD-CTX-EXE-001 only | 1 | draft | — |
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
| SD-STA-DAT-001 | State | [DataClassificationState](contracts/camera-observation.md#sd-sta-dat-001--dataclassificationstate) | Primary Sol + structural review | SD-CTX-DAT-001 | SD-TRN-DAT-001 | 1 | draft | — |
| SD-CTX-PAP-001 | Context | [Physical Action Policy Context](contracts/camera-observation.md#sd-ctx-pap-001--physical-action-policy-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-PAP-001 | State | [PhysicalActionPolicyState](contracts/camera-observation.md#sd-sta-pap-001--physicalactionpolicystate) | Primary Sol + structural review | SD-CTX-PAP-001 | Policy configuration transition（Pilot Cで定義） | 1 | draft | — |
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
| SD-STA-QLI-001 | State | [QualiaState](contracts/finite-conversation.md#sd-sta-qli-001--qualiastate) | Primary Sol + structural review | SD-CTX-QLI-001 | SD-TRN-QLI-001 | 1 | draft | — |
| SD-CTX-INT-001 | Context | [Interaction Context](contracts/finite-conversation.md#sd-ctx-int-001--interaction-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-INT-001 | State | [InteractionState](contracts/finite-conversation.md#sd-sta-int-001--interactionstate) | Primary Sol + structural review | SD-CTX-INT-001 | SD-TRN-INT-001 | 1 | draft | — |
| SD-CTX-CNV-001 | Context | [Conversation Context](contracts/finite-conversation.md#sd-ctx-cnv-001--conversation-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-CNV-001 | State | [ConversationState](contracts/finite-conversation.md#sd-sta-cnv-001--conversationstate) | Primary Sol + structural review | SD-CTX-CNV-001 | SD-TRN-CNV-001, SD-TRN-CNV-002, SD-TRN-CNV-003, SD-TRN-CNV-004 | 1 | draft | — |
| SD-CTX-MEM-001 | Context | [Memory Context](contracts/finite-conversation.md#sd-ctx-mem-001--memory-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-MEM-001 | State | [MemoryState](contracts/finite-conversation.md#sd-sta-mem-001--memorystate) | Primary Sol + structural review | SD-CTX-MEM-001 | SD-TRN-MEM-001, SD-TRN-MEM-002, SD-TRN-MEM-003, SD-TRN-MEM-004, SD-TRN-MEM-005, SD-TRN-MEM-006, SD-TRN-MEM-007, SD-TRN-MEM-008 | 1 | draft | — |
| SD-CTX-AGT-001 | Context | [Agent Session Context](contracts/finite-conversation.md#sd-ctx-agt-001--agent-session-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-AGT-001 | State | [AgentSessionState](contracts/finite-conversation.md#sd-sta-agt-001--agentsessionstate) | Primary Sol + structural review | SD-CTX-AGT-001 | SD-TRN-AGT-001, SD-TRN-AGT-002, SD-TRN-AGT-003, SD-TRN-AGT-004, SD-TRN-AGT-005, SD-TRN-AGT-006 | 1 | draft | — |
| SD-CTX-NOT-001 | Context | [Notification Policy Context](contracts/finite-conversation.md#sd-ctx-not-001--notification-policy-context) | Primary Sol + structural review | N/A | N/A | 1 | draft | — |
| SD-STA-NOT-001 | State | [NotificationPolicyState](contracts/finite-conversation.md#sd-sta-not-001--notificationpolicystate) | Primary Sol + structural review | SD-CTX-NOT-001 | Policy configuration transition（Pilot Cで定義） | 1 | draft | — |
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
