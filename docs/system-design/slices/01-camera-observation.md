# Pilot A — TC70の移動・撮影・画像解釈

このsliceは[canonical contract](../contracts/camera-observation.md)を観測可能な因果列へ接続します。型、owner、guardを再定義しません。
Pilot Cで改訂した共通契約は変更集合`SD-REV-PILOT-C-001`として同じrevisionで再審査します。
現在のarchitecture review statusは`pending`です。旧slice PASSはcurrent change-setの承認に使用しません。

## 対象scenario

「右を向いて何が見える？」がroutingとadmissionを通過し、`SD-CMD-CAM-001`になったところから開始します。

```text
Initial snapshot
  device capability ready
  configuration snapshot / Profile candidate / Policy available
  accepted admission candidate, but no Interaction/Qualia/lineage commit yet
  no conflicting resource lease
  reference deviceならvalid Device Test Exclusion lease

Inbound
  SD-CMD-CAM-001

Decision and durable commit
  SD-RUL-CAM-001 -> SD-DEC-CAM-001
  SD-PER-CAM-001 + SD-PER-EXE-007 atomically commit Interaction/Qualia,
    generation 0 lineage, Profile/QPR uses, Artifact reservation, Graph, Occurrences and Pending

Dispatch and results
  SD-TRN-EXE-002 claims attempt/profile/policy/resource durably
  SD-EVT-EXE-001 / SD-EVT-EXE-002
  SD-EVT-PHY-001またはSD-EVT-PHY-002
  SD-EVT-DAT-001
  SD-EVT-ART-002またはSD-EVT-ART-003
  SD-EVT-INF-001

Final snapshot
  SD-STA-PHY-001 keeps evidence and certainty
  SD-STA-ART-001 keeps lifecycle without path
  SD-PRJ-CAM-001 shows result, premise, Failure, Recovery
  temporary Artifact is deleted only after terminal/handoff and no dependents
```

## Atomic Design Obligation

`Parent AC`は一行につき一つです。同じproofを共有する兄弟は`Joint group`で結びます。全行Accounting=`accounted-for`、Design=`designed`です。まだproduction codeがないためProofは原則`planned`、実機証拠が必要なものだけ`blocked-by-spike`です。

| Obligation | Parent AC | Joint group | Parent contribution | Design contracts | Proof | Negative case | Scope | Accounting | Design | Proof status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| DO-CAM-001 | AC-PRD-005 | JG-CAM-E2E | full | SD-EFX-PHY-001, SD-EVT-EXE-001, SD-EVT-PHY-001, SD-EVT-PHY-002, SD-STA-PHY-001 | real-device | start欠落、OutcomeUnknown | TC70必須/C210独立 | accounted-for | designed | blocked-by-spike |
| DO-CAM-002 | AC-PRD-006 | JG-CAM-E2E | full | SD-EFX-CAP-001, SD-EVT-ART-002, SD-EVT-ART-003, SD-RUL-ART-001, SD-EFX-INF-001 | integration/real-device | capture Failure、無効Artifact | TC70必須/C210独立 | accounted-for | designed | blocked-by-spike |
| DO-CAM-003 | AC-PRD-007 | JG-CAM-E2E | full | SD-GPH-CAM-001, SD-POL-PHY-001 | integration/real-device | DefinitelyNotApplied、OutcomeUnknown、Policy deny | TC70必須 | accounted-for | designed | blocked-by-spike |
| DO-CAM-004 | AC-PRD-019 | JG-CAM-E2E | partial | SD-PRF-PHY-001, SD-PRT-PHY-001, SD-POL-DEX-001 | architecture/real-device | C210非ready、Core製品分岐 | 機種別 | accounted-for | designed | blocked-by-spike |
| DO-CAM-005 | AC-EFX-001 | JG-CAM-GRAPH | full | SD-STA-EXE-001, SD-GPH-CAM-001 | pure | 同じ右移動二件 | 共通 | accounted-for | designed | planned |
| DO-CAM-006 | AC-EFX-002 | JG-CAM-GRAPH | full | SD-RUL-EXE-001, SD-GPH-CAM-001 | pure | node生成順を逆転 | 共通 | accounted-for | designed | planned |
| DO-CAM-007 | AC-EFX-003 | JG-CAM-TIME | full | SD-EVT-EXE-001, SD-EFX-TIM-001, SD-RUL-PHY-001 | pure/contract | queue時間、Started欠落 | 共通 | accounted-for | designed | planned |
| DO-CAM-008 | AC-EFX-004 | JG-CAM-RECOVERY | partial | SD-STA-EXE-001, SD-TRN-EXE-002, SD-REC-PHY-001 | crash-recovery | Effect再開とrestart同時発生。API request重送はPilot外 | 共通 | accounted-for | designed | planned |
| DO-CAM-009 | AC-EFX-005 | JG-CAM-GRAPH | full | SD-GPH-CAM-001 | pure | Effect重複排除 | 共通 | accounted-for | designed | planned |
| DO-CAM-010 | AC-PHY-001 | JG-CAM-PHYSICAL | full | SD-STA-PHY-001, SD-EVT-PHY-001, SD-EVT-PHY-002 | pure/contract | Assumed→Observed自動昇格 | 共通 | accounted-for | designed | planned |
| DO-CAM-011 | AC-PHY-002 | JG-CAM-RECOVERY | full | SD-POL-REC-001, SD-REC-PHY-001 | crash-recovery | restart後OutcomeUnknown再送 | 共通 | accounted-for | designed | planned |
| DO-CAM-012 | AC-PHY-003 | JG-CAM-TIME | full | SD-EFX-TIM-001, SD-PRT-TIM-001, SD-RUL-PHY-001 | pure/contract | duration前ready | 共通 | accounted-for | designed | planned |
| DO-CAM-013 | AC-PHY-004 | JG-CAM-TIME | full | SD-EVT-PHY-002, SD-STA-PHY-001 | pure | elapsedからObserved生成 | 共通 | accounted-for | designed | planned |
| DO-CAM-014 | AC-PHY-005 | JG-CAM-TIME | full | SD-EVT-EXE-001, SD-EFX-TIM-001 | pure | queue滞留をdurationへ算入 | 共通 | accounted-for | designed | planned |
| DO-CAM-015 | AC-PHY-006 | JG-CAM-TIME | full | SD-EVT-EXE-001, SD-RUL-PHY-001 | pure | StartedなしAssumed | 共通 | accounted-for | designed | planned |
| DO-CAM-016 | AC-PHY-007 | JG-CAM-PHYSICAL | full | SD-CMD-CAM-001, SD-STA-PHY-001 | architecture/pure | absolute pose注入 | 共通 | accounted-for | designed | planned |
| DO-CAM-017 | AC-PHY-009 | JG-CAM-PHYSICAL | full | SD-POL-PHY-001, SD-RUL-EXE-001 | pure | Policy欠落 | 共通 | accounted-for | designed | planned |
| DO-CAM-018 | AC-PER-001 | JG-CAM-GRAPH | full | SD-RUL-EXE-001, SD-GPH-CAM-001 | pure | dependency不足 | 共通 | accounted-for | designed | planned |
| DO-CAM-019 | AC-PER-002 | JG-CAM-GRAPH | full | SD-STA-EXE-001, SD-RUL-EXE-002, SD-TRN-EXE-002, SD-MOD-EXE-001 | concurrency | 二dispatcher競合 | 共通 | accounted-for | designed | planned |
| DO-CAM-020 | AC-ARC-001 | JG-CAM-ARCH | partial | SD-RUL-CAM-001, SD-RUL-EXE-001, SD-RUL-PHY-001, SD-RUL-DAT-001, SD-RUL-ART-001, SD-RUL-ART-002, SD-RUL-REC-001, SD-RUL-DEX-001 | pure | Rule内Port call | 共通 | accounted-for | designed | planned |
| DO-CAM-021 | AC-ARC-003 | JG-CAM-OWNER | partial | SD-CTX-EXE-001, SD-CTX-PHY-001, SD-CTX-ART-001, SD-CTX-DAT-001, SD-CTX-PAP-001, SD-CTX-DEX-001 | architecture | owner重複/未登録 | 共通 | accounted-for | designed | planned |
| DO-CAM-022 | AC-ARC-004 | JG-CAM-OWNER | partial | SD-PRT-PHY-001, SD-PRT-CAP-001, SD-PRT-INF-001, SD-PRT-ART-001, SD-EVT-EXE-002 | contract/architecture | Adapterからreducer到達 | 共通 | accounted-for | designed | planned |
| DO-CAM-023 | AC-ARC-005 | JG-CAM-ARCH | partial | SD-EFX-PHY-001, SD-EFX-TIM-001, SD-EFX-TIM-002, SD-EFX-CAP-001, SD-EFX-INF-001, SD-EFX-ART-001 | pure | closure/callback Effect | 共通 | accounted-for | designed | planned |
| DO-CAM-024 | AC-ARC-006 | JG-CAM-PHYSICAL | partial | SD-EVT-PHY-001, SD-EVT-PHY-002, SD-EVT-EXE-002 | contract | bool successへ圧縮 | 共通 | accounted-for | designed | planned |
| DO-CAM-025 | AC-ARC-012 | JG-CAM-PROFILE | partial | SD-CTX-DPF-001, SD-TRN-DPF-003, SD-PRF-PHY-001 | pure | plan後Profile変更 | 共通 | accounted-for | designed | planned |
| DO-CAM-026 | AC-ARC-017 | JG-CAM-OWNER | partial | SD-STA-EXE-001, SD-STA-PHY-001, SD-STA-ART-001, SD-STA-DAT-001, SD-STA-PAP-001, SD-STA-DEX-001 | architecture | 非owner reducer到達 | 共通 | accounted-for | designed | planned |
| DO-CAM-027 | AC-OPS-002 | JG-CAM-PERSIST | partial | SD-PER-EXE-001 | crash-recovery | snapshot restart差分 | 共通 | accounted-for | designed | planned |
| DO-CAM-028 | AC-OPS-003 | JG-CAM-PERSIST | partial | SD-PER-EXE-001 | architecture | journal replay dispatch | 共通 | accounted-for | designed | planned |
| DO-CAM-029 | AC-OPS-004 | JG-CAM-PERSIST | partial | SD-TRN-EXE-001, SD-TRN-ART-001, SD-PER-CAM-001 | crash-recovery | 任意CAS競合、commit後dispatch前crash | 共通 | accounted-for | designed | planned |
| DO-CAM-030 | AC-OPS-005 | JG-CAM-DISPATCH | partial | SD-RUL-EXE-002, SD-TRN-EXE-002, SD-MOD-EXE-001, SD-PER-EXE-001 | concurrency/contract | pendingなしdispatch | 共通 | accounted-for | designed | planned |
| DO-CAM-031 | AC-OPS-006 | JG-CAM-DISPATCH | partial | SD-TRN-EXE-002, SD-PER-EXE-002, SD-REC-PHY-001, SD-REC-ART-001, SD-REC-DEX-001 | crash-recovery | 全Effect classのintent/result crash | 共通 | accounted-for | designed | planned |
| DO-CAM-032 | AC-OPS-012 | JG-CAM-CANCEL | full | SD-TRN-EXE-004 | crash-recovery | revoke後restart | 共通 | accounted-for | designed | planned |
| DO-CAM-033 | AC-OPS-013 | JG-CAM-CANCEL | full | SD-CMD-INT-001, SD-EVT-INT-001, SD-TRN-EXE-004 | crash-recovery | dispatch済みmove cancel | 共通 | accounted-for | designed | planned |
| DO-CAM-034 | AC-OPS-024 | JG-CAM-RECOVERY | partial | SD-REC-PHY-001, SD-REC-ART-001, SD-REC-DEX-001 | crash-recovery | unsafe auto-resume | 共通 | accounted-for | designed | planned |
| DO-CAM-035 | AC-OPS-025 | JG-CAM-RECOVERY | partial | SD-TRN-EXE-003, SD-TRN-PHY-001 | crash-recovery | Camera occurrenceへのlate result。Qualia／Interaction全体はPilot外 | 共通 | accounted-for | designed | planned |
| DO-CAM-036 | AC-OPS-026 | JG-CAM-RECOVERY | full | SD-STA-PHY-001, SD-POL-REC-001 | pure | cooldown→Observed pose | 共通 | accounted-for | designed | planned |
| DO-CAM-037A | AC-OPS-028 | JG-CAM-EXCLUSION | full | SD-CTX-DEX-001, SD-STA-DEX-001, SD-RUL-DEX-001, SD-EFX-DEX-001, SD-PRT-DEX-001 | real-device | handle/session未解放、排他証拠欠落 | TC70 | accounted-for | designed | blocked-by-spike |
| DO-CAM-037B | AC-OPS-028 | JG-CAM-EXCLUSION | full | SD-STA-DEX-001, SD-POL-DEX-001, SD-TRN-DEX-001 | real-device | window expiry、abort、send race | TC70 | accounted-for | designed | blocked-by-spike |
| DO-CAM-037C | AC-OPS-028 | JG-CAM-EXCLUSION | full | SD-EFX-DEX-001, SD-EVT-DEX-001, SD-REC-DEX-001 | real-device | Y1復帰/機能確認失敗 | TC70 | accounted-for | designed | blocked-by-spike |
| DO-CAM-037D | AC-OPS-028 | JG-CAM-EXCLUSION | full | SD-POL-DEX-001, SD-MOD-CAM-001 | architecture/real-device | Y1 repository/runtime/config/dataへのwrite | TC70 | accounted-for | designed | blocked-by-spike |
| DO-CAM-038 | AC-DAT-001 | JG-CAM-DATA | partial | SD-CTX-DAT-001, SD-RUL-DAT-001, SD-POL-DAT-001 | pure | 一分類のみ許可 | 共通 | accounted-for | designed | planned |
| DO-CAM-039 | AC-DAT-002 | JG-CAM-CLEANUP | partial | SD-CMD-ART-001, SD-RUL-ART-002, SD-EVT-ART-004 | pure/integration | revoked authorization、削除済み再公開 | 共通 | accounted-for | designed | planned |
| DO-CAM-040 | AC-DAT-003 | JG-CAM-DATA | full | SD-STA-ART-001, SD-PRT-ART-001, SD-PRJ-CAM-001 | architecture | path/locator露出 | 共通 | accounted-for | designed | planned |
| DO-CAM-041 | AC-DAT-004 | JG-CAM-CLEANUP | full | SD-CMD-ART-001, SD-EFX-ART-001, SD-EVT-ART-004, SD-TRN-ART-002 | integration | EventなしDeleted | 共通 | accounted-for | designed | planned |
| DO-CAM-042 | AC-DAT-005 | JG-CAM-CLEANUP | partial | SD-RUL-ART-002, SD-REC-ART-001 | crash-recovery | dependent/hold中削除、orphan | temp capture | accounted-for | designed | planned |
| DO-CAM-043 | AC-DAT-006 | JG-CAM-DATA | partial | SD-RUL-DAT-001, SD-EVT-DAT-001, SD-TRN-EXE-002 | pure | Unknown、空、過少分類 | 共通 | accounted-for | designed | planned |
| DO-CAM-044 | AC-DAT-007 | JG-CAM-OWNER | partial | SD-CTX-DAT-001, SD-STA-DAT-001, SD-TRN-DAT-001 | architecture | Artifact/Adapterが分類変更 | 共通 | accounted-for | designed | planned |
| DO-CAM-045 | AC-OUT-004 | JG-CAM-OUTPUT | partial | SD-RUL-ART-001, SD-EVT-INF-001 | pure/integration | Viewのevidence/Artifact欠落、purpose変換。RecallはPilot外 | 共通 | accounted-for | designed | planned |
| DO-CAM-046 | AC-FR-003 | JG-CAM-PROJECTION | partial | SD-PRJ-CAM-001 | projection | lifecycle欠落 | 共通 | accounted-for | designed | planned |
| DO-CAM-047 | AC-FR-004 | JG-CAM-PROJECTION | partial | SD-FAIL-CAM-001, SD-PRJ-CAM-001 | projection | raw exception表示 | 共通 | accounted-for | designed | planned |
| DO-CAM-048 | AC-NFR-001 | JG-CAM-MEASURE | partial | SD-EVT-ING-001, SD-PRJ-CAM-001 | measurement | 区間相関欠落 | 実機Profile | accounted-for | designed | blocked-by-spike |
| DO-CAM-049 | AC-NFR-003 | JG-CAM-MEASURE | partial | SD-PRJ-CAM-001 | measurement | 欠測理由なし | 実機Profile | accounted-for | designed | blocked-by-spike |
| DO-CAM-050 | AC-PER-001 | JG-CAM-GUARD | partial | SD-EVT-EXE-004, SD-TRN-EXE-009, SD-GPH-CAM-001 | pure/integration | 未宣言factをguardに使う、producer自身の結果で自分をready化、DeclarationとRecordに別lifecycleを持つ | 共通Guard Fact | accounted-for | designed | planned |
| DO-CAM-051 | AC-OPS-024 | JG-CAM-RECOVERY-CUSTODY | partial | SD-EVT-EXE-005, SD-RUL-EXE-003, SD-TRN-EXE-010, SD-TRN-EXE-011, SD-TRN-EXE-012, SD-PER-EXE-004, SD-PER-EXE-005, SD-REC-PHY-001 | concurrency/crash-recovery | custody移管/出口の部分commit、旧exclusive leaseでRecovery自己阻害、StillUnknownでrelease、Quarantined資源を通常再利用 | 物理資源Recovery | accounted-for | designed | planned |
| DO-CAM-052 | AC-ARC-012 | JG-CAM-PROFILE-USE | partial | SD-PER-DPF-001, SD-TRN-DPF-003, SD-TRN-QPR-001 | concurrency/crash-recovery | Profile/QPR useの片側だけ取得・解放、retired revisionを無参照と誤認 | Camera Profile/QPR | accounted-for | designed | planned |
| DO-CAM-053 | AC-OPS-004 | JG-CAM-INITIAL-LINEAGE | partial | SD-PER-CFG-005, SD-EVT-EXE-008, SD-RUL-EXE-006, SD-TRN-EXE-015, SD-PER-EXE-007, SD-PER-CAM-001 | concurrency/crash-recovery | CFG useだけ、BRP/IRP useだけ、INT/QLIだけ、lineage/Graphだけの部分commit、generation 1で初期化、同一admissionの二Graph、同じidentityの異payload再送 | Camera initial admission/Graph | accounted-for | designed | planned |

## Failure、取消、Recovery scenario

| Scenario | Expected result |
| --- | --- |
| 二dispatcherが同じpendingをclaim | 同じState revisionに対して一方だけcommitし、他方はDispatchConflict |
| dispatch intent後、Started前にcrash | 送信有無を推測せずOutcomeUnknown。物理Effectを自動再送しない |
| Startedなしでdeadline | OutcomeUnknown、子孫revoke、Recovery。Assumedを作らない |
| settle中Cancel | 未dispatch子孫をdurable revoke。move停止を主張しない |
| Assumed後にblocking evidence到着 | evidenceを追記し、既dispatch仕事を未実行にせずPremiseInvalidated/Recoveryを新revisionで示す |
| capture Failure/分類deny | ArtifactAvailableとInference Effectを作らない |
| temporary Artifact cleanup | terminal/handoff、dependentなし、holdなしでだけDelete Effectを作る |
| delete OutcomeUnknown | DeletedとせずRecoveryへ渡し、自動再送しない |
| reference device window expiry | 新規dispatch停止、Y2解放、cleanup、legacy復帰確認。失敗はquarantine |
| clock epoch変更 | monotonic tickを比較せずTimingAnchorInvalidated/OutcomeUnknown |

## Proof design

- pure: ready/guard、settle、evidence precedence、classification union/all-of、cleanup条件。
- concurrency: 二dispatcher、複数Graphのvisual-frame lease。
- architecture: owner重複、非owner reducer到達、Domain製品名/vendor schema/path漏洩。
- contract: 六Portの全成功／Failure／OutcomeUnknownと相関不一致。
- crash-recovery: plan commit、claim、intent、send、Started、result、cancel、delete、test leaseの各窓。
- real-device: Y1排他障壁を通したTC70と独立C210 Profile。
- measurement: dispatch、Started、settle、capture、Agent request/responseを同一Interactionで記録。

## Change impact

- TC70→C210: Profile、Adapter、Bootstrap、実機contract testだけを変更候補とする。
- settle値変更: 新Profile versionだけ。active attemptへ遡及しない。
- 画像Provider変更: route bindingとinference Adapterだけ。motion/capture法則を変えない。
- storage変更: ArtifactContent Adapterだけ。logical ID/lifecycle/cleanup法則を変えない。
