# Pilot C — 設定更新・Capability binding

このsliceは[SD-REV-PILOT-C-001](../verification/change-sets/SD-REV-PILOT-C-001.md)の検証単位です。正式定義は
[configuration](../contracts/configuration-application.md)、
[runtime binding](../contracts/runtime-binding.md)、
[routing](../contracts/routing-policy.md)、
[migration/restart](../contracts/migration-and-restart.md)に置きます。

## 設計の核

- SD-CTX-CFG-001はdesired／effective／pending設定だけを所有する。
- 各Capability、Authorization、Routing、Profile、Quality、Restart、Migrationは別Contextが所有する。
- 設定保存はSD-EFX-CFG-001であり、readback digest一致後にだけdesiredを確定する。
- owner EventとSD-TRN-EXE-007はSD-PER-EXE-003で同時確定する。
- active InteractionはBehavior初期UoWでCFG/BRP/IRP RevisionUseを原子取得し、pinned revisionを保持して自動fallbackしない。
- Camera Profile／QPR useはadmissionでなくSD-PER-CAM-001で取得する。
- 最後のBindingUse解放とretirement登録はSD-PER-RBI-001で同時確定する。
- RestartAdapterのMaterialize／Probe成功はcandidateをStagedReadyにするだけで、全atomic group targetとCFGをSD-PER-CFG-004で同時に有効化する。
- old generationがactivation時点でzero-useなら、AllBindingUsesReleasedとretirement Graphを同じactivation commitで登録する。
- RestartAdapterはProfileがparallel candidate probeを証明したCapabilityだけに許可し、RequiresGlobalRestartを暗黙fallbackしない。
- 組込みcandidate probe Profile/proofはversion付きrelease/migration seed、ローカル追加・再検証は認証済みLinux管理者CLIだけを入口とし、Web/APIやAdapter自己申告からPassingを作らない。
- normal Materialize/Probeの確定FailureはCFG step Failedとold effective/snapshot維持を原子確定する。M未適用またはno-artifact証明時だけ即時Rejectedとし、M適用済みcandidateはcleanup lifecycle/custodyとRCP useを保持して外部runtimeをorphan化しない。
- 初期candidate cardinalityはCapability/mode/Adapter classごとに1とし、valid current Passing Profileに対するfirst admissionがcompare-not-exists CASで決定論的slot revision 0を生成する。generation登録からactivationまたは安全なcleanup終端までcandidate slotのNamedInterval leaseを保持する。
- restart handoffはexact epoch／execution subject generationだけを対象にし、Resume後は必ず通常dispatch claimを通る。
- Snapshotだけを復旧正本とし、journalからStateやEffectを再生成しない。

## Atomic Design Obligation

| Obligation | Parent AC | Joint group | Parent contribution | Design contracts | Proof | Negative case | Scope | Accounting | Design | Proof status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| DO-CFG-001 | AC-CFG-001 | JG-CFG-ROOTS | partial | SD-STA-CFG-001, SD-PRT-CFG-001 | architecture/contract | XDG役割混在、secret平文 | Linux storage境界 | accounted-for | designed | planned |
| DO-CFG-002 | AC-CFG-002 | JG-CFG-SCHEMA | full | SD-RUL-CFG-001, SD-EVT-CFG-001 | pure | 不正型、未知必須値受理 | configuration schema | accounted-for | designed | planned |
| DO-CFG-003 | AC-CFG-003 | JG-CFG-LAYER | full | SD-RUL-CFG-002, SD-PRJ-CFG-001 | pure/projection | layer逆転、provenance欠落 | configuration layer | accounted-for | designed | planned |
| DO-CFG-004 | AC-CFG-004 | JG-CFG-WRITE | full | SD-CMD-CFG-001, SD-EFX-CFG-001, SD-PER-CFG-001, SD-PER-CFG-003 | contract/crash-recovery | Web直接write、部分commit | configuration write | accounted-for | designed | planned |
| DO-CFG-005 | AC-CFG-005 | JG-CFG-WRITE | full | SD-GPH-CFG-001, SD-REC-CFG-001, SD-STA-CFG-001 | crash-recovery | 失敗後に部分設定をeffective化 | configuration write | accounted-for | designed | planned |
| DO-CFG-006 | AC-CFG-006 | JG-CFG-APPLY | full | SD-RUL-CFG-004, SD-PRJ-CFG-001, SD-GPH-RST-001 | pure/projection | 指定外restart、反映差分欠落 | apply modes | accounted-for | designed | planned |
| DO-CFG-007 | AC-CFG-007 | JG-CFG-MIGRATION | full | SD-GPH-MIG-001, SD-RUL-MIG-001, SD-PRT-MIG-001 | integration | 利用者asset上書き | upgrade | accounted-for | designed | planned |
| DO-CFG-008 | AC-CFG-008 | JG-CFG-MIGRATION | full | SD-REC-MIG-001, SD-PER-MIG-001, SD-PRJ-MIG-001 | crash-recovery | 部分migration公開 | upgrade | accounted-for | designed | planned |
| DO-CFG-009 | AC-CFG-009 | JG-CFG-BINDING | full | SD-MOD-RBI-001, SD-PRT-RBI-001 | architecture/contract | mode切替でDomain変更 | capability binding | accounted-for | designed | planned |
| DO-CFG-010 | AC-CFG-010 | JG-CFG-BINDING | full | SD-RUL-RBI-001, SD-EVT-RBI-002, SD-REC-RBI-001 | pure/contract | mismatchを互換扱い、fallback | remote binding | accounted-for | designed | planned |
| DO-CFG-013 | AC-CFG-013 | JG-CFG-APPLY | full | SD-PER-CFG-005, SD-PER-EXE-007, SD-TRN-CFG-006, SD-TRN-BRP-002, SD-TRN-IRP-002 | concurrency/crash-recovery | PER-CFG-005がINT/QLIを単独admit、CFG useだけ/BRP-IRP useだけ/Interactionだけ/Graphだけの部分commit、active rebind、fallback | next interaction initial admission | accounted-for | designed | planned |
| DO-CFG-014 | AC-CFG-014 | JG-CFG-MATRIX | partial | SD-MOD-RBI-001, SD-EFX-AGT-007, SD-RUL-AGT-007 | integration/contract | Codex remote扱い、disabled依存ready | initial deployment | accounted-for | designed | planned |
| DO-CFG-015 | AC-CFG-015 | JG-CFG-APPLY | partial | SD-PER-CFG-004, SD-PER-CFG-005, SD-TRN-MEM-009, SD-TRN-NOT-001, SD-TRN-AUT-001, SD-CTX-DPF-001 | concurrency | active Effectへ遡及 | cross-context config | accounted-for | designed | planned |
| DO-CFG-017 | AC-SET-002 | JG-CFG-SETUP | partial | SD-PRJ-RBI-002, SD-PRJ-AGT-001 | integration/projection | readiness理由・remedy欠落 | doctor | accounted-for | designed | planned |
| DO-CFG-019 | AC-QPR-001 | JG-CFG-QUALITY | full | SD-STA-QPR-001, SD-TRN-QPR-001 | measurement | 測定欠落 | profile | accounted-for | designed | blocked-by-spike |
| DO-CFG-020 | AC-QPR-002 | JG-CFG-QUALITY | full | SD-STA-QPR-001, SD-PRJ-RBI-002 | measurement | warm/cold混同 | profile | accounted-for | designed | blocked-by-spike |
| DO-CFG-021 | AC-QPR-003 | JG-CFG-QUALITY | full | SD-STA-QPR-001, SD-RUL-RBI-001 | measurement | 基準FIX前ready | profile | accounted-for | designed | blocked-by-spike |
| DO-CFG-022 | AC-QPR-004 | JG-CFG-QUALITY | full | SD-TRN-QPR-001, SD-PRJ-RBI-002 | measurement | 証拠流用 | profile | accounted-for | designed | blocked-by-spike |
| DO-CFG-023 | AC-PRD-009 | JG-CFG-CAP | partial | SD-MOD-RBI-001, SD-PRJ-RBI-001 | integration | local/remote広告欠落 | inference capability | accounted-for | designed | planned |
| DO-CFG-024 | AC-PRD-010 | JG-CFG-ROUTE | full | SD-RUL-BRP-001, SD-RUL-IRP-001, SD-STA-IRP-001 | pure/integration | route選択LLM生成 | inference routing | accounted-for | designed | planned |
| DO-CFG-025 | AC-PRD-011 | JG-CFG-ROUTE | full | SD-RUL-IRP-001, SD-PRJ-IRP-001, SD-REC-RBI-001 | pure/projection | preferred/effective混同、fallback表示 | inference routing | accounted-for | designed | planned |
| DO-CFG-026 | AC-PRD-017 | JG-CFG-ROUTE | full | SD-PER-CFG-005, SD-TRN-IRP-002, SD-STA-AGT-001 | concurrency/integration | active turn rebind | agent turn | accounted-for | designed | planned |
| DO-CFG-027 | AC-PRD-020 | JG-CFG-CONTINUITY | full | SD-RUL-IRP-001, SD-STA-AGT-001, SD-STA-PRV-001 | pure/integration | NoExternalContinuityへThread偽装 | inference route | accounted-for | designed | planned |
| DO-CFG-028 | AC-FR-017 | JG-CFG-ROUTE | full | SD-RUL-BRP-001, SD-RUL-IRP-001 | pure | behaviorとVision routeを一Decision化 | multimodal routing | accounted-for | designed | planned |
| DO-CFG-029 | AC-ARC-002 | JG-CFG-DEPENDENCY | partial | SD-MOD-RBI-001, SD-PRT-CFG-001, SD-PRT-RBI-001 | architecture | DomainからAdapter/FFIへ依存 | Core boundary | accounted-for | designed | planned |
| DO-CFG-032 | AC-ARC-009 | JG-CFG-ROUTING | full | SD-STA-BRP-001, SD-RUL-BRP-001 | pure | gray gate結果を区別しない | behavior routing | accounted-for | designed | planned |
| DO-CFG-033 | AC-ARC-010 | JG-CFG-ROUTING | full | SD-RUL-BRP-001, SD-PRJ-BRP-001 | pure | 競合・曖昧・候補なしを統合 | behavior routing | accounted-for | designed | planned |
| DO-CFG-034 | AC-ARC-013 | JG-CFG-CONTRIBUTOR | full | SD-STA-BRP-001, SD-RUL-BRP-001 | pure | rule-onlyでもSBERT必須 | contributor policy | accounted-for | designed | planned |
| DO-CFG-035 | AC-ARC-018 | JG-CFG-CONTRIBUTOR | full | SD-STA-BRP-001, SD-TRN-BRP-001, SD-RUL-BRP-001 | pure/architecture | Policy version変更にKernel分岐 | contributor policy | accounted-for | designed | planned |
| DO-CFG-037 | AC-ARC-028 | JG-CFG-AUTHORITY | partial | SD-CTX-AUT-001, SD-STA-AUT-001, SD-TRN-AUT-001 | architecture | Skill/LLMがgrant所有 | authorization | accounted-for | designed | planned |
| DO-CFG-055 | AC-OPS-009 | JG-CFG-RUNTIME | full | SD-MOD-RBI-001, SD-PRT-RBI-001, SD-PRT-RBI-002 | architecture/contract | rebindでDomain変更 | capability adapter | accounted-for | designed | planned |
| DO-CFG-056 | AC-OPS-027 | JG-CFG-RUNTIME | partial | SD-RUL-INT-001, SD-RUL-RBI-001, SD-PRJ-RBI-002 | pure/integration | unavailable資源でもadmit | Qualia admission | accounted-for | designed | planned |
| DO-CFG-057 | AC-API-001 | JG-CFG-API | partial | SD-CMD-CFG-001, SD-PRJ-CFG-001 | contract | UIのみ | API | accounted-for | designed | planned |
| DO-CFG-058 | AC-API-002 | JG-CFG-API | partial | SD-CMD-CFG-001, SD-RUL-CFG-003, SD-GPH-CFG-001 | contract | APIがEffect/Adapter/Stateを直接操作 | configuration API | accounted-for | designed | planned |
| DO-CFG-059 | AC-API-003 | JG-CFG-API | partial | SD-CMD-CFG-001, SD-PRJ-CFG-001, SD-PRT-CFG-001 | architecture | transport schemaをDomain型化 | configuration API | accounted-for | designed | planned |
| DO-CFG-064 | AC-SKL-003 | JG-CFG-SKILL | full | SD-TRN-AUT-001, SD-STA-AUT-001 | pure | 自己権限拡大 | Skill | accounted-for | designed | planned |
| DO-CFG-065 | AC-CFG-006 | JG-CFG-INTERNAL-APPLY | full | SD-RUL-CFG-004, SD-PER-CFG-004, SD-TRN-CFG-005 | pure/concurrency | internal Policy/Profile変更を外部Effect化、owner commit前にeffectiveへ昇格、複数ownerの部分commit | Immediate/NextInteraction apply | accounted-for | designed | planned |
| DO-CFG-066 | AC-CFG-006 | JG-CFG-EXTERNAL-APPLY | full | SD-GPH-RBI-001, SD-MOD-RBI-002, SD-RUL-CFG-004 | architecture/integration | 汎用ApplyTarget Effect、RuntimeControl payloadでCapability materialize/probeを代用 | external capability apply | accounted-for | designed | planned |
| DO-CFG-067 | AC-CFG-009 | JG-CFG-RUNTIME-PAYLOAD | full | SD-MOD-RBI-001, SD-MOD-RBI-002, SD-EFX-RBI-001, SD-EFX-RBI-002, SD-EFX-RBI-003, SD-EFX-RBI-004, SD-EFX-RBI-005, SD-EFX-RBI-006, SD-EFX-RBI-007, SD-EFX-RBI-008 | contract/architecture | mode、target operation、candidate cleanup contract/custody、AllBindingUsesReleased evidence、query/probe evidence、deadline stage/anchor/durationのfield loss、generic operation DTO | runtime binding payload closure | accounted-for | designed | planned |
| DO-CFG-068 | AC-CFG-010 | JG-CFG-RUNTIME-RECOVERY | partial | SD-MOD-RBI-001, SD-EFX-RBI-005, SD-EFX-RBI-006, SD-EFX-RBI-007, SD-EFX-RBI-008, SD-EVT-RBI-004, SD-EVT-RBI-005, SD-RUL-RBI-002, SD-RUL-RBI-004, SD-RUL-RBI-010, SD-PER-RBI-003, SD-PER-RBI-006, SD-PER-EXE-005, SD-REC-RBI-001 | concurrency/crash-recovery | OutcomeUnknownを自動再送、Q/C/Rを二回attempt、cleanup custody/RCP useの部分Recovery、EXE custody QuarantinedでBindingUseだけRecovery、Quarantined UseをLastUseReleased扱い、late reconcileで新generation変更、旧modeへfallback | runtime binding recovery/no-fallback部分 | accounted-for | designed | planned |
| DO-CFG-069 | AC-CFG-009 | JG-CFG-RUNTIME-DISPATCH | partial | SD-PER-RBI-002, SD-RUL-RBI-001, SD-RUL-RBI-003 | concurrency/crash-recovery | owner revision/readiness/generation/EXEの一部だけ確認、BindingUseまたはoutboxだけcommit、Codexへ非Codex UoWを適用 | non-Codex capability dispatch部分 | accounted-for | designed | planned |
| DO-CFG-070 | AC-CFG-013 | JG-CFG-REVISION-USE | full | SD-PER-CFG-005, SD-PER-DPF-001, SD-PER-RBI-001 | concurrency/crash-recovery | 最終use解放とretirementの部分commit、active work中にrevision破棄 | configuration/profile/binding retirement | accounted-for | designed | planned |
| DO-CFG-071 | AC-CFG-006 | JG-CFG-RESTART-GRAPH | full | SD-RUL-CFG-004, SD-PER-CFG-007, SD-GPH-RST-001, SD-GPH-RBI-001, SD-PER-RST-001, SD-PER-RST-003, SD-EVT-RST-004 | integration/concurrency/crash-recovery | RestartAdapterをglobal restart、RestartRuntimeをRBI集合へ誤写像、API retryでGraph重複、別desired/atomic group completionでactivation | apply mode/global runtime restart | accounted-for | designed | planned |
| DO-CFG-072 | AC-OPS-024 | JG-CFG-RESTART-RECOVERY | partial | SD-EVT-EXE-005, SD-RUL-EXE-003, SD-TRN-EXE-010, SD-TRN-EXE-011, SD-TRN-EXE-012, SD-PER-EXE-004, SD-PER-EXE-005, SD-EFX-RST-006, SD-EFX-RST-007, SD-RUL-RST-003, SD-EVT-RST-002, SD-GPH-RST-001, SD-TRN-RST-003, SD-PER-RST-003, SD-REC-RST-001 | concurrency/crash-recovery | ZがQ/Xより先にready、cancel branchでX evidenceなしZ、custody移管/出口の部分commit、Q/X/Zを二回attempt、StillUnknownのRecord非終端またはrelease、quarantine runtime再利用 | runtime restart Recovery | accounted-for | designed | planned |
| DO-CFG-073 | AC-CFG-006 | JG-CFG-RESTART-HANDOFF | full | SD-MOD-EXE-002, SD-RUL-EXE-004, SD-TRN-EXE-013, SD-RUL-RST-002, SD-RUL-RST-004, SD-TRN-RST-002, SD-TRN-RST-004, SD-EVT-RST-003, SD-EVT-RST-005, SD-PER-RST-002, SD-PER-RST-004 | concurrency/crash-recovery | active work残存中restart、handoff Eventだけcommit、target owner未終端でReleased、AwaitOwnerDecisionでReleased、ContributionなしResume、QLI/Behavior/EXEの部分resume、Resume UoWがattempt/BindingUse/intent/outboxを直接生成、crash後にold workを再開 | restart active-work handoff lifecycleとpre-claim resume | accounted-for | designed | planned |
| DO-CFG-074 | AC-CFG-008 | JG-CFG-MIGRATION-RECOVERY | full | SD-MOD-MIG-001, SD-GPH-MIG-001, SD-EFX-MIG-001, SD-EFX-MIG-002, SD-EFX-MIG-003, SD-EFX-MIG-005, SD-EVT-MIG-001, SD-EVT-MIG-002, SD-EVT-MIG-003, SD-EVT-MIG-004, SD-EVT-MIG-005, SD-RUL-MIG-002, SD-RUL-MIG-003, SD-RUL-MIG-004, SD-TRN-MIG-001, SD-TRN-MIG-002, SD-TRN-MIG-003, SD-TRN-MIG-004, SD-TRN-MIG-005, SD-PER-MIG-002, SD-PER-MIG-003, SD-PER-MIG-004, SD-REC-MIG-001 | pure/concurrency/crash-recovery | intermediate DefinitelyAppliedをCompleted、MIG001/003でstage mutation、MIG004二回適用、step skipまたは二段advance、dependency未成立next、operation固有field欠落、Queryへのcancel混入、同stage duplicateで新recovery generation、別stageのbranchをdedupe、Q/X/R再attempt、Plan/stage/next/lease/custody部分commit、未検証Completed/Restored、quarantine workspace公開 | ordered migration stage、single mutator、stage-scoped Recovery | accounted-for | designed | planned |
| DO-CFG-075 | AC-CFG-005 | JG-CFG-PERSISTENCE-RECOVERY | full | SD-EVT-CFG-007, SD-RUL-CFG-006, SD-TRN-CFG-007, SD-PER-CFG-008, SD-PER-EXE-005, SD-REC-CFG-001 | concurrency/crash-recovery | digest不一致をDefinitelyAppliedとしてfinalize、Q/C/Rの二回attempt、CFG/lease/custodyの部分commit、StillUnknown文書資源を非終端または再利用 | configuration persistence Recovery | accounted-for | designed | planned |
| DO-CFG-076 | AC-CFG-006 | JG-CFG-ADAPTER-ATOMIC-ACTIVATION | full | SD-RUL-RBI-005, SD-EVT-RBI-006, SD-PER-RBI-004, SD-RUL-RBI-006, SD-EVT-RBI-007, SD-RUL-CFG-007, SD-PER-CFG-004 | pure/concurrency/crash-recovery | target一件だけEffective、CFGだけ新snapshot、Materialize受付だけでactivation、stale readinessでactivation、旧generationをactivation前にretire | RestartAdapter staged preparationとatomic activation | accounted-for | designed | planned |
| DO-CFG-077 | AC-OPS-024 | JG-CFG-RESTART-EPOCH | full | SD-MOD-RST-002, SD-MOD-EXE-003, SD-STA-QLI-001, SD-RUL-RST-002, SD-RUL-RST-004, SD-TRN-RST-002, SD-TRN-RST-004, SD-PER-RST-002, SD-PER-RST-004 | pure/concurrency/crash-recovery | E1 late handoffでE2 subject変更、handoffがreplacement subjectを自動包含、recovery history上書き、同一Qualiaの二回目restart拒否 | restart epochと複数resume cycle | accounted-for | designed | planned |
| DO-CFG-078 | AC-CFG-013 | JG-CFG-ZERO-USE-RETIREMENT | full | SD-RUL-RBI-007, SD-EVT-RBI-003, SD-PER-CFG-004, SD-PER-RBI-001 | pure/concurrency/crash-recovery | zero-use旧generationが永久Retiring、activation/last-release競合で二Graph、AllBindingUsesReleasedだけ部分commit、Quarantinedをrelease扱い | post-activation generation drain | accounted-for | designed | planned |
| DO-CFG-079 | AC-CFG-006 | JG-CFG-CANDIDATE-COEXISTENCE | full | SD-PRF-RBI-001, SD-RUL-RBI-008, SD-RUL-CFG-004, SD-PER-RBI-004, SD-PER-CFG-004 | contract/integration/spike | singleton local-managed旧/candidateを未証明で並行起動、RequiresGlobalRestartをRestartAdapter実行、RestartRuntimeへ暗黙fallback | Capability別candidate probe能力 | accounted-for | designed | blocked-by-spike |
| DO-CFG-080 | AC-CFG-009 | JG-CFG-CANDIDATE-PROFILE-OWNER | partial | SD-CTX-RCP-001, SD-STA-RCP-001, SD-EVT-RCP-001, SD-EVT-RCP-002, SD-RUL-RCP-001, SD-RUL-RCP-002, SD-RUL-RCP-003, SD-TRN-RCP-001, SD-TRN-RCP-002, SD-TRN-RCP-003, SD-TRN-RCP-004, SD-PER-RCP-001 | pure/architecture/concurrency/crash-recovery | AdapterがProfile/proof変更、evidenceなしPassing、missing/stale/Blocked refでstaging/activation、generationだけ/useだけcommit、Retired/Rejected/Quarantined前release、Acquired use中GC | Runtime candidate probe Profile ownership/use | accounted-for | designed | planned |
| DO-CFG-081 | AC-CFG-009 | JG-CFG-CANDIDATE-PROFILE-INGRESS | partial | SD-MOD-RCP-001, SD-CMD-RCP-001, SD-CMD-RCP-002, SD-EVT-RCP-003, SD-EVT-RCP-004, SD-RUL-RCP-004, SD-RUL-RCP-005, SD-TRN-RCP-005, SD-PER-RCP-002, SD-PER-RCP-003, SD-PRT-RCP-001 | pure/contract/architecture/concurrency/crash-recovery | Web/API runtime approval、Adapter/Skill/LLM自己申告、未認証CLI、seed一部適用、証拠なしPassing、同一idempotency key異digest、crash後のProfile/proof/ledger部分commit | RCP Profile/proof ingressと初期provisioning | accounted-for | designed | planned |
| DO-CFG-082 | AC-CFG-010 | JG-CFG-RUNTIME-KNOWN-FAILURE | partial | SD-RUL-RBI-009, SD-RUL-RBI-010, SD-EVT-RBI-008, SD-EVT-RBI-009, SD-EFX-RBI-008, SD-PER-RBI-005, SD-PER-RBI-006, SD-PER-RBI-003, SD-TRN-CFG-003, SD-EVT-CFG-004, SD-RUL-RCP-003, SD-TRN-RCP-003 | pure/contract/concurrency/crash-recovery | M applied/P known-negativeで即時use/slot lease解放して外部runtimeをorphan化、cleanup proofなしRejected、candidate/use/custody/Occurrence/generation lease/slot lease/CFG stepの部分終端、old effective/snapshot変更、OutcomeUnknownをReleased、duplicate再適用、late resultで復活、複数failed candidateがcleanup identity共有 | normal Runtime candidate known-failureとcleanup terminal | accounted-for | designed | planned |
| DO-CFG-083 | AC-CFG-010 | JG-CFG-CANDIDATE-CARDINALITY | partial | SD-MOD-RBI-001, SD-PRF-RBI-001, SD-RUL-RBI-008, SD-EVT-RBI-010, SD-PER-RBI-007, SD-PER-CFG-004, SD-PER-RBI-005, SD-PER-RBI-006, SD-PER-RBI-003, SD-MOD-EXE-001, SD-RUL-EXE-002, SD-TRN-EXE-010 | pure/architecture/concurrency/crash-recovery | valid Profile後のfirst admission不能、missing/Superseded/Blocked/mismatch Profileからslot自動生成、同じAbsent keyの並行生成で二holder、replayでslot再作成、QuarantinedをAbsent扱い、cleanup/Recovery/StagedReady中の二重candidate、slot/generation/RCP use/Graph/lease部分admission、M/P/K/Q/Rのslot lease欠落、admission/terminal/profile-supersede race、証明なしmulti-candidate | Capability candidate slot lazy creation/cardinality/resource isolation | accounted-for | designed | planned |

## Failure、Recovery、非目標

書込、restart、migration、retirementの不明結果は自動再送せずRecoveryへ渡します。
active workのpinned revisionを遡及変更しません。KernelへCapabilityやProviderの分岐を置かず、
Capability全体を所有する万能Context、journal replay、暗黙fallbackも作りません。

## Recovery fixture

| Fixture | Expected result |
| --- | --- |
| ApplyStep S1のOutcomeUnknownをQ/RがDefinitelyAppliedと確認 | S1だけApplied、dependency成立時だけ`next_stage=S2`、S2だけReady。planはCompletedにしない |
| S1 Recovery終端後にS2がOutcomeUnknown | S1とS2は別stage-scoped generation/custody/keyを持ち、S2のQ/X/Rを独立に一回登録 |
| S2の同OutcomeUnknownをduplicate取込 | 同じbranch keyを返し、新generation/custody/Q/X/Rを作らない |
| 通常またはRecovery結果をstageへ適用 | result/resolution ledger記録後に`SD-TRN-MIG-004`を正確に一回だけ適用 |
| ApplyStep S2の結果をS1待ちで受信 | out-of-orderとして隔離し、S1/S2/next_stageを変更しない |
| VerifyTarget以外のDefinitelyApplied | exact stageをAppliedへ進めるだけでCompletedを拒否 |
| Restore以外の結果にrestore evidenceを付与 | Restoredを拒否し、variant conflictとして隔離 |
| restart Query branchでQ未終端 | Zをreadyにしない。cancel branchではQとX双方のterminal owner factまでZをreadyにしない |
| handoffにAwaitOwnerDecision sessionが存在 | handoffとsessionをRecoveringに維持し、Released/Homeを拒否 |
| RestartAdapter groupのAだけProbe Ready、BはFailure | AをStagedReadyに維持し、A/B旧generationとCFG effective snapshotを変更しない |
| A/B両candidateがStagedReady | activation時freshnessと全Owner revisionを再検証し、A/B Effective化、両旧generation Retiring化、CFG snapshotを一つのcommitで切り替える |
| Aのreadinessがactivation直前にstale | atomic activationを拒否し、再ProbeまでcandidateをStagedReady、旧generationをEffectiveに維持 |
| 旧generationのUseがactivation時点で0 | activationと同じcommitでAllBindingUsesReleased、Guard Fact、deterministic retirement Graphを一度だけ登録する |
| activationと最後のUse解放が競合 | runtime/EXE CASと同じgeneration-derived identityにより一方だけ登録し、敗者は同値replayする |
| singleton local-managed ProfileがRequiresGlobalRestart | RestartAdapter planをUnsupportedApplyModeとして拒否し、Ownerが明示したRestartRuntime以外へ進めない |
| candidate profile revisionがmissing/Superseded/Blocked | generation/Graph登録、staging、activationを拒否し、old effectiveを維持する |
| BindingGeneration登録またはRetired/Rejected/Quarantined終端中にcrash | generationとRCP RevisionUseを同じUoWで取得/解放し、片側だけを残さない |
| 初回setupで検証済みrelease seedを適用 | 全ProfileをBlockedで登録し、evidence付きentryだけPassingへ昇格し、seed/operation ledgerと同一commitで確定する |
| 同じseed artifact/operation/idempotency/payloadを再送 | 既存commit結果を返し、Profile revision、proof evidence、ledgerを増やさない |
| 同じseedまたはadmin idempotency identityへ異digest | Conflictとして拒否し、既存Profile/proofを変更しない |
| seed適用中またはadmin proof昇格中にcrash | Profileだけ、Passingだけ、seed/operation ledgerだけの部分状態を残さずSnapshotから再開する |
| Web/API、Skill、runtime AdapterがRCP登録またはPassingを要求 | UnauthorizedIngressとして拒否し、Linux管理者CLIまたはtrusted seed以外を通さない |
| local adminがProfileを追加後、別Commandで証拠を提出 | 認証済み同一host/scopeとexact revision/evidenceを検証し、Blocked登録とPassing昇格を別commitとして監査する |
| MがDefinitelyNotAppliedの確定Failure | candidate Rejected、P/deadline revoke、全normal lease解放、RCP use Released(Rejected)、exact CFG step Failedを同一commitにし、old effective/snapshotを維持する |
| M DefinitelyApplied後のPがAuthenticationFailed、cleanup required | exact CFG stepをFailedにしてold effective/snapshotを維持し、candidateをRejectingCleanup、RCP useをAcquiredのまま、決定論的cleanup Graph/K/custody/leaseを同一commitで登録する |
| cleanup KがCleaned/DefinitelyApplied | candidate Rejected、RCP use Released(Rejected)、K/custody/lease Releasedを同一commitにする |
| cleanup KがNoArtifact/DefinitelyNotApplied | immutable profileのno-artifact requirementとexact result proofが成立するときだけRejected/Releasedへ進め、証拠欠損はRecoveryへ渡す |
| cleanup KがOutcomeUnknown | candidateをRejectingCleanup.Recovery、RCP useをAcquired、cleanup custody/leaseを保持し、一回限りのQ/Rを登録する |
| cleanup Q/R後もStillUnknown | candidate/custody/leaseをQuarantined、RCP useをReleased(Quarantined)へ同一commitで終端する |
| immutable profile/resultがcleanup不要を証明 | M applied/P known-negativeでも即時Rejectedを許可するが、P failureだけをno-artifact proofにしない |
| known failure/cleanup終端中にcrashまたは同一result duplicate | 各branchの全変更を一つのresolution/cleanup identityから再開／replayし、部分終端や二重releaseを残さない |
| Rejected/Quarantined後にM/P/K/deadline late result | exact terminal generation/cleanup inboxへ隔離し、candidate/use/CFG step/old effectiveを変更しない |
| generation G1/G2が連続してP known-negative | 各generation固有のcleanup Graph/operation/custodyを作り、G1結果でG2を終端せず、cleanup identityを共有しない |
| G1がStagedReadyまたはRejectingCleanup Planned/InFlight/Recovery | G2 admissionをtyped CandidateSlotBusyで拒否し、G2 generation/Graph/RCP use/slot leaseを一件も作らない |
| G1がsafe RejectedとなりRCP use/NamedInterval slot lease解放済み | slotをFreeへ進めた同一terminal commit後の明示G2 admissionだけを受理する |
| G1 cleanup RecoveryがStillUnknownでQuarantined | slotとNamedInterval leaseもQuarantinedとし、明示Owner recovery/replacement PolicyなしのG2をCandidateSlotQuarantinedで拒否する |
| G1 cleanup terminalとG2 admissionが同時にslot CAS | 一方だけが勝ち、terminal先行なら再評価後G2 admission可、Busy記録先行ならterminal後の別retryまでG2を作らない |
| G1 activationでEffectiveへ進む | activationと同じcommitでcandidate slotをFree、NamedInterval slot leaseをReleasedとし、CFGだけ切替またはslotだけ解放を残さない |
| ProfileがProvenMultiCandidateを宣言する | 初期releaseはcapacity 1のまま。将来はversion付きcardinality/resource-isolation proofとOwner採用、slot/resource契約更新なしに複数candidateを許可しない |
| release seed適用後、valid current Passing Profileのslot keyが未登録でfirst admission | Capability runtime ownerが決定論的slot identityを導出し、compare-not-exists CASでslot revision 0 Held、generation、RCP use、Graph、NamedInterval leaseを一つのcommitにする |
| 認証済みLinux管理者CLIが新しいkeyのProfileを登録・Passing昇格後にfirst admission | CLI UoWはslotを作らず、first admissionだけがexact Profile/keyを再検証してslot revision 0を原子生成する |
| 異なるadmission identityが同じAbsent slotへ同時到着 | compare-not-exists CASの一方だけがslot revision 0とcandidateを作り、敗者は再評価後typed CandidateSlotBusyとなり二holderを作らない |
| Absent branch成功後に同じadmission identity/payloadを再送 | admission resultを同値replayし、slot lookupやcompare-not-existsを再実行せずslot/generation/Graph/use/leaseを増やさない。異payloadはConflictとする |
| profile supersedeとAbsent slot first admissionが競合 | RCP current mappingを含むCASで一方だけが勝つ。supersede先行ならProfileNotReadyでslotを作らず、admission先行ならRevisionUseが旧revisionを保持する |
| Quarantined slot entryが存在するkeyへadmission | entryをAbsentと扱わずCandidateSlotQuarantinedで拒否し、slot revision 0の再作成や既存entry上書きを行わない |
| restart epoch E1 resume後にepoch E2で再restart | E2はreplacement subject generationだけをtargetにし、E1 late resultをE1 handoffへ隔離する |
