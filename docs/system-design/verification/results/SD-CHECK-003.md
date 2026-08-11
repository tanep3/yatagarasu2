# SD-CHECK-003 — Pilot C設計整合検査

## 対象

- 要件基準commit: `4df6fb1`
- 設計変更集合: [SD-REV-PILOT-C-001](../change-sets/SD-REV-PILOT-C-001.md)
- 設計対象: Pilot C（設定更新・Capability binding・routing・restart・migration）
- 検査日: 2026-08-11

## 再現command

```text
docs/system-design/verification/check-system-design.sh
git diff --check
```

## 結果

```text
PASS(structural-index) REQ=62 AC=214 canonical=519 states=30 stateOwners=30 parentAC=128 obligations=184 revision=sha256:f0c85ec41234afc5399ba4e6d1ce464b1ae4bca30050a2f240ca5ec09ef60705
git diff --check: PASS
change-set exact canonical Design ID coverage: PASS (519/519)
verification revision: sha256:617f6a338fba5b3a71a9a11dee6eade42204e57454df947e7f6d2904ac87681a
```

このPASSは、canonical Design IDの単一定義、State owner索引、正式Transition参照、
parent ACとAtomic Design Obligation、相対link、差分形式の機械整合だけを示します。
Stateの意味的な独立性、GraphとRecoveryの完全性、Atomic Design Obligationの十分性は証明しません。
production code、外部runtime、実機、測定値の成立を証明するものではありません。

## Architecture reviewとGate

- Pilot C architecture review: 再審査待ち
- Pilot C Design slice: 改訂済み・未承認
- Proof: production code未実装のため`planned`または`blocked-by-spike`
- 三本全体のDesign Pilot Gate: 保留
- Implementation / Evidence Gate: 未評価

管理操作のExecution correlation、Guard Fact lifecycle、設定保存、revision use、runtime readiness、
restart／migrationのGraphとOutcomeUnknown recoveryを変更集合`SD-REV-PILOT-C-001`へ反映しました。
第七回closureでは、Execution lineage／resume claim mutator、同一有限Qualiaの複数safe checkpoint、
restart epoch、Runtime candidate staging、CFG cross-owner atomic activationを追加し、Resume直送と
RestartAdapter部分activationを機械検査の拒否対象にしました。
第八回closureでは、generation 0の初期lineage/Graph admission、resume claim恒久拒否の
Behavior owner terminal mapping、zero-use旧generationのactivation同時退役登録、Capability別の
candidate probe共存Profileを追加し、部分admission、永久Active、永久Retiring、未証明の並行起動と
暗黙global restart fallbackを機械検査の拒否対象にしました。
第九回closureでは、CFG/BRP/IRP RevisionUse取得を単独でcommitできない構成部品へ限定し、
有限Interactionの初期UoWへrevision use、INT/QLI/Behavior/EXE generation 0、Graphを原子的に統合しました。
またRuntime Candidate Probe Profile専用Contextを追加し、immutable revision、proof昇格、BindingGeneration単位の
RevisionUse、retention/GCを単一ownerへ集約しました。profile欠落、stale/Superseded/Blocked revision、use欠落、
部分crash状態はgeneration登録、staging、activationのいずれでも拒否します。
第十回closureでは、RCP Profile/proofの正式入口をversion付きrelease/migration seedと認証済みLinux管理者CLIへ限定し、
typed Command、authorization/evidence schema、Event、pure Rule、owner Transition、原子的seed/admin UoWを追加しました。
Web/API runtime approval、Adapter/Skill/LLM自己申告、証拠なしPassing、seed/ledgerの部分適用を拒否します。
またnormal Materialize/Probeの確定Failureとexact CFG step Failedを原子的に扱う境界を追加しました。
第十一回closureでは、M DefinitelyApplied後のP known-negativeを即時Releasedへ進めず、candidateを
RejectingCleanup、RCP RevisionUseをAcquired、CapabilityGenerationをcleanup custody占有として保持し、
決定論的CandidateCleanup Graph/Occurrenceを登録するよう修正しました。M DefinitelyNotAppliedまたは
immutable profile/resultがno artifactを証明する場合だけ即時Rejectedを許可します。cleanup DefinitelyApplied、
またはDefinitelyNotAppliedとno-artifact proofが成立した後だけRejected/Releasedへ進め、OutcomeUnknownは
一回限りのQ/R Recoveryを経てReleasedまたはQuarantinedへ閉じます。old effective generationとCFG effective
snapshotは全branchで維持します。
第十二回closureでは、Capability／mode／Adapter class単位のcandidate slotを追加し、初期cardinalityを1へ
固定しました。candidate generation、RCP RevisionUse、Graph、slot、NamedInterval leaseを原子的にadmitし、
Materialize／Probe／cleanup／Recovery／Quarantine中は後続candidateをtyped BusyまたはQuarantinedで拒否します。
activationまたは安全なRejected終端だけがslotを解放し、cleanup終端と後続admissionの競合は同一revision CASで
一方だけが勝ちます。将来の複数candidateはversion付きcardinality、資源分離proof、Owner採用、契約更新を
必須としました。
第十三回closureでは、valid current Passing Profileに対するfirst admissionがcandidate slotをlazy creationする
境界を確定しました。release seed／管理者CLIはslotを作らず、Capability runtime ownerが決定論的identityと
revision 0のHeld entryをcompare-not-exists CASでgeneration／RCP use／Graph／leaseと同時生成します。
missing／Superseded／Blocked／key mismatch Profileからの生成、Quarantined entryのAbsent扱いを拒否し、
同一Absent keyの並行admission、同値replay、profile supersede競合を機械検査対象にしました。
このArtifactは再審査の入力であり、architecture承認記録ではありません。
