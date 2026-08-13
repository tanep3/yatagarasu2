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

## 状態を三軸に分ける

設計義務の所在、設計完成度、証拠進捗を一つの状態へ混ぜません。

| 軸 | 主な状態 | 問い |
| --- | --- | --- |
| Accounting | `unaccounted` / `accounted-for` | 義務の所在とscopeを把握したか |
| Design | `undesigned` / `designed` / `blocked-by-spike` / `blocked-by-owner` / `deferred` | canonical contractとproof designを確定できたか |
| Proof | `unplanned` / `planned` / `implemented` / `passing` / `blocked-by-spike` / `blocked-by-owner` / `not-applicable` | 実装・試験・実機証拠がどこまで存在するか |

設計は確定済みで実機証拠だけを待つ場合は、Design=`designed`、Proof=`blocked-by-spike`です。
実測結果によってState ownerやDomain法則自体が変わり得る場合だけDesign=`blocked-by-spike`です。
文書を埋めただけではProof=`implemented`または`passing`にしません。実機受入条件は
Fake Adapterだけで`passing`にしません。

## 二つのGate

- [Design Pilot Gate](verification/pilot-gate.md): 三本のpilotで設計方法を検証し、全214 ACへ横展開してよいかを判定する。
- [Implementation / Evidence Gate](verification/implementation-evidence-gate.md): 実装とrevision付き証拠がrelease水準かを判定する。

Design Pilot Gateはproduction codeや実機passingを要求しません。Implementation / Evidence Gateは
Proof=`passing`を要求します。設計完成とrelease証拠を分離することで、実装しなければ設計を
展開できない循環と、証拠がない実装を完成扱いする誤りの両方を防ぎます。

横展開後のsystem design FIXは、Design Pilot Gateとは別の完成確認です。
[system design FIX検査](verification/check-system-design-fix.sh)は、全214 ACが`covered`、
全canonical contractが`accepted`、人間向け読み物版が存在してcanonical Design IDへ
接続されていることを要求します。この検査を通らない限り「システム設計書FIX」と表示しません。

## 人間向けの読み物版

canonical system designは、AIエージェントと実装者が曖昧なく参照できる契約形式を維持します。
全214 ACへの転写が完了しsystem designをFIXする際、非権威の派生成果物
`docs/system-design/system-design-guide.md`を必ず作成します。

読み物版は、Yatagarasu 2の世界モデル、Context／State owner地図、
Command→Decision→Effect→result Event、Pilot A/B/Cの因果関係、Failure／Recovery、
Rust／Python／Web／外部能力境界を、人間が順に理解できる文体と図で説明します。
canonical Design IDへリンクし、新しいpayload、owner、guard、要件を独自に定義しません。

## 現在のGate

三本の縦断設計は2026-08-13に[Design Pilot Gate](verification/pilot-gate.md)を通過しました。
全214受入条件への構造横展開は
[AC横展開実施契約](verification/ac-expansion-plan.md)に従って開始できます。これはproduction
implementation、実機成立、releaseを承認するものではありません。全system designを横展開・FIXした後に
production implementationへ進み、実装とrelease証拠の合否はImplementation / Evidence Gateで別に管理します。
accepted contractは[Design Approval Aggregation Manifest](verification/design-approval.md)の
content-addressed subsetへID／Version／definition hash単位で追加し、過去のPilot承認範囲を拡張しません。

Pilot Aは[カメラ移動・撮影・画像解釈のcanonical contract](contracts/camera-observation.md)と[Pilot A slice](slices/01-camera-observation.md)、Pilot Bは[有限Conversation・外部Thread・SemanticMemoryのcanonical contract](contracts/finite-conversation.md)と[Pilot B slice](slices/02-finite-conversation.md)、Pilot Cは[設定適用契約](contracts/configuration-application.md)、[runtime binding契約](contracts/runtime-binding.md)、[routing契約](contracts/routing-policy.md)、[migration／restart契約](contracts/migration-and-restart.md)と[Pilot C slice](slices/03-configuration-capability.md)で設計しました。三sliceと共通contractはcurrent change-setの同一revisionで審査・承認済みです。

技術spike待ちのIPC、process数、storage engine、Web更新transport、Skill権限強制方式、実測数値は、仮の既定値として設計へ紛れ込ませません。
