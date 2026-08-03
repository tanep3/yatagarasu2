# 用語集

本文では、英語だけで意味が伝わりにくい語に日本語を添えます。この表は訳語を統一し、同じ構造を別の言葉で重複して作ることを防ぎます。

| 用語 | このプロジェクトでの意味 |
| --- | --- |
| WorldState（世界状態） | 判断時点でCoreが知っている状態の集合。すべての外部データを持つ巨大な袋ではない。 |
| Context（文脈境界） | 一つの意味領域と、その状態を唯一所有する境界。processとは限らない。 |
| Qualia（クオリア） | Yatagarasuが現在どの振る舞いとして世界を知覚し活動しているかを表す製品状態。現在の非Home sessionは全体で0または1。 |
| Home（基本待受） | 現在の非Home qualia sessionがない状態。すべての物理作用が観測済みという意味ではない。 |
| Y2 Behavior（振る舞い） | domain/application/ports/adaptersへ寄与するversion付きrobot機能。Codex Skillや単なる外部fileではない。 |
| 自律神経 | Home／Stop検知、永続化、Recovery、診断、認証、Web同期など、Qualiaを支えて並行稼働する基盤機能。第二のQualiaではない。 |
| Command（要求） | 受理、拒否、確認要求の対象となる依頼。まだ起きた事実ではない。 |
| Event（事実） | 過去に起きたことを表す不変値。結果Eventも含む。 |
| CancelRequested（取消要求） | 共通Inbound境界へ入るCommand。取消が受理された事実ではない。 |
| CancellationAccepted（取消受理） | Interaction Contextが取消を受理したことを表すEvent。外部処理や物理動作の停止証拠ではない。 |
| Interaction request-idempotency ledger（Interaction要求冪等性台帳） | Interaction Contextが唯一所有する耐久記録。API client key、payload fingerprint、replay可能な型付きresult、status、lifecycleを持ち、Rejected、AcceptedNoEffect、Pending、Completedを再起動後も区別する。EffectOccurrence pending recordではない。 |
| Rule（規則） | StateとEventをI/Oなしで評価する純粋な法則。 |
| Transition（遷移） | 内部Stateを次のStateへ決定論的に変える変換。 |
| Decision（決定） | Ruleが返す、TransitionとEffect Graphを含み得る判断値。 |
| Effect（外部作用） | 外界へ依頼する仕事を表す不変値。作成は実行や成功を意味しない。 |
| EffectOccurrence（外部作用出現） | Effect Graphの一頂点を表す一意な不変identity。同値のEffectが複数回必要でも別の出現・結果・監査記録にする。 |
| Effect Graph（外部作用グラフ） | Effect間の因果依存、guard、資源要求を表す構造。逐次手順書ではない。 |
| Proposal（提案） | LLMや外部能力が返す、まだPolicyで許可されていない実行候補。 |
| Policy（方針） | 候補や提案を受理、拒否、確認、合成する版付きの判断基準。 |
| Contributor（候補提供者） | SBERT、純粋Rule、LLMなど、意味解決へ候補や材料を寄与するもの。 |
| Candidate（意味候補） | Contributorが返す、scoreと出所を持つ未解決の候補。Command、Decision、Effectではない。 |
| Capability Catalog（能力目録） | 利用可能な候補種別、能力広告、Proposal schema、Effect型を発見する目録。意味の正解やStateを所有しない。 |
| logical profile（論理プロファイル） | 速度重視、画像理解、高性能推論など、具体的なモデル名・Provider名から分離した能力選択単位。 |
| preferred / effective route（希望／実効経路） | 利用者・Policyが希望したrouteと、configured authorization・可用性を評価してdispatch前に固定されたroute。自動縮退/fallbackはしない。 |
| revision（更新版） | Webが現在Projectionと後続更新の連続性を確認する単調増加値。domain Eventの通し番号と同一とは限らない。 |
| Codex Skill（Codex作業能力／AI接続面） | Codexが人のアプリ、データ、能力を扱うための能力・接続面。`SKILL.md`、Python、Web、scriptを含み得るが、正式Y2 updateなしにY2 Behavior/Rule/Policy/Port/Effect/ownershipを変更しない。 |
| SkillCreator | Codex Skillを作成・更新する初期必須Codex capability。Y2はCodex自身の権限に追加の承認・制限層を加えない。 |
| Agent Session Context | Codex Thread ID、connection/status、correlation、rebind/recovery、durable AgentTurnBindingを唯一所有するY2 Context。Provider内部stateとconversation textは所有しない。 |
| AgentTurnBinding | 一external turnの耐久相関値。Y2 Interaction ID、exact Thread ID、external turn/operation IDまたはabsence、dispatch前にY2が発行するimmutable attempt/generation/correlation ID、`Planned`/`Requested`/`Started`/`Terminal`/`Interrupted`/`Recovery`、pinしたprovider/profile/protocolを持つ。別turnの結果・取消を更新しない。 |
| `thread/start` / `thread/resume` | Codex外部Threadを開始／記録済みexact IDへ再開する閉じたoperation。`--last`やY2 Conversation IDを使わない。 |
| `turn/start` / `turn/interrupt` | Codex Threadへturnを開始／取消する閉じたoperation。`turn/interrupt`はexact current AgentTurnBinding/generationだけをtargetにし、staleならno-effect。adapterは対応するtyped result Eventを返す。 |
| Port（抽象接続口） | Applicationが外部能力へ要求する、具体製品に依存しない契約。 |
| Adapter（変換境界） | Portの値と具体製品・通信・入出力の表現を相互に翻訳するもの。 |
| Projection（参照表現） | EventやStateから作る、利用者・運用者向けの読取モデル。外部配達の証拠ではない。 |
| ArtifactRef（成果物参照） | 画像、音声、文字列などの成果物を、その存在・利用条件とともに参照する値。 |
| logical Artifact ID（論理成果物ID） | filesystem pathやstorage locatorを隠し、認可済みArtifactを参照するID。 |
| Presentation（提示） | 利用者へ表示・再生する内容と確かさ・出所を保つ型付き値。 |
| OutputPurpose（出力目的） | Presentationの目的を表す閉じた値。`View`はSceneStatus、FaceExpression、Object、DocumentRead、Summarize、Translate、Transcribe、SummarizeTranslate、TranscribeTranslate、`Recall`はSummarize、ExistenceConfirm、TopicSearch、Compare、Contextualizeを持つ。 |
| RecallPurpose（想起目的） | `Summarize`、`ExistenceConfirm`、`TopicSearch`、`Compare`、`Contextualize`から選ぶ、Memoryを取り出す閉じた理由値。 |
| empty Recall（空の想起） | 検索は成功したが該当記録がないこと。FailureやViewではない。 |
| Quality Profile（品質プロファイル） | Wake/SBERT、warm/cold、CPU/RAM、endurance、reconnectの測定条件・結果・Failureを版付きで記録する値。 |
| content class（内容分類） | `Image`、`Audio`、`Transcript`、`Conversation`、`Memory`、`Artifact`など、保持・処理・移送Policyを個別評価するデータの性質。 |
| processing location / transfer direction（処理場所／移送方向） | `Local`/`Remote`は処理場所、`LocalToRemote`/`RemoteToLocal`は移送方向。content classごとに別Policy/configured authorizationで評価し、データ分類そのものではない。 |
| standing authorization（継続許可） | README/setup/configのdisclosureとenabled configで与える保存・transferの許可。利用ごとのprompt UIではない。disable/revocationは次の新規save/transferより前に効く。 |
| operations / audit / debug log | rolling retentionの運用記録。既定で30/90/7日。journal、pending、Recovery、snapshot/stateとは別であり、通常logへraw media、secret、full Conversation、SemanticMemoryを入れない。 |
| provenance（出所） | 検索・取得・記憶・観測について、どこからいつ何として得たかを示す追跡情報。 |
| resource claim（資源要求） | カメラの首や音声出力など、Effectが排他的または有限に使う資源の宣言。schedulerの同時dispatch可否だけに使い、意味順序は表さない。 |
| guard（進行条件） | 先行結果に応じ、下流Effectを進行または停止する条件。 |
| snapshot（状態スナップショット） | commit済みWorldStateを復旧するための初期Source of Truth。 |
| journal（出来事記録） | 監査とProjection再構築の記録。外部作用の再実行源ではない。 |
| durable pending（永続待機仕事） | 再起動後も失ってはいけない、dispatch可能なEffect記録。 |
| Observed（観測済み） | 証拠により物理結果を確認した状態。 |
| Assumed（仮定済み） | 方針や時間により進行を許すが、物理観測はない状態。 |
| DefinitelyNotApplied（未適用確定） | 証拠により外部作用が適用されなかったと分かる状態。 |
| OutcomeUnknown（結果不明） | 適用済み・未適用のどちらとも安全に判断できない状態。 |

`intent`は外部製品やY1の実装を説明する場合に使うことがありますが、Y2 Coreへ単一の正式Intent登録簿を置くことは意味しません。Y2では、意味候補、動作単位の方針、解決結果を区別します。
