# プロダクト要件

## 目的

目・耳・口は部品一覧ではありません。利用者が頼み、Yatagarasuが必要な観測や身体操作を選び、確認できた事実に基づいて応答する、一つのロボット体験として結びます。

### REQ-PRD-001 — 目・耳・口を一つのInteractionに結ぶ

製品は、利用者が音声またはテキストでInteractionを依頼し、必要に応じて利用可能な観測または身体操作を用い、利用可能な出力チャネルから応答を受け取れることを目指す。

受入条件:

- AC-PRD-001: デモ実装が、音声起点とテキスト起点を各一つ受理し、共通のInteraction状態を公開できる。
- AC-PRD-002: Interactionに起因する応答が、Observed（観測済み）、Assumed（仮定済み）、または物理観測なしのいずれに基づくかを示す。これは表示上の装飾ではなく、利用者へ物理世界について嘘をつかないための証拠である。

### REQ-PRD-002 — Skillによって人とAIがアプリの世界を共有する

製品は、Skillを通して人が使うアプリ、データ、能力をAIへ接続できなければならない。Skillは作業指示書だけを意味せず、人とAIが同じアプリ所有の世界へ異なる入口から関われる接続面である。Skill追加のためにKernelへ製品固有の主手順を追加してはならない。

受入条件:

- AC-PRD-003: 試験用アプリの同じデータを、人向け入口とSkill入口から参照でき、データの所有者がYatagarasu Coreへ移らないことを示す。
- AC-PRD-004: 試験用Skillを一つ追加しても、Kernelにそのアプリ名または製品固有の条件分岐を追加せず、能力一覧と境界契約から利用可能にできる。

### REQ-PRD-003 — 実機による代表Interaction

対応実機構成において、Yatagarasu 2は、相対身体操作、撮影と画像解釈、それらを結ぶ複合要求、音声入力から音声応答までを、実際の外部I/Oを含む一つの因果列として実行できなければならない。Fake Adapterだけの試験はこの要件の受入証拠にならない。

受入条件:

- AC-PRD-005: 「右を向いて」に相当する入力により、対応実機のカメラ移動Effectがdispatchされ、Adapterの開始・結果EventがCoreへ戻り、物理結果がObservedまたはAssumedとして記録される。AssumedはObservedへ昇格しない。
- AC-PRD-006: 対応実機から画像を取得し、有効なArtifactRefとしてAgentへ渡し、画像に基づく回答を得られる。撮影Failureまたは無効ArtifactRefではAgentへ画像解釈を要求しない。
- AC-PRD-007: 「右を向いて何が見える？」が、移動、想定動作時間、撮影、画像解釈、応答の因果列を生成する。移動のDefinitelyNotApplied、Failure、OutcomeUnknownは下流を止め、Assumedから進む場合は明示Policyを要求する。
- AC-PRD-008: 実音声入力がWakeWord、VAD/STT、Interaction受理を経て応答を生成し、対応TTS／再生Adapterから少なくとも再生開始の結果Eventが返る。

### REQ-PRD-004 — SBERTで推論能力を動的に選択する

製品は、少なくともローカル推論能力と外部推論能力をlogical profile（論理プロファイル）として構成し、SBERTの意味候補と決定方針により、LLMへ選択判断を求めずにLLM modelおよびProvider routeを選択できなければならない。速度重視、Vision、高性能推論などの論理プロファイルを、具体製品名と分離して扱う。具体的なProvider再構成、会話継続、切替中Interaction、利用者同意、privacy、Recovery方式は個別Policyとして未決に保つ。

受入条件:

- AC-PRD-009: 対応構成が、利用可能なローカル推論能力と外部推論能力を、能力広告と論理プロファイルとして各一つ以上公開できる。
- AC-PRD-010: 速度重視、Vision、高性能推論の代表入力が、SBERT候補とversion付きPolicyにより異なる論理プロファイルへ解決され、route選択のためのLLM requestを生成しない。
- AC-PRD-011: 選択したpreferred route（希望経路）と、可用性・Policy適用後のeffective route（実効経路）が別々に参照でき、縮退または拒否理由を型付き結果として示す。

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
