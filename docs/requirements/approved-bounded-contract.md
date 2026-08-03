# 承認済み境界契約

この文書は、Yatagarasu 1で確認した機能価値を、初期Yatagarasu 2の**承認済みの境界**として正規化する。具体的なRTSP、IPC、保存実装、数値閾値、Provider、モデル、検索実装はここで決めない。これらは実装前のspike（小さな実測検証）後に別途決定する。

`Presentation`、`OutputPurpose`、`EffectOccurrence`などの英語名は、実装で閉じた型として扱う契約名である。本文では必要に応じて日本語を添える。

## REQ-ACOU-001 — Acoustic Contextはwakeから一命令までを唯一所有する

Acoustic Contextは、wake受理、音声session、pre-rollの選択window/cursorと保持・discard判断、prompt再生中の入力破棄、prompt guard（自己音声を避ける保護期間）、空命令の破棄を唯一所有する。初期既定は一wakeにつき一命令（one-wake-one-command）である。受理済み命令後、同じ音声や遅延入力が次のwakeへ循環する自己ループを作ってはならない。source Adapterは音声接続、raw audio bytes/ring buffer、再接続を所有してよいが、wake受理、session、pre-roll選択、Conversation、Interaction、WorldStateを所有しない。

受入条件:

- AC-ACOU-001: Acoustic Contextのownership registryはwake受理、session identity、pre-roll選択window/cursor、保持/discard、guard、空命令判定を一度だけ登録する。Yata Wake、Mimy、RTSPその他のsource Adapterはraw audio bytes/ring bufferを所有してよいが、前記のdomain判断の所有者として登録しない。
- AC-ACOU-002: wake fixtureが、最初の実発話を保持したまま、prompt由来入力だけをdiscardし、guard終了後に一命令だけを`SubmitInteraction`へ変換することを示す。固定の無音fixtureだけで合格にしてはならない。
- AC-ACOU-003: 空命令、prompt回り込み、dispatch後の遅延音声、再接続の各fixtureが、追加のwake/session/Interactionを生成せず、型付きのdiscard、empty、またはsource-recovered事実を残す。
- AC-ACOU-004: pre-roll長、guard長、source bufferのflush/reconnect方式を未固定のまま、実profile fixtureがwake、prompt、最初の発話、命令確定、discard理由を相関ID付きで記録する。
- AC-ACOU-005: 実profile fixtureが、wake prompt「はい」をtranscriptへ含めず、実TTS応答を新しい通常Wake/通常command/Interaction/LLMとして受理せず、最初の利用者発話を保持することを示す。ただしTTS中も独立したHome/Stop control検知は生存する。空命令はLLMまたはbody Effectを作らずHomeへ戻り、通知の有無は別のNotification Policy/Effectとして扱う。
- AC-ACOU-006: 実または代表的TTS waveform再生中のfixtureが、利用者のHome/Stop発話を共通control Commandと型付きtermination/cancellationへ変換する一方、TTS waveform自体は通常入力にもfalse control commandにも変換しないことを示す。

## REQ-MEM-001 — ConversationとMemoryをYatagarasu所有の記録として分離する

Conversation ContextはYatagarasuの会話turn履歴を、Memory ContextはYatagarasuの長期記憶とその保持・削除状態を唯一所有する。外部Skillアプリのデータ、外部Provider thread、検索先の本文はYatagarasu Memoryへ所有移管しない。初期契約ではlocal auto-saveを既定でONとし、Conversation Behaviorは元の利用者発話と最終応答の組だけを保存する。reflex commandは構造化operations logだけへ残しMemoryへ保存しない。明示`Memorize`は別目的の保存要求であり、自動保存と同一視しない。

MemoryはOwnerがdeleteするまで無期限に保持する。README/setup/configでのstanding disclosureとenabled configが保存・許可済み移送のstanding authorizationであり、利用ごとのprompt/consent UIは置かない。configでdisableでき、revocationは次の新規save/transferより前に効く。disabled/revoked時に別のProvider、保存先、transferへ自動fallbackしない。Y1 import/migrationは不要である。ただし同じ互換storeが過去recordを示す場合、そのrecordをY2がimportしたと偽らずprovenanceを残す。

`RecallPurpose`（想起目的）は閉じた値として`Summarize`（要約）、`ExistenceConfirm`（存在確認）、`TopicSearch`（話題検索）、`Compare`（比較）、`Contextualize`（文脈化）を区別する。既定のversion付きrecall policyは、時系列のrecent 3件と意味近傍のsemantic 3件を別集合として返す。両方に同じ記録が現れた場合はrecentを優先し、重複・競合理由と各記録のprovenanceを一度だけ示す。空の検索結果は成功した内容なしであり、Failureと混同しない。

受入条件:

- AC-MEM-001: ownership fixtureがConversation Context、Memory Context、外部Skill app data、Provider threadを別Stateとして示し、外部側がConversation/Memory/WorldStateを変更できないことを示す。
- AC-MEM-002: enabled既定profile、disabled/revoked profile、明示`Memorize`、Owner delete、reflex command、既存互換store recordのfixtureが、Conversationの原発話と最終応答だけをauto-saveし、reflexをMemoryへ保存せず、disable/revocation後の次save/transfer Effectを作らず、削除済み記録をrecallしないことを示す。Y1 recordのimport job/API/Upgrade migrationを作らず、同じ互換storeですでに可視なrecordだけをprovenance付きで扱う。
- AC-MEM-003: version付き既定Policyのfixtureがrecent 3件とsemantic 3件を目的付きで返し、重複時はrecentを優先して一度だけ示す。空結果、検索Failure、保存拒否は三つの異なる型付き結果である。
- AC-MEM-004: `Summarize`、`ExistenceConfirm`、`TopicSearch`、`Compare`、`Contextualize`の各RecallPurpose fixtureが、recent 3 + semantic 3、recent優先/競合理由、記録provenanceを保ち、目的外の記憶を事実または現在観測として提示しない。
- AC-MEM-005: enabledな初期Conversation profileは、conversational LLM requestより前にrecent 3 + semantic 3を取得し、選択された参照とprovenanceだけをrequestへ渡す。retrieval Failureまたはdisabled状態は型付きPolicy結果として残し、記憶を捏造しない。current-image interpretationなどのBehavior Policyはmemoryを`NotApplicable`と宣言できるが、実装がmemory経路全体を省略してこのACに合格してはならない。

## REQ-OUT-001 — Presentationと出力目的を型付きにする

応答を利用者へ提示する前に、`Presentation`（提示内容）と`OutputPurpose`（出力目的）を閉じた値として決める。`OutputPurpose::View`は`SceneStatus`（場面/状態）、`FaceExpression`（顔/表情）、`Object`（物体）、`DocumentRead`（文書読取）、`Summarize`（要約）、`Translate`（翻訳）、`Transcribe`（文字起こし）、`SummarizeTranslate`、`TranscribeTranslate`を持つ。`OutputPurpose::Recall`は`Summarize`、`ExistenceConfirm`、`TopicSearch`、`Compare`、`Contextualize`を持つ。

各目的は、必要入力、許可される出力surface（Projection、文字、音声、認可済みArtifact参照）、必要なevidence/provenance、禁止する提示を型で宣言する。Viewは入力Observation/ArtifactRefと確かさを、RecallはMemory record/provenanceと保存状態を必要とする。`DocumentRead`以外へ文書読取を偽装せず、`FaceExpression`は根拠なしに人物の同一性・感情・属性を断定せず、`Translate`系は原文を追加音声再生せず、`Transcribe`系はカメラ文書画像の確定OCR以外を正確な転記として提示しない。`Recall`の空結果は、無内容だが正常な提示として、Failureとも`View`とも区別する。

| 閉じた目的値 | 必要入力 | 許可surface | 必要evidence/provenance | 禁止presentation |
| --- | --- | --- | --- | --- |
| View.SceneStatus | scene/status Observationまたは認可済み画像Artifact | Projection、文字、音声 | 観測確かさ、device/Artifact provenance | 未観測の変化、人物属性 |
| View.FaceExpression | 顔/表情に十分なObservation/Artifact | Projection、文字、音声 | 顔領域のevidence/provenance | identity、感情、属性の根拠ない断定 |
| View.Object | 物体Observation/Artifact | Projection、文字、音声 | object evidence/provenance | 未検出物、所有者・危険性の断定 |
| View.DocumentRead | カメラ文書画像Artifactと自然説明の読取結果 | Projection、文字、音声 | document image/reader provenance、確かさ | 読めない箇所の補完、逐語OCRの偽装 |
| View.Summarize | カメラ文書画像または確定OCR text | Projection、文字、音声 | document image/OCR provenance、確かさ | 新事実、未確認の因果 |
| View.Translate | カメラ文書画像のOCR textと対象言語 | Projection、文字、**翻訳後だけ**の音声 | document image/OCR provenance、言語 | 原文/英語の追加音声、原文を新事実化 |
| View.Transcribe | カメラ文書画像と確定OCR text | Projection、文字、音声 | document image/OCR provenance、確かさ | 自然説明への置換、読めない箇所の補完 |
| View.SummarizeTranslate | カメラ文書画像または確定OCR textと対象言語 | Projection、文字、**翻訳後だけ**の音声 | document image/OCR provenance | 原文/英語の追加音声、新事実 |
| View.TranscribeTranslate | カメラ文書画像と確定OCR text、対象言語 | Projection、文字、**翻訳後だけ**の音声 | document image/OCR provenance | 原文/英語の追加音声、OCR不確実性の隠蔽 |
| Recall.Summarize | provenance付きMemory record集合 | Projection、文字、音声 | record ID、保存状態、Recall Policy version | 現在観測または未保存事実としての提示 |
| Recall.ExistenceConfirm | 検索条件とMemory recordまたは空結果 | Projection、文字、音声 | record IDまたは空成功、Policy version | 空結果をFailureまたは存在肯定として提示 |
| Recall.TopicSearch | queryとMemory record集合 | Projection、文字、音声 | query、record ID、score/provenance | scoreを確定事実・現在観測として提示 |
| Recall.Compare | 比較対象となるMemory record集合 | Projection、文字、音声 | 各record ID/provenance | 片側欠落を同等比較、外部事実の補完 |
| Recall.Contextualize | 現在入力とMemory record集合 | Projection、文字、音声 | 現在入力と各record provenance | 記憶を現在の観測または指示として昇格 |

受入条件:

- AC-OUT-001: 全9種のView purposeと全5種のRecall purposeのfixtureが、それぞれ必要入力、許可surface、evidence/provenance、禁止presentationを検証し、目的を文字列の自由入力で代用しない。
- AC-OUT-002: View、Recall、空Recall、Failureのfixtureが相互に異なる`Presentation`/結果値を返し、Projectionと音声出力がその区別を失わないことを示す。
- AC-OUT-003: 翻訳、要約翻訳、文字起こし翻訳のfixtureが選択した翻訳言語だけを音声再生対象にし、英語または原文の二重再生Effectを生成しない。
- AC-OUT-004: View/Recall fixtureが、必要Observation/ArtifactRef/Memory provenanceを欠く場合に目的固有の拒否またはFailureを返し、別purposeへ暗黙変換しない。

## REQ-EFX-001 — EffectOccurrenceで仕事の出現と再実行を区別する

一つのEffect値は、同じ意味の仕事を表せても、一回の出現を表さない。Effect Graphの各頂点は一意な`EffectOccurrence`（外部作用出現）identityを持ち、同じEffect値が複数回必要な場合も別Occurrenceとして保持する。意味の進行順序はEffect値の比較、生成順、中央の逐次手順、resource claimではなく、dependency edgeとguardだけで表す。resource claimはscheduler admissionと同時実行競合だけを表す。

physical profileのsettle（安定待ち）はversion付きprofileデータとしてOccurrenceへ固定し、`EffectExecutionStarted`後にのみAssumedの進行条件になり得る。これは物理完了の観測ではない。API requestの冪等性と、restart/recovery時の同一Occurrence再照合・再dispatchの冪等性は別の型付きkeyとPolicyで扱う。

受入条件:

- AC-EFX-001: 同値のEffectを二回含むGraph fixtureが、二つのOccurrence identity、結果Event、監査記録を保持し、一方の結果を他方へ誤相関しない。
- AC-EFX-002: 並列可能な同値Effectと、意味的dependency edge/guard、resource claimを持つEffectのfixtureが、値や生成順ではなくedge/guardだけから意味のready順を決める。resource claimはscheduler admissionの競合を防ぐだけで、順序そのものを表さない。
- AC-EFX-003: profile settle fixtureがdispatch時のprofile versionを保持し、start Event前には時計を消費せず、経過後もObserved完了を作らない。
- AC-EFX-004: 同じAPI requestの重送とrestart後の同一Occurrence recoveryを別々に試験し、一方のkey/Policyを他方の代用にしない。
- AC-EFX-005: `right -> settle -> left`と`right -> settle -> right`のGraph fixtureが、各moveを別Occurrenceとして保持し、各profile settleを持ち、`move -> settle -> capture -> interpret/recall`の意味edgeを記録する。resource claimだけでこの順序を表現してはならない。

## REQ-CNV-001 — 初期FallbackToConversationを有限な一往復にする

Homeで有効なBehavior候補がないときだけ、純粋なresolutionは`FallbackToConversation`を返してよい。初期Conversation Behaviorは、一入力・一最終応答の有限Interactionとして開始する。Home前に、response generationのterminal、最終Presentationのpublish、Memory saveのterminalまたはdurable Failure/Recovery handoffを確認する。物理TTSのheard completionはHomeの前提にせず、playback `OutcomeUnknown`はRecoveryへ引き渡す。会話履歴はHome復帰後もConversation Contextに残る。連続会話、複数入力のsession、長時間Conversationは将来のversion付きBehaviorとして扱い、初期契約へ暗黙に持ち込まない。

受入条件:

- AC-CNV-001: 候補なしfixtureが`FallbackToConversation`を返し、一入力、一つの最終Presentation、型付きterminalまたはRecovery handoff、Home復帰を順に観測できる。
- AC-CNV-002: 安全、権限、Capability Policyで拒否された候補のfixtureはfallbackせず、拒否と無Effectを返す。
- AC-CNV-003: Home後の次Interactionが会話履歴を参照できても、前のConversation Effect、session、取消、未解決結果を再利用しないことを示す。
- AC-CNV-004: terminal fixtureがresponse generation terminal、final Projection published、Memory save terminalまたはdurable Failure/Recovery handoffを確認してからHomeへ戻ること、TTS heard completionを要求せずplayback `OutcomeUnknown`をRecoveryへ相関することを示す。

## REQ-QLI-001 — QualiaとInteractionのadmission責務を分離する

Qualia Contextだけが非Home qualia sessionの開始とHome復帰を所有する。Interaction Contextだけが入力受理、耐久request-idempotency ledger、取消を所有する。ledgerはAPI client key、payload fingerprint、replay可能な型付きresult、status、lifecycleを持ち、Rejected、AcceptedNoEffect、Pending、Completedをrestart後も区別する。これはExecution Contextのpending `EffectOccurrence` recordとRecovery照合keyとは別である。admission Ruleは両Contextの読取viewを受ける純粋な判断であり、どちらも直接変更しない。非Home中の新しいQualia開始は`Busy`として拒否し、暗黙のqueueを作らない。現在のQualiaが通常入力を受けるか、振る舞い固有のcontrolへ渡すかはversion付きBehavior Policyが決める。HomeとCancelはそのPolicyより優先する共通制御である。

受入条件:

- AC-QLI-001: ownership fixtureがQualiaの開始/HomeとInteractionの受理/request-idempotency ledger/cancelを別々に一度だけ登録し、ledgerがclient key、payload fingerprint、replay可能な型付きresult、status、lifecycleを持つこと、admission Ruleが純粋な読取だけで評価できることを示す。
- AC-QLI-002: Busy fixtureが新しいQualia、待機列、Effect Graph、dispatchを作らず、型付きBusy結果を返す。
- AC-QLI-003: 同じ通常入力を二つのBehavior Policyへ与えるfixtureが、current Qualiaのcontrolと通常入力の異なる解釈を明示し、Home/Cancelは両方で優先して共通Commandになることを示す。
- AC-QLI-004: 二つの認証済みbrowser/API mutationとvoiceが同時に入力するfixtureで、browser/API mutationはclient idempotency keyを必須にする。voiceはAPI keyを要求されず、Adapter/Interaction Contextがserver-assigned input identityを付与する。同一API key/同一payloadは同じ型付きresultをreplayしてEffectを重複せず、同一API key/異payloadはConflictを返す。restart fixtureはRejected mutation、AcceptedNoEffect mutation、Pending mutation、Completed mutationをInteraction request-idempotency ledgerから復元・replayし、Execution pending `EffectOccurrence` recordやRecovery keyと混同しない。Home/Cancelは競合中も優先する。

## REQ-SET-001 — 初期Linux導入をOwner、Capability、secret、診断、E2Eで検証する

初期の対応platformはUbuntu 24.04 LTS、x86_64、Intel第8世代Core i5以上、RAM 8GB以上である。外部serverはそれぞれの要件を所有する。setupは一Server、一Workspace、一Ownerを作り、Capabilityのlogical mode、configから参照するsecret storage boundary、診断結果を明示する。services/capabilitiesはinstallation serverごとに個別選択し、全Y2 serverを自動installしない。Codexは公式installerを使いbundleしない。local-managed、remote、disabledを独立に選び、設定変更は次Interactionから適用し、自動fallbackしない。secretは第六のXDG rootではなく、平文でconfig、Event、Projection、journal、通常log、Artifact名へ出してはならない。`doctor`は未設定、非互換、利用不能を成功として隠さず、Capabilityごとの型付き診断を返す。最初の実機E2Eはwake、有限Conversation、最終出力、Home復帰を一つの因果列として確認する。

受入条件:

- AC-SET-001: clean Linux fixtureが一Owner/一Workspaceを作成し、config・data・state・cache・runtimeを五つのXDG rootへ役割別に分離する。secretは第六rootにせずconfigから参照するdistinct secret storage boundaryへ置き、平文をconfig/Event/Projection/logへ出さない。Capability選択とcredential registrationを明示する。
- AC-SET-002: doctor fixtureがSource、Wake、STT、SBERT、camera、TTS、Provider、Memoryのready/未設定/認証失敗/非互換/利用不能、各remedyを別の型付き結果として示す。secret本文とconfigured authorizationのない外部transferを露出または実行しない。
- AC-SET-003: 対応実機E2Eがclean Linux setup、credential registration、doctorの全ready、real wake、最初の発話、有限Conversation、最終Presentation、Homeを相関IDで記録する。FakeだけをこのACの証拠にしない。
- AC-SET-004: Ubuntu 24.04 LTS/x86_64/Intel第8世代Core i5以上/RAM 8GB以上のfixtureがbaselineを明示し、installation serverごとにservice/capabilityを個別選択する。全Y2 serverの自動install、Codex bundle、active Interaction中のprovider rebind、失敗時の自動fallbackを行わない。

## REQ-QPR-001 — Quality Profileをversion付き実測契約にする

Quality ProfileはWake、SBERT、warm/cold（常駐済み/初回）状態、CPU、RAM、endurance（継続稼働）、reconnectの計測条件・結果・測定時点をversion付きで記録する。365日稼働目標は、計画、hardware/profile、途中evidence、spike後のsoak thresholdを揃えたときだけ主張できる。pre-roll、guard、settleは環境ごとに計測したdefaultをversion/configとして固定し、未計測ならrelease-readyではない。測定値、対象hardware、入力fixture、Failure分類を欠くprofileもrelease-readyではない。数値閾値、測定時間、合格境界はspike後にprofile versionへ追加し、この初期契約では固定しない。

受入条件:

- AC-QPR-001: profile fixtureがWake positive、near-negative、silence、self-audio、SBERT single、composite、negative、unrelated、warm/cold、CPU/RAM、endurance、reconnectをそれぞれ欠測可能な独立項目として記録する。
- AC-QPR-002: 閾値または必須測定が未設定のprofileをrelease-readyと表示しない。測定不能、Failure、未実施は成功値に置き換えない。
- AC-QPR-003: quality fixtureが各測定のhardware、input fixture、profile version、時点、Failure分類を残し、実測値なしの既定値またはY1値をY2のrelease閾値として流用しない。
- AC-QPR-004: 365日objective fixtureが計画、対象hardware/profile、途中evidence、spike後soak thresholdを持ち、pre-roll/guard/settleの環境別計測defaultをversion/configへ固定する。いずれかが欠けるprofileをrelease-readyと表示しない。

## REQ-DAT-001 — 内容分類ごとのlocal-first処理場所・移送とArtifact境界を明示する

初期方針はlocal-first（configured standing authorizationがない限りデータをlocalに留める）とする。内容分類は少なくとも`Image`、`Audio`、`Transcript`、`Conversation`、`Memory`、`Artifact`である。`Local`と`Remote`は処理場所、`LocalToRemote`と`RemoteToLocal`は移送方向であり、内容分類ごとに別のPolicy/authorizationを評価する。自動会話保存、明示memorize、Provider送信、検索取得、Artifact保存・削除は、目的別のconfigured authorization、保持、削除、移送Policyに従う。Artifact Contextは論理Artifact ID、認可、lifetime、delete状態を唯一所有し、利用者・Provider・Projectionへローカルfilesystem pathを露出しない。

受入条件:

- AC-DAT-001: `Image`、`Audio`、`Transcript`、`Conversation`、`Memory`、`Artifact`のfixtureが、各内容分類についてLocal/Remoteの処理場所とLocalToRemote/RemoteToLocalの移送方向を別々にPolicy/configured authorizationで評価し、許可されない移送Effectを生成しない。
- AC-DAT-002: auto-save、明示memorize、delete、standing authorization enabled/disabled/revokedのfixtureが、目的ごとのauthorization状態を区別し、削除済みArtifact/Memoryを再公開せず、利用ごとのconsent promptを要求しない。
- AC-DAT-003: Artifact fixtureが論理IDと認可済み参照だけをProjection/Providerへ渡し、path、secret、実装固有storage locatorを渡さない。
- AC-DAT-004: Artifact delete fixtureが`DeleteArtifact` Decisionから明示Effect、Adapter result Eventへ進み、論理ID、authorization、lifetime、delete状態を検証する。Adapter/Projectionがpathで削除を代行したり、結果Eventなしに削除済みと主張したりしない。
- AC-DAT-005: TTS WAVはplayback terminalまたはdurable Recovery後、かつ未解決dependentがないときだけdeleteし、temp captureはInteraction terminal後かつ未解決dependentがないときだけdeleteする。saved ArtifactはOwner deleteまで保持する。restart、参照、outcome unknownのfixtureはpathでなくlogical ID/lifetime/dependent/recovery状態で再判定し、Auditは最小logical referenceとmetaだけを残す。

## REQ-NET-001 — search/fetchを別のnetwork capabilityとして形式化する

`Search`と`Fetch`は、LLMの一般的な外部転送許可とは別の必須Capabilityである。network allowlist、request目的、provenance（取得元・取得時点・処理結果）、citation（利用者へ示す出典）、typed Failureを持つ。検索/取得で得た内容をLLM/Providerへ送るには、network取得のconfigured authorizationとは独立したLocalToRemote transfer authorizationが必要である。外部検索先、Fetcher、LLM、SkillはWorldState、Conversation、Memory、planを所有しない。

受入条件:

- AC-NET-001: allowlist外URL、search Failure、fetch Failure、citation欠落、provenance欠落、search/fetchのno-resultsのfixtureが、相互に区別できる型付きFailure、拒否、または空成功を返す。
- AC-NET-002: Search/Fetch成功fixtureが、許可されたsource、取得時点、logical ArtifactRef、利用者へ示すcitationを返し、取得本文を観測済みの世界事実へ昇格しない。
- AC-NET-003: network取得を許可しLLM transferを拒否したfixtureが、検索/取得結果を保持してもProvider requestを生成しない。
- AC-NET-004: retrieved content fixtureが、RemoteToLocal取得の許可と、内容分類ごとのLocalToRemote Provider transfer許可を別々に要求し、後者なしではProvider requestを生成しない。

## REQ-AGT-001 — Codex Agent adapterを外部Thread境界として扱う

初期Agent adapterはCodexだけである。通常経路はruntime bootstrapがlong-lived `codex app-server`をstart/superviseし、connectionごとに一回のinitialize handshakeを行う。turnごとの`codex exec`は使わない。production transportはspike後のstdioまたはUnix socket、WebSocketはexperimentalでproduction非対応とする。Agent Session Contextだけがexternal binding record/status/correlation、正確なCodex Thread ID、external turnごとの耐久`AgentTurnBinding`を所有し、Provider内部stateやconversation textを所有しない。

`AgentTurnBinding`はY2 Interaction ID、exact external Thread ID、外部が返したturn/operation ID（未返却はabsence）、dispatch前にY2が発行するimmutable attempt/generation/correlation ID、`Planned`/`Requested`/`Started`/`Terminal`/`Interrupted`/`Recovery` lifecycle、pinしたprovider/profile/protocolを持つ。`thread/start`、`thread/resume`、`turn/start`、`turn/interrupt`を閉じたoperationとして扱う。Y2 Conversationは複数の有限Interaction/Qualia/Homeを越えて同じThreadへbindでき、Home/Qualia終了はThread終了ではない。restart/reconnectは正確なIDへresumeし、`--last`、暗黙new Thread、Y2 Conversation IDの転用をしない。`turn/interrupt` Effectはexact active Binding/generationだけをtargetとし、dispatch前にcurrentでなくなったcancelはrejected/no-effectにする。crash-before-external-ID、notification/delta、duplicate/late result、deleted Thread/resume mismatchはBindingのtyped result/progress Event、`RebindRequired`、Recoveryとして扱う。turn A後に同じThreadのturn Bが始まれば、Aのlate/duplicate result/cancelはAのBinding/Recovery/auditだけを更新し、BのState/Presentation/cancel/terminalを変更しない。raw deltaは無制限journalに保存しない。Thread IDは保護・redactする。Codex/Python/外部capabilityはWorldState、plan、provider state、Conversationを変更せず、Adapter result Eventだけを返す。

受入条件:

- AC-AGT-001: bootstrap fixtureがlong-lived `codex app-server`を一回start/superviseし、connectionごとにinitializeを一回だけ行い、通常turnで`codex exec`を起動しないことを示す。doctorはpinしたCodex version/schema/readinessの非互換を型付きFailureにする。
- AC-AGT-002: ConversationがHomeと有限Qualiaを複数回通るfixtureが、同じ正確なThread IDへ`thread/start`後の`turn/start`を相関し、Home/Qualia終端でThreadを終了しないことを示す。
- AC-AGT-003: restart/reconnect、deleted thread、resume mismatch、crash-before-external-ID、duplicate/late resultのfixtureが、Y2 Interaction ID/exact Thread ID/Y2-issued immutable attempt-generation-correlation/pinned provider-profile-protocolを持つdurable `AgentTurnBinding`、記録済みIDの`thread/resume`、typed `RebindRequired`/Recovery、重複抑止を示し、`--last`、暗黙new Thread、Y2 Conversation IDによる継続偽装を行わない。
- AC-AGT-004: Cancel fixtureがexact active `AgentTurnBinding`/generationだけをtargetとする`turn/interrupt` Effectと相関したterminal/Recovery Eventを返し、dispatch直前にBindingがcurrentでなくなったcancelをrejected/no-effectとして送らないことを示す。notification/delta fixtureは型付きprogress/result Eventへ縮約し、raw deltaとThread IDを通常journal/Projection/auditへ無制限・平文で出さない。
- AC-AGT-005: warm/cold latency fixtureが同一app-server process/connectionと同一Threadが再利用された証拠を記録し、Agent Session Context以外がexternal binding/status/correlationを所有せず、AdapterがWorldStateを変更しないことを示す。
- AC-AGT-006: 同じThreadでAを開始後Bを開始し、Aのdelayed/duplicate resultとstale cancelを注入するfixtureが、AのBinding/Recovery/auditだけを更新し、BのState、Presentation、cancel、terminal、Effect Graphを変更しないことを示す。

## REQ-SCP-001 — 初期release scopeを有限かつnon-streamingに固定する

初期TTSはnon-streamingであり、初期Effect Graphはaudio chunk、stream queue、chunk間backpressureを持たない。long-duration transcription、simultaneous interpretation、surveillance、continuous conversationは延期する。初期Codex capabilityはSkillCreator、Search、Fetchを必須とする。Codexは自身の権限で外部Skill資産を作成できるが、Y2はその作成に追加承認/制限を加えず、正式Behavior version updateなしにY2の信頼済み型・catalog・ownershipを変更しない。

受入条件:

- AC-SCP-001: 初期TTS fixtureが単一のnon-streaming synthesis/playback Effectとterminal/Recovery Eventを持ち、audio chunk、stream queue、chunk worker、backpressure edgeをGraphへ生成しない。
- AC-SCP-002: long-duration transcription、simultaneous interpretation、surveillance、continuous conversationのrequest fixtureが初期Behaviorへ暗黙routing/fallbackせず、typed unsupported/deferred結果を返す。
- AC-SCP-003: SkillCreator、Search、Fetch capability fixtureが初期catalogで必須と分かり、Codex Skill作成が正式Y2 Behavior/Rule/Policy/Port/Effect/ownership変更を自動発生させず、Search/FetchがREQ-NET-001のallowlist/provenance/transfer authorizationを守ることを示す。

## REQ-LOG-001 — 運用logを状態・記憶・監査から分離する

operations logは既定30日、audit logは90日、debug logは7日のrolling retentionとし、設定で変更できる。journal、pending EffectOccurrence、Recovery、snapshot/stateはlog retentionの対象外である。通常logはraw audio/image、secret、full Conversation、SemanticMemoryを既定で含めない。reflex commandは構造化operations logだけに残しMemoryへ保存しない。cleanupは明示PolicyからEffect、result Event、Failureまでを持ち、失敗を観測可能にする。

受入条件:

- AC-LOG-001: operations 30日/audit 90日/debug 7日のrolling cleanup fixtureが設定値を適用し、journal/pending/recovery/stateを削除対象に含めない。
- AC-LOG-002: raw audio/image、secret、full Conversation、SemanticMemory、reflex commandのfixtureが、通常logとauditの許可面を分離し、reflexがMemoryへ保存されないことを示す。
- AC-LOG-003: retention cleanup fixtureがDecision、Effect、result Eventを相関し、delete Failure/OutcomeUnknownを成功として隠さずRecoveryまたは型付きFailureへ残す。

## 未決の具体化

この契約で決めないものは、RTSPやMimyのbuffer/reconnect手順、pre-roll/guard/settleの数値、Memory schemaと保存engine、Artifact store、Linux package/installerの実装、doctor実装、Quality Profileの閾値・測定時間、network allowlistの中身、citation形式、Providerごとのmodel/credential、Codex transportのspike結果である。これらは上のREQ/ACを弱めず、後続のspike、ADR、version付きPolicy/Profileで定める。
