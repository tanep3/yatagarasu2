# ドメインモデル — ロボットの世界を記述する語彙

## 一つの法則

Yatagarasu 2は、カメラ、会話、Skillごとに別の主手順を持ちません。すべてを次の法則へ入れます。

```text
WorldState + Event
  -> Rule
  -> Decision(Transition, Effect Graph)
  -> WorldState'
```

これは「必ずこの順番で部品を呼ぶ」という処理フローではありません。現在の世界と起きた事実から、適用可能な規則が、内部の状態変化と外界へ依頼する仕事を値として決める、という意味です。

## 基本の値

| 値 | 入力と出力 | 責務 |
| --- | --- | --- |
| Command（要求） | 外からCoreへ入る | 方針により受理、拒否、確認要求できる依頼。まだ事実ではない。 |
| Event（事実） | Adapterや内部判断からCoreへ入る | 過去に起きたこと。要求や推測と区別する。 |
| State（状態） | Ruleが読む | 名前を持つContextが唯一所有する、判断時点の世界の断面。 |
| Rule（規則） | State view + Event → Decisionまたは無判断 | I/Oを行わず、適用できる法則を純粋に評価する。 |
| Transition（遷移） | State → State | 内部で確定できる、決定論的な状態変換。 |
| Decision（決定） | Ruleの出力 | Transitionと、必要ならEffect Graphをまとめた判断値。 |
| Effect（外部作用） | CoreからPortへ出る | 外界へ依頼する仕事。作成しただけでは実行済みにならない不変値。 |
| Failure（失敗） | 外部・内部境界から戻る | 例外文字列ではなく、判断可能な型付き失敗データ。 |
| ArtifactRef（成果物参照） | Context間・Effect間で渡る | 画像、音声、文字列など大きな成果物の存在と利用条件を示す参照。 |

WorldStateは外部データを何でも詰め込む巨大な袋ではありません。画像、音声、モデル、長い文字列は必要に応じてArtifactRefで参照します。

## 状態の所有者は一つ

| 状態 | 唯一の所有者 | 所有しないもの |
| --- | --- | --- |
| wake受理と発話入力の生存期間 | Acoustic Context | Yata Wake、Mimy、音声Adapter |
| Interactionの生存期間と取消 | Interaction Context | Web、音声、CLI、LLM |
| 意味解決方針の版 | Decision Policy Context | SBERT、LLM、profile |
| Effect Graph、永続待機、取消済み仕事 | Execution Context | dispatcher、Adapter、journal再生 |
| 物理観測と姿勢 | Physical Observation Context | カメラAdapter、校正能力 |
| 成果物の生存期間 | Artifact Context | TTS、撮影、Provider、filesystem Adapter |
| 通知の方針 | Notification Policy Context | 通知チャネル、Projection |

Contextは、自分が所有する状態だけを変更します。他のContextへ可変参照を渡さず、事実をEventとして交換します。Adapter、Python worker、外部Provider、profile、ProjectionはWorldStateを所有しません。

## Effect Graphは、手順書ではなく因果構造である

複合動作の順番は、中央の関数へ並べるのではなく、Effect Graphに宣言します。

- **依存関係**: どの結果がそろえば次の仕事を始められるか。
- **guard（進行条件）**: どの結果なら先へ進み、どの結果なら止めるか。
- **resource claim（資源要求）**: カメラの首、撮影、音声出力など、同時使用できない資源は何か。
- **取消状態**: まだ送っていない仕事を、再起動後も含めて止める必要があるか。

Schedulerは、依存関係を満たし、guardが許可し、資源が空いている仕事を選ぶだけです。カメラや会話に固有の主手順を知りません。

### 「右を向いて、何が見える？」

```text
MoveCamera(right)
  -> CaptureImage
  -> RequestInterpretation(valid ArtifactRef)
  -> PlaySpeech
```

これは見た目の順序だけでは不十分です。

- 移動がDefinitelyNotAppliedなら、撮影とLLMを進めない。
- 移動がOutcomeUnknownなら、明示方針がない限り撮影を進めない。
- 時間に基づくAssumedの後続許可には、専用の方針が必要である。
- 撮影が失敗した、またはArtifactRefが無効なら、LLMへ画像を渡さない。
- 通知をしない設定でも、内部の結果Eventは消さない。

この条件がGraphとPolicyに残ることで、別のカメラや身体へ交換しても、世界の法則を失いません。

## 意味を解くContributor

意味解決へ材料を出すものをContributor（候補提供者）と呼びます。

| Contributor | 返すもの | 返さないもの |
| --- | --- | --- |
| SBERT Adapter | 意味候補、score、出所 | 実行済み結果、WorldState変更 |
| 純粋Rule | 決定論的な判断材料またはDecision | I/O結果 |
| LLM / Codex | 解釈やProposed Effect | 許可済みEffect、確定済みGraph |

通常の意味ルーティングではSBERT候補を先に得て、灰色帯域の候補を動作固有のキーワード／規則で絞り込みます。ただし、全機能に固定された三段階処理ではありません。明示方針により、規則だけ、SBERT、LLM提案だけ、または複数のContributorを組み合わせられます。

ここでいう「動作固有の候補」は、すべてを`calibrate_camera`のような中央の正式Intent登録簿へ集約することを意味しません。Decision Policy Contextが所有するのは、候補の閾値、gate、競合・曖昧・合成可能時の扱いを記した版付き方針です。

カメラ校正は、SBERT候補と校正に固有のキーワード／規則が決定論的方針に一致すれば、LLMへ送らずEffect Graphを作れます。ただし、安全方針、能力方針、資源要求を迂回しません。

### LLM／Provider routeも候補として解く

推論能力は、具体モデル名を直接Domainへ持ち込まず、速度重視、Vision、高性能推論などの論理profileとして扱います。SBERTは入力からroute候補を返し、Decision Policyが利用可能性、privacy、利用者同意、能力広告を踏まえて解決します。

preferred route（希望経路）とeffective route（実効経路）を分けます。希望した外部Vision profileが使えない場合、拒否、利用者確認、許可済み縮退のどれを選ぶかはPolicyです。外部Providerやworkerはroute方針、会話状態、WorldStateを所有しません。

## Skill、Proposal、Effectを分ける

Skillは、人間が使うアプリ、データ、外部能力をAIへ公開する接続面です。Skillを追加することで、Coreへ製品固有の分岐を足さずに、AIが新しい世界へ触れられるようにします。

Skillの読出しが観測を返す場合も、AIが書込みを提案する場合も、決定論的な能力を公開する場合もあります。したがってSkillは、Contributor、Proposal、Effect、Adapterのどれか一つと同義ではありません。

```text
Skillを介した観測
  -> 型付きObservation/Event候補

Skillを介したAIの行動提案
  -> Proposal
  -> Policy検証
  -> 許可されたEffect Graph
  -> Adapter実行
  -> 結果Event
```

LLM、Codex、Skill内の外部主体が返すProposalは、命令ではありません。Policyが拒否、確認要求、許可済みEffectへの変換を決めます。

## Profile、取消、通知

機能、機種、推論routeごとのprofileは、外側の中立なschemaから選びます。Effectをdispatchする時点で、実効profileと版を不変値としてEffectと永続待機記録へ固定します。後から設定が変わっても、すでに送った仕事の意味を変えません。

`CancelRequested`は共通Inbound境界へ入るCommandです。Interaction Contextが受理した結果は`CancellationAccepted` Eventとして記録します。さらに、待機中仕事の永続取消、実行中仕事の取消結果、物理結果を別々のEventとStateで表します。取消後に遅れて届いたProposalは適用しません。止められない物理動作を、止めたことにはしません。

通知する操作、計画、チャネル、言い回し、無通知はNotification Policy Contextが所有します。Projectionへの表示は、外部へ通知が届いた証拠ではありません。

## 時刻と物理的事実

時刻はClockPortから導入します。`EffectExecutionStarted`（外部作用の実行開始Event）は、Adapterが実行を試みた、または開始したという事実です。物理的に適用された、完了したという証拠ではありません。

`ExpectedActionDuration`（想定動作時間）は、Coreがこの開始Eventを受理した時点から、機能・機種profileの単調時間を測ります。待ち行列にいた時間は含めません。開始Eventがなければ、時間に基づくAssumed（仮定済み）の進行事実を作りません。

相対移動の要求と、観測・推定した姿勢も別の値です。証拠のない絶対姿勢を作りません。校正成功は校正能力の結果であって、現在姿勢の観測証明ではありません。
