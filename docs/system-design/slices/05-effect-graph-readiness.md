# WP-01 Persistence Graph — Execution Revision 3

このsliceはREQ-PER-001のAC-PER-001〜002を、Yatagarasu 2内部の
[Execution Revision 3](../contracts/execution-revision-3.md)へ接続するreview用縦断索引です。
R3は製品Yatagarasu 3ではありません。accepted V1/V2を変更せず、active V2からlossless migrationする
versioned/superseding contractです。要件基準は`4df6fb1`、依存はaccepted `TR-PILOT-ABC`と
`TR-WP01-ACOU-001`です。

## 1. Problem framing

Effectの意味順序はdependency edgeとclosed guardだけから導きます。resource claimはadmission／同時実行競合だけを
表し、生成順、ID順、queue順、獲得順、fairnessをsemantic orderへ昇格しません。同値Effectも別Occurrenceです。

Rejected candidateはaccepted V1/V2への参照だけで済ませ、shared capacity、claim quantity、multi-claim atomicity、
durable outbox、common deadline、active V2 native Acoustic migrationを一つの実装可能schemaとして閉じていませんでした。
R3はこれらを新しいclosed State/Rule/Transition/UoWへまとめ、旧definitionをin-place変更しません。

## 2. Affected contexts and owners

| State／fact | 唯一owner | 非owner |
| --- | --- | --- |
| R3 Graph/Occurrence/attempt/lease/guard/revocation/custody/inbox/outbox/migration control | SD-CTX-EXE-001 | Kernel、scheduler、dispatcher、Adapter、Projection、Python worker |
| guardを発行する業務結果／Policy判断 | 各Behavior／operationの既存owner | Execution、Adapter |
| capacity profile本文 | pin元ConfigurationまたはCapability Profile owner | Execution、scheduler |
| 外部operation接続／buffer | Adapter operational state | Core WorldState |

V2→R3 activationは同じExecution owner内のschema handoffで、Domain/process境界変更ではありません。activation後の
mutable ownerはR3一つだけです。V2 snapshotはimmutable audit/rollback artifactで、reducerとして再開しません。

## 3. Proposed domain contract

- Commands: 新設なし。result/deadline/candidateをCommandへ昇格しない。
- Events: topology commit、claim commit、deadline result、R3 activationをtyped owner Eventにする。
- Rules: topology、readiness、resource claim、deadline、migrationをsnapshotからpureに決める。
- Transitions: R3 State ownerだけがtopology、claim、result、activationを決定論的に変更する。
- Effects: planned/dispatch値はimmutableで、attempt/generation/stable operation/intentへ固定する。
- Ports: dispatch Effectを受け完全相関result Eventを返すだけで、ready、lease、成功を決めない。
- Projection: V2 inverse viewと診断だけでmutation/dispatch sourceにならない。

### Atomic Design Obligations

| Obligation ID | Parent AC | Joint group | Parent contribution | Canonical Design IDs | Proof type | Negative case | Target profile / scope | Accounting status | Design status | Proof status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| DO-PER-003A | AC-PER-001 | JG-PER-R3-SCHEMA | full | SD-CTX-EXE-001, SD-MOD-EXE-006, SD-MOD-EXE-010, SD-STA-EXE-003, SD-MOD-EXE-008 | architecture/contract | accepted V1/V2 in-place変更、audit injectionとoperational mapを二重mutable正本化、R3を製品世代化 | Execution R3 | accounted-for | designed | planned |
| DO-PER-003B | AC-PER-001 | JG-PER-R3-TOPOLOGY | full | SD-MOD-EXE-008, SD-RUL-EXE-010, SD-TRN-EXE-019, SD-PER-EXE-011, SD-EVT-EXE-012 | pure/crash-recovery | unknown consumer／別Graph edge／未宣言issuer、DependencyTerminal cycle、既存consumer前提の遡及変更、digest encoding差 | initial+extensions topology | accounted-for | designed | planned |
| DO-PER-003C | AC-PER-001 | JG-PER-R3-READY | full | SD-RUL-EXE-011, SD-MOD-EXE-008, SD-STA-EXE-003 | pure | dependency一件不足、Failed／Pending／Revoked／OutcomeUnknown guard、capacity/leaseをsemantic ready input化 | common semantic ready set | accounted-for | designed | planned |
| DO-PER-003D | AC-PER-001 | JG-PER-R3-CYCLE | full | SD-RUL-EXE-010, SD-MOD-EXE-008, SD-FAIL-EXE-002 | pure | self-edge、dependency cycle、producer自身／descendant guard fact | topology validation | accounted-for | designed | planned |
| DO-PER-003E | AC-PER-001 | JG-PER-R3-OCCURRENCE | full | SD-STA-EXE-003, SD-TRN-EXE-021, SD-PER-EXE-013 | pure/concurrency | 同値Effectを一Occurrenceへ畳む、旧attempt／generation resultを現workへ付替え | occurrence/result identity | accounted-for | designed | planned |
| DO-PER-003F | AC-PER-001 | JG-PER-R3-DEADLINE | full | SD-EVT-EXE-014, SD-RUL-EXE-013, SD-TRN-EXE-021, SD-PER-EXE-013 | pure/concurrency/crash-recovery | deadline/target attempt・generation・timer epoch不一致、Elapsedをtarget未適用／停止へ昇格、二winner | common deadline | accounted-for | designed | planned |
| DO-PER-003G | AC-PER-001 | JG-PER-R3-MIGRATION | full | SD-CMD-EXE-002, SD-EVT-EXE-018, SD-MOD-EXE-010, SD-RUL-EXE-014, SD-RUL-EXE-017, SD-RUL-EXE-018, SD-TRN-EXE-022, SD-TRN-EXE-025, SD-PER-EXE-014, SD-EVT-EXE-015, SD-PRJ-EXE-002, SD-PRF-EXE-002, SD-PRF-EXE-004 | architecture/crash-recovery | injection validationだけcommit、operational map/occupancyなしactivation、closed表外edge、RetrySameCut dead-end | atomic active V2→R3 activation | accounted-for | designed | planned |
| DO-PER-003H | AC-PER-001 | JG-PER-REVIEW-CLOSURE | full | SD-MOD-EXE-006, SD-PRF-EXE-002, SD-PRF-EXE-003 | architecture/contract | transitive dependency definition欠落、Pilot partial一件だけでcovered、未accepted／self依存tranche | review integrity | accounted-for | designed | planned |
| DO-PER-004A | AC-PER-002 | JG-PER-R3-RESOURCE-KEY | full | SD-MOD-EXE-007, SD-MOD-EXE-009, SD-STA-EXE-003, SD-RUL-EXE-018, SD-PRF-EXE-004 | pure/contract | V2 active leaseをoccupancy外に置く、同physical identityを異profileで別resource扱い、Adapter自己申告idempotency | physical identity / trusted evidence | accounted-for | designed | planned |
| DO-PER-004B | AC-PER-002 | JG-PER-R3-RESOURCE-ALGEBRA | full | SD-MOD-EXE-007, SD-RUL-EXE-012, SD-RUL-EXE-019, SD-TRN-EXE-026, SD-PER-EXE-017, SD-PRF-EXE-003 | pure/concurrency | named continuation Transitionなし、replayでuse count二重増、holder terminalとrelease別commit、全holder terminal前release | conflict / named interval algebra | accounted-for | designed | planned |
| DO-PER-004C | AC-PER-002 | JG-PER-R3-CLAIM-ATOMICITY | full | SD-RUL-EXE-012, SD-TRN-EXE-020, SD-PER-EXE-012, SD-EVT-EXE-013 | concurrency/crash-recovery | multi-claim subset、same-key二winner、phantom insert、global revisionで非競合claim直列化 | per-resource occupancy CAS | accounted-for | designed | planned |
| DO-PER-004D | AC-PER-002 | JG-PER-R3-DISPATCH | full | SD-MOD-EXE-009, SD-STA-EXE-003, SD-EVT-EXE-013, SD-TRN-EXE-020, SD-TRN-EXE-023, SD-RUL-EXE-012, SD-RUL-EXE-015, SD-PER-EXE-012, SD-PER-EXE-015, SD-PRF-EXE-003 | concurrency/crash-recovery | Attempt/Eventへevidence tuple未保存、capacityのみCASしdispatch profile race見逃し、V2 outbox class再推測 | durable dispatch/evidence | accounted-for | designed | planned |
| DO-PER-004E | AC-PER-002 | JG-PER-R3-RESULT | full | SD-TRN-EXE-021, SD-PER-EXE-013, SD-FAIL-EXE-002 | concurrency/crash-recovery | result_event_id差でduplicateを別winner化、same canonical key異payloadでwinner上書き、lease二重解放 | canonical inbox identity | accounted-for | designed | planned |
| DO-PER-004F | AC-PER-002 | JG-PER-R3-RECOVERY | full | SD-GPH-EXE-001, SD-CMD-EXE-001, SD-EVT-EXE-017, SD-RUL-EXE-016, SD-TRN-EXE-021, SD-TRN-EXE-024, SD-PER-EXE-011, SD-PER-EXE-012, SD-PER-EXE-013, SD-PER-EXE-016, SD-STA-EXE-003 | concurrency/crash-recovery | cancel/query/reconcileをimperative送信、RecoveryPrivilegedをnormal claim/UoW bypass、subset custody | recovery occurrence/custody | accounted-for | designed | planned |
| DO-PER-004G | AC-PER-002 | JG-PER-R3-MIGRATION | full | SD-RUL-EXE-014, SD-RUL-EXE-018, SD-PER-EXE-014, SD-PRF-EXE-002, SD-PRF-EXE-004, SD-PRJ-EXE-002 | architecture/crash-recovery | V2 active lease reservationをoccupancyへ写さずR3 claim許可、empty claimsをnative invariantで拒否、pending work audit-only | V2→R3 operational resource migration | accounted-for | designed | planned |
| DO-PER-004H | AC-PER-002 | JG-PER-TRANCHE-DAG | full | SD-MOD-EXE-006, SD-PRF-EXE-003 | architecture/contract | same-WP依存を過剰package扱い、tranche self/cycle、review-readyが未accepted dependency参照 | expansion checker | accounted-for | designed | planned |

新規canonical definitionは46件です。R3 definitionのdirect dependencyからaccepted dependencyのdirect dependencyまでを
再帰展開した完全closureをcontent-addressed review inputへ固定し、checkerが全source completeness、status、row deletion、self-referenceを検証します。

## 4. Effect Graph

```text
Behavior owner Event
  -> pure R3 topology candidate
  -> atomic initial/extension commit
  -> effective initial+extension topology
  -> pure semantic ready set (dependency + guard + revocation only)
  -> separate all-or-none resource admission CAS
  -> attempt/generation + every lease + immutable Effect + stable intent/outbox
  -> committed intentだけをidempotency class別publish/reconcile/custody
  -> durable normal/deadline result inbox
  -> one terminal winner / custody / quarantine
```

nonconflicting claimは並行可能です。同一resource conflictはkey/profile/quantity algebraとCASだけで一winnerになります。
claim待ちはdependency edgeを生成せず、resource解放後のadmissionもsemantic successorを意味しません。

## 5. Failure and recovery model

cycle、guard issuer mismatch、existing-consumer mutation、invalid quantity、capacity mismatch、partial claim、dispatch/result
identity conflict、deadline/cancel correlation conflict、migration loss/dual ownerを`SD-FAIL-EXE-002`でtypedに拒否します。cancel/deadline/OutcomeUnknownは
外部停止を推測せず、全claim leaseを同じcustodyへ移します。DefinitelyApplied/DefinitelyNotAppliedだけがrelease候補、
StillUnknownはQuarantinedです。

commit前crashは送信0、commit後/publish前crashはsame intentから再開します。publish/ack raceはIdempotentのみexact operation
再送、ReconcileBeforeRepeatはquery後、NonIdempotentはcustodyです。same inbox key/same payloadはno-op、異payloadはquarantineです。

## 6. Implementation boundaries

- Domain: R3 closed values、pure Rules、deterministic Transitions。
- Application: owner/readiness snapshot、CAS UoW、outbox publish/ack、migration barrierを接続するが意味を発明しない。
- Ports/Adapters: immutable Effect/result Event translationのみ。WorldState、ready、leaseを変更しない。
- Bootstrap: storage/dispatcher/timer/Adapterのconcrete bindingだけ。
- Kernel: lawを接続するだけでBehavior/device/conversation/provider固有orderを持たない。

storage engine、transaction API、process/IPC、fairness/priority、capacity数値、timer製品は未決です。

## 7. Testable acceptance criteria

1. 2 parent ACが16 DOへ完全分解され、各DOはexact-one assignment、full/designed/plannedを持つ。
2. accepted V1/V2のdefinition hash/approvalが不変で、46 R3 draft definitionだけが新規review対象である。
3. 全causal edge、consumer/issuer/source/statusがclosedで、cycle/self-causal/unknown ref/既存consumer遡及変更を全体拒否する。
4. 全dependency/guard前はnot-ready。同値Effect二件は別identity。capacity/lease/resource順はsemantic readinessへ影響しない。
5. physical identityとprofile evidenceを分離し、同identity異profileはmismatch、全algebra/named/recovery claimをpure fixtureで証明する。
6. per-key phantom-safe CASでsame-key一winner、非競合parallel、全lease/occupancy/attempt/Effect/intent/outboxは一UoWである。
7. dispatch evidence ref/version/digestをAttempt/Eventへ保存しcapacity evidenceと同CAS、V2 outboxもtrusted evidenceへmappingする。
8. deadline双方のattempt/generation/timer identityが完全相関し、normal/deadline resultが一winner、late/conflictを隔離する。
9. named use-count Ruleが専用Transition/UoWを通り、claim/result composition内でreplay/holder terminal/releaseをCASする。
10. active V2全store/variant/fieldをaudit injectionと一意operational mapへ写し、pending workの二重mutable表現を作らない。
11. activationがinjection validation、operational maps/occupancy/evidence、control/reducerを一CASし、exhaustive migration表外edgeなし。
12. tranche cycle fixtureがstatus/orderで先に落ちずproduction checkerのcycle branchへ到達し、self/unacceptedも拒否する。
13. covered ACの実slice copyをpartial siblingへ変異し、production completion checkerがaccepted non-Pilot full set不足を拒否する。
14. dependency manifestがdraft/accepted全sourceの再帰的canonical reference closure、status、row deletion、self-referenceを検証する。
15. review inputsのhash/WORKTREE再生成一致、obligation→definition closure、`git diff --check`がPASSする。
16. proofはplannedのまま、production/passing/release/FIXを主張しない。FIXは未完了packageを理由にexpected FAILする。

## 8. Open questions and non-goals

新しいOwner判断はありません。Owner決定「Yatagarasu 2内部Execution契約をRevision 3へ正式改訂する」をそのまま採用しました。
capacity数値、fairness、priority、storage、process、timer製品はR3 lawを変えず後続で決められます。

non-goal: accepted/Owner artifact、accepted昇格、V1/V2変更、Yatagarasu 3製品、runtime plugin、Behavior workflow、
public UI、production implementation、実proof、passing、release、system-design FIX、commit。
