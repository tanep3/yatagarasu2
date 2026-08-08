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
| EffectOccurrence（外部作用出現） | Effect Graphの頂点 | 同じEffect値でも区別する、一回の仕事出現の不変identity。 |
| Failure（失敗） | 外部・内部境界から戻る | 例外文字列ではなく、判断可能な型付き失敗データ。 |
| ArtifactRef（成果物参照） | Context間・Effect間で渡る | 画像、音声、文字列など大きな成果物の存在と利用条件を示す参照。 |

WorldStateは外部データを何でも詰め込む巨大な袋ではありません。画像、音声、モデル、長い文字列は必要に応じてArtifactRefで参照します。

## 状態の所有者は一つ

| 状態 | 唯一の所有者 | 所有しないもの |
| --- | --- | --- |
| wake受理、session、pre-roll選択window/cursor、保持/discard、prompt guard、空命令 | Acoustic Context | Yata Wake、Mimy、音声Adapter（raw audio bytes/ring bufferはAdapter所有） |
| Active Qualiaの開始/Home、identityとLifecycle | Qualia Context | Behavior固有State、Web、音声、device、Effect Graph |
| 入力受理、request idempotency ledger、Interactionの生存期間と取消 | Interaction Context | Web、音声、CLI、LLM、Execution Context |
| 会話turn履歴 | Conversation Context | Provider thread、Codex Skill app data、LLM |
| 長期記憶、standing authorization、delete状態 | Memory Context | SemanticMemory等のAdapter、Codex Skill app data、Provider |
| 外部推論binding、Codex connection/Thread、correlation、rebind/recovery、durable AgentTurnBinding | Agent Session Context | Codex、Provider、Conversation Context、LLM |
| 意味解決方針の版 | Decision Policy Context | SBERT、LLM、profile |
| OwnerのSkillCreator包括委任、SkillExecutionGrant、status/revocation | Authorization Policy Context | SkillCreator、Skill、LLM、Adapter |
| 内容分類schema/導出Policy版、分類済みauthorization view | Data Classification Policy Context | Provider、Skill、Fetcher、Artifact store |
| Effect Graph、永続待機、取消済み仕事、playback occurrenceと回答全文/Stop Policy版のbinding | Execution Context | dispatcher、TTS/音声Adapter、journal再生 |
| 登録Stop語とStopSuppressionPolicy版 | Acoustic Context | STT、TTS、音声Adapter |
| 物理観測と姿勢 | Physical Observation Context | カメラAdapter、校正能力 |
| 成果物の生存期間 | Artifact Context | TTS、撮影、Provider、filesystem Adapter |
| 通知の方針 | Notification Policy Context | 通知チャネル、Projection |

Contextは、自分が所有する状態だけを変更します。他のContextへ可変参照を渡さず、事実をEventとして交換します。Adapter、Python worker、外部Provider、Codex Skill、profile、ProjectionはWorldState、plan、provider state、Conversation、Memoryを所有しません。Agent Session ContextもProvider内部stateとconversation textを所有しません。AgentTurnBindingはY2 Interaction ID、exact Thread IDまたはabsence、external turn/operation IDまたはabsence、Y2-issued immutable attempt/generation/correlation、lifecycle、pinしたprovider/profile/protocol/ContextContinuityだけを持つ耐久外部相関である。TTS/音声Adapterはwaveform、候補、結果Eventを返すだけで、回答全文照合またはStop抑止を決めません。

## クオリア、振る舞い、Interactionを分ける

Qualia（クオリア）は、Yatagarasuが現在どの振る舞いとして世界を知覚し活動しているかを表します。現在の非Home qualia sessionは全体で0または1です。これはLifecycleのActive phaseだけでなく、Starting、Active、Terminating、Recoveringにある現在session全体を指します。Homeは現在sessionがない基本待受状態です。

会話、文字起こし、同時通訳、見守りはBehavior（振る舞い）です。BehaviorはQualiaとして開始される場合がありますが、一つの万能objectやprocessを意味しません。必要なContext、Rule、Effect、Projection、Port、Adapterへ構造を寄与します。

Interactionは一つの入力から生じる有限の因果単位です。一つの文字起こしQualiaが複数の音声Eventを受け取れるように、QualiaとInteractionは同じ生存期間ではありません。ConversationもBehaviorの一つであり、Qualia、Interaction、Kernelの別名ではありません。

初期`FallbackToConversation`は、Homeで有効なBehavior候補がない場合だけに限る。一入力・一最終応答の後、型付きterminal結果またはRecoveryへの責任移管を経てHomeへ戻る。履歴はConversation Contextに残るが、連続会話は別の将来Behaviorである。

Home／Stop検知、永続化、Recovery、診断、認証、Web状態同期は自律神経として並行稼働しますが、第二のQualiaにならず、Qualia Stateを直接変更しません。

## Effect Graphは、手順書ではなく因果構造である

複合動作の順番は、中央の関数へ並べるのではなく、Effect Graphに宣言します。

- **依存関係**: どの結果がそろえば次の仕事を始められるか。
- **guard（進行条件）**: どの結果なら先へ進み、どの結果なら止めるか。
- **resource claim（資源要求）**: カメラの首、撮影、音声出力など、同時使用できない資源は何か。
- **取消状態**: まだ送っていない仕事を、再起動後も含めて止める必要があるか。

Schedulerは、依存関係を満たし、guardが許可し、資源が空いている仕事を選ぶだけです。カメラや会話に固有の主手順を知りません。

Effect値と一回の仕事を同一視しない。Graphの頂点は`EffectOccurrence` identityを持ち、同値Effectが二回あれば二つのOccurrence、結果Event、監査記録を持つ。API requestの重送を抑えるkeyと、Recoveryで同一Occurrenceを照合・再dispatchするkeyは別である。順序はOccurrence IDや生成順ではなく、意味を持つdependency edgeとguardだけで決まる。resource claimはschedulerが同時dispatch可否を判断するための競合宣言であり、意味順序を表さない。

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

推論能力は、具体モデル名を直接Domainへ持ち込まず、速度重視、Vision、高性能推論などの論理profileとして扱います。初期Agent adapterはCodexだけで、Provider choiceはCodex default経由のOpenAI、Hoshikage、Ollama APIである。SBERTは入力からroute候補を返し、Decision Policyが利用可能性、privacy、configured authorization、能力広告を踏まえて解決します。

preferred route（希望経路）とeffective route（実効経路）を分けます。effective route/provider/profile/versionはdispatch前に固定し、設定変更は次Interactionからだけ反映する。利用不能ならtyped terminal Failure/Recoveryを返し、Provider間/local-remote間/同一Provider内の自動fallbackやactive turn rebindを行わない。外部Providerやworkerはroute方針、会話状態、WorldStateを所有しません。

### Behavior routeと推論routeを分ける

HomeでYatagarasuを起点とする通常構成は、独立制御語の後に、SBERT候補とDecision Policyから使用するBehaviorを解決します。ただしCapability Policyがrule-only、LLM-proposal-only等を宣言した機能へSBERTを強制しません。BehaviorがLLMを必要とする場合だけ、別のDecisionとして論理LLM／Provider profileを解決します。

宣言されたContributorの評価後に有効なBehavior候補がなければ`FallbackToConversation`を明示的に返せます。安全、権限、能力方針で拒否された候補は、会話へfallbackして迂回しません。Qualia/Interactionのread-only viewを読む純粋admission Ruleが開始を判断し、Starting、Active、Terminating、Recoveringでは別Qualiaの開始要求を`Busy`として拒否する。暗黙queueは作らない。現在Qualiaの通常入力はversion付きBehavior Policyが決める。HomeとWeb Cancelは常にそれより優先するが、TTS再生中の音声Stop候補は`StopSuppressionPolicy`で抑止され得る。

## Codex Skill、Y2 Behavior、Proposal、Effectを分ける

Codex Skillは、人間が使うアプリ、データ、外部能力をCodexへ公開する接続面です。Y2 Behaviorはdomain/application/ports/adaptersへ寄与するversion付きrobot機能である。Skillを追加しても、Coreへ製品固有の分岐を足さずに、AIが新しい世界へ触れられるようにします。

初期Codex capabilityはSkillCreator、Search、Fetchである。OwnerはAuthorization Policy Contextが所有するstanding delegationにより、SkillCreatorへSkill資産と初期SkillExecutionGrantの構成を包括委任する。assetはinactive staging、grant commit、activation Eventを経て実行可能になり、作成ごとの承認UIは置かない。Skillはgrant範囲でWorkspace外read/write、network、secret、外部副作用を行えるが、自身または別Skillのgrantを拡大しない。ただし外部資産は正式Y2 Behavior updateなしにY2のBehavior、Rule、Policy、Port、Effect、ownership/catalogを変更しない。Skillの読出しが観測を返す場合も、AIが書込みを提案する場合も、決定論的な能力を公開する場合もあります。したがってCodex Skillは、Contributor、Proposal、Effect、Adapterのどれか一つと同義ではありません。

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

profileがsettle（安定待ち）を宣言する場合も、値と版をOccurrenceへ固定する。`EffectExecutionStarted`受理後の単調時間だけがAssumed進行条件になり得て、物理完了をObservedに変えない。

## 記憶と提示は、外部アプリの所有権を奪わない

Conversation ContextはYatagarasuの原発話/最終応答の正本履歴を、Memory ContextはYatagarasuの長期記憶を所有する。Codex ThreadはHomeと有限Interactionを越えて推論へ影響する外部継続文脈であり、Agent Session Contextは本文でなくopaque bindingだけを所有する。外部Codex Skill app data、Provider thread、search/fetch本文は外部のまま型付き参照またはArtifactRefで扱う。local auto-saveは既定ONでConversationの原発話と最終応答の組に限り、reflex commandはMemoryへ保存せずoperations logだけへ残す。MemoryはOwner deleteまで無期限で、README/setup/configのstanding disclosureとenabled configをauthorizationとする。明示`Memorize`は別目的である。Y1 import/migrationはしないが、同じ互換storeの旧recordはprovenance付きで示せる。通常Conversationのversion付きRecall Policyは既定`recent=0`、`semantic=3`を返し、件数は設定可能である。`CodexThread` routeでは選択済み参照/provenanceを継続Threadへ追加し、`NoExternalContinuity` routeでは現在入力と選択参照だけを`RequestInference`へ渡す。SemanticMemory delete/resetは既注入Threadを遡及消去せず、完全に外部文脈を切るOwner Thread resetはdurable barrier後に新Threadを開始する別Commandである。memoryが関係しないBehaviorは`NotApplicable`を明示できる。

利用者へ渡す内容は`Presentation`と`OutputPurpose`で表す。`View`はSceneStatus、FaceExpression、Object、DocumentRead、Summarize、Translate、Transcribe、SummarizeTranslate、TranscribeTranslateを、`Recall`はSummarize、ExistenceConfirm、TopicSearch、Compare、Contextualizeを閉じた目的値として持つ。目的ごとに必要入力、許可surface、evidence/provenance、禁止presentationを宣言し、空RecallとFailureを混同しない。翻訳系は提示変換であり、英語または原文を追加で音声再生しない。

`CancelRequested`は共通Inbound境界へ入るCommandです。Interaction Contextが受理した結果は`CancellationAccepted` Eventとして記録します。さらに、待機中仕事の永続取消、実行中仕事の取消結果、物理結果を別々のEventとStateで表します。取消後に遅れて届いたProposalは適用しません。止められない物理動作を、止めたことにはしません。

Interaction Contextは、API mutationごとの耐久request-idempotency ledgerを唯一所有する。recordはclient key、payload fingerprint、replay可能な型付きresult、status、Interaction lifecycleを持つ。Rejected、AcceptedNoEffect、Pending、Completedはrestart後も区別して再生する。これはExecution Contextのdurable pending `EffectOccurrence` recordと、RecoveryのOccurrence照合keyとは別State・別keyである。voice入力はclient keyを要求せず、Adapter/Interaction Contextがserver-assigned input identityを記録する。

通知する操作、計画、チャネル、言い回し、無通知はNotification Policy Contextが所有します。Projectionへの表示は、外部へ通知が届いた証拠ではありません。

Y1から継承するThinkingNotice（「考えるね」）は、設定で文言と有効/無効を選べるvoice-only通知です。Memory retrievalとroute確定後、LLM dispatch直前だけに置き、SBERT反射、Web、Homeでは生成しません。通知FailureはLLMを止めず、Homeへ「待機します」を暗黙に結び付けません。

## 時刻と物理的事実

時刻はClockPortから導入します。`EffectExecutionStarted`（外部作用の実行開始Event）は、Adapterが実行を試みた、または開始したという事実です。物理的に適用された、完了したという証拠ではありません。

`ExpectedActionDuration`（想定動作時間）は、Coreがこの開始Eventを受理した時点から、機能・機種profileの単調時間を測ります。待ち行列にいた時間は含めません。開始Eventがなければ、時間に基づくAssumed（仮定済み）の進行事実を作りません。

相対移動の要求と、観測・推定した姿勢も別の値です。証拠のない絶対姿勢を作りません。校正成功は校正能力の結果であって、現在姿勢の観測証明ではありません。
