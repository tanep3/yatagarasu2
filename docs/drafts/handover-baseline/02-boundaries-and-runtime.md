# Boundaries and Runtime

## 1. Ports and Adapters

Coreが必要とする能力はProtocolとして定義する。

### Inbound Ports

- `InteractionCommandPort`
- `CancellationPort`
- `AdministrationPort`
- `QueryPort`

### Outbound Ports

- `IntentClassificationPort`
- `CameraControlPort`
- `ImageCapturePort`
- `AgentPort`
- `MemoryPort`
- `SpeechSynthesisPort`
- `AudioPlaybackPort`
- `ArtifactStorePort`
- `EventJournalPort`
- `ClockPort`

Adapter例:

```text
CameraControlPort
  -> TapoOnvifAdapter
  -> SimulatedCameraAdapter

AgentPort
  -> CodexCliAdapter
  -> HoshikageResponsesAdapter
  -> ClaudeCodeAdapter
  -> FakeAgentAdapter
```

MainはAdapterを選択して依存を組み立てるだけにする。
Capability固有の条件分岐をMainへ書かない。

## 2. Gateway

### 2.1 Voice Gateway

現行`listend`から次を継承する。

- Audio capture
- VAD
- Wake word
- Wake acknowledgement
- Utterance segmentation
- STT
- Self-audio suppression

Voice GatewayはIntent判定、Skill実行、LLM呼び出し、記憶保存を行わない。

### 2.2 Web Gateway

- 静的Web UI配信
- HTTP command受付
- WebSocketまたはSSEによるProjection配信
- 認証と接続管理

Web GatewayはInteractionを実行しない。

### 2.3 CLI Gateway

`yatagarasu "右を向いて"`はDaemonへCommandを送信し、Projection上の完了を待つ。

CLIだけが別の実行経路を持つことは禁止する。
テスト用のin-process実行は同じCoreを同じEvent列で駆動する。

## 3. Runtime Kernel

Kernelは単一WriterとしてWorldStateを更新する。

```text
Event Inbox
    -> Rule Evaluation
    -> Transition Apply
    -> Event Journal
    -> Effect Outbox
```

Effect実行は非同期でも、State更新は順序付けされたEvent Loopで行う。
これによりlockをCore全体へ散らさずに済む。

## 4. Outbox

Transition適用とEffect配送の間でprocessが停止すると、状態だけ進んでEffectが失われる可能性がある。

そのため、永続化が必要な構成では次を同一transactionへ記録する。

- 受理Event
- 新しいStateまたはState再構築用Event
- 発行予定Effect

Effect DispatcherはOutboxから未配送Effectを取得する。

初期プロトタイプではin-memoryでもよいが、型と境界はOutboxを導入できる形に保つ。

## 5. Idempotency

すべてのEffectに`EffectId`と`idempotency_key`を与える。

ただし、物理Effectは完全な冪等性を保証できない。

例:

- `CaptureImage`: 同じEffectIdなら既存Artifactを再利用できる
- `RecallMemory`: 再実行可能
- `AskAgent`: 応答cacheにより重複を避けられる
- `MoveCamera(relative=RIGHT)`: 再実行すると二重移動するため危険

物理Effectでは、失敗を次のいずれかへ分類する。

```text
DefinitelyNotApplied
Applied
OutcomeUnknown
```

`OutcomeUnknown`を安易に自動再試行しない。
必要なら観測、校正、ユーザー確認をPlanへ追加する。

## 6. Failure as Data

例外文字列をstderrから解析して判断しない。

```python
EffectFailure = (
    Timeout
    | Unavailable
    | Rejected
    | InvalidRequest
    | AuthenticationFailed
    | OutcomeUnknown
    | InternalFailure
)
```

Failure Ruleが次のTransitionを生成する。

- Retry
- Fallback
- Skip
- Compensate
- FailInteraction
- AskUser

再試行方針も値としてEffectへ付与する。

## 7. Time

Coreで`time.sleep()`しない。

待機は`StartTimer` Effectと`TimerElapsed` Eventで表す。

カメラ移動後の1秒待機:

```text
CameraMoveCompleted
    -> StartTimer(duration=1s, purpose=motion_settle)
    -> TimerElapsed
    -> CaptureImage becomes ready
```

テストではFake Clockを進めるだけで検証できる。

## 8. Concurrency

### 8.1 Interaction Queue

最初は一件ずつ処理するPolicyを推奨する。
ただし「単一Workerのwhile loop」へ固定せず、`ConcurrencyPolicy`として表現する。

```python
ConcurrencyPolicy(
    max_active_interactions=1,
    queue_limit=8,
    overflow=RejectNewest,
)
```

### 8.2 Effect Concurrency

一つのInteraction内でも、依存がなくResourceが競合しないEffectは並行実行できる。

例:

```text
MoveCamera ----\
                -> Capture -> AskAgent
RecallMemory --/
```

実際にはCaptureはMove完了を待つが、RecallはMoveと並行できる。

### 8.3 Cancellation

取消はprocess killではなく`CancelInteraction` Commandとして扱う。

各Effectは次の取消特性を宣言する。

- `Cancellable`
- `FinishThenCancel`
- `NotCancellable`

## 9. Event Journal and Recovery

Event Journalを導入すると、次が可能になる。

- Web画面の履歴再構築
- 障害原因の時系列確認
- レイテンシ分析
- State replay
- テストケース生成

ただし、Replayは外部Effectを再実行しない。
Journal EventからStateとProjectionだけを再構築する。

起動時に未完了Interactionがある場合はRecovery Ruleを適用する。

```text
Running effect with no terminal event
    -> mark OutcomeUnknown
    -> reconcile or fail safely
```

初期保存先はSQLiteが適する。
単一Writer、transaction、配布容易性、運用の軽さがYatagarasuに合う。

## 10. Observability

ログ文ではなくEventを観測の一次情報にする。

全Eventに次を持たせる。

- `event_id`
- `occurred_at`
- `interaction_id`
- `causation_id`
- `correlation_id`
- `source`

これにより、音声検出から応答までを一本の因果列として追跡できる。

主要指標:

- wake detection latency
- STT latency
- routing latency
- camera movement latency
- capture latency
- memory recall latency
- first agent response latency
- speech completion latency
- end-to-end latency

## 11. Security

- Web Gatewayは既定でlocalhost bind
- LAN公開は明示設定とToken認証を要求
- SecretをEvent、Projection、Prompt、Journalへ保存しない
- AdapterがSecret Storeから資格情報を取得する
- Webから任意shell commandを受け取らない
- CapabilityとCommandをallow-list型で定義する

## 12. Configuration

`.env`は入力形式であり、アプリケーション内部の設定APIではない。

起動時に一度だけ読み込み、型付きの不変`RuntimeConfig`へ変換する。

```python
@dataclass(frozen=True)
class RuntimeConfig:
    acoustic: AcousticConfig
    routing: RoutingConfig
    execution: ExecutionConfig
    adapters: AdapterConfig
```

Coreで`os.getenv()`を呼ばない。

設定変更は次のいずれかにする。

- restartで新しいConfigを構築
- 検証済み`Reconfigure` Commandから新しいConfig Stateへ遷移

初期版はrestart方式を推奨する。

## 13. Model Residency

STT、SBERT、LLMなどのモデル常駐もResource Contextとして表現できる。

```text
Absent
Loading
ResidentInRAM
ResidentInVRAM
Evicting
Failed
```

保持時間はAdapter内部の裸のtimerにせず、Residency Policyとして値にする。

```python
ResidencyPolicy(
    vram_idle_ttl=Duration(minutes=5),
    ram_idle_ttl=Duration(minutes=30),
)
```

モデルのロード、VRAM退避、RAM解放はEffectであり、完了結果はEventになる。
Web GUIはProjectionから現在のResident状態を表示できる。

## 14. Deployment Shape

### Phase A: Modular Monolith

```text
yatagarasud
  - Runtime Kernel
  - Voice Gateway
  - Web Gateway
  - Effect Adapters
  - SQLite
```

論理境界を保ちながら、運用とデバッグを簡単にする。

### Phase B: Optional Process Isolation

```text
voice-gateway --\
web-gateway ----- event protocol -> yatagarasu-core
effect-worker ---/
```

CPU負荷、GPU配置、障害分離が必要になったContextだけを分離する。

分割を前提に複雑にしない。
同時に、分割不能な密結合にも戻さない。

## 15. Suggested Source Shape

確定案ではないが、論理構造をfilesystemにも反映する。

```text
src/yatagarasu2/
  domain/
    state.py
    events.py
    commands.py
    effects.py
    transitions.py
    rules/
    planning/
  application/
    kernel.py
    scheduler.py
    policies.py
    projections.py
  ports/
    inbound.py
    outbound.py
  adapters/
    voice/
    web/
    cli/
    camera/
    agent/
    memory/
    speech/
    persistence/
  bootstrap/
    config.py
    wiring.py
```

`domain`は`adapters`へ依存しない。
`application`は具体的な外部製品名を知らない。
`bootstrap`だけが具体Adapterを組み立てる。
