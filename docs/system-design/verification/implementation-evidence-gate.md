# Implementation / Evidence Gate（実装・証拠Gate）

このGateは、実装がcanonical system designに適合し、対象releaseに必要な証拠が揃ったかを
判定します。[Design Pilot Gate](pilot-gate.md)とは目的が異なります。

```text
Design Pilot Gate
  設計を全214 ACへ横展開してよいか

Implementation / Evidence Gate
  実装またはreleaseを合格にしてよいか
```

## Release scopeを先に固定する

release対象は、passingになった項目から実装者が選びません。Implementation / Evidence Gateの前に、
version付きの[Release Manifest](release-manifest.md)を正本として固定します。

証拠取得前にRelease Scopeが全atomic obligationを一件ずつ列挙し、次のいずれかへ分類します。

- `required`: 当該releaseで必須。Proof=`passing`が必要
- `excluded-by-owner`: 要件変更または明示的なOwner判断で除外した。判断記録が必要

`deferred-by-requirement`は、正本要件に機械可読な将来版scope台帳がない現在は使用禁止です。
全Obligation台帳との差分、重複、未分類を機械照合し、根拠がない限り`required`として扱います。

Release Scopeだけのhash、version、対象release、設計revision、要件revision、検査規則revisionを、
Evidence取得前に独立したOwner承認Artifactへ固定します。Gateはscope承認commitがEvidence実行commitの
祖先であることも確認します。除外も、判断文書とは別のOwner承認Artifactが
対象Obligation、Parent AC、Disposition、各revision、判断文書hashを完全一致で承認します。
実装者が判断文書へ`accepted`と書くだけではGateを通過できません。

## 通過条件

固定済みRelease Scopeで`required`となる全Atomic Design Obligationについて、次を要求します。

- Accounting=`accounted-for`
- Design=`designed`
- Proof=`passing`
- 実行revisionとEvidence Refが存在する
- canonical Design IDから実装、試験、証拠まで追跡できる
- 未解決の必須review conditionがない

加えて、Manifest自体が次を満たさなければなりません。

- 全atomic obligationと一対一で一致する
- 要件基準revisionとsystem design revisionを記録する
- 対象version、Profile、Provider、Agentを固定する
- 延期には正本要件、除外にはOwner判断のrevision付き根拠がある
- scope差分の機械検査がpassingである

Proof=`planned`、`implemented`、`blocked-by-spike`、`blocked-by-owner`は通過しません。
source codeが存在するだけではProof=`passing`にしません。

## Proof type別の証拠

| Proof type | `passing`に必要な証拠 |
| --- | --- |
| `pure` | Rule／Transition／Policyのtable-driven testと否定例 |
| `architecture` | 依存方向、単一owner、mutation境界、到達不能性の機械検査または構造review |
| `contract` | Port／Adapterの成功、Failure、取消、OutcomeUnknownを含むcontract test |
| `integration` | 複数Context、Effect Graph、Projectionを通した因果関係の試験 |
| `concurrency` | 同時要求、競合winner、late result、取消raceの決定的試験 |
| `crash-recovery` | crash windowを明示した障害注入、restart、late／duplicate resultの試験 |
| `projection` | 再同期、権限別表現、内部情報非漏洩を含むProjection試験 |
| `real-device` | 指定Profileと実機による試験。Fake Adapterだけでは不可 |
| `measurement` | hardware、Profile、測定条件、母数、欠測を含む測定Artifact |
| `spike` | 実験手順、候補比較、採否条件、canonical lawへ与えた影響の記録 |
| `owner-gate` | 実測結果とOwnerの採否記録 |

## Profile別の判定

TC70、C210、将来機種、Provider、Agent、音声Profileは別々に証拠を持てます。
TC70のrelease証拠をC210へ流用せず、あるProfileの未証明だけを理由に、要件上独立して
release可能な別Profileまで不合格にしません。

## Evidence Ref

Evidence Refは最低限、次を識別できなければなりません。

- 対象Design IDとAtomic Design Obligation
- source／test revision
- 実行commandまたは実機手順
- hardware、Profile、設定snapshot
- 成功、Failure、欠測、未確認結果
- 結果Artifactまたは保存場所

Gateは文字列が書かれているだけでは受理せず、Evidence Artifactと結果Artifactの実在、hash、
対象Obligation／Parent AC、設計revision、実行commit、Profile、Provider／Agentの一致を検査します。

Projection、ログの存在、architecture reviewの感想だけを実機成功の代用にしません。

## Gateが禁止する誤認

- Design Pilot Gate PASSをrelease許可と呼ばない。
- `implemented`を試験合格と呼ばない。
- `blocked-by-spike`を暗黙の成功と呼ばない。
- Assumed／OutcomeUnknownをObservedへ昇格しない。
- 一つのProfile、Provider、正常系の証拠を全構成へ一般化しない。
- passing済みの少数だけをRelease Manifestへ登録しない。
