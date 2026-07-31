# Configuration, Workspace and Capability Operations

- 文書状態: Discussion Draft
- 作成日: 2026-07-31
- 対象: Yatagarasu 2の導入、設定、Workspace、外部Capability運用

## 1. 目的

Yatagarasu 1は、go2rtc、VOICEVOX ENGINE、SearXNG、SemanticMemory、ReazonSpeech、
LiveKit WakeWord、Hoshikageなど、複数の製品とサービスを組み合わせて価値を実現した。

一方、利用者が各製品を個別に導入し、`.env`へ多数のURL、モデル名、閾値を記述する方式は、
高い参入障壁になる。

Yatagarasu 2では次を実現する。

1. 利用者には一つの製品として見せる。
2. 開発者には交換可能なCapabilityとAdapterとして見せる。
3. Dockerを必須にしない。
4. Capabilityを同一PCとLAN内サーバーのどちらにも配置できる。
5. Web GUIから安全に設定、診断、状態確認を行える。
6. 設定、ユーザー資産、実行状態、Cacheを混在させない。

## 2. Workspace方針

### 2.1 単一固定ディレクトリへすべてを入れない

`~/.config/yatagarasu2`を従来Workspace全体の代替にはしない。
XDG Base Directoryの役割に沿って配置する。

```text
~/.config/yatagarasu2/
├─ config.toml
├─ secrets.toml
└─ profiles/
   └─ default.toml

~/.local/share/yatagarasu2/
├─ workspaces/
│  └─ default/
│     ├─ AGENTS.md
│     ├─ skills/
│     └─ media/
├─ models/
└─ artifacts/

~/.local/state/yatagarasu2/
├─ events.db
├─ conversations.db
└─ logs/

~/.cache/yatagarasu2/
└─ model-cache/

$XDG_RUNTIME_DIR/yatagarasu2/
├─ runtime.sock
└─ temporary-files/
```

### 2.2 標準Workspace

- 初回セットアップで`default` Workspaceを作成する。
- 一般利用者はWorkspaceパスを指定しなくても動作できる。
- `AGENTS.md`、追加Skill、人格設定、ユーザーMediaはWorkspaceで編集できる。
- 配布Defaultとユーザー変更を分け、Upgradeでユーザー変更を上書きしない。

### 2.3 Profile

初期UIは一つの`default` Profileだけを見せてよい。
内部構造は、将来の複数ロボット、複数カメラ、検証環境へ対応できるようProfileを持つ。

`listend`またはVoice GatewayはWorkspaceを所有しない。
現在のProfileとWorkspaceはYatagarasu Runtimeが所有する。

## 3. 設定形式

### 3.1 `.env`を主設定にしない

Yatagarasu 2の主設定は型付き`config.toml`とする。
環境変数はsystemd、CI、診断、一時的上書きのための入力手段として残す。

```toml
[robot]
name = "ヤタガラス"
workspace = "default"

[camera]
profile = "c210"

[voice]
speaker_id = 13

[agent]
preferred_model = "low"
provider = "hoshikage"

[capabilities.stt]
implementation = "mimy-stt"
mode = "remote"
endpoint = "http://stt-server:8088"
```

### 3.2 優先順位

```text
組込みDefault
-> system config（任意）
-> user config.toml
-> active Profile
-> environment override
-> CLI override
```

各設定値は、現在値だけでなく、どのLayerから採用されたかを診断できるようにする。

### 3.3 Secret

- API Token、カメラ資格情報を通常の`config.toml`から分離できる。
- `secrets.toml`を使用する場合はmode `0600`を要求する。
- SecretをWeb Projection、Event Journal、Prompt、ログへ含めない。
- Web GUIは保存済みSecretを再表示しない。
- 将来はsystemd credentialなどのSecret Storeへ交換可能にする。

## 4. Web GUIによる設定変更

Web Gatewayは設定ファイルを直接編集しない。

```text
Web Form
-> UpdateConfiguration Command
-> Schema validation
-> Safety validation
-> Atomic write
-> ConfigurationChanged Event
-> Hot reloadまたはRestartRequired
```

設定項目は次の属性を持つ。

```text
scope
value_type
default
validation
secret
read_only
apply_mode
```

`apply_mode`候補:

- `immediate`: 即時反映
- `restart_adapter`: 対象Adapterだけ再起動
- `restart_runtime`: Yatagarasu Runtime再起動
- `next_interaction`: 次のInteractionから反映

GUIは変更前後と反映方法を表示する。失敗時は壊れた設定を保存しない。

## 5. Capability配置モデル

Capabilityの実行場所はアーキテクチャではなく、利用者が選択する配置設定である。

```text
local-managed
  このPCへYatagarasuがNative導入し、起動と監視を行う

remote
  LAN内または外部サーバーのAPIへ接続する

disabled
  使用しない
```

Docker Containerを標準管理単位にはしない。
将来Container Adapterを追加することは妨げないが、一般利用者へDockerを要求しない。

### 5.1 Capability Binding

```toml
[capabilities.memory]
implementation = "semantic-memory"
mode = "remote"
endpoint = "http://memory-server:6001"

[capabilities.tts]
implementation = "voicevox"
mode = "remote"
endpoint = "http://voice-server:50021"

[capabilities.search]
implementation = "searxng"
mode = "disabled"
```

CoreはURLや製品名から分岐しない。Bootstrapが設定からPortへAdapterをBindingする。

### 5.2 Local Managed Service

`local-managed`では、Yatagarasu Setupが次を担当する。

- 対応バージョンとライセンスの提示
- Native binaryまたはPython仮想環境の導入
- 公式Modelの取得とchecksum検証
- 設定生成
- 起動、Health Check、限定的再起動
- Upgrade前の互換性確認
- Uninstall時にユーザーデータを勝手に削除しない

Voice Gatewayが子Serviceを管理しない。
単一systemd unit構成では`yatagarasud`のRuntime SupervisorがLocal Workerを管理する。

### 5.3 Remote Service

- Endpoint、認証、Timeoutを設定する。
- 接続時にHealthとCapabilitiesを照合する。
- 期待するAPI version、機能、モデルがない場合は明示的に拒否または縮退する。
- LocalからRemoteへの切替でDomain処理を変更しない。
- Remote障害時にLocalへ自動送信するかはPrivacy Policyで明示する。

## 6. 初期Capability方針

| Capability | 実装候補 | 配置候補 | 必須性 |
|---|---|---|---|
| Camera stream | go2rtc | local-managed / remote | 必須 |
| WakeWord | LiveKit WakeWord | Yatagarasu Voice Gateway | 音声利用時に必須 |
| STT | Mimy STT Server | local-managed / remote | 音声利用時に必須 |
| Intent embedding | Ruri v3 | local-managed Worker | 必須 |
| TTS | VOICEVOX ENGINE | local-managed / remote | 音声応答時に必須 |
| Memory | SemanticMemory | local-managed / remote / disabled | 任意 |
| Search | SearXNG | local-managed / remote / disabled | 任意 |
| Local agent | Hoshikage | remote / disabled | Provider選択による |
| Cloud agent | OpenAI | remote / disabled | 任意 |

### 6.1 Mimy STT Server

STTはYatagarasu 2本体から分離し、独立したMimy STT Serverを使用する。

- Mimyがgo2rtcへ直接接続する。
- Yatagarasuは音声をMimyへ転送しない。
- MimyはSource接続とリングバッファを常時維持する。
- WakeWord検出時にheld Listen Sessionを作成する。
- 「はい」の再生完了後にSessionをReleaseする。
- Mimyは次の発話をVADで取得し、Transcript Eventを返す。
- 同一PCとLAN内別PCで同じAPIを使用する。

Mimy repository:

- https://github.com/tanep3/Mimy-STT-Server

### 6.2 自作プロジェクトの扱い

- `zunda`: 必要な振る舞いをSpeech Adapterへ統合する方向を検討する。
- `SemanticMemory`: 独立repositoryを正とし、Yatagarasu Adapterと対応Versionを管理する。
- `Hoshikage`: 独立Providerとして維持し、Yatagarasuへコードを複製しない。
- 専用改造はforkの常態化ではなく、Adapter、Profile、upstream変更で解決する。

Yatagarasu repositoryへ包含するのは、外部プロジェクトの複製ではなく、互換Version、設定、
Installer、Adapter、Health Checkである。

## 7. Capability状態と縮退

Capabilityは存在する／しないの真偽値ではなく、状態を持つ。

```text
Unconfigured
Installing
Starting
Ready
Degraded
Unavailable
Incompatible
Stopping
```

任意Capabilityの障害でYatagarasu全体を停止しない。

例:

- Search停止: 通常会話とロボット操作を継続
- Memory停止: 記憶なしで会話を継続し、状態を表示
- Remote Hoshikage停止: 明示許可された別Providerだけを候補にする
- STT停止: Web Chatを継続
- Web停止: 音声Interactionを継続

`doctor`とWeb Projectionは、状態、配置場所、Version、Latency、最終Failureを表示する。

## 8. systemdとProcess管理

一般利用者が登録するuser systemd unitは原則一つとする。

```text
yatagarasu2.service
└─ yatagarasud
   ├─ Runtime Kernel
   ├─ Web Gateway
   ├─ Voice Gateway
   └─ local-managed workers
```

- `listend`を親Supervisorにしない。
- Remote CapabilityはProcess Treeへ含めない。
- 子ProcessのCrash回数に上限とBackoffを持たせる。
- Runtime終了時に管理対象子Processを残存させない。
- 個別Workerの障害をRuntime全体の即時終了理由にしない。

## 9. セットアップ体験

目標操作:

```text
yatagarasu2 setup
```

SetupはローカルWeb UIまたは対話CLIを開き、次を案内する。

1. 標準WorkspaceとProfileを作成する。
2. カメラとgo2rtcへ接続する。
3. STTをこのPCで動かすか、Mimy Serverへ接続するか選ぶ。
4. VOICEVOXをこのPCで動かすか、既存Serverへ接続するか選ぶ。
5. Agent Providerを設定する。
6. MemoryとSearchを任意選択する。
7. 必要なNative ServiceとModelを導入する。
8. Health、音声、カメラ、推論を順に試験する。
9. user systemdを登録して起動する。
10. WakeWordから一連の受入試験を行う。

一般画面では内部製品名を必要以上に見せない。

```text
音声認識の実行場所
  このPCで動かす
  既存サーバーへ接続

長期記憶
  使用する
  使用しない
```

Advanced画面でのみEndpoint、Engine、Timeout、Modelなどを編集する。

## 10. UpgradeとMigration

- Config schemaにVersionを持たせる。
- Upgrade前にConfigとState DBをBackupする。
- MigrationはDry Runと変更一覧を提供する。
- ユーザーWorkspaceとSecretをUpgradeで上書きしない。
- 外部Capabilityは対応Version範囲を持つ。
- Model更新をアプリ更新と分離できる。
- Rollback時に互換性のないStateを黙って読み込まない。

## 11. 受け入れ条件

1. `.env`を手編集せず、標準構成をセットアップできる。
2. 標準Workspaceを自動作成できる。
3. Web GUIで設定値と採用元Layerを確認できる。
4. Web GUIで検証済みの設定変更ができる。
5. Mimy、VOICEVOX、SemanticMemoryをLocal／Remoteから選択できる。
6. Remote Mimyがgo2rtcから直接取得した音声を認識できる。
7. Remote Capability障害時も利用可能な機能を継続できる。
8. Secretがログ、Event、Web応答へ漏れない。
9. user systemd unit一つで標準Local構成を起動・停止できる。
10. UpgradeでユーザーWorkspaceと設定を失わない。

## 12. 未決事項

1. `local-managed` Workerを子Process、transient unitのどちらで管理するか。
2. go2rtcのNative導入方法と対応Platform。
3. VOICEVOX ENGINEの配布条件、対応Architecture、Model容量。
4. SearXNGをNative管理対象に含めるか、Remote推奨にするか。
5. Web GUIを初回Setup前にどう起動するか。
6. LAN CapabilityのService Discoveryを導入するか。
7. LAN通信でTLSを必須化する段階。
8. Capabilityごとの自動FallbackとPrivacy確認方法。
