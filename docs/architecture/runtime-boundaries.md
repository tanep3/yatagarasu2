# ランタイム境界 — 意味の分割と配置の分割を混同しない

## Domain境界とprocess境界は別である

Domain境界は、何を意味ある状態として扱い、誰が所有し、どの法則で変えるかという設計判断です。process境界は、それを同じプロセス、別プロセス、別マシンのどこへ配置するかという運用判断です。

責務を分けたからといって、必ず別プロセスにする必要はありません。逆に、別プロセスで動いているだけでは、責務が分かれたことにはなりません。IPC方式やサービス数は計測後に選べますが、状態所有とドメイン契約は配置によって変えません。

## 依存方向

```text
domain <- application <- ports <- adapters
                     \- bootstrapが具体実装を組み立てる
```

依存を内側へ向ける理由は、カメラ、マイク、GPU、Provider、通信方式を交換しても、世界の法則を変えないためです。

- Domainは製品、通信、filesystem、network、clock、microphone、camera、GPU、Providerを知りません。
- ApplicationはDomainの値と抽象Portを使いますが、具体製品名を知りません。
- Adapterは外部表現とPortの値を相互に翻訳します。
- Bootstrapだけが、どのAdapterをどのPortへ結ぶかを決めます。

通信schemaをDomain型にすると、配置の都合が世界の意味へ混ざります。これを禁止します。

## 音声入力 — WakeWordとMimyを分ける

Yata Wakeは、Mimyの外側に置くYatagarasuのWakeWord Adapterです。Mimyは、入力元に依存しない汎用STT能力です。

```text
Audio Source
  ├─ Yata Wake -> wake候補
  └─ Mimy      -> VAD / STT結果

Acoustic Context
  -> wake受理とpromptの生存期間を所有
  -> 必要なMimy sessionの作成・解放を要求
```

go2rtc、PCのマイク、エッジデバイスはAudio Source Adapterの候補です。Mimyへgo2rtcを直結する構成を必須にしません。Yata WakeとMimyは、それぞれの接続・buffer状態を所有してよい一方、Interaction、会話、計画、Provider、WorldStateを所有しません。

一つの物理マイクを複数が読む場合はfan-outが必要です。すべてのAdapterが同時に独立消費できると仮定しません。具体的なbuffer、API、IPCは未決です。

通常のWakeWordと、活動中に割り込むHome／Stop制御語は意味を分けます。検知実装を共有しても、Home制御語は通常Behavior routingの候補なしfallbackへ流さず、共通の`ReturnToHomeRequested`へ変換します。文字起こし等がマイク入力を利用中でも、この制御経路は自律神経として生存します。

## Webは公開APIを使う身体面である

Web Gatewayは、標準Web画面だけの特権的な司令塔ではありません。標準画面、利用者HTML／CSS、将来の外部clientは、認証された公開APIから共通Command／Query境界へ入ります。公開APIは内部Effect、Adapter、Providerへ直接接続しません。

Webへの状態同期は、現在Projectionとrevision、その後の更新で構成します。Web切断はActive Qualiaを終了せず、再接続時は現在Projectionから再同期します。live映像・音声は状態更新と異なるtransportに配置できます。具体方式はprocess境界と同じく技術検証後に決めます。

初期運用単位は一Server、一Workspace、一Ownerです。複数browser、access token、cameraは同じOwnerの接続・身体能力であり、別Qualiaや別Workspaceを意味しません。

## 外部能力、Python worker、Provider

Python推論workerや外部能力は、Portを通じて型付き要求を受け、型付き観測、Proposal、Failureを返します。WorldState、Effect Graph、Provider状態、会話状態を所有しません。

Hoshikageからは、稼働確認と受付可能性の分離、能力広告、待ち行列受付失敗と推論失敗の分離、stream終端と切断の分離、secretの伏せ字、世代・貸出し管理といったProvider境界の候補を学びます。ただし、具体Providerの内部契約やルーティング、同意、privacy、transportはまだY2の決定ではありません。

Yatagarasu 2は、SBERTとDecision Policyにより論理LLM／Provider profileを動的選択します。これは必須の製品能力です。一方、同一Provider内のmodel指定、Provider process再構成、active turnの扱い、会話の再bindingはAdapter／運用契約であり未決です。preferred routeとeffective route、能力広告、選択根拠は型付き値として観測可能にします。

## Skillと人間のアプリ

Skillは、AIが人間のアプリ、データ、機能へ触れるための接続面です。外部能力を何でもSkillと呼ぶわけでも、Skillを一つのprocessやtransportへ固定するわけでもありません。

人がWeb UIから操作するアプリと、AIがSkillから利用する能力は、同じアプリ所有の世界へ異なる入口から関われます。Yatagarasu Coreはそのアプリの内部状態を奪いません。必要な観測、Proposal、Effect、結果Eventを境界越しに交換します。

Skillを追加してもKernelへ製品固有の分岐を追加しません。Skillが返したAI由来の行動提案は、必ずPolicy検証を通ります。具体的なSkill形式、transport、認証・認可、Skill作成時の検証、配備、rollback、安全方針は今後の契約です。

## 音声出力と取消

ストリーミングTTSの採用と優先度はOPENです。採用する場合は、文区切り、並列音声生成、順序付き再生、上限付きqueue、逆圧、取消後chunk、成果物削除を、Effect Graphと結果Eventで扱います。

`PlaybackCompletionAssumed`（再生完了の仮定）は、再生Adapterの開始EventをCoreが受理した後、音声時間と余裕時間から導きます。音が実際に聞こえたという観測ではありません。go2rtc sessionの維持方法、数値、停止能力は未決です。

Webを含むすべての入力Adapterは、共通の`CancelRequested` Commandとして取消要求を入れられます。取消を受理した事実は`CancellationAccepted` Eventとして別に返します。物理移動は送信後に止められないことがあります。その場合は後続仕事を取り消し、遅い結果を記録します。voice stopは、LLM、待機TTS、再生queue、現在chunkのうちAdapterが対応する対象だけへ要求し、未対応の停止を成功扱いしません。

## 将来の自律入力

cronなどの定時自律は将来の作業です。第二の制御中枢にはしません。導入時は、音声やWebと同じCommand/Event境界へ入るInbound Adapterとし、同じPolicyと世界の法則を通します。
