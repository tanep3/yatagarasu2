# 全214 AC横展開実施契約

## 1. Problem framing

Design Pilot Gateは、Pilot A/B/Cで確立した設計法則を全214 Acceptance Criteriaへ展開してよいかを判定するGateです。Gate通過は残りACの設計済み、production implementation、実機成立、release-readyを意味しません。

横展開の入力を次に固定します。

- 要件基準: commit `4df6fb1`の62要件・214 AC
- accepted pilot basis: commit `1eafd3deab687e29c3d81609ae0959823e246165`
- reviewed content revision: `sha256:f0c85ec41234afc5399ba4e6d1ce464b1ae4bca30050a2f240ca5ec09ef60705`
- accepted canonical set: `SD-REV-PILOT-C-001`の519 Design ID
- AC入口の唯一の正本: [ac-inventory.md](ac-inventory.md)
- atomic分解規則の唯一の正本: [design-obligations.md](design-obligations.md)
- baseline provenance: [requirements-baseline.tsv](requirements-baseline.tsv)
- machine-readable package mapping: [expansion-packages.tsv](expansion-packages.tsv)と[ac-work-packages.tsv](ac-work-packages.tsv)
- obligation assignment: [obligation-assignments.tsv](obligation-assignments.tsv)
- review tranche ledger: [expansion-tranches.tsv](expansion-tranches.tsv)

目的は、各ACの成功、拒否、Failure、取消、OutcomeUnknown、restart、実機条件を原子的義務へ分解し、State、唯一owner、Rule、Transition、Effect、result Event、Graph、Port、Recovery、Projection、proof designへ接続することです。AC行、obligation行、canonical contractを重複台帳へ複製しません。

## 2. Affected contexts and owners

横展開processはDomain Stateを新しく所有しません。発見したStateはcanonical contractで一つのContextだけへ登録します。

| 対象 | 単一owner／authority | 禁止事項 |
| --- | --- | --- |
| AC入口214行 | `ac-inventory.md` | package別にAC台帳を複製しない |
| atomic obligation schemaとrouting | `design-obligations.md` | canonical payload、owner、guardを再定義しない |
| canonical domain contract | `contracts/*.md`の一anchor | slice、scenario、matrixを第二の定義にしない |
| Design ID lifecycle | `00-design-authority.md` | runtime catalog、登録順routing、mutation permissionに使わない |
| package scopeと進捗 | このArtifactのpackage ID | AC本文またはobligation本文を再掲しない |
| package内のwrite authority | Primary Solがtrancheごとに指名する一名 | 同じcanonical fileへの並行writeを行わない |
| Domain State | canonical `SD-CTX-*`一つ | Adapter、Projection、Python worker、Provider、Kernelをownerにしない |

package ownerは文書変更責任であり、Domain State ownerではありません。processやworkerの配置からContext境界を導きません。Atomic Design Obligationの本文とstatusはsliceのcanonical DO行だけが所有し、assignment TSVは参照関係だけを持ちます。

## 3. Proposed domain contract for expansion

### 一つのACを閉じる条件

各親ACは次を全て満たすまで`covered`にしません。

1. 原文の独立した成功、否定、障害、実機条件がatomic obligationへ分解されている。
2. 各obligationが一つのpackageだけに属し、親ACとsource locatorを保つ。
3. Accounting=`accounted-for`、Design=`designed`である。
4. Proofが`planned`、`implemented`、`passing`、`blocked-by-spike`のいずれかで、proof type、negative case、target scope、blockerを持つ。
5. Design=`blocked-by-spike`／`blocked-by-owner`、Proof=`unplanned`／`blocked-by-owner`がない。
6. canonical contractが必要十分で、既存accepted契約を参照するだけなら新Design IDを作らない。
7. 新規または意味変更したcontractは独立architecture challengeを通り、Critical／Highが0になってから`accepted`になる。

`Proof=blocked-by-spike`は設計法則が確定し実機・外部API・測定証拠だけを待つ状態です。これはpackage設計を止めません。実測がState owner、Domain法則、Port意味を変え得るならDesign=`blocked-by-spike`として停止します。

### Tranche上限

一回のdesign review trancheは、既定で親AC 12件以下かつ新規atomic obligation 30件以下にします。複数Contextのowner変更、accepted public contractの意味変更、Recovery custody変更のいずれかがあるtrancheは、件数にかかわらずその一論点へ縮小します。上限超過時はreviewを始めず、Joint groupまたは依存境界で分割します。

12／30は`check-ac-expansion.sh`内のauthoritative limitです。package／tranche TSVの上限列はこの値の複製ではなく照合対象であり、列だけを書き換えて上限を迂回できません。package依存はDAGでなければならず、accepted package／trancheは全依存が先行行でacceptedになった後にだけacceptedへ進めます。

複数packageに跨るJoint groupはDOを複製せず、`expansion-tranches.tsv`の一trancheへ複数Package IDを明記します。各DOは親ACのpackageへ一意に所属したまま、cross-package dependencyと共同reviewだけをtrancheが表します。既存Pilotは方法確立用の例外trancheとして184 obligationを一括審査したstable provenanceを残し、横展開trancheへこの上限例外を流用しません。

accepted trancheのreviewed revisionとprovenance commitは、指定Approval setのarchitecture-review Artifactに記録されたrevision／Source commitと一致しなければなりません。tranche行の自己申告だけではacceptedになりません。
Review／Owner ArtifactはTranche ID、Package ID、親AC、obligation、definitionのexact setをcontent-addressed scopeとして共有します。別trancheへのApproval set流用は禁止です。package dependencyが同一Joint tranche内で閉じない場合、必要packageを提供するaccepted dependency trancheを過不足なく`Dependencies`へ導出します。
全accepted trancheはPilotと同じ16 semantic columnsのObligation Reviewを持ち、review Source commitとcurrentからの再生成結果が保存hashへ一致しなければなりません。Tranche Scopeは各obligationのmeaning hashも含みます。obligation参照Design IDのApproval set外欠落は拒否し、同じintegrated reviewに含まれる余分definitionsは許容してexact scopeへ固定します。

横展開trancheは`review-pending -> challenge-pending -> owner-pending -> accepted`だけを進みます。`review-pending`はcanonical draft、Obligation Review、definition set、scopeがarchitecture challengeへ渡せる状態であり、review PASSまたはOwner承認を意味しません。全横展開trancheは方法論のaccepted basisとして`TR-PILOT-ABC`を依存に明記します。これはWP package依存を満たしたことには数えず、別WP依存はそのpackageを提供するaccepted横展開trancheで追加します。

`review-pending`以降は、未承認でもDesign IDs、Definitions、Obligation Review、Tranche Scopeの参照とSHA-256をchange-setへ固定します。`check-ac-expansion.sh`はprovenance sourceとcurrent worktreeからdefinitions／obligations／scopeを再生成し、保存artifactとの一致とobligation→definition closureを検証します。これはreview inputの改ざん／drift拒否であり、architecture verdict、Primary／Owner approval、accepted statusを付与しません。accepted後もApproval manifestのID／definition hashとreview source/currentの再生成を同じ検査内で継続します。

### 214 ACの排他的work package

prefix集合は相互排他的で、合計は214です。package artifactを将来作る場合も、AC本文とcanonical定義を複製せず、担当AC ID、tranche、review result、差分参照だけを持たせます。

| Package | AC prefix | AC数 | 依存 | Contract write owner | Review gate | Package完了条件 |
| --- | --- | ---: | --- | --- | --- | --- |
| WP-01 Core laws and ownership | ACOU, ARC, EFX, PER, FUT | 43 | baselineのみ | Primary Sol（委任時もtranche一名） | Gate A + Gate B | owner、inbound、execution、persistenceの共通法則がacceptedで43 ACがcovered |
| WP-02 Product and functional behavior | PRD, FR | 37 | WP-01 | Primary Sol（委任時もtranche一名） | Gate A + Gate B | BehaviorごとのState／Rule／Effect寄与が中央workflowなしで閉じ37 ACがcovered |
| WP-03 Physical and quality evidence | PHY, QPR, NFR | 16 | WP-01, WP-02 | Primary Sol（委任時もtranche一名） | Gate A + Gate B | observation／assumption／resultとprofile proofが分離され16 ACがcovered |
| WP-04 Public boundary, data and network policy | API, DAT, SCP, NET | 34 | WP-01 | Primary Sol（委任時もtranche一名） | Gate A + Gate B | public Command／Projection、classification、network authorizationがtransport非依存で34 ACがcovered |
| WP-05 Conversation and presentation lifecycle | CNV, QLI, SET, OUT | 16 | WP-01, WP-04 | Primary Sol（委任時もtranche一名） | Gate A + Gate B | finite lifecycle、Home、Presentation、setup境界が単一ownerで16 ACがcovered |
| WP-06 Memory, agent, skill and security | MEM, AGT, SKL, SEC | 20 | WP-01, WP-04, WP-05 | Primary Sol（委任時もtranche一名） | Gate A + Gate B | 外部Thread／Memory／Proposal／Tool grantがCore policyを迂回せず20 ACがcovered |
| WP-07 Configuration | CFG | 15 | WP-01, WP-04 | Primary Sol（委任時もtranche一名） | Gate A + Gate B | desired／effective／binding／migrationへの既存Pilot law再利用を確認し15 ACがcovered |
| WP-08 Operations and logging | OPS, LOG | 33 | WP-01〜WP-07 | Primary Sol（委任時もtranche一名） | Gate A + Gate B | startup、recovery、diagnosis、retentionが全Context結果と整合し33 ACがcovered |

`7 + 28 + 5 + 2 + 1 + 20 + 17 + 9 + 4 + 3 + 19 + 7 + 3 + 5 + 4 + 4 + 4 + 6 + 9 + 4 + 1 + 15 + 30 + 3 = 214`を基準にし、package間移動は同じ変更で移動元削除・移動先追加・総数214を検証します。

## 4. Dependency graph and runtime Effect Graph rule

次は設計作業の依存であり、runtime Effect Graphではありません。文書workflowをDomain Effectへ偽装しません。

```text
AC baseline / pilot accepted
  -> WP-01
      -> WP-02 -> WP-03
      -> WP-04 -> WP-05 -> WP-06
               -> WP-07
      -> accepted WP-01..07 -> WP-08
```

各ACのdomain behaviorに外部作用がある場合だけ、canonical contractへEffect Graphを定義します。そのGraphは少なくとも、immutable Effect occurrence、dependency、guard fact、resource claim、cycle拒否、revocation、terminal result Event、OutcomeUnknown custodyを持ちます。外部作用がない範囲検証はpure Rule／Transitionだけで閉じ、装飾的Graphを作りません。

## 5. Failure and recovery model

### Hard stop conditions

次のいずれかを検出したtrancheはstatusを進めず、Primaryへ返します。

- 要件／Accepted ADRの矛盾、または原文を弱めないと分解できない。
- State ownerが二つになる、owner不明、または非ownerからmutation境界へ到達する。
- accepted contractの意味変更を同じVersion／Design IDのまま行う必要がある。
- Design=`blocked-by-owner`、またはState／law／Port意味を変え得るDesign=`blocked-by-spike`が生じる。
- CommandとEvent、Effectとimperative call、result Eventと成功推測を分離できない。
- Failure、cancel、timeout、late result、retry、idempotency、crash recovery、OutcomeUnknownのいずれかが該当するのに未設計である。
- Graph dependency、guard、resource claim、revocation、cycle拒否が該当するのに未設計である。
- Kernel、Main、GatewayへBehavior／device／Provider知識を足す必要がある。
- transport/vendor schema、filesystem path、clock、process配置がCore contractへ漏れる。
- Python worker、Provider、LLM proposal、ProjectionがWorldStateまたはconversation stateを所有する。
- 一ACが複数packageに存在する、入口214件が増減する、source locatorが基準commitと一致しない。
- tranche上限を超える、または未accepted依存へ意味的に依存する。

停止後は例外を追加せず、要件／ADRへのOwner判断、限定spike、package分割、または新Version contractのarchitecture reviewへ戻します。recoveryは「作業を続行したこと」にせず、blocker、影響AC、最後にacceptedなrevision、再開条件をpackage記録へ残します。

## 6. Implementation boundaries

- この横展開はsystem design文書だけを変更し、production code、crate/module配置、process数、IPC、storage engine、transportを固定しません。
- Coreは外部製品名、transport、path、clock、GPU、microphone、camera、Providerを知りません。
- Applicationはdomain contractとabstract Portを使い、Adapterは外部表現をEffect/result Eventへ翻訳します。
- Bootstrapだけが具体Adapterを組み立てます。process境界をDomain境界にしません。
- KernelはRule、Transition、Effect Graphの法則を接続するだけで、Behavior、conversation、device、provider routingを判断しません。
- LLM／Skillのtool callはProposalであり、Core Policyの検証後だけEffectになります。
- Gate C〜F、production test、実機proof、migration deployabilityは、各implementation change-setで別途評価します。

## 7. Testable acceptance criteria

横展開完了時は、少なくとも次を機械または独立reviewで証明します。

1. `ac-inventory.md`が基準commitの214 ACと一対一で、重複・欠落が0。
2. WP-01〜08のprefix和集合が214 ACと一致し、交差が空。
3. 全親ACがAccounting=`accounted-for`、Coverage=`covered`であり、`check-ac-expansion.sh`が各covered ACについてfull contribution、designed obligation、accepted trancheを再構成できる。
4. 全initial-scope obligationがDesign=`designed`でproof designを持つ。
5. Design=`blocked-by-spike`／`blocked-by-owner`、Proof=`unplanned`／`blocked-by-owner`が0。
6. 全canonical Design IDが単一定義・単一anchorを持ち、State ownerが一つ。
7. 全canonical contractが`accepted`で、意味変更はVersion／Supersedesとreview evidenceを持つ。
8. Rule／TransitionのI/O、imperative Effect、Adapter／Projection／workerからのState mutation到達が0。
9. 外部作用を持つ全behaviorがresult EventのFailure／uncertaintyとRecovery custodyを保持する。
10. `check-system-design.sh`、`check-design-approvals.sh --require-all-accepted`、`check-ac-expansion.sh`、`check-system-design-fix.sh`、`git diff --check`がPASSする。
11. 人間向け`system-design-guide.md`がcanonical Design IDだけを参照し、第二の契約を作らない。

Design完了時点でもProof=`planned`／`blocked-by-spike`を`passing`と表示せず、Implementation / Evidence Gateは未評価のままです。

## 8. Open questions and explicit non-goals

### Owner判断

横展開開始に必要な新しいOwner判断はありません。`AC-FUT-001`は将来実装のままですが、共通Inbound境界を守る設計義務としてWP-01で扱えます。TC70の音声Stop採否、Quality Profile数値、実測後のrelease判断は既存のProof／owner-gateであり、横展開Design Gateの判断へ昇格させません。

作業中にhard stop conditionが生じた場合だけ、新しいOwner判断点として、対象AC、選択肢、各選択がowner／law／boundaryへ与える影響を一件ずつ提示します。暗黙の既定値を置きません。

### Non-goals

- 全214 AC本文の今すぐの実装
- production code、実機試験、external API proof、測定値の生成
- Proof=`planned`／`blocked-by-spike`の`passing`昇格
- crate/module/process/IPC/storage/transportの先行固定
- package別AC台帳、Design ID catalog、scenario内canonical payloadの複製
- Kernelを横断workflowまたはintelligent orchestratorにすること
- Yatagarasu 1のproduction環境へ未完成Yatagarasu 2を混ぜること
