# Yatagarasu Agent化 要件定義書

## 常駐エージェント・Web GUI・動的LLMルーティング統合

- 文書状態: Draft
- 作成日: 2026-07-31
- 対象: Yatagarasu 2
- 文書の役割: 常駐Agent、Web GUI、動的LLMルーティングに関する要求原典
- 備考:
  - 本書は要件検討のたたき台であり、今後のレビューで確定・変更する
  - 記載されたプロセス構成、責務配置、IPC方式は確定設計ではない
  - アーキテクチャへの統合判断は`05-agentization-architecture-review.md`を参照する

---

## 1. 文書の目的

本書は、現行Yatagarasuを、命令ごとにCodexを起動するバッチ型システムから、常時起動したAIエージェントを共有する常駐型システムへ移行するための要件を定義する。

本開発では、単なるCodex常駐化に加え、以下を実現する。

* 音声待受とAIエージェントの分離
* Web GUIによるチャット操作
* Unixドメインソケットによる共通Agent接続
* 同一Codex app-server内での動的モデル切替
* Codex app-server再構成による動的プロバイダ切替
* SBERT Routerによる決定論的なモデル・プロバイダ選択
* ローカルLLMとOpenAI GPTの使い分け
* 単一systemdサービスによる一括起動
* 音声、Web、Vision、Tool、LLMを統合する常駐AI基盤

---

## 2. 背景

現行Yatagarasuでは、音声命令やCLI命令を受け取るたびにCodexを新規起動している。

従来の処理フローは概ね以下である。

```text
音声入力
→ WakeWord検出
→ 録音
→ ReazonSpeechによるSTT
→ SBERT Router
→ codex exec起動
→ Codex初期化
→ 設定・Skill・Tool定義の読込
→ Hoshikageへ推論要求
→ Tool実行
→ 応答
→ Codex終了
```

この方式では、LLMの推論時間以外に、命令ごとのCodex起動および初期化時間が発生する。

Codex app-serverを一度だけ起動し、同一Threadへ複数の`turn/start`を送信する実験では、従来方式と比較して大幅な応答時間短縮が確認された。

この結果から、Yatagarasuの主要なボトルネックは、LLMの生成速度だけでなく、Codexのプロセス起動および初期化処理にあると判断した。

さらに、Yatagarasuには複数のLLMを用途別に使い分けたいという要求がある。

例：

* 軽量・高速な日常会話用モデル
* Vision対応モデル
* 高性能なローカルモデル
* 高難度問題向けOpenAI GPT

これらをLLM自身に自動選択させると、ルーティング判断そのものに推論時間と誤判定リスクが発生する。

一方、Yatagarasuには既にSentence-BERTを用いた高速かつ決定論的なIntent Routerが存在する。

そこで、SBERT RouterをSkill選択だけでなく、LLMモデルおよびプロバイダの切替にも利用する。

---

## 3. プロダクトコンセプト

Yatagarasuは、単一のLLMを搭載した音声ロボットではない。

複数のAIモデル、複数の推論プロバイダ、身体操作、Vision、Toolを、自然言語によって選択・制御できる常駐AIロボット基盤である。

### 3.1 各構成要素の位置づけ

```text
listend           = 耳・音声インターフェース
yatagarasu-agent  = 脳・エージェント制御
yatagarasu-web    = 顔・操作盤・管理画面
SBERT Router      = 反射神経・決定論的ルーター
Codex app-server  = エージェントランタイム
Hoshikage         = ローカル推論基盤
OpenAI            = クラウド高性能推論基盤
Unix socket       = プロセス間の神経線
```

### 3.2 Yatagarasuの独自ポジション

Yatagarasuは、以下を一つのシステムとして提供する。

* 音声による身体操作
* 音声によるSkill選択
* 音声によるLLMモデル切替
* 音声による推論プロバイダ切替
* ローカルAIとクラウドAIの使い分け
* Visionモデルへの動的切替
* Web GUIによる状態確認とチャット
* 同一Agentによる会話文脈の管理

本システムの中核的な価値は、ユーザーが自然言語によって、AIへの質問だけでなく、AIの脳構成そのものを操作できる点にある。

---

## 4. 現状の課題

### 4.1 Codexの起動コスト

命令ごとにCodexプロセスを新規起動するため、短い命令でも大きな固定遅延が発生する。

### 4.2 会話文脈の断絶

命令ごとにCodexを終了するため、以下のような連続命令を自然に扱いにくい。

```text
「右を向いて」
「もう少し」
「そこで止めて」
「今、何が見える？」
```

### 4.3 CLI中心の操作

常駐Agent化後は、従来のYatagarasu CLIがCodexを直接起動する必要がなくなる。

一般利用者にとってCLIは参入障壁でもあるため、ブラウザから操作できるGUIが必要である。

### 4.4 systemd登録数の増加

責務分離だけを優先すると、以下を個別登録する必要が生じる。

```text
listend.service
yatagarasu-agent.service
yatagarasu-web.service
```

これは導入・更新・停止・トラブル対応を複雑にする。

### 4.5 LLMルーティングの判断コスト

LLMに「どのLLMを使うべきか」を判断させると、以下の問題が生じる。

* モデル選択前にLLM推論が必要
* 誤選択が発生する
* 意図しないクラウド利用が発生し得る
* コストやプライバシーをユーザーが制御しにくい
* モデル選択の結果が非決定的になる

### 4.6 ローカルLLMとクラウドLLMの切替

Hoshikage内のモデルは同一Providerとして切替可能だが、HoshikageとOpenAIはCodex上のProviderが異なる。

そのため、モデル変更とProvider変更を異なる処理として設計する必要がある。

---

## 5. 目的

本開発の目的は以下である。

1. Codex app-serverを常駐させ、命令ごとの初期化コストを排除する。
2. 音声入力とWeb入力で同一の常駐Agentを利用する。
3. 同一Threadを維持し、文脈依存の連続会話を可能にする。
4. ユーザーが登録するsystemdサービスを原則1つにする。
5. Listend、Agent、Webをプロセス分離し、障害を局所化する。
6. SBERT Routerにより、LLMを介さずモデル切替を実行する。
7. 同一Provider内のモデルを、Codex再起動なしで動的に切り替える。
8. Provider切替時は、ListendやWebを停止せず、Codexのみ再構成する。
9. ローカルLLM、Visionモデル、高性能モデル、OpenAI GPTを音声で選択可能にする。
10. Web GUIからもモデルおよびProviderを確認・変更可能にする。
11. TTFT、総応答時間、Tool処理時間、推論メトリクスを計測可能にする。
12. Yatagarasuを、音声・Web・身体・Vision・複数AIを統合する常駐AI基盤へ発展させる。

---

## 6. 対象ユーザー

### 6.1 一般利用者

* 音声でYatagarasuへ命令したい
* ブラウザから会話したい
* 普段はローカルAIを使いたい
* 難しい質問だけOpenAIを使いたい
* 画像を見る場合だけVisionモデルへ切り替えたい
* Linuxサービスの登録を一つで済ませたい

### 6.2 開発者

* STT結果を確認したい
* SBERTの判定結果を確認したい
* 現在のモデルとProviderを確認したい
* CodexイベントとTool Callを確認したい
* TTFTや応答時間を測定したい
* モデル切替やProvider切替をテストしたい

---

## 7. 全体ユースケース

## UC-01 音声で質問する

1. ユーザーがWakeWordを発話する。
2. ListendがWakeWordを検出する。
3. 音声を録音する。
4. ReazonSpeech K2が文字起こしする。
5. SBERT RouterがIntentを判定する。
6. 通常会話の場合、STT結果をAgentへ送信する。
7. Agentが現在選択中のモデルを指定してCodexへTurnを送る。
8. 回答をListendへストリーム返却する。
9. ListendがTTSで発話する。

---

## UC-02 文脈を引き継いだ連続命令

```text
ユーザー：「右を向いて」
ユーザー：「もう少し」
ユーザー：「そこで止めて」
ユーザー：「今、何が見える？」
```

同一Threadを利用し、直前の行動および会話文脈を引き継ぐ。

---

## UC-03 Webチャット

1. ユーザーがWeb GUIを開く。
2. テキストを入力する。
3. WebプロセスがUnixソケット経由でAgentへ送る。
4. AgentがCodexへTurnを送る。
5. 回答deltaをWebSocketでブラウザへ転送する。
6. 回答を逐次表示する。

---

## UC-04 ローカル軽量モデルへ切り替える

ユーザー発話：

```text
「ねぇ、ヤタガラス。LLM LOW」
```

処理：

```text
WakeWord
→ STT
→ SBERT Intent: llm.low
→ Agentのactive_model_profileをlowへ変更
→ Codex app-serverは再起動しない
→ 次TurnからLFMを指定
```

応答例：

```text
「LOWモードに切り替えました」
```

---

## UC-05 Visionモデルへ切り替える

ユーザー発話：

```text
「ねぇ、ヤタガラス。LLMビジョン」
```

処理：

```text
SBERT Intent: llm.vision
→ active_model_profile = vision
→ 次TurnからQwen3.5-9B-Vision
```

続けて、

```text
「今、何が見える？」
```

と指示すると、Vision対応モデルが利用される。

---

## UC-06 高性能ローカルモデルへ切り替える

ユーザー発話：

```text
「ねぇ、ヤタガラス。LLM High」
```

処理：

```text
SBERT Intent: llm.high
→ active_model_profile = high
→ 次TurnからGemma4-12B-MTP
```

---

## UC-07 ProviderをOpenAIへ切り替える

ユーザー発話：

```text
「ねぇ、ヤタガラス。プロバイダをOpenAIに変更」
```

処理：

```text
SBERT Intent: provider.openai
→ 新規Turn受付を一時停止
→ 実行中Turnの完了または中断
→ 現Codex app-server終了
→ OpenAI Provider指定でCodex再起動
→ initialize
→ 新Thread作成
→ active_provider = openai
→ 切替完了通知
```

ListendおよびWebプロセスは停止しない。

---

## UC-08 ProviderをHoshikageへ戻す

ユーザー発話：

```text
「ねぇ、ヤタガラス。プロバイダをHoshikageに変更」
```

処理：

```text
SBERT Intent: provider.hoshikage
→ Codex app-serverのみ再起動
→ Hoshikage Providerでinitialize
→ 新Thread作成
→ 既定ローカルモデルを選択
```

---

## UC-09 Web画面からモデルを切り替える

Web画面上のボタンまたは選択欄から以下を切り替える。

```text
LOW
VISION
HIGH
GPT
```

Webからの切替要求も、音声と同じAgent状態へ反映する。

---

## UC-10 現在の構成を確認する

ユーザー発話：

```text
「ねぇ、ヤタガラス。今どのモデル？」
```

SBERTまたは専用状態確認Intentにより、LLMを呼び出さず状態を回答する。

応答例：

```text
「現在はHoshikageのQwen3.5-9B-Visionを使用しています」
```

---

## UC-11 Provider切替後も会話を継続する

Provider切替ではCodex Threadが新しくなる。

会話継続機能を有効にした場合、Agentが保持する会話要約または直近履歴を、新Threadへ引き継ぐ。

---

## UC-12 縮退運転

* Webが停止しても音声機能は継続する。
* マイクが利用できなくてもWebチャットは継続する。
* OpenAIへ接続できない場合はHoshikageへ戻せる。
* 高性能モデルのロードに失敗した場合は既定モデルへフォールバックできる。

---

## 8. 機能要件

# 8.1 listend

Listendは音声インターフェース兼、全体プロセスのスーパーバイザーを担当する。

必要な機能：

* WakeWord検出
* 録音
* VAD
* ReazonSpeech K2によるSTT
* SBERT Router呼び出し
* Agentへの通常会話送信
* Agentからの回答受信
* TTS処理
* Agent子プロセス起動
* Web子プロセス起動
* 子プロセス監視
* graceful shutdown
* 異常終了時の限定的な再起動
* Agent readiness確認
* Web readiness確認

Listendは、モデル切替やProvider切替の実処理を行わない。

SBERTが判定したIntentをAgentへ送信し、状態変更はAgentが担当する。

---

# 8.2 SBERT Router

SBERT Routerは、以下のIntentを決定論的に判定する。

### 既存Intent

* 身体操作
* Vision要求
* Skill実行
* 状態確認
* その他Yatagarasu固有操作

### 新規モデル切替Intent

```text
llm.low
llm.vision
llm.high
```

### 新規Provider切替Intent

```text
provider.hoshikage
provider.openai
```

### 新規状態確認Intent

```text
llm.status
provider.status
```

### 登録フレーズ例

```yaml
llm.low:
  - LLM LOW
  - エルエルエム ロー
  - 軽いモデルにして
  - 軽量モデルに変更
  - 高速なモデルにして

llm.vision:
  - LLM ビジョン
  - ビジョンモデルに変更
  - 画像が見えるモデルにして
  - カメラ用モデルにして

llm.high:
  - LLM High
  - エルエルエム ハイ
  - 高性能モデルにして
  - 賢いローカルモデルにして

provider.openai:
  - プロバイダをOpenAIに変更
  - OpenAIに切り替えて
  - GPTを使って
  - クラウドAIに切り替えて

provider.hoshikage:
  - プロバイダをHoshikageに変更
  - 星影に戻して
  - ローカルAIに戻して
  - ローカルモデルを使って
```

モデル切替およびProvider切替命令は、原則としてLLMへ送らず、SBERT RouterとAgentで完結させる。

---

# 8.3 yatagarasu-agent

Agentは常駐AI制御の中心を担当する。

必要な機能：

* Unixソケットサーバー
* Codex app-server起動
* Codexとのstdio JSON-RPC通信
* initialize
* thread/start
* turn/start
* delta転送
* Tool Call処理
* Thread管理
* Turn管理
* リクエストキュー
* メトリクス記録
* モデル状態管理
* Provider状態管理
* Codex再起動
* Provider切替
* 会話引継ぎ
* Health check
* エラー処理

---

# 8.4 モデルプロファイル管理

Agentはモデル名を直接Intentへ埋め込まず、論理プロファイルを持つ。

```yaml
llm_profiles:
  low:
    provider: hoshikage
    model: LFM
    supports_vision: false
    description: 軽量・高速会話用

  vision:
    provider: hoshikage
    model: unsloth-Qwen3.5-9B-Vision
    supports_vision: true
    description: Vision・標準会話用

  high:
    provider: hoshikage
    model: Gemma4-12B-MTP
    supports_vision: false
    description: 高性能ローカル推論用

  gpt:
    provider: openai
    model: configured-openai-model
    supports_vision: model-dependent
    description: 高難度クラウド推論用
```

モデル名の変更時に、SBERT辞書の修正を必要としない設計とする。

---

# 8.5 同一Provider内のモデル切替

Hoshikage内のモデル切替では、Codex app-serverおよびThreadを維持する。

Agentは次の`turn/start`でモデルを指定する。

```json
{
  "method": "turn/start",
  "params": {
    "threadId": "current-thread-id",
    "model": "Gemma4-12B-MTP",
    "input": [
      {
        "type": "text",
        "text": "質問本文"
      }
    ]
  }
}
```

要件：

* Codex app-serverを再起動しない
* Thread IDを維持する
* 次Turnから新モデルを利用する
* active_model_profileを更新する
* Web画面へ状態変化を通知する
* 音声で切替完了を通知する
* 切替処理自体ではLLMを呼び出さない

---

# 8.6 Provider切替

HoshikageとOpenAIの切替では、Codex app-serverを再起動する。

要件：

* Listendは再起動しない
* Webは再起動しない
* Agentプロセスは原則再起動しない
* Agent内部のCodex子プロセスだけを再起動する
* 切替中は状態を`switching`とする
* 新規Turnを一時的にキューへ保持する
* Codexを正常終了させる
* 新Provider指定でCodexを起動する
* initializeを実行する
* 新Threadを作成する
* 切替成功後にキュー処理を再開する
* 切替失敗時は旧Providerへの復旧を試みる
* 無限再試行を禁止する

---

# 8.7 Provider切替状態

Agentは以下の状態を管理する。

```text
ready
busy
switching_provider
restarting_codex
degraded
error
```

Provider切替中の問い合わせには、以下のようなイベントを返す。

```json
{
  "event": "provider_switch_started",
  "from": "hoshikage",
  "to": "openai"
}
```

```json
{
  "event": "provider_switch_completed",
  "provider": "openai",
  "model": "configured-openai-model"
}
```

---

# 8.8 会話コンテキスト引継ぎ

同一Provider内のモデル切替では、原則として同じCodex Threadを維持する。

Provider切替では新Threadとなるため、会話継続方法を段階的に実装する。

### 初期実装

* Provider切替時に新Threadを作成する。
* ユーザーへ会話文脈がリセットされることを通知する。

### 拡張実装

* Agentが直近の会話履歴を保持する。
* 切替前に会話要約を生成または再利用する。
* 新Threadの初期コンテキストへ要約を投入する。
* ユーザーから見て会話が継続している状態を実現する。

---

# 8.9 yatagarasu-web

Webプロセスは以下を提供する。

* Webチャット
* ストリーミング回答
* 会話履歴
* STT結果表示
* Agent状態表示
* Codex状態表示
* Hoshikage状態表示
* OpenAI状態表示
* 現在のProvider表示
* 現在のモデル表示
* モデル切替ボタン
* Provider切替ボタン
* Threadリセット
* TTFT表示
* 総応答時間表示
* Tool実行表示
* エラー表示
* カメラ画像表示
* 接続再試行

画面例：

```text
Provider: Hoshikage
Model: Qwen3.5-9B-Vision
Agent: Ready

[LOW] [VISION] [HIGH] [GPT]
[Hoshikage] [OpenAI]
```

音声操作とWeb操作は、同じAgent状態へ反映する。

---

## 9. IPC要件

ListendおよびWebからAgentへの通信にはUnixドメインソケットを使用する。

```text
$XDG_RUNTIME_DIR/yatagarasu/agent.sock
```

通信形式：

```text
Unix domain socket
＋ UTF-8
＋ JSONL
```

---

## 9.1 通常Turn

```json
{
  "id": "request-uuid",
  "type": "turn",
  "source": "voice",
  "session": "main",
  "text": "今何が見える？",
  "stream": true
}
```

---

## 9.2 モデル切替

```json
{
  "id": "request-uuid",
  "type": "model_switch",
  "profile": "vision",
  "source": "voice"
}
```

応答：

```json
{
  "id": "request-uuid",
  "event": "model_switch_completed",
  "profile": "vision",
  "provider": "hoshikage",
  "model": "unsloth-Qwen3.5-9B-Vision"
}
```

---

## 9.3 Provider切替

```json
{
  "id": "request-uuid",
  "type": "provider_switch",
  "provider": "openai",
  "source": "voice"
}
```

途中イベント：

```json
{
  "id": "request-uuid",
  "event": "provider_switch_started",
  "provider": "openai"
}
```

完了：

```json
{
  "id": "request-uuid",
  "event": "provider_switch_completed",
  "provider": "openai",
  "model": "configured-openai-model"
}
```

---

## 9.4 状態取得

```json
{
  "type": "status"
}
```

応答：

```json
{
  "type": "status",
  "ready": true,
  "agent_state": "ready",
  "provider": "hoshikage",
  "model_profile": "vision",
  "model": "unsloth-Qwen3.5-9B-Vision",
  "codex_pid": 12345,
  "thread_id": "019fb...",
  "active_turn": null,
  "queue_length": 0
}
```

---

## 10. 非機能要件

### 10.1 性能

* Codex app-serverは通常Turnごとに再起動しない。
* 同一Provider内モデル切替は、Codex再起動なしで完了する。
* モデル切替Intent処理はLLMを呼び出さない。
* モデル切替操作は原則1秒以内に状態反映する。
* Provider切替はCodex再初期化時間を含む。
* 通常会話のTTFT目標は3秒以内とする。
* 短い命令の総応答時間目標は5秒以内とする。
* 40 tokens/sec以上を会話用途の十分な目安とする。
* TTSは将来的に文単位ストリーミングへ対応する。

### 10.2 可用性

* Web障害時も音声機能を継続する。
* 音声障害時もWeb機能を継続する。
* Provider切替失敗時もListendとWebは生存する。
* Codex異常終了時はAgentがCodexのみ再起動する。
* 短時間の無限再起動を禁止する。

### 10.3 セキュリティ

* Webは初期状態でlocalhostへbindする。
* Unixソケットは利用ユーザーのみアクセス可能とする。
* OpenAIへの切替は明示的操作を必要とする。
* 意図しないクラウド送信を防ぐ。
* 現在のProviderをWebおよび音声で確認可能とする。
* APIキーをWebフロントエンドへ渡さない。
* WebからCodexおよびHoshikageへ直接接続させない。

### 10.4 保守性

* Listend、Agent、Webは独立プロセスとする。
* モデル名は設定ファイルへ分離する。
* SBERT Intentは論理プロファイルを返す。
* Provider切替ロジックはCodexProcess管理クラスへ集約する。
* IPC仕様は実装言語に依存しないJSONLとする。

---

## 11. 制約

* Codex app-serverとの通信はstdio JSON-RPCを使用する。
* HoshikageはOpenAI Responses API互換として動作する。
* Hoshikage内モデルは同一Providerとして扱う。
* Provider変更時にはCodex app-serverの再構成が必要となる。
* Provider変更時には新しいCodex Threadを作成する。
* 音声認識はReazonSpeech K2を基本とする。
* STT誤認識は文脈とYatagarasuの能力情報を用いて補正する。
* Yatagarasu本体はGPUなしの端末でも動作可能とする。
* LLM推論はLAN上のHoshikageへ委譲可能とする。

---

## 12. 対象外

初期リリースでは以下を対象外とする。

* 複数ユーザー認証
* インターネット公開
* スマートフォン専用アプリ
* 複数Turnの完全並列実行
* 複数Codex app-serverの常時並列運用
* LLMによる完全自動モデル選択
* 利用料金に基づく自動Provider変更
* 長期記憶基盤の全面刷新
* Provider間での完全なThread移送
* WebRTC音声通話

---

# 13. 実装フェーズと優先順位

## Phase 1：常駐Codex基盤

### 優先度：最優先

目的：

Codex起動コストを除去し、Agent化の基礎を完成させる。

実装範囲：

* `codex-server-test.py`の整理
* Codex app-server常駐
* initialize
* thread/start
* 複数turn/start
* stdoutイベントルーター
* deltaストリーム
* turn/completed
* graceful shutdown
* Codex PID維持確認
* TTFTおよび総応答時間計測

完了条件：

* 複数会話でCodex PIDが変化しない
* 同一Threadで文脈を維持できる

---

## Phase 2：yatagarasu-agent独立化

### 優先度：最優先

目的：

Codex制御をListendから分離し、共通Agentとして利用可能にする。

実装範囲：

* `yatagarasu-agent`プロセス
* Unixドメインソケット
* JSONLプロトコル
* Ping
* Status
* Turn
* Error
* リクエストキュー
* Thread管理
* Codex再起動
* stale socket処理
* 二重起動防止

完了条件：

* 外部クライアントからAgentへ質問できる
* Agent停止時にCodexが残存しない

---

## Phase 3：Listend統合

### 優先度：高

目的：

既存の音声処理を常駐Agentへ接続する。

実装範囲：

* ListendからAgentへSTT結果送信
* Agent回答の受信
* TTS連携
* Agent子プロセス起動
* Agent readiness確認
* Listend終了時のAgent停止
* systemdサービス一本化

完了条件：

* `listend.service`一つで音声Agentが動作する
* 従来の`codex exec`を使用しない

---

## Phase 4：Hoshikage内モデル動的切替

### 優先度：高

目的：

Yatagarasuの独自価値である、音声による思考ギア切替を実現する。

実装範囲：

* モデルプロファイル
* `active_model_profile`
* SBERT Intent追加
* `llm.low`
* `llm.vision`
* `llm.high`
* `turn/start.params.model`指定
* モデル切替完了通知
* 現在モデル確認
* モデル切替テスト
* 同一Thread文脈維持テスト
* Tool Call互換性テスト

完了条件：

* 音声でLOW、VISION、HIGHを切り替えられる
* Codex PIDが変化しない
* Thread IDが維持される
* 次Turnから指定モデルが使われる

---

## Phase 5：Web GUI

### 優先度：高

目的：

CLIを置き換え、Yatagarasuの状態と会話を可視化する。

実装範囲：

* `yatagarasu-web`
* FastAPI等のWebサーバー
* WebSocket
* チャット画面
* ストリーム表示
* Agent状態
* モデル状態
* Provider状態
* LOW、VISION、HIGHボタン
* Threadリセット
* TTFT表示
* 総応答時間表示
* STT結果表示
* ListendからWeb子プロセス起動

完了条件：

* ブラウザからAgentへ会話できる
* 音声とWebが同じAgent状態を共有する
* Web停止時も音声機能が継続する

---

## Phase 6：Provider動的切替

### 優先度：中高

目的：

音声およびWebから、HoshikageとOpenAIを切り替えられるようにする。

実装範囲：

* `provider.hoshikage`
* `provider.openai`
* Providerプロファイル
* Codex子プロセス停止
* Provider指定でCodex再起動
* initialize
* 新Thread作成
* Provider切替状態
* 切替中のTurnキュー
* 切替失敗時の復旧
* WebからのProvider切替
* 現在Provider確認
* OpenAI接続失敗処理
* 意図しないクラウド送信防止

完了条件：

* 音声でHoshikageとOpenAIを切り替えられる
* ListendとWebのPIDは変化しない
* AgentのPIDも原則変化しない
* Codex PIDだけが変更される
* 切替後に会話を再開できる

---

## Phase 7：Provider間会話継続

### 優先度：中

目的：

Provider切替時のThread断絶をユーザーから隠蔽する。

実装範囲：

* Agent側会話履歴
* 直近履歴保存
* 会話要約
* 新Threadへの要約投入
* Provider切替前後の文脈継続テスト
* 履歴注入上限
* プライバシー設定

完了条件：

* HoshikageからOpenAIへ切り替えた後も、直前の会話を参照できる
* OpenAIからHoshikageへ戻した場合も同様に継続できる

---

## Phase 8：音声体験および管理機能の高度化

### 優先度：中

実装範囲：

* 文単位ストリーミングTTS
* Provider切替中の音声ガイダンス
* モデルロード中の状態表示
* Tool実行状況表示
* カメラ画像表示
* モデル別速度測定
* Hoshikage推論メトリクス表示
* エラー履歴
* Web管理画面
* モデルプロファイル編集

---

## Phase 9：将来の自動ルーティング

### 優先度：低・研究枠

ユーザーが明示的に選択する現行方式を維持しつつ、将来的に以下を検討する。

* Vision要求時の自動Visionモデル選択
* 難問判定時のHigh提案
* OpenAI利用の提案
* コスト上限
* プライバシーポリシー
* 自動切替ではなくユーザー確認付き提案
* SBERT、ルール、メタデータによるハイブリッド選択

初期段階では、LLMによる自動Provider変更は行わない。

---

## 14. 優先順位の根拠

実装順は以下の考え方に基づく。

### 第一優先：Codex常駐化

既に速度改善効果が確認されており、全機能の基礎となる。

### 第二優先：Agent分離とListend統合

音声、Web、将来クライアントの共通入口を先に確立する。

### 第三優先：Hoshikage内モデル切替

Codex再起動を必要とせず、比較的低リスクでYatagarasu独自の価値を実現できる。

### 第四優先：Web GUI

ユーザビリティを大幅に改善し、モデル状態やエラーを可視化できる。

### 第五優先：Provider切替

高い差別化価値を持つ一方、Codex再起動、Thread再生成、失敗復旧が必要なため、基盤完成後に実施する。

### 第六優先：Provider間の文脈継続

Provider切替そのものを先に完成させ、その後ユーザー体験を高度化する。

---

## 15. 受け入れ条件

以下を満たした場合、Agent化の主要開発を完了とみなす。

1. `listend.service`一つでListend、Agent、Web、Codexが起動する。
2. 通常TurnごとにCodexが再起動しない。
3. 音声とWebが同じAgentを利用する。
4. 複数Turnで会話文脈を維持できる。
5. Web画面へ回答をストリーミング表示できる。
6. 音声でLOWモデルへ切り替えられる。
7. 音声でVISIONモデルへ切り替えられる。
8. 音声でHIGHモデルへ切り替えられる。
9. 同一Provider内モデル切替でCodex PIDが変化しない。
10. 同一Provider内モデル切替でThreadを維持できる。
11. Web画面からモデルを切り替えられる。
12. 音声でOpenAI Providerへ切り替えられる。
13. 音声でHoshikage Providerへ戻せる。
14. Provider切替時にListendとWebが停止しない。
15. Provider切替時はCodexだけが再起動される。
16. Provider切替失敗時にAgent全体が無限再起動しない。
17. 現在のProviderおよびモデルを音声で確認できる。
18. 現在のProviderおよびモデルをWebで確認できる。
19. Web停止時も音声機能を利用できる。
20. 音声機能停止時もWebチャットを利用できる。
21. Agent停止時にCodexプロセスが残存しない。
22. stale socketから復旧できる。
23. Agent二重起動を防止できる。
24. TTFTおよび総応答時間を記録できる。
25. 意図しないOpenAIへの送信が発生しない。

---

## 16. 完成時の最終構成

```text
systemd
└─ listend.service
   └─ listend
      ├─ WakeWord
      ├─ Recording
      ├─ ReazonSpeech K2
      ├─ SBERT Router
      │  ├─ Skill Routing
      │  ├─ Model Routing
      │  └─ Provider Routing
      │
      ├─ yatagarasu-agent
      │  ├─ Agent State
      │  ├─ Model Profile
      │  ├─ Provider Profile
      │  ├─ Thread Manager
      │  ├─ Turn Manager
      │  ├─ Tool Dispatcher
      │  └─ Codex app-server
      │       ├─ Hoshikage
      │       │  ├─ LFM
      │       │  ├─ Qwen3.5-9B-Vision
      │       │  └─ Gemma4-12B-MTP
      │       │
      │       └─ OpenAI
      │          └─ GPT
      │
      └─ yatagarasu-web
         ├─ Web Chat
         ├─ Model Selector
         ├─ Provider Selector
         ├─ Status
         └─ Metrics
```

---

## 17. 最終的なプロダクト定義

Yatagarasuは、AIモデルを一つ搭載したロボットではない。

Yatagarasuは、音声およびWebから、身体、Skill、Vision、LLMモデル、推論Providerを動的に選択できる常駐AIロボット基盤である。

普段はローカルAIを利用し、画像認識時にはVisionモデルへ切り替え、高度な推論が必要な場合には高性能モデルまたはOpenAI GPTへ切り替える。

これらの選択を、LLMへ委ねるのではなく、SBERT Routerによる高速かつ決定論的な自然言語操作として提供する。

```text
「右を向いて」
「今何が見える？」
「LLM LOW」
「LLMビジョン」
「LLM High」
「プロバイダをOpenAIに変更」
「プロバイダをHoshikageに変更」
```

Yatagarasuは、ユーザーがAIへ命令するシステムから、ユーザーがAIの脳構成そのものを操作できるシステムへ進化する。
