# クオリアと振る舞い — 一つの体験を、構造として拡張する

## クオリアは一つ

Qualia（クオリア）は、Yatagarasuが現在どの振る舞いとして世界を知覚し活動しているかを表します。会話、文字起こし、同時通訳、見守りはそれぞれ異なるクオリアです。現在の非Home qualia sessionは全体で0または1です。ここでいう「一つ」はLifecycleのActive phaseだけでなく、Starting、Active、Terminating、Recoveringにある現在session全体を指します。

```text
Home
  -> Starting
  -> Active
  -> Terminating
  -> Home

persisted non-Home
  -> Recovering
       ├─ ResumeFromCheckpoint -> Active（同じsession）
       ├─ AwaitOwnerDecision   -> Recovering
       └─ Terminate / Quarantine責任移管
            -> Terminating
            -> Home
```

Homeは現在の非Home qualia sessionがない基本待受状態です。Starting、Active、Terminating、Recoveringの間に別のクオリアを開始しません。これは処理能力の制限ではなく、一つの音声、一つのHome要求、一つの身体資源がどの活動へ属するかを明確にする製品法則です。

再起動時にStarting、Active、Terminatingのどれを復元しても、まずRecoveringへ入ります。安全なcheckpointと明示Policyがある場合だけ、同じqualia sessionをActiveへ戻せます。これは別Qualiaの開始ではありません。Owner判断待ちはRecoveringを維持し、終了または資源隔離を選ぶ場合は、責任移管と終了処理を経てHomeへ戻ります。

## 自律神経はクオリアではない

Home／Stop制御語の検知、永続化、Recovery、診断、認証、Web状態同期は、どのクオリアでも生存します。これらはYatagarasuの自律神経であり、第二のクオリアではありません。

自律神経は製品固有のBehavior知識を所有せず、Qualia StateやBehavior Stateを直接変更しません。外部事実または内部運用事実をEventとして返し、名前を持つContextのRuleとTransitionが状態を変えます。

## Qualia Contextが所有する範囲

Qualia Contextは次だけを所有します。

```text
QualiaState
├─ lifecycle phase
├─ qualia session identity
├─ behavior identity / version
├─ start / termination cause
├─ policy / profile version
└─ behavior-specific state reference
```

機能固有Stateへの参照は、所有Context名とsession／correlation identityだけから成る不変・不透明な値です。State値、可変参照、reducer、dispatch handleではありません。文字起こし本文、会話履歴、監視対象、device内部状態、Effect Graph、画像・音声本体は所有しません。例えばQualia Contextは「文字起こし中」を所有し、Transcription Contextが文章と認識進行を所有します。

Interactionは一つの入力から生じる有限の因果単位です。一つの長時間Qualiaは複数Interactionまたは外部Eventを受け取れます。Qualia、Interaction、Conversationを同義にしません。

## Home復帰

設定可能な音声制御語とWebの常設Home操作は、同じ`ReturnToHomeRequested` Commandを作ります。既定音声は「ヤタガラス、ホーム」です。

```text
ReturnToHomeRequested
  -> 新規admission停止
  -> pending仕事の永続取消
  -> 対応可能なin-flight取消
  -> 成果物確定 / cleanup
  -> 資源解放またはRecoveryへの責任移管
  -> Qualia終了
  -> Home
```

Home要求の受理は終了完了ではなく、終了完了は物理作用の停止観測でもありません。`TerminationCompleted`、`TerminationPending`、`TerminationFailed`、`TerminationOutcomeUnknown`を分けます。

物理結果不明の仕事は自動再送せず、自律神経のRecoveryへ引き渡します。資源を再利用できるかは、即時、cooldown後、照合後、Owner確認後、利用不能というeffect／device別Policyで決めます。資源を再利用できることと、姿勢や物理結果が確認済みであることは別です。

## 振る舞いは万能objectではない

一つの振る舞いは、必要なLayerへ構造を寄与します。

| 寄与先 | 必要なときに追加するもの |
| --- | --- |
| 発見 | identity、version、説明、必要Capability、入出力面 |
| 意味解決 | SBERT Candidate、例、gate、Policy data |
| Domain | Command、Event、State、Rule、Transition、Policy、Effect、Failure |
| Application | Graph contributor、Qualia開始・終了、Projection、Recovery |
| Port | 新しい外部能力の抽象境界だけ |
| Adapter | 具体製品・通信とPort値の翻訳 |
| Bootstrap | binding、配置、設定、能力診断 |
| Web | 公開API操作、標準部品、画面、成果物表示 |
| 運用 | schema、migration、license、Upgrade |
| 検証 | ownership、失敗、取消、Recovery、API、traceability |

既存の移動、撮影、Artifact、Web表示を組み合わせるだけなら、新しいPort Traitは要りません。新しい温度センサーなど外部能力の抽象境界が必要なときだけPort Traitを追加します。

Yatagarasu 2では、この追加を正式なversion updateとして行います。利用者のHTML／CSSは画面を変えますが、振る舞い、Rule、Effect、Portを追加しません。実行時pluginやエンドユーザーによる機能追加は、必要ならYatagarasu 3で検討します。

規範的な条件は[プロダクト要件](../requirements/product-requirements.md)、[アーキテクチャ要件](../requirements/architecture-requirements.md)、[運用要件](../requirements/operational-requirements.md)にあります。
