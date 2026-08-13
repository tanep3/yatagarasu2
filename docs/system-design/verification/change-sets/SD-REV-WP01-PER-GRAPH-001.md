# SD-REV-WP01-PER-GRAPH-001 — Execution Revision 3 review candidate

Rejected predecessor candidateをOwner決定に従い全面再設計したreview入力です。R3はYatagarasu 2内部Execution
契約のRevision 3で、製品Yatagarasu 3ではありません。accepted V1/V2と過去Approval setは変更しません。

## Candidate identity

- lifecycle: `review-pending`
- tranche/package: `TR-WP01-PER-GRAPH-001` / `WP-01`
- dependencies: `TR-PILOT-ABC,TR-WP01-ACOU-001`（両方accepted）
- baseline/start: `4df6fb1` / `080c4004233f0e8157ebd439dc94342c10a355ef`
- review source/revision: `WORKTREE` / `—`
- architecture review/approval set: `pending` / `—`
- write authority: one WP-01 Persistence Graph owner; overlapping writers prohibited
- parent/obligation limits: `2 / 12`, `16 / 30`
- definition delta: `46 new draft / 0 accepted changed / 601 accepted dependency definitions in complete review closure`
- Owner decision: Yatagarasu 2内部Execution契約をRevision 3へ正式改訂。製品世代変更ではない

## Content-addressed review inputs

| Input | Ref | SHA-256 | Meaning |
| --- | --- | --- | --- |
| Design IDs | `docs/system-design/verification/approvals/SD-REV-WP01-PER-GRAPH-001-design-ids.txt` | `sha256:43bbc76cb662f4e5c42cb74123a7a72357e9b52a4cc5ad4cbcebc1f9c9feb66e` | 46 R3 draft + complete 601-definition accepted dependency closure |
| Definitions | `docs/system-design/verification/approvals/SD-REV-WP01-PER-GRAPH-001-definitions.tsv` | `sha256:fd23218ec8c2e21a8912c35610ac2af319c3a45293c3b10d7ba834860b2b41ac` | exact versions/refs/meaning hashes |
| Dependency manifest | `docs/system-design/verification/approvals/SD-REV-WP01-PER-GRAPH-001-dependencies.tsv` | `sha256:c74f22f325e78601ef4ad9b76797d989a9351e0995d6f4030c2ed7bb422d503e` | every draft/accepted source and recursively closed canonical references |
| Obligation review | `docs/system-design/verification/approvals/SD-REV-WP01-PER-GRAPH-001-obligations.tsv` | `sha256:b0688e4880e4aaf3b791ef41c4d7e3aca0c4516a0d383f17cbc9e9dc00a0c322` | 16 rows / 16 semantic columns |
| Tranche scope | `docs/system-design/verification/approvals/TR-WP01-PER-GRAPH-001-scope.tsv` | `sha256:4b99b415addafa4585bad709b7a2886e957355947eb34fdfb839326fc67ecae0` | exact WP/AC/DO/647 definitions |

## 1. Problem framing

意味順序をdependency/guardだけに限定しつつ、実装可能なresource algebra、atomic dispatch/outbox、deadline、
OutcomeUnknown custodyをclosed R3 schemaで定義します。Rejected predecessorの曖昧なV1/V2参照closureは採用しません。

## 2. Affected contexts and owners

`SD-CTX-EXE-001`だけがR3 Graph、Occurrence、attempt、lease、guard、revocation、custody、inbox/outbox、migration
controlを所有します。capacity本文はpin元Profile owner、業務guard EventはBehavior ownerです。Kernel/scheduler/
dispatcher/Adapter/Projection/Python workerはownerでもmutatorでもありません。V2→R3は同ownerのatomic schema handoffです。

## 3. Proposed domain contract

- canonical: `contracts/execution-revision-3.md`
- slice: `slices/05-effect-graph-readiness.md`
- R3 contract/state/resource algebra/closed topology/delivery/migration control: `SD-MOD-EXE-006`〜`010`, `SD-STA-EXE-003`
- cancel/migration Commands and owner Events: `SD-CMD-EXE-001/002`, `SD-EVT-EXE-012`〜`018`
- pure Rules: `SD-RUL-EXE-010`〜`019`
- recovery Graph: `SD-GPH-EXE-001`
- owner Transitions: `SD-TRN-EXE-019`〜`026`
- UoW: `SD-PER-EXE-011`〜`017`
- compatibility/proof/failure: `SD-PRJ-EXE-002`, `SD-PRF-EXE-002/003`, `SD-FAIL-EXE-002`

physical identityはclass/scopeだけ、profile/versionはpin済みcapacity evidenceです。同identity異profileは別resourceにせず
mismatch、Exclusive×anyは競合、Shared合計はcapacity以下だけ互換です。duplicate拒否、複数claimはall-or-noneです。

## 4. Effect Graph

initial+immutable extensionsからeffective topologyをdigest chainで作り、consumer refs、guard source/issuer/status、
dependency、resource claimsをclosed valueにします。pure semantic readinessはdependency/guard/revocationだけ、resource admissionは
別Ruleです。DependencyTerminalを含むcycle/self-causal/unknown refと既存consumer前提変更はtopology全体rejectです。

claim UoWはattempt/generation、全leases、immutable Effect、stable adapter operation/intent/outbox identity/statusを一度に
commitします。per-resource phantom-safe CASで同key一winner、非競合keyは並行可能です。idempotency classはtrusted versioned
capability evidenceへpinし、publish/ack crashはclass別です。

## 5. Failure and recovery

normal/deadline resultはevent IDを除くcanonical delivery identityでdedupeしterminal winner CASへ参加します。Elapsedはtarget
未適用/停止を意味せず、in-flightなら全claimをcustodyへ移します。same key/same payloadはno-op、異payloadはquarantineです。
StillUnknownは全claim Quarantined、blind retry/partial releaseなしです。

active V2 migrationは全store/field/variantをimmutable audit injectionと一意operational mapへ写し、pending lifecycleの二重正本を
拒否します。active V2 leasesはR3 occupancy/evidenceへmaterializeします。typed pause/candidate/abort/retry/activate controlとsealed
cutでdual owner/downgradeを拒否します。cancel/query/reconcileはRecovery Graph Occurrenceとして通常claim/outbox UoWを通ります。

## 6. Implementation boundaries

Domainはclosed values/pure laws、ApplicationはCAS UoW/outbox/migration barrier、Ports/AdaptersはEffect/result translation、
Bootstrapはconcrete bindingだけを担当します。storage/process/IPC/fairness/capacity値/timer製品は未決です。production codeなし。

Checkerはtranche DAG self/cycle/unaccepted dependencyを全lifecycleで拒否し、same-WP accepted semantic dependencyを許可します。
coveredはcontent-addressed accepted non-Pilot full completion setを必須にし、partial sibling bypassを拒否します。dependency
manifestはdependency trancheのaccepted 601件とR3 draft 46件の全source、status、canonical reference closureを検証します。

## 7. Testable acceptance criteria

sliceの16 criteriaを正本とします。特にresource algebra全組合せ、multi-claim/crash/publish race、deadline terminal race、
active V2全record round-trip、tranche DAGとmanifest row/status mutation fixtures、review hash再生成一致をarchitecture/pure/concurrency/
crash-recovery proofとしてplannedに固定します。passing/implementation/release/FIXは主張しません。

## 8. Open questions and non-goals

新しいOwner判断はありません。capacity数値、fairness/priority、storage/process/timer製品は後続判断です。
accepted/Owner artifact、accepted昇格、V1/V2変更、Yatagarasu 3製品、production、passing proof、release、FIX、commitはnon-goalです。
