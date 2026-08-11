# Design Pilot Gate（設計Pilot Gate）

三本の縦断設計は説明用の作例ではありません。設計方法そのものを検証し、誤った構造を全要件へ複製しないための正式Gateです。

## Pilot A — TC70の移動・撮影・解釈

```text
相対移動要求
-> 実行開始Event
-> settleによるAssumed進行条件
-> 物理結果guard
-> 撮影
-> Artifact有効性guard
-> 推論route
-> 解釈結果
-> Presentation / Projection
```

確認する変動軸:

- TC70からC210または別機種への交換
- settle値と結果確実性の分離
- 同値移動の別Occurrence
- device profileとCore法則の分離
- Failure、DefinitelyNotApplied、OutcomeUnknownで下流を止める構造

この図はruntimeの命令列ではありません。canonical Graph契約が生成する代表的な因果関係です。

## Pilot B — 有限Conversation・Codex Thread・SemanticMemory

確認する変動軸:

- 一Interaction一応答と、Homeを越える外部Threadの分離
- Conversation正本、SemanticMemory、opaque Threadの別所有
- `CodexThread`と`NoExternalContinuity`の切替
- `recent=0`、`semantic=3`のversion付きPolicy
- Thread reset、SemanticMemory delete、compaction、route gap、late result
- Stopによる推論取消と、停止結果を捏造しないRecovery

## Pilot C — 設定更新・Capability binding

確認する変動軸:

- desired／effective／pending設定version
- schema／safety validationと原子的保存
- apply modeと次Interactionからの適用
- Bootstrap bindingとDomain Stateの分離
- health/readiness Observationとroute Policyの分離
- Skill grantをAuthorization Policyへ残すこと
- local-managed／remote／disabledと自動fallback禁止

`Capability Context`という箱を先に作りません。mutable stateと不変条件から所有者を導きます。

## 各sliceの必須成果物

- Atomic Design Obligation
- canonical Design ID参照
- State分類と単一owner
- pure Rule／Transition
- Command、Event、Decision、Effect、結果Eventの区別
- Graph dependency、guard、resource claim、cycle拒否、revocation
- Failure、取消、retry、idempotency、Recovery
- PortとAdapter契約
- Projectionと再同期
- proof design
- [Change Impact Matrix](change-impact-matrix.md)の更新
- revisionを記録した機械検査結果

## このGateが許可すること

Design Pilot Gateは、三本の縦断設計で確立した構造を全214受入条件へ横展開してよいかを
判定します。production code作成、実機動作、releaseを許可するGateではありません。
実装と実証は[Implementation / Evidence Gate](implementation-evidence-gate.md)で別に判定します。

## Gate通過条件

未決事項が存在すること自体はGateを停止しません。未決事項がState所有、Domain法則、外部境界の意味、永続化、Failure、取消、Recovery契約を確定不能にする場合だけGateを停止します。Portの背後へ隔離できる実装方式の選択は、候補と検証計画を記録したうえでGateを妨げません。

三本すべてについて次を満たします。

- 全atomic obligationがcanonical contractとproof designへ接続されている。
- pilotの構造へ影響する全atomic obligationがAccounting=`accounted-for`かつDesign=`designed`である。Design=`blocked-by-spike`または`blocked-by-owner`はGateを止める。要件で正式に初期scope外とされた義務だけをGate対象外にできる。
- 各義務にproof design（証明設計）があり、Proof statusが`planned`、`implemented`、`passing`、`blocked-by-spike`のいずれかである。Proof=`blocked-by-spike`は実機・外部API・測定証拠待ちであり、このGateを止めない。
- Proof=`unplanned`または`blocked-by-owner`はGateを止める。
- State ownerが一つで、非ownerからmutation境界へ到達できない。
- Rule／TransitionがI/Oを持たない。
- Effectと結果Eventが不確実性を失わない。
- Kernel、Main、GatewayへBehavior、device、Provider固有の分岐がない。
- Adapter、Python worker、ProjectionからDomain Stateの変更境界へ到達できない。
- transport schemaとvendor schemaがDomain型になっていない。
- Effectがimperative callではなく、不変で比較・永続化可能な値である。
- scenario、slice、適合表が型、owner、guardを再定義していない。
- Behavior適合表がruntime descriptorまたは中央登録簿になっていない。
- 要件基準commit `4df6fb1`の214 ACと入口索引が一対一で一致し、未追跡・重複がない。
- canonical Design IDの重複、複数canonical anchor、Domain State ownerの重複・未登録、未追跡obligation、相対Markdown link切れがない。
- 前項の機械検査について、検査ID、実行revision、結果Artifactまたは再現commandが保存されている。
- 三本で参照するcanonical contractが全て`accepted`へ昇格している。slice単体の設計審査中は`draft`を許すが、三本全体のGate PASSには使わない。
- architecture challengerの未解決Critical／Highがない。

一つでも満たさない場合、構造を全要件へ展開しません。pilotに合わせて例外を追加せず、フェーズ契約またはcanonical lawを修正して再審査します。

## DesignとProofの`blocked-by-spike`を混同しない

```text
設計法則は確定済み、実機証拠だけ待つ
  -> Design=designed / Proof=blocked-by-spike
  -> Design Pilot Gateは通過可能

実測結果によってState owner、Domain法則、Portの意味が変わり得る
  -> Design=blocked-by-spike / Proof=unplanned
  -> Design Pilot Gateは停止
```

Design Pilot Gate通過後も、Proof=`passing`でない義務を実装済み・release可能とは表示しません。

## 現在の判定

| Pilot | Architecture review | Design slice | Evidence | 判定 |
| --- | --- | --- | --- | --- |
| Pilot A | current change-set再審査待ち | 改訂済み・未承認 | planned／blocked-by-spike | 保留 |
| Pilot B | current change-set再審査待ち | 改訂済み・未承認 | planned／blocked-by-spike | 保留 |
| Pilot C | 再審査待ち | 改訂済み・未承認 | planned／blocked-by-spike | 保留 |

Pilot A/B/Cは共通Execution vocabulary、Guard Fact、revision-use、runtime BindingUse、Recovery custodyを変更する[SD-REV-PILOT-C-001](change-sets/SD-REV-PILOT-C-001.md)の同一revisionで再審査します。旧Pilot A/Bの単独PASSはhistorical evidenceでありcurrent change-setの承認ではありません。
構造索引の機械PASSは意味整合、Atomic Design Obligationの十分性、architecture review PASSを
証明しません。Pilot Cの再審査とPrimary承認、参照canonical contractの`accepted`昇格が終わるまで、
三本全体のDesign Pilot GateをPASSと表示しません。
