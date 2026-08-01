# トレーサビリティ、矛盾、未決事項

## 要件トレーサビリティ

| 要件 | 受入条件 | 判断・説明 |
| --- | --- | --- |
| REQ-PRD-001 | AC-PRD-001, AC-PRD-002 | ADR-002; Product experience |
| REQ-FR-001 | AC-FR-001, AC-FR-002 | ADR-003; Domain model |
| REQ-FR-002 | AC-FR-003, AC-FR-004 | Domain model |
| REQ-FR-003 | AC-FR-005, AC-FR-006 | ADR-010; Domain model |
| REQ-ARC-001 | AC-ARC-001, AC-ARC-002 | ADR-003; Design philosophy |
| REQ-ARC-002 | AC-ARC-003, AC-ARC-004 | ADR-003 |
| REQ-ARC-003 | AC-ARC-005, AC-ARC-006 | ADR-003; Persistence and uncertainty |
| REQ-ARC-004 | AC-ARC-007, AC-ARC-008 | ADR-007 |
| REQ-ARC-005 | AC-ARC-009, AC-ARC-010, AC-ARC-011, AC-ARC-013 | ADR-008; Domain model |
| REQ-ARC-006 | AC-ARC-012 | ADR-008; ADR-009; Domain model |
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
| 凍結02 §8.3の取消分類 | ADR-010のdurable revocationと遅延結果 | `CancelRequested`、受理、revocation、in-flight取消結果、physical outcomeを分ける。physical moveはdispatch後non-cancellable。 |
| 凍結04のSBERT単独状態更新・固定Intent経路 | ADR-008の複数contributor解決 | SBERTは候補/score/provenanceを返し、version付きPolicyと純粋resolutionで決める。LLM/CodexはProposal境界を越えない。 |
| Y1 `intent_router.py`: keyword gateをscore band分類より前に適用し、middle候補をLLMへ送る | ADR-008の通常routing Policy | Y2ではgray candidateをintent固有keyword/rule gateで受理可能にし、LLMへ送るかは純粋resolution Policyが決める。calibrationが決定論的Policyに一致するときはLLM request/Proposalを作らない。rule-only/LLM-proposal-onlyも明示capability Policyで選べる。 |

## 未決事項一覧

これらは意図的に未決です。現時点では要件ではなく、受入条件も持ちません。

| 話題 | 未決の問い |
| --- | --- |
| IPC | Rust/Python process境界、protocol、worker管理 |
| 永続化 | snapshot保存機構、schema migration、Recovery機構 |
| カメラ | 校正、照合、retry、完了の証拠 |
| 音声 | 安全margin、cancel、Interaction完了Policy |
| streaming TTS | 採用・優先度、数値上限、cancel timeout、Adapter別current chunk停止能力 |
| model/provider routing | route選択、切替、Recovery、利用者同意Policy |
| Provider境界 | Hoshikage由来候補（liveness/readiness、能力広告、admission/inference Failure、terminal/disconnect、generation/lease）をY2 Portへどう正規化するか |
| Web security | authentication、TLS/reverse proxy、LAN公開 |
| process management | supervisor配置とlocal workerのlifecycle |
| privacyとmemory | 保持、利用者制御、remote transfer、削除規則 |
| external network capability | search/fetchの許可、取得先制約、citation、Failure、利用者同意 |
| legal inventory | component version、license、notice、distribution obligation |

## 基準資料の扱い

- Yatagarasu 1は実機で検証済み機能要件の基準である。
- 凍結`00`–`06`、DOCS README、ROOT READMEはYatagarasu 2構造要件の基準である。
- Accepted ADRは実際の矛盾に限り優先し、後続の凍結資料は先行資料の明示的訂正として扱う。
- manifestは凍結バイト列の完全性を示すだけで、要求内容の真実性や採用を示さない。
