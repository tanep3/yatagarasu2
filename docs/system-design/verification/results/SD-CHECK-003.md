# SD-CHECK-003 — Pilot C設計整合検査

## 対象

- 要件基準commit: `4df6fb1`
- 設計変更集合: [SD-REV-PILOT-C-001](../change-sets/SD-REV-PILOT-C-001.md)
- 設計対象: Pilot C（設定更新・Capability binding・routing・restart・migration）
- 検査日: 2026-08-13

## 再現command

```text
docs/system-design/verification/check-system-design.sh
docs/system-design/verification/check-design-approvals.sh
docs/system-design/verification/check-design-pilot-gate.sh
docs/system-design/verification/check-ac-expansion.sh
git diff --check
```

## 結果

```text
PASS(structural-index) REQ=62 AC=214 canonical=519 states=30 stateOwners=30 parentAC=128 obligations=184 revision=sha256:748a0f741e82cb004a3d92f8ec48181d7bb3fcaf1f1961920a291ccde859f482
PASS(design-approvals) sets=1 definitions=519 require_all=false
PASS(design-pilot-gate) approval_set=APR-PILOT-ABC-EE8F532A definitions=sha256:89c749815303b3aa6ca9e2bcf914dc36fa411c27fbb18f057ab84fb3cfea1fd9 obligations=184
PASS(ac-expansion) requirements=62 ac=214 packages=8 obligations=184 tranches=1 covered=0
git diff --check: PASS
change-set exact canonical Design ID coverage: PASS (519/519)
verification revision: sha256:fe928cef2252fa3c21c8fafea40c3806294af703ad60059f62ebd2e3de8cdc9d
```

このPASSは、canonical Design IDの単一定義、State owner索引、正式Transition参照、
parent ACとAtomic Design Obligation、相対link、差分形式の機械整合だけを示します。
Stateの意味的な独立性、GraphとRecoveryの完全性、Atomic Design Obligationの十分性は証明しません。
production code、外部runtime、実機、測定値の成立を証明するものではありません。

## Architecture reviewとGate

- reviewed content commit: `1eafd3deab687e29c3d81609ae0959823e246165`
- reviewed content revision: `sha256:f0c85ec41234afc5399ba4e6d1ce464b1ae4bca30050a2f240ca5ec09ef60705`
- independent architecture challenger: PASS（Critical 0／High 0）
- Primary／Owner approval: 2026-08-13「レビュー通過、問題なし、先へ」
- accepted canonical Design ID: 519/519
- accepted canonical definition non-drift: 519/519 ID/version/ref/hash
- approval aggregation: `APR-PILOT-ABC-EE8F532A` immutable subset
- reviewed definitions: Source commitから519 definitionを再生成し保存payload／currentと一致
- reviewed Pilot obligations: Source commitから184 routing／meaning／proof行を再生成しcurrent non-drift
- accepted tranche scope: package／親AC／obligation／definition exact setをReview／Owner Artifactで固定
- obligation definition closure: 184 DOが参照する401 Design IDはApproval definitions 519件に全包含。余分118件はintegrated/common lawとしてscope固定
- requirements baseline: 62 Requirement／214 ACを`4df6fb1`から本文hash付きで再構成
- expansion mapping: 8 package、214 AC exact-one、184 pilot obligation exact-one、1 accepted pilot tranche
- Pilot A/B/C Design slice: accepted
- Proof: production code未実装のため`planned`または`blocked-by-spike`
- 三本全体のDesign Pilot Gate: PASS
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
このArtifactは、構造検査とDesign Pilot Gateの実行結果です。architecture reviewとPrimary承認の
原本およびhashは[Design Approval Manifest](../design-approval.md)が保持します。Proof=`planned`／
`blocked-by-spike`は実装・実機passingを意味しません。
