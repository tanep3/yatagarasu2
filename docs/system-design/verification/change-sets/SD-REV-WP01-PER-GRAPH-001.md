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
- definition delta: `62 new draft / 0 accepted changed / 601 accepted dependency definitions in complete review closure`
- Owner decision: Yatagarasu 2内部Execution契約をRevision 3へ正式改訂。製品世代変更ではない

## Content-addressed review inputs

| Input | Ref | SHA-256 | Meaning |
| --- | --- | --- | --- |
| Design IDs | `docs/system-design/verification/approvals/SD-REV-WP01-PER-GRAPH-001-design-ids.txt` | `sha256:bca3f6c9bef36a79476c05b252c4a1cad3c3e3ff0a918dfad0abe66bb37c99f7` | 62 R3 draft + complete 601-definition accepted dependency closure |
| Definitions | `docs/system-design/verification/approvals/SD-REV-WP01-PER-GRAPH-001-definitions.tsv` | `sha256:3f2efead185ffd4151771494bf6a9ead4d1304c859b176daefcda239603a9608` | exact versions/refs/meaning hashes |
| Dependency manifest | `docs/system-design/verification/approvals/SD-REV-WP01-PER-GRAPH-001-dependencies.tsv` | `sha256:3a92f0d7f979c1854c28be14aee7bff8720d88b7d49cbf4ae94c664a9a3fc1cd` | every draft/accepted source and recursively closed canonical references |
| Obligation review | `docs/system-design/verification/approvals/SD-REV-WP01-PER-GRAPH-001-obligations.tsv` | `sha256:2c0674806236964b1ed4850413312201356cf851a2c494ba58e9e89ae4225058` | 16 rows / 16 semantic columns |
| Tranche scope | `docs/system-design/verification/approvals/TR-WP01-PER-GRAPH-001-scope.tsv` | `sha256:41ac97754503021dfe7c5289829e745c13a6c9b11f75c979bc34f9594971eed2` | exact WP/AC/DO/663 definitions |

## 1. Problem framing

意味順序をdependency/guardだけに限定しつつ、実装可能なresource algebra、atomic dispatch/outbox、deadline、
OutcomeUnknown custodyをclosed R3 schemaで定義します。Rejected predecessorの曖昧なV1/V2参照closureは採用しません。

## 2. Affected contexts and owners

`SD-CTX-EXE-001`だけがActivate後のR3 Graph、Occurrence、attempt、lease、guard、revocation、custody、inbox/outbox、
preactivationからterminalまでのmigration-attempt coordination record、V2-for-R3 phase/gate/apply authorization/publication fenceを所有します。
accepted V2 Stateはhandoffまでdata/tail/inbox/apply cursor/outboxを所有し、この三責務は重複しません。
capacity本文はpin元Profile owner、業務guard EventはBehavior ownerです。Kernel/scheduler/
dispatcher/Adapter/Projection/Python workerはownerでもmutatorでもありません。V2→R3は同ownerのatomic schema handoffです。

## 3. Proposed domain contract

- canonical: `contracts/execution-revision-3.md`
- slice: `slices/05-effect-graph-readiness.md`
- R3 contract/state/resource algebra/closed topology/delivery/migration/catch-up: `SD-MOD-EXE-006`〜`012`, `SD-STA-EXE-003`〜`005`
- cancel/migration Commands and owner Events: `SD-CMD-EXE-001/002`, `SD-EVT-EXE-012`〜`021`
- pure Rules: `SD-RUL-EXE-010`〜`022`
- recovery Graph: `SD-GPH-EXE-001`
- owner Transitions: `SD-TRN-EXE-019`〜`029`
- UoW: `SD-PER-EXE-011`〜`020`
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
cutでdual owner/downgradeを拒否します。active V2 pause/abortはnew `SD-MOD-EXE-012`/`SD-PER-EXE-019`だけが所有し、accepted V1→V2
pause/abort Decisionを流用しません。cancel/query/reconcileはRecovery Graph Occurrenceとして通常claim/outbox UoWを通ります。
V2 publicationはdurable claim commit後だけsendし、pause/activateとSTA005 revisionで一winner、closed claimだけをR3へhandoffします。
late ack/resultはmaterialized R3 identityへ入り、V2 mutable ownerを復活させません。
claim identityは`(intent,generation)`で、old generationはimmutable、V2Running/AbortedToV2RunningのOpen viewでlatest
DefinitelyNotSentだけを同一法則・same operation/payload/evidenceでgeneration+1へre-armできます。head/generationはSTA005が唯一所有します。

## 6. Implementation boundaries

Domainはclosed values/pure laws、ApplicationはCAS UoW/outbox/migration barrier、Ports/AdaptersはEffect/result translation、
Bootstrapはconcrete bindingだけを担当します。storage/process/IPC/fairness/capacity値/timer製品は未決です。production codeなし。

Checkerはtranche DAG self/cycle/unaccepted dependencyを全lifecycleで拒否し、same-WP accepted semantic dependencyを許可します。
coveredはcontent-addressed accepted non-Pilot full completion setを必須にし、partial sibling bypassを拒否します。dependency
manifestはdependency trancheのaccepted 601件とR3 draft 62件の全source、status、canonical reference closureを検証します。

## 7. Testable acceptance criteria

sliceの23 criteriaを正本とします。特にresource algebra全組合せ、multi-claim/crash/publish race、deadline terminal race、
active V2全record round-trip、initial running claim→DNS→g+1 publish、parallel re-arm、pause race、ack/unknown re-arm拒否、send-status/ack crash、
abort exact-next catch-up/open、activation handoff、tranche DAGとmanifest
row/status mutation fixtures、review hash再生成一致をarchitecture/pure/concurrency/
crash-recovery proofとしてplannedに固定します。passing/implementation/release/FIXは主張しません。

## 8. Open questions and non-goals

新しいOwner判断はありません。capacity数値、fairness/priority、storage/process/timer製品は後続判断です。
accepted/Owner artifact、accepted昇格、V1/V2変更、Yatagarasu 3製品、production、passing proof、release、FIX、commitはnon-goalです。
