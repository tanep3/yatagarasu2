# Evolution Plan and Open Questions

## 1. これは移行計画ではない

この文書は、Yatagarasu 1を今すぐ置き換える計画ではない。
Yatagarasu 2の設計仮説を、小さく検証する順序を示す。

Yatagarasu 1は稼働を継続し、Yatagarasu 2は別repository、別service、別workspaceで育てる。

## 2. 最初に実装しないもの

- 本物のマイク入力
- 本物のカメラ
- Codex CLI
- SemanticMemory
- VOICEVOX
- Web GUIの装飾
- 分散process

最初に実装するのは、純粋なState、Event、Rule、Transition、Effect GraphとFake Adapterである。

## 3. Architecture Test Scenario

最初の完成条件は、次のシナリオを外部I/Oなしで表現できること。

1. `TextSubmitted("右を向いて左を向いて")`
2. 二つのMove Effectが順序付きで生成される
3. 最初の完了前に二つ目はReadyにならない
4. Timer Event後に二つ目がReadyになる
5. LLMとSpeech Effectは生成されない
6. InteractionがCompletedへ遷移する

次に複合シナリオを追加する。

1. `TextSubmitted("右を向いて何が見える？")`
2. Move、settle、Capture、Agent、Speakが依存グラフになる
3. Capture ArtifactがContextBundleへ入る
4. Agent回答がProjectionへ即時反映される
5. Speech完了後にInteractionが完了する

この段階では一台のカメラも動かさない。
構造の正しさを先に証明する。

## 4. Proposed Milestones

### M0: Architecture Laboratory

- Domain type
- Pure Transition
- Rule evaluation
- Effect Graph
- Fake Clock
- Fake Adapter
- Property-based test

### M1: Text Robot

- CLI Gateway
- SBERT Intent Adapter
- Camera Simulator
- Fake Agent
- Conversation Projection

### M2: One Real Effect

- Tapo Camera Adapter
- Move Effectのみ実機接続
- OutcomeUnknownを含む失敗モデル検証

### M3: Visual Interaction

- Capture
- Artifact Store
- Agent Adapter
- ContextBundle

### M4: Voice Interaction

- Voice Gateway
- Wake word
- STT
- Self-audio suppression
- Speech Effect

### M5: Web Control Center

- Web Gateway
- Chat Projection
- Runtime Projection
- Manual command
- Camera image
- Error and latency display

### M6: Memory and Recovery

- SemanticMemory Adapter
- RecallPolicy
- Conversation persistence
- Event Journal
- Restart recovery

## 5. Yatagarasu 1から移植する単位

ファイル単位ではなく、Capability単位で移植する。

| Capability | 継承する知識 | 移植時の形 |
|---|---|---|
| Wake word | ONNX、閾値、CPU最適化 | Voice Adapter |
| STT | go2rtc常時接続、ReazonSpeech | Mimy STT Server + Transcription Port |
| Intent | Ruri v3、テンプレート、閾値 | Intent Adapter |
| PTZ | worker常駐、settle時間 | Camera Effect Adapter |
| View | go2rtc frame API | Capture Adapter |
| Agent | Codex Profile、Hoshikage | Agent Adapter |
| Memory | recent 3 + semantic 3 | RecallPolicy + Memory Adapter |
| Speech | VOICEVOX、tapovoice | Speech Effect Adapter |
| Doctor | 実運用診断項目 | Capability Projection |

既存の制御フローをコピーしない。

## 6. 言語選択

アーキテクチャは言語非依存とする。

Pythonを選ぶ場合:

- `dataclass(frozen=True)`
- `Protocol`
- tagged union相当の型
- exhaustiveな型check
- `mypy`または`pyright`
- property-based test
- Coreでの暗黙mutable state禁止

Rustを選ぶ場合:

- enumによるCommand/Event/Effect
- ownershipによる状態境界
- traitによるPort
- ResultによるFailure
- async runtimeによるEffect実行

現時点の第一候補は、Rust CoreとPython Inference Adapterのハイブリッドである。

- RustはKernel、State、Event、Rule、Effect Graph、Codex app-server管理、Webを担当する
- PythonはSentence Transformers、WakeWordなど既存AI資産をAdapterとして担当する
- STTは独立したMimy STT Serverが担当し、go2rtcへ直接接続する
- Python側はWorldStateや会話状態を所有せず、型付き要求に推論結果を返す
- process境界とIPC方式は技術検証で決め、Domain境界と混同しない

最終決定前に、Codex app-server常駐制御、Rust/Python IPC遅延、Mimy API遅延、
Worker復旧、配布の複雑さを小さな実験で測定する。

## 7. Open Questions

### Q1. Event Journalを最初からSource of Truthにするか

推奨:

最初はState snapshotを正とし、Event Journalは監査とProjection再構築に使う。
完全なEvent Sourcingは、Recovery要件が固まってから判断する。

### Q2. 複数RuleがDecisionを生成した場合の選択

候補:

- 明示Priority
- Policy object
- 全DecisionをPlan fragmentとして合成
- Ambiguous Eventを生成して上位判断へ委譲

推奨:

Ruleへ暗黙の順序を持たせず、`DecisionPolicy`を独立した値として定義する。

### Q3. SBERT RouterはCoreかAdapterか

推奨:

Intentという概念とconfidenceはDomain。
埋め込み計算とモデルはAdapter。
閾値をどのIntentへ適用するかはPolicy。

### Q4. LLMによるSkill選択をどう扱うか

推奨:

LLMへ直接Skillを実行させない。
LLMがTool Callを返した場合も、`ProposedEffect` EventとしてCoreへ戻し、
PolicyとCapability Ruleで検証してからEffect Graphへ追加する。

### Q5. 音声応答とWeb応答を同時に扱うか

推奨:

回答生成と出力Channelを分離する。
`AnswerAvailable`から、Channel Policyが`PublishWebAnswer`、`SpeakAnswer`を生成する。

Webからの命令をTapoが発話するかは、入力元に埋め込んだifではなくChannel Policyで決める。

### Q6. 一つのDaemonか複数serviceか

推奨:

最初はModular Monolith。
実測で必要になった境界だけ分離する。

### Q7. カメラ姿勢をどう表現するか

相対移動しか確実でない機種では、正確な絶対PoseをStateへ持つと嘘になる。

推奨:

- `Unknown`
- `CalibratedOrigin`
- `EstimatedPose`
- `ObservedPose`

を区別し、確度を型で表す。

### Q8. Interactionを直列化するか

推奨:

ユーザーInteractionは初期版で直列。
内部Effectは依存とResourceが許す範囲で並列。

### Q9. Promptを保存するか

推奨:

Domainでは`ContextBundle`とAgent Requestを保存する。
Adapterが生成した最終Promptは、Secret除去後の診断Artifactとして任意保存する。

### Q10. Web GUIはどこまで管理機能を持つか

初期MVP:

- Chat
- 手入力
- 状態
- 実行Effect
- 画像
- エラー
- レイテンシ

設定編集、モデル管理、Skill作成は別要件として後回しにする。

## 8. Architecture Invariants

実装レビューでは、最低限次を機械的または人的に検査する。

1. Domain moduleはnetwork、filesystem、subprocess、wall clockへ依存しない。
2. Stateは外部から変更できない。
3. RuleはEffectを直接実行しない。
4. AdapterはWorldStateを直接変更しない。
5. すべての外部処理結果はEventとしてCoreへ戻る。
6. 一つのStateには一つの所有Contextしかない。
7. Gatewayごとの業務処理経路を作らない。
8. Effectの順序は依存関係またはResource Policyで説明できる。
9. 未知の物理結果を成功として扱わない。
10. Mainは依存を組み立て、Kernelを起動するだけである。

## 9. 最後に

Yatagarasu 2で目指すのは、クラスの多いシステムでも、流行の分散アーキテクチャでもない。

音声が届き、意味が生まれ、ロボットが動き、世界を観測し、AIが答え、記憶が残る。
その因果関係を、曖昧な手続きではなく、型を持つ構造として記述することである。

> Yatagarasu 1は、何ができるかを証明した。
> Yatagarasu 2は、それがどのような世界なのかを記述する。
