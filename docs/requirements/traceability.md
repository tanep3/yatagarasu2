# トレーサビリティ、矛盾、未決事項

## 要件トレーサビリティ

| 要件 | 受入条件 | 判断・説明 |
| --- | --- | --- |
| REQ-PRD-001 | AC-PRD-001, AC-PRD-002 | ADR-002; Product experience |
| REQ-PRD-002 | AC-PRD-003, AC-PRD-004 | ADR-007; Skill boundary; Y1 capability baseline |
| REQ-PRD-003 | AC-PRD-005, AC-PRD-006, AC-PRD-007, AC-PRD-008 | Product experience; ADR-005; ADR-009 |
| REQ-PRD-004 | AC-PRD-009, AC-PRD-010, AC-PRD-011 | ADR-011; Domain model; Runtime boundaries |
| REQ-FR-001 | AC-FR-001, AC-FR-002 | ADR-003; Domain model |
| REQ-FR-002 | AC-FR-003, AC-FR-004 | Domain model |
| REQ-FR-003 | AC-FR-005, AC-FR-006 | ADR-010; Domain model |
| REQ-FR-004 | AC-FR-007, AC-FR-008 | ADR-008; Architecture requirements |
| REQ-NFR-001 | AC-NFR-001, AC-NFR-002, AC-NFR-003 | ADR-011; Product acceptance |
| REQ-ARC-001 | AC-ARC-001, AC-ARC-002 | ADR-003; Design philosophy |
| REQ-ARC-002 | AC-ARC-003, AC-ARC-004, AC-ARC-017 | ADR-003 |
| REQ-ARC-003 | AC-ARC-005, AC-ARC-006 | ADR-003; Persistence and uncertainty |
| REQ-ARC-004 | AC-ARC-007, AC-ARC-008 | ADR-007 |
| REQ-ARC-005 | AC-ARC-009, AC-ARC-010 | ADR-008; Domain model |
| REQ-ARC-006 | AC-ARC-012 | ADR-008; ADR-009; Domain model |
| REQ-ARC-007 | AC-ARC-014, AC-ARC-015, AC-ARC-016 | ADR-007; Domain model; Runtime boundaries |
| REQ-ARC-008 | AC-ARC-013, AC-ARC-018 | ADR-008; Architecture requirements |
| REQ-ARC-009 | AC-ARC-011, AC-ARC-019, AC-ARC-020 | ADR-008; Architecture requirements |
| REQ-PER-001 | AC-PER-001, AC-PER-002 | ADR-003 |
| REQ-PHY-001 | AC-PHY-001, AC-PHY-002 | ADR-005 |
| REQ-PHY-002 | AC-PHY-003, AC-PHY-004, AC-PHY-005, AC-PHY-006 | ADR-005 |
| REQ-PHY-003 | AC-PHY-007, AC-PHY-008, AC-PHY-009 | ADR-009; Persistence and uncertainty |
| REQ-OPS-001 | AC-OPS-001 | ADR-002 |
| REQ-OPS-002 | AC-OPS-002, AC-OPS-003 | ADR-004 |
| REQ-OPS-003 | AC-OPS-004, AC-OPS-005, AC-OPS-006 | ADR-004 |
| REQ-OPS-004 | AC-OPS-007, AC-OPS-008, AC-OPS-010, AC-OPS-011 | ADR-005 |
| REQ-SEC-001 | AC-SEC-001 | 運用要件; ADR-007 |
| REQ-OPS-005 | AC-OPS-009 | ADR-006; ADR-007 |
| REQ-OPS-006 | AC-OPS-012, AC-OPS-013, AC-OPS-014, AC-OPS-019 | ADR-010; Persistence and uncertainty |
| REQ-OPS-007 | AC-OPS-015, AC-OPS-016 | ADR-009; Domain model |
| REQ-OPS-008 | AC-OPS-017, AC-OPS-018, AC-OPS-020, AC-OPS-021, AC-OPS-022, AC-OPS-023 | ADR-005; ADR-010; Runtime boundaries |
| REQ-CFG-001 | AC-CFG-001, AC-CFG-002, AC-CFG-003 | ADR-012; Configuration architecture |
| REQ-CFG-002 | AC-CFG-004, AC-CFG-005, AC-CFG-006 | ADR-012; Configuration architecture |
| REQ-CFG-003 | AC-CFG-007, AC-CFG-008 | ADR-012; Configuration architecture |
| REQ-CFG-004 | AC-CFG-009, AC-CFG-010, AC-CFG-011 | ADR-012; Runtime boundaries |
| REQ-FUT-001 | AC-FUT-001 | ADR-007 |

## 矛盾索引

Yatagarasu 1の実機で検証済み機能要件と、凍結済みYatagarasu 2構造要件は補完的な基準資料です。原則採用し、除外はAccepted ADRとの矛盾、後続資料による訂正、既知欠陥、意図的延期、Y2範囲外のいずれかと理由を明記します。`04-agentization-requirements-draft.md`には、後続の基準資料（`05`、`06`）および現在のAccepted decisionと矛盾する初期要求があります。履歴を黙って書き換えず、次の表で明示します。全件の採否は[根拠監査台帳](source-audit.md)にある。

| 凍結資料の箇所 | 矛盾する後続・新規判断 | 正本での解決 |
| --- | --- | --- |
| 凍結04 §8.1、§13 Phase 3、§15、§16: `listend` がAgent/Webをsuperviseする | 凍結05 §3.1および凍結06 §8が`listend`をsupervisorから外す | 旧supervisor契約は採用しない。process managementは未決であり、domain所有権にならない。ADR-002/003。 |
| 凍結04 §9および§10.4: 固定Unix socket UTF-8 JSONL IPC | 凍結05 §3.3がUnix socket/JSONLを候補にとどめる | IPCは延期する。transport schemaはdomain型ではない。ADR-003。 |
| 凍結06 §6.1: Mimyがgo2rtcへ直接接続する | 新しいaudio topology判断 | Mimyは汎用でsource-agnosticとし、go2rtcはsource adapterの一例にする。ADR-006。 |
| 凍結02 §2.1: Voice GatewayがVAD/STTを所有する。凍結06 §6.1: Mimyがsource/ring bufferを常時維持し、wakeでsessionを作成・releaseする | 新しいwake/session所有判断 | Yata WakeとMimyは接続/buffer状態をそれぞれ独立して所有する。Acoustic Contextがwake acceptance/promptを所有し、Mimy sessionのcreate/releaseをcommandする。ADR-006。 |
| 凍結04 §5、§8.3、§8.6: Agentがmodel/provider/thread/turn制御を所有する | 凍結05 §3.2/§9および新しいdomain判断 | Kernelと名前を持つContextがdomain stateを所有する。Python/外部capabilityはWorldState、plan、provider state、conversation stateを所有しない。ADR-003。 |
| 凍結04 §9: IPC例を要件として扱う | 新しい要件規律 | 明示的制約でない限り、具体vendor/transport機構は要件にしない。ADR-001。 |
| 凍結01 §14および凍結04の逐次実行例: move後にcapture/LLMを無条件実行する | ADR-009のGraph guardと物理不確実性 | move Failure/OutcomeUnknown、capture Failure、無効ArtifactRefは下流をblockする。Assumed継続には明示Policyが必要。 |
| 凍結02 §8.3の取消分類 | ADR-010のdurable revocationと遅延結果 | `CancelRequested` Command、`CancellationAccepted` Event、revocation、in-flight取消結果、physical outcomeを分ける。physical moveはdispatch後non-cancellable。 |
| 凍結04のSBERT単独状態更新・固定Intent経路 | ADR-008の複数contributor解決 | SBERTは候補/score/provenanceを返し、version付きPolicyと純粋resolutionで決める。LLM/CodexはProposal境界を越えない。 |
| Y1 `intent_router.py`: keyword gateをscore band分類より前に適用し、middle候補をLLMへ送る | ADR-008の通常routing Policy | Y2ではgray candidateを動作候補固有のkeyword/rule gateで受理可能にし、LLMへ送るかは純粋resolution Policyが決める。calibrationが決定論的Policyに一致するときはLLM request/Proposalを作らない。rule-only/LLM-proposal-onlyも明示capability Policyで選べる。 |

## 思想から要件までの導出

この表は要求の権威順を変更せず、設計判断を再生成するための補助索引です。

| 読み解きの起点 | Y2での構造 | 主な要件 |
| --- | --- | --- |
| 世界と可能な変化を、中央手順ではなく構造として記述する | 単一状態所有、純粋Rule/Transition、汎用Kernel | REQ-ARC-001, REQ-ARC-002 |
| soukobanの閉じた世界でRuleとTransitionを分離する | 内部状態変化と外部作用を分離する | REQ-ARC-003, REQ-PER-001 |
| Y1で物理完了、遅延、取消不能を発見する | 結果語彙、開始Event、永続取消、Recovery | REQ-PHY-001–003, REQ-OPS-002–006 |
| Y1でSBERTの意味反射を実証する | 意味候補と決定方針を分離する | REQ-ARC-005 |
| Y1でLLM待ちと複数推論engineを経験する | 区間別遅延とSBERTによる動的route選択 | REQ-NFR-001, REQ-PRD-004 |
| Y1で実機能力と外部I/Oを結ぶ | Fakeだけでは合格しない代表E2E | REQ-PRD-003 |
| 凍結06で導入・更新の複雑さを構造化する | 型付き設定、Layer、原子的変更、資産保護、配置mode | REQ-CFG-001–004 |
| Y1と他アプリでSkillの横断価値を発見する | 人とAIが同じアプリ世界へ触れる接続面 | REQ-PRD-002, REQ-ARC-007 |

## 未決事項一覧

これらは意図的に未決です。現時点では要件ではなく、受入条件も持ちません。

| 話題 | 未決の問い |
| --- | --- |
| IPC | Rust/Python process境界、protocol、worker管理 |
| latency budget | 区間別計測は必須。wake ACK、routing、TTFT、実機E2Eの数値budgetと対象profileはspike後に決定 |
| 永続化 | snapshot保存機構、schema migration、Recovery機構 |
| カメラ | 校正、照合、retry、完了の証拠 |
| 音声 | 安全margin、cancel、Interaction完了Policy |
| streaming TTS | 採用・優先度、数値上限、cancel timeout、Adapter別current chunk停止能力 |
| model/provider routing | 必須の動的選択を実現する具体profile、閾値、Provider再構成、active turn、Conversation再binding、fallback、Recovery、利用者同意、privacy／cost Policy |
| Provider境界 | Hoshikage由来候補（liveness/readiness、能力広告、admission/inference Failure、terminal/disconnect、generation/lease）をY2 Portへどう正規化するか |
| Web security | authentication、TLS/reverse proxy、LAN公開 |
| process management | supervisor配置とlocal workerのlifecycle |
| configuration mechanisms | Windows/macOS root、schema／atomic write library、secret store、installer、migration engine |
| privacyとmemory | 保持、利用者制御、remote transfer、削除規則 |
| external network capability | search/fetchの許可、取得先制約、citation、Failure、利用者同意 |
| Skill運用契約 | Skill形式、transport、認証・認可、Skill作成の検証、配備、rollback、安全方針 |
| legal inventory | component version、license、notice、distribution obligation |

## 実装開始後の追跡形式

実装開始後は、上の要件対応に次の列を加える。文書上のACが存在するだけでは`passing`にしてはならない。

| Requirement | Acceptance Criterion | Test ID | Source module | Status |
| --- | --- | --- | --- | --- |
| REQ-* | AC-* | TEST-* | 実装またはtest path | planned / implemented / passing / blocked |

- 一つのACには、一つ以上の再現可能なTest IDまたは実機demonstration IDを割り当てる。
- `passing`は実行証拠と対象revisionを持つ場合だけ使用する。
- 実機ACはFakeだけのtestを証拠にしない。hardware、profile version、計測区間、結果分類を記録する。
- 要件・AC・Test・sourceの対応は、実装taskごとに同時更新する。

## 基準資料の扱い

- Yatagarasu 1は実機で検証済み機能要件の基準である。
- 凍結`00`–`06`、DOCS README、ROOT READMEはYatagarasu 2構造要件の基準である。
- Accepted ADRは実際の矛盾に限り優先し、後続の凍結資料は先行資料の明示的訂正として扱う。
- manifestは凍結バイト列の完全性を示すだけで、要求内容の真実性や採用を示さない。
- 「オブジェクト指向はなぜ挫折するのか」とsoukobanは、正本要件の追加権威ではない。正本構造を理解し、新しい設計判断を同じ思考で導くための読み解きの基準である。
