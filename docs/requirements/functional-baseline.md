# Yatagarasu 1 機能基準

Yatagarasu 1は、Yatagarasu 2へ移植するコードの一覧ではありません。実機が発見し、成立を証明した機能世界です。

この文書は、主要能力が監査台帳の奥に隠れて要件漏れになることを防ぎます。具体的な根拠、revision、採否理由は[根拠監査台帳](source-audit.md#yatagarasu-1実機機能要件)を正とします。

## 分類

| 分類 | 意味 |
| --- | --- |
| 必須基準 | Y2が体験または構造として継承する。具体実装は交換可能。 |
| 契約未決の継承基準 | 能力の価値は継承するが、privacy、権限、Provider、保存などの契約が未決。 |
| 延期 | 将来価値を認めるが、初期の必須実装にはしない。 |
| 実装方式は非採用 | Y1の機能は受け継ぐが、直接呼出しや中央手順などの実装形は移植しない。 |

## 必須基準

| 能力 | Y1で発見したこと | Y2で守る入口 |
| --- | --- | --- |
| テキストInteraction | CLI等からAIへ依頼できる | REQ-PRD-001, REQ-FR-001 |
| 常時音声、WakeWord、VAD、STT、stop word | 耳は一回限りの録音ではなく生存期間を持つ | REQ-PRD-001, ADR-006 |
| SBERT意味ルーティング | 意味の反射がLLM待ちを避け、実機体験を大きく改善する | REQ-ARC-005, REQ-ARC-008, ADR-008 |
| 相対カメラ操作と校正 | 身体操作はLLMなしでも決定でき、姿勢の事実とは分ける必要がある | REQ-PHY-003, ADR-009 |
| 撮影と画像解釈 | 撮影成果物が有効な場合だけAIへ渡す | REQ-PER-001, ADR-009 |
| 複合要求 | 移動、撮影、解釈は一つの関数ではなく依存する仕事群である | REQ-PER-001 |
| 実機End-to-End | Fake境界だけでなく、本物の目・耳・口を一つの因果列として動かす必要がある | REQ-PRD-003 |
| 区間別遅延計測 | 反射速度を守るには、総時間だけでなくwake、STT、routing、dispatch等を分けて測る必要がある | REQ-NFR-001 |
| 音声promptと応答再生 | 口には再生時間、取消、成果物の生存期間がある | REQ-OPS-004, REQ-OPS-006 |
| Skillによる能力拡張 | AIがロボット外のアプリ、データ、能力へ接続できる | REQ-PRD-002, REQ-ARC-007 |
| 動的LLM／Provider選択 | SBERTの反射で用途に合うlocal／external推論能力を選び分ける | REQ-PRD-004, ADR-011 |
| 設定と能力診断 | 設定、Workspace、状態、cacheを分け、採用元と能力を診断する | REQ-CFG-001, REQ-CFG-004 |
| 安全な設定変更とUpgrade | 型検証、原子的保存、反映範囲、利用者資産保護が必要である | REQ-CFG-002, REQ-CFG-003 |
| 会話に閉じない振る舞い | Tapo完結、Web完結、Hybridの機能を会話やLLM必須にせず実行する | REQ-PRD-005, ADR-015 |
| Web身体面と公開API | 文字、操作、映像、状態をWebで扱い、標準画面も公開APIを使う | REQ-PRD-006, REQ-API-001–003, ADR-014 |
| 単一Active Qualia | 一度に一つの振る舞いへ集中し、自律神経だけを並行稼働する | REQ-FR-005, ADR-013 |
| Home復帰 | 音声制御語とWeb常設操作から現在Qualiaへ終了を要求する | REQ-FR-006, ADR-013 |
| SBERTによるBehavior選択 | 既知機能を反射的に選び、候補なしだけを会話へfallbackする | REQ-FR-007, ADR-008 |
| 一Server・一Workspace・一Owner | 一人のOwnerが複数browser、token、deviceを利用する | REQ-API-004, ADR-014 |

## 契約未決の継承基準

| 能力 | 継承する価値 | 未決の契約 |
| --- | --- | --- |
| recall | 過去の記憶を現在の判断へ使う | memory保持、privacy、検索結果の意味 |
| memorize | 利用者の明示依頼で記憶を保存する | 同意、削除、保存期間、migration |
| search / fetch | 現在の外部情報を取得して考える | network許可、取得先、citation、Failure、同意 |
| Skill作成 | 新しいAI接続面を増やす | 作成権限、検証、配備、rollback、安全方針 |
| 長期会話文脈 | 「もう少し」など前の行動を踏まえる | Conversation保持、privacy、Provider越境 |

これらを未決とするのは、機能を捨てるためではありません。価値を継承したまま、危険な前提を実装前に確定しないためです。

## 延期

| 能力 | 扱い |
| --- | --- |
| cron等による定時自律 | 将来、共通Inbound Adapterとして導入する。第二の制御中枢にしない。 |
| ストリーミングTTS | 応答速度への価値は高いが、採否と優先度はOPEN。採用時の条件だけ要件化済み。 |

## 実装方式は非採用

Y1の直接subprocess、network、filesystem制御や、機能知識を集めた中央の時間順処理はY2 Coreへ移植しません。これはY1の機能を否定する判断ではありません。Y1が発見した機能を、Port、Adapter、Rule、Policy、Effect Graphへ再記述する判断です。

この分類を変更するときは、[根拠監査台帳](source-audit.md)と[トレーサビリティ](traceability.md)を同時に更新します。
