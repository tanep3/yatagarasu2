# プロダクト要件

## 目的: 日常のやり取りでロボットを理解しやすく役立つものにする

### REQ-PRD-001 — 目・耳・口

製品は、利用者が音声またはテキストでInteractionを依頼し、必要に応じて利用可能な観測または身体操作を用い、利用可能な出力チャネルから応答を受け取れることを目指す。

受入条件:

- AC-PRD-001: デモ実装が、音声起点とテキスト起点を各一つ受理し、共通のInteraction状態を公開できる。
- AC-PRD-002: Interactionに起因する応答が、観測、仮定、または物理観測なしのいずれに基づくかを示す。

### REQ-FR-001 — 受理後の入力意味は等価

入力を受理した後、システムは音声、Web、CLIの要求を同じInteraction意味論で表現する。入力元はチャネル方針へ影響してよいが、別のドメイン処理経路を作ってはならない。

受入条件:

- AC-FR-001: 二つの対応Inbound Adapterから同じテキストを投入すると、source provenance以外は同じ受理済みInteraction Event形状になる。
- AC-FR-002: 適合テストにより、PlanningがAdapter固有の業務ロジックではなく受理済みInteractionから選ばれることを示せる。

### REQ-FR-002 — Interaction進行を参照可能にする

システムは、利用者または運用者に適したProjectionへ、Interactionの進行と型付きFailureを提供する。

受入条件:

- AC-FR-003: Projectionが、試験用Interactionの accepted、executing、completed、cancelled、failed の状態を表示する。
- AC-FR-004: 外部処理の失敗が、未解析の例外文字列ではなく型付きFailure分類として表示される。

### REQ-FR-003 — 中止の要求と結果を混同しない

利用者は共通のInteraction境界から中止を要求できる。Webの中止操作は直ちに同じ境界へ
`CancelRequested`を投入する。中止の受理、保留仕事の取消、実行中の取消結果、物理結果は別々に
参照可能でなければならない。

受入条件:

- AC-FR-005: Webと別のInbound Adapterの中止要求は、同じ型付き`CancelRequested`事実を生む。
- AC-FR-006: Projectionは取消要求を外部処理の停止または物理結果の証拠として表示しない。

### REQ-FUT-001 — 定時自律はInboundの関心事

スケジュールまたはcron起点の自律動作は将来の作業である。導入時は他の入力と同じCommand/Event境界を通るInbound Adapterとして入る。

受入条件:

- AC-FUT-001: 実装前に、スケジュールAdapterの契約と、共通Inbound境界から投入されることを示すテストが承認される。

プロダクト説明の例は説明用であり、要件を追加しない。
