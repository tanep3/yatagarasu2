# システム設計

このディレクトリは、確定要件を実装可能な構造へ転写するための正本です。

システム設計の目的は、要件文をクラス図や処理手順へ置き換えることではありません。要件基準であるcommit `4df6fb1`の62要件・214受入条件を、State、唯一の所有者、純粋なRule／Transition、Effect、結果Event、Port、Recovery、Projection、検証へ漏れなく接続することです。

## 設計思想

Yatagarasu 2では、変わり得る箇所を中央処理の条件分岐へ埋め込みません。

- 意味判断の変化は、Candidate、Contributor、Policyへ置く。
- 機種、外部製品、通信、配置の変化は、Profile、Port、Adapter、Bootstrapへ置く。
- 状態の変化は、唯一の所有Contextと純粋なTransitionへ置く。
- 外界へ依頼する仕事は、不変のEffectとEffect Graphへ置く。
- 外界から戻る不確かな結果は、型付きEventとRecoveryへ置く。
- 利用者へ見せる変化は、Projection、公開API、Web部品へ置く。

ただし、将来変わるかもしれないという想像だけで抽象化しません。各抽象は、correctness（正確性）、latency（応答時間）、diagnosis（診断）、recovery（復旧）、replaceability（交換可能性）、usability（使いやすさ）のどれを改善するか説明できなければなりません。

この思想の導出は[設計思想](../architecture/design-philosophy.md)を正本とします。原典「オブジェクト指向はなぜ挫折するのか」とsoukobanは、新しい要件を追加する権威ではなく、未知の設計判断を同じ思考から再生成するためのfew-shotです。

## 文書の権威

優先順位は次のとおりです。

1. Accepted ADR
2. `docs/requirements/`の正本要件
3. このディレクトリのcanonical design contract（設計上の正本契約）
4. `docs/architecture/`の説明
5. scenario、slice、適合表、索引

システム設計は要件を変更しません。設計中に要件の矛盾、曖昧さ、Owner判断の不足を発見した場合、設計で補完せず要件またはADRへ戻します。

## 単一定義の原則

State、Command、Event、Decision、Transition、Policy、Effect、Graph、Port、Projection、Failure、Recovery契約には、canonical definition（唯一の正式定義）を一つだけ置きます。

[設計契約索引](00-design-authority.md)は、Design IDからその定義場所を引くための索引です。意味を所有せず、runtime catalogとして読み込まず、登録順で優先順位を決めません。他の文書はcanonical Design IDを参照し、payload、所有者、guard、mutation authorityを再定義しません。

## 要件転写の単位

一つの受入条件には、複数の成功条件、否定条件、障害条件、実機条件が含まれる場合があります。このため「一ACにつき一行のDesign ID」をcoverage（網羅）とは扱いません。

[設計義務台帳](verification/design-obligations.md)で、各ACをatomic Design Obligation（原子的な設計義務）へ分解します。分解後も親ACの原文位置と、同時に満たすべき義務groupを保持します。`accounted-for`（所在確認済み）と`covered`（設計網羅済み）を区別し、初期scope内の全義務が設計済みになるまで親ACを`covered`と表示しません。技術検証待ち、Owner判断待ち、延期は、見失っていないことを示せても設計済みの証明にはなりません。

## 縦断設計を先に行う

全State、全型、全Graphを水平に一括設計しません。全体法則、State分類、単一定義規則を置いた後、次の三本を入力から試験まで縦に閉じます。

1. TC70の移動 → 安定待ち → 撮影 → 解釈
2. 有限Conversation → Codex Thread → SemanticMemory
3. 設定更新 → Capability binding

三本は作例ではなく、[pilot Gate](verification/pilot-gate.md)です。各sliceで、State所有、Rule／Transition、Effectと結果Event、Graph、Failure、取消、Recovery、Port、Projection、proof design（証明設計）が閉じ、未解決の重大指摘がない場合だけ全体へ展開します。

## scenarioとBehavior適合表

scenarioは命令的なruntime手順ではありません。次だけを記述します。

```text
Initial snapshot
Inbound Command / Event
Expected Decision / Effect Graph
Adapter result Events
Final snapshot / Projection
```

Behavior適合表もruntime descriptorではありません。各Layerへの寄与を確認する設計時の索引であり、canonical Design IDだけを参照します。型、State、owner、guardを定義せず、実行順、reducer参照、dispatch handleを持ちません。runtime descriptorへ変更する場合は別のADRとOwner判断が必要です。

## 設計状態

設計義務の状態は次に限定します。

| 状態 | 意味 |
| --- | --- |
| `unmapped` | まだcanonical design contractへ割り当てていない |
| `designed` | canonical contractとproof designが存在する |
| `blocked-by-spike` | 技術検証結果がなければ設計を確定できない |
| `blocked-by-owner` | Owner判断がなければ確定できない |
| `deferred` | 正式に初期scope外である |
| `implemented` | 対応sourceが存在するが、証拠は未確認 |
| `passing` | revision付きの自動試験または実機証拠がある |

文書を埋めただけでは`implemented`または`passing`にしません。実機受入条件はFake Adapterだけで`passing`にしません。

## 現在のGate

現在は「system design pilot」段階です。三本の縦断設計がGateを通るまで、全214受入条件への構造横展開、crate/module固定、production code作成を開始しません。

最初の成果物は[カメラ移動・撮影・画像解釈のcanonical contract](contracts/camera-observation.md)と[Pilot A slice](slices/01-camera-observation.md)です。

技術spike待ちのIPC、process数、storage engine、Web更新transport、Skill権限強制方式、実測数値は、仮の既定値として設計へ紛れ込ませません。
