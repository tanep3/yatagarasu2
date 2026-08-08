# プロダクト要件

## 目的

目・耳・口とWebは部品一覧ではありません。Yatagarasu 2は、物理世界、利用者、AI、アプリを結び、交換・追加可能な振る舞いを実行するロボット基盤です。会話は中心手順ではなく、選択できる振る舞いの一つです。

### REQ-PRD-001 — 目・耳・口を一つのInteractionに結ぶ

製品は、利用者が音声またはテキストでInteractionを依頼し、必要に応じて利用可能な観測または身体操作を用い、利用可能な出力チャネルから応答を受け取れることを目指す。

受入条件:

- AC-PRD-001: デモ実装が、音声起点とテキスト起点を各一つ受理し、共通のInteraction状態を公開できる。
- AC-PRD-002: Interactionに起因する応答が、Observed（観測済み）、Assumed（仮定済み）、または物理観測なしのいずれに基づくかを示す。これは表示上の装飾ではなく、利用者へ物理世界について嘘をつかないための証拠である。

### REQ-PRD-002 — Codex SkillとY2 Behaviorを分けて人とAIがアプリの世界を共有する

製品は、Codex Skillを通して人が使うアプリ、データ、能力をAIへ接続できなければならない。Codex SkillはCodexの作業能力またはアプリ/AI接続面であり、version付きrobot機能であるY2 Behaviorとは別である。初期Codex capabilityにはSkillCreator、Search、Fetchを含める。OwnerはSkillCreatorへSkill作成と初期実行権限構成を包括委任し、作成ごとの承認操作なしで`SKILL.md`、Python、Web、scriptとSkill単位grantを有効化できる。作成済みSkillはgrantの範囲でWorkspace外の外部アプリ、ファイル、network、secret、副作用へ接続できるが、自身のgrantを拡大しない。ただし外部資産は正式Y2 Behavior updateなしに信頼済みBehavior、Rule、Policy、Port、Effect、ownership/catalogを変更しない。Skill追加のためにKernelへ製品固有の主手順を追加してはならない。

受入条件:

- AC-PRD-003: 試験用アプリの同じデータを、人向け入口とSkill入口から参照でき、データの所有者がYatagarasu Coreへ移らないことを示す。
- AC-PRD-004: 試験用Skillを一つ追加しても、Kernelにそのアプリ名または製品固有の条件分岐を追加せず、能力一覧と境界契約から利用可能にできる。
- AC-PRD-016: SkillCreator、Search、Fetchが初期Codex capabilityとして存在し、Codex Skillが作る外部ファイルをY2の信頼済みBehavior/Rule/Policy/Port/Effectまたは状態所有へ自動昇格させないことを示す。Search/FetchはREQ-NET-001のallowlist、provenance、transfer authorizationを通る。
- AC-PRD-018: Ownerの包括委任から作成された試験Skillが、作成ごとの承認UIなしで初期grantの範囲にあるWorkspace外アプリデータを読み書きできる一方、自身のgrantまたはY2 Behaviorを拡大できないことを示す。

### REQ-PRD-003 — 実機による代表Interaction

初期対象機種はTapo TC70とTapo C210とする。第一基準かつ初期releaseの必須実機はY1で実績のあるTC70、第二基準はC210であり、同時対応を目指す。C210対応が困難な場合は、初期TC70契約を弱めず追加の機種profileとして後続対応できる。製品名はAdapter/bootstrap/profileに閉じ、Coreの型・Rule・Policyへ持ち込まない。対応実機構成において、Yatagarasu 2は、相対身体操作、撮影と画像解釈、それらを結ぶ複合要求、音声入力から音声応答までを、実際の外部I/Oを含む一つの因果列として実行できなければならない。Fake Adapterだけの試験はこの要件の受入証拠にならない。

受入条件:

- AC-PRD-005: 「右を向いて」に相当する入力により、対応実機のカメラ移動Effectがdispatchされ、Adapterの開始・結果EventがCoreへ戻り、物理結果がObservedまたはAssumedとして記録される。AssumedはObservedへ昇格しない。
- AC-PRD-006: 対応実機から画像を取得し、有効なArtifactRefとしてAgentへ渡し、画像に基づく回答を得られる。撮影Failureまたは無効ArtifactRefではAgentへ画像解釈を要求しない。
- AC-PRD-007: 「右を向いて何が見える？」が、移動、想定動作時間、撮影、画像解釈、応答の因果列を生成する。移動のDefinitelyNotApplied、Failure、OutcomeUnknownは下流を止め、Assumedから進む場合は明示Policyを要求する。
- AC-PRD-008: 実音声入力がWakeWord、VAD/STT、Interaction受理を経て応答を生成し、対応TTS／再生Adapterから少なくとも再生開始の結果Eventが返る。
- AC-PRD-019: TC70を第一基準としてAC-PRD-005–008を実機で満たし、対象hardware/firmware、device profile、Adapter versionを記録する。C210は第二基準として同じ証拠を目指し、未達ならtyped unsupported/deferredと後続profile計画を示す。どちらもCoreへ製品名分岐を追加しない。

### REQ-PRD-004 — SBERTで推論能力を動的に選択する

製品は、少なくともローカル推論能力と外部推論能力をlogical profile（論理プロファイル）として構成し、SBERTの意味候補と決定方針により、LLMへ選択判断を求めずにLLM modelおよびProvider routeを選択できなければならない。初期Agent adapterはCodexのみであり、Provider choiceはCodex default経由のOpenAI、Hoshikage、Ollama APIだけとする。各routeは`CodexThread`または`NoExternalContinuity`の文脈継続能力を広告し、effective routeとともにdispatch前へ固定する。Codex Threadを継続できるrouteだけがexact Threadをresumeし、非対応routeへThread継続を要求または偽装しない。local/remoteおよびSBERT-policyの選択は明示configured choiceであり、設定変更は次Interactionからのみ適用し、active turnをrebindせず、Provider間/local-remote間/同一Provider内の自動fallbackをしない。失敗はtyped terminal FailureまたはRecoveryとする。

受入条件:

- AC-PRD-009: 対応構成が、利用可能なローカル推論能力と外部推論能力を、能力広告と論理プロファイルとして各一つ以上公開できる。
- AC-PRD-010: 速度重視、Vision、高性能推論の代表入力が、SBERT候補とversion付きPolicyにより異なる論理プロファイルへ解決され、route選択のためのLLM requestを生成しない。
- AC-PRD-011: 選択したpreferred route（希望経路）と、configured authorization・可用性・Policy適用後のeffective route（実効経路）が別々に参照でき、selection、rejection、Failureの理由を型付き結果として示す。自動縮退/fallbackを示してはならない。
- AC-PRD-017: 初期Provider choice以外を要求する、またはeffective route bind後に設定変更/利用不能を注入するfixtureが、active turnをrebindせず自動fallbackもせず、次Interactionへ新設定を適用し、現在turnにはtyped terminal Failure/Recoveryを返す。
- AC-PRD-020: OpenAI/Codex routeとHoshikage/Ollamaの対応profileが文脈継続能力を広告し、`CodexThread` routeだけがexact Thread resumeを要求する。`NoExternalContinuity` routeは現在入力と選択済みSemanticMemoryだけで開始し、route切替後も存在しない外部履歴を継承したと表示しない。

### REQ-PRD-005 — 会話に閉じない振る舞いを提供する

製品は会話を中心手順に固定せず、文字起こし、同時通訳、見守り、身体操作、Webだけで完結する機能など、性質の異なる振る舞いを同じ実行法則の上へ正式version updateで追加できなければならない。振る舞いはTapo等の物理デバイスだけ、Webだけ、または両方を組み合わせて成立してよい。会話、LLM request、音声応答を全振る舞いの必須段階にしてはならない。この例示は、列挙した機能すべてを初期実装の必須範囲にするものではない。

受入条件:

- AC-PRD-012: Tapoだけで完結する振る舞い、Webだけで完結する振る舞い、TapoとWebを組み合わせる振る舞いの各fixtureが、同じQualia（クオリア）・Command・Event・Effect Graphの法則を利用し、会話またはLLMを不要な経路では生成しない。
- AC-PRD-013: 初期の有限Conversation Behaviorについてversion付きBehavior適合manifestとarchitecture conformance fixtureが存在し、単一クオリアのLifecycle、State所有、終了、Recovery契約への適合を検証できる。long-duration transcription、simultaneous interpretation、surveillance、continuous conversationはREQ-SCP-001により初期scope外であり、対応manifestを初期受入条件にしない。

### REQ-PRD-006 — WebをYatagarasuの身体面として提供する

Webは管理画面だけではなく、文字、ボタン、タッチ、画像、映像、状態、成果物を利用者とYatagarasuの間で交換する正式な身体面である。標準Web画面はPCとスマートフォンへ対応し、利用者向け全機能の公開APIを使用する。複数の対応デバイスを一人の利用者の身体能力として参照・選択できなければならない。

受入条件:

- AC-PRD-014: 標準Web画面が、スマートフォンとPCの表示幅で、現在のクオリア、進行、型付き結果、成果物、利用可能デバイス、常設Home操作を表示または操作できる。
- AC-PRD-015: 対応する複数カメラをWebから選択しても、Workspace、Owner、またはクオリアを増やさず、選択したdevice identityを型付きCommandへ含められる。一つの振る舞いが複数deviceを明示的に使うことも妨げない。

### REQ-FR-001 — 受理後の入力意味は等価

入力を受理した後、システムは音声、Web、CLIの要求を同じInteraction意味論で表現する。入力元はチャネル方針へ影響してよいが、別のドメイン処理経路を作ってはならない。

受入条件:

- AC-FR-001: 二つの対応Inbound Adapterから同じテキストを投入すると、入力元の出所情報以外は同じ受理済みInteraction Event形状になる。
- AC-FR-002: 適合テストにより、PlanningがAdapter固有の業務ロジックではなく受理済みInteractionから選ばれることを示せる。

### REQ-FR-002 — Interaction進行を参照可能にする

システムは、利用者または運用者に適したProjectionへ、Interactionの進行と型付きFailureを提供する。

受入条件:

- AC-FR-003: Projectionが、試験用Interactionのaccepted、executing、completed、cancelled、failedの状態を表示する。
- AC-FR-004: 外部処理の失敗が、未解析の例外文字列ではなく型付きFailure分類として表示される。

### REQ-FR-003 — 中止の要求と結果を混同しない

利用者は共通のInteraction境界から中止を要求できる。Webの中止操作は直ちに同じ境界へ`CancelRequested` Commandを投入する。中止の受理は`CancellationAccepted` Eventとし、保留仕事の取消、実行中の取消結果、物理結果と別々に参照可能でなければならない。

受入条件:

- AC-FR-005: Webと別のInbound Adapterの中止要求は、同じ型付き`CancelRequested` Commandを生み、受理時は別の`CancellationAccepted` Eventを生む。
- AC-FR-006: Projectionは取消要求を外部処理の停止または物理結果の証拠として表示しない。

### REQ-FR-004 — 校正をLLMなしの反射経路で解決する

カメラ校正は、SBERTが返す意味候補と校正候補に固有のキーワード／規則gateが決定論的Policyに一致する場合、LLM requestまたはProposalを生成せず、Policy承認済みEffect Graphへ解決する。安全方針、Capability方針、依存関係、resource claimを迂回してはならない。

受入条件:

- AC-FR-007: gray bandの校正候補を校正固有gateが受理するfixtureが、LLM request／Proposalなしに校正Effect Graphを生成する。
- AC-FR-008: 同じ入力が安全方針またはCapability方針で拒否された場合、校正Effectをdispatchせず、型付き拒否結果を返す。

### REQ-FR-005 — Activeなクオリアを一つに保つ

Qualia（クオリア）は、Yatagarasuが現在どの振る舞いとして世界を知覚し活動しているかを表す。システム全体で現在の非Home qualia sessionは0または1とする。ここでいう「一つ」はLifecycleのActive phaseだけでなく、Starting、Active、Terminating、Recoveringにある現在session全体を指す。Homeは現在sessionがない基本待受状態とし、非Homeの間に別クオリアの開始要求を受理してはならない。Home／Stop検知、永続化、Recovery、診断、認証、Web状態同期などの自律神経は並行稼働してよいが、第二のクオリアまたは製品固有の司令塔になってはならない。

受入条件:

- AC-FR-009: table-driven fixtureがHome、Starting、Active、Terminating、Recoveringの各状態で開始要求を評価し、Homeからだけ開始を受理する。
- AC-FR-010: Activeまたは終了途中で別クオリアを要求するfixtureが型付きBusy結果を返し、新しいクオリアState、Effect Graph、Effect、dispatchを一切生成しない。
- AC-FR-011: 自律神経の一つを停止・再開してもActive Qualiaの唯一性を破らず、そのserviceがQualia Stateを直接変更しないことを示す。

### REQ-FR-006 — Home復帰を独立制御経路にする

音声の設定可能な制御語とWebの常設Home操作は、共通の型付き`ReturnToHomeRequested` Commandを投入する。音声の既定語句は「ヤタガラス、ホーム」とする。要求は現在のクオリアへ終了を求め、終了処理、成果物確定、取消結果、物理結果と区別する。Home復帰の受理またはクオリア終了を、停止不能な外部作用が停止した証拠にしてはならない。

受入条件:

- AC-FR-012: 既定音声制御語とWebの常設Home操作が、出所情報以外は同じ`ReturnToHomeRequested` Commandを生む。
- AC-FR-013: Home要求fixtureが新規仕事のadmissionを止め、pending仕事を永続取消し、対応可能なin-flight取消と成果物確定を要求した後、`TerminationCompleted`、`TerminationPending`、`TerminationFailed`、`TerminationOutcomeUnknown`を区別する。
- AC-FR-014: 文字起こし中もHome制御語の検知経路が生存し、通常音声は文字起こしへ、Home制御語はQualia終了要求へ別々に渡る。

### REQ-FR-007 — 振る舞い選択と推論能力選択を分離する

HomeでYatagarasuを起点とする通常のBehavior routing構成は、独立制御語の評価後、SBERTの意味候補とversion付きDecision Policyにより振る舞い候補を解決する。ただしCapability Policyは、REQ-ARC-008に従いrule-only、LLM-proposal-only等のContributor構成を明示できる。振る舞い選択と、その振る舞いが必要とするLLM／Providerの推論route選択は別のDecisionとして表す。宣言されたContributorを評価して有効な振る舞い候補がない場合は会話クオリアへfallbackする。安全・権限・能力方針で拒否された候補を、会話またはLLM経由で迂回してはならない。

受入条件:

- AC-FR-015: 既知の文字起こし開始入力がSBERT候補とPolicyにより文字起こしクオリアへ解決され、機能選択のためのLLM requestを生成しない。
- AC-FR-016: 通常SBERT構成と明示rule-only構成の候補なしfixtureが、各構成で宣言されたContributorを評価した後にだけ`FallbackToConversation` Decisionを返し、会話クオリアを開始する。Policy拒否fixtureは同じfallbackを返さず、拒否結果と無Effectを示す。
- AC-FR-017: 画像を伴う会話fixtureが、振る舞いとして会話を選ぶDecisionと、Vision用論理プロファイルを選ぶDecisionを別々に記録する。

### REQ-NFR-001 — Interaction遅延を因果区間ごとに測定可能にする

システムは、利用者体験へ影響するInteraction遅延を、単一の総時間だけでなく因果区間ごとに単調時刻で測定できなければならない。数値budgetは実機spike後にADRまたはversion付きprofileへ定める。

受入条件:

- AC-NFR-001: wake検出、入力受付、VAD/STT確定、意味routing開始・終了、Effect dispatch、物理Effect開始・結果、capture完了、Agent request、first response、playback開始の対応境界に、同一Interactionへ関連付けられる単調時刻を持つ。
- AC-NFR-002: 決定論的なSBERT反射経路がLLM requestを生成せず、STT確定からroute決定、route決定から最初のEffect dispatchまでを独立計測できる。
- AC-NFR-003: 代表実機Interactionの計測結果を、総時間と区間別時間の両方で出力し、各区間の欠測理由を型付き状態として示す。

### REQ-FUT-001 — 定時自律はInboundの関心事

スケジュールまたはcron起点の自律動作は将来の作業である。導入時は他の入力と同じCommand/Event境界を通るInbound Adapterとして入る。

受入条件:

- AC-FUT-001: 実装前に、スケジュールAdapterの契約と、共通Inbound境界から投入されることを示すテストが承認される。

説明文書の体験例は、ここにIDを持つ要件を自動的に追加しない。
