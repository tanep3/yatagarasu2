# 根拠監査台帳

## 読み解きのレンズ

この台帳の採否は、次の導出を理解した上で読む。

```text
構造と変化の法則を記述する理論
  -> soukobanで閉じた世界の実行可能な構造にする
  -> Yatagarasu 1で現実の機能・失敗・時間・不確実性を発見する
  -> Yatagarasu 2で外部作用と結果Eventを含む開いた世界へ再抽象化する
```

このレンズは、理論文書やsoukobanを新しい要求源へ昇格させるものではない。Y1の機能基準と凍結Y2構造基準を、なぜその形で正規化するのかを説明するためのものである。今回の再解釈によって、凍結資料の採否、Y1分離、物理不確実性、SBERTの通常経路は変更していない。Skillについては、作業指示に限定しないAIとアプリの接続面として、既存の能力拡張方針をREQ-PRD-002/REQ-ARC-007へ明文化した。単一Qualia、Web身体面、API優先、正式version updateによるBehavior拡張は、凍結資料を黙って書き換えず、アプリオーナーの後続判断としてADR-013–015と正本要件へ記録した。

## 判定規則

この台帳は二つの補完的な基準資料を扱う。Yatagarasu 1は実機で検証済みの機能要件、凍結`00`–`06`、DOCS README、ROOT READMEはYatagarasu 2の構造要件である。いずれも**原則採用、除外理由を明記**とする。Accepted ADRは実際の矛盾だけで優先し、後続凍結資料は先行資料の明示的訂正として扱う。外部製品・既存実装の振る舞いは設計根拠であり、Y2のStateやPortの権威ではない。

状態は次のいずれかである。

| 状態 | 意味 |
| --- | --- |
| covered | 正本要件または説明へ取り込み済み。 |
| accepted | ADRで拘束する判断として受理済み。 |
| open | 採用意図は保つが、具体契約を未決として追跡する。 |
| rejected | 矛盾、既知欠陥、または範囲外として理由付きで不採用。 |
| legacy | 履歴、実装手順、roadmapであり、現在の振る舞い要件ではない。 |

`MANIFEST.sha256`は凍結バイト列の完全性を確認するだけで、内容の真実性・採用・優先順位を証明しない。`docs/drafts/handover-baseline/docs/04`–`06`は同内容の互換wrapperであり、重複として除外し、primary sourceに数えない。

## 凍結Y2構造要件

表の節範囲は、下位節を含む監査単位である。検証欄のACは将来の実装fixtureで観測する受入条件、ADRは判断の確認先を示す。

| Primary source / 節範囲 | 正規化した項目 | 状態 | 正本の行先・理由 | 検証 |
| --- | --- | --- | --- | --- |
| [00 §1](../drafts/handover-baseline/00-architecture-vision.md) | 文書位置づけ | accepted | [ADR-001](../adr/ADR-001-document-authority-and-baseline.md); 二つの基準資料として保持 | 台帳全件 |
| 00 §2 | Y1からの再構築 | covered | [プロダクト要件](product-requirements.md) REQ-OPS-001 | AC-OPS-001 |
| 00 §3（§3.1–3.8） | 構造、単一所有、純粋Rule、不変Effect、汎用Kernel | accepted | [設計思想](../architecture/design-philosophy.md), ADR-003 | AC-ARC-001–006 |
| 00 §4 | State/Event/Rule/Transition/Decision/Effect観 | covered | [ドメインモデル](../architecture/domain-model.md) | AC-ARC-001–006 |
| 00 §5 | 一人のオーケストレーターを置かない | accepted | ADR-003 | AC-PER-001–002 |
| 00 §6（§6.1–6.8） | Context分割と所有 | accepted | [ドメインモデル](../architecture/domain-model.md#状態の所有者は一つ) | AC-ARC-003 |
| 00 §7 | 入力同格、意味一つ | covered | REQ-FR-001 | AC-FR-001–002 |
| 00 §8 | process境界は配備判断 | accepted | ADR-003 | AC-ARC-002, AC-OPS-009 |
| 00 §9 | Y1を稼働維持し混在させない | accepted | ADR-002, REQ-OPS-001 | AC-OPS-001 |
| 00 §10 | 設計標語 | legacy | §3–§9へ正規化済みで独立契約ではない | 台帳参照 |
| [01 §1](../drafts/handover-baseline/01-domain-and-execution-model.md) | Kernel algebra | accepted | ADR-003, [ドメインモデル](../architecture/domain-model.md) | AC-ARC-001–006 |
| 01 §2（§2.1–2.3） | WorldStateとAcoustic/Interaction/Device State | covered | ドメインモデルの所有表。wake acceptance/prompt lifecycleはAcoustic Contextのみが所有 | AC-ARC-003, AC-PRD-001 |
| 01 §3 | Command/Event区別 | covered | ドメインモデル | AC-ARC-004–006 |
| 01 §4 | Ruleの純粋性 | accepted | ADR-003, REQ-ARC-001 | AC-ARC-001–002 |
| 01 §5 | Transitionの決定論 | accepted | ADR-003, REQ-ARC-001 | AC-ARC-001 |
| 01 §6 | Effectは値、Adapterは結果Event | accepted | ADR-003, REQ-ARC-003 | AC-ARC-004–006 |
| 01 §7（§7.1–7.4） | Effect Graph例と順序 | accepted | REQ-PER-001、ADR-009/018。無条件逐次例はguardへ訂正し、同値Effectの出現はEffectOccurrence、順序は意味edge、settleは独立条件へ正規化 | AC-PER-001–002, AC-PHY-009, AC-EFX-001–005 |
| 01 §8 | Planner | covered | contributor/resolution Policyへ正規化 | AC-ARC-009–011 |
| 01 §9 | Scheduler | covered | Graph ready/claim scheduler | AC-PER-001–002 |
| 01 §10 | Artifact | accepted | ADR-009/021、[永続化と不確実性](../architecture/persistence-and-uncertainty.md#artifactと通知も推測しない)。論理ID、authorization、lifetime、Decision→Effect→Adapter result Event deleteへ正規化 | AC-OPS-018, AC-DAT-003–004 |
| 01 §11 | ContextBundle | covered | 名前付きContextのsnapshot view | AC-ARC-003 |
| 01 §12 | Conversation | accepted | Conversation/MemoryをYatagarasu所有、外部Codex Skill app data/Provider threadを非所有、standing authorization、5目的recall、enabled初期ConversationのLLM前retrieval、typed Presentation、初期fallbackのterminalをADR-017/019/REQ-MEM-001/REQ-OUT-001/REQ-CNV-001で正規化。schema/保存engine/継続会話は未決 | AC-MEM-001–005, AC-OUT-001–004, AC-CNV-001–004 |
| 01 §13（Projection各節） | Conversation/Runtime/Diagnostic Projection | covered | REQ-FR-002; Projectionは配達証拠でない | AC-FR-003–004, AC-OPS-016 |
| 01 §14 | 完全なInteraction流れ | rejected | 命令的主手順は採用しない。Graph/Policyへ分解 | AC-PER-001–002 |
| [02 §1](../drafts/handover-baseline/02-boundaries-and-runtime.md) | Ports and Adapters | accepted | ADR-003, [ランタイム境界](../architecture/runtime-boundaries.md) | AC-ARC-002, AC-ARC-004 |
| 02 §2（§2.1–2.3） | Voice/Web/CLI Gateway | covered | REQ-FR-001, REQ-FR-003 | AC-FR-001, AC-FR-005 |
| 02 §3 | Runtime Kernel | accepted | ADR-003; product固有知性を置かない | AC-ARC-003 |
| 02 §4 | Outbox | accepted | ADR-004, REQ-OPS-003 | AC-OPS-004–006 |
| 02 §5 | Idempotency | accepted | Interaction Contextの耐久request-idempotency ledger（client key、payload fingerprint、replayable typed result/status/lifecycle）とExecution ContextのEffectOccurrence recovery照合を別State/key/Policyとして正規化。APIは同一key replay・異payload Conflict、voiceはserver identity、restartはRejected/AcceptedNoEffect/Pending/Completedを扱う。具体storageは未決 | AC-EFX-004, AC-QLI-004, AC-API-015, AC-OPS-006 |
| 02 §6 | Failure as Data | covered | REQ-ARC-003, REQ-FR-002 | AC-FR-004 |
| 02 §7 | Time | accepted | ADR-005 | AC-PHY-003–006 |
| 02 §8（§8.1–8.2） | Interaction queueとEffect concurrency | covered | Graph dependency/resource claim | AC-PER-001–002 |
| 02 §8.3 | Cancellation | accepted | ADR-010; 単純な一結果分類は置換 | AC-FR-005–006, AC-OPS-012–014 |
| 02 §9 | Event Journal and Recovery | accepted | ADR-004 | AC-OPS-002–006 |
| 02 §10 | Observability | covered | Projectionと型付きFailure | AC-FR-003–004 |
| 02 §11 | Security | covered | secret redactionはREQ-SEC-001、Owner認証と取消可能tokenはREQ-API-004。具体session／TLSは未決 | AC-SEC-001, AC-API-011–014 |
| 02 §12 | Configuration | covered | profile外側schemaと実効version固定 | AC-ARC-012 |
| 02 §13 | Model Residency | open | process/worker配置は未決、所有禁止はADR-003 | AC-ARC-002 |
| 02 §14（Phase A–B） | Deployment Shape | open | process分離は配備判断、IPC未決 | 未決事項: IPC |
| 02 §15 | Suggested Source Shape | legacy | 実装配置例であり依存方向のみ採用 | AC-ARC-002 |
| [03 §1](../drafts/handover-baseline/03-evolution-plan-and-open-questions.md) | 移行計画ではない | covered | REQ-OPS-001 | AC-OPS-001 |
| 03 §2 | 最初に実装しないもの | open | 項目別に台帳と未決事項へ移送 | 未決事項一覧 |
| 03 §3 | Architecture Test Scenario | covered | [設計思想](../architecture/design-philosophy.md#将来の実行可能シナリオ) | 全AC |
| 03 §4（M0–M6） | Milestones | legacy | roadmapであり受入契約ではない | planning時再評価 |
| 03 §5 | Y1から移植する単位 | covered | 下のY1機能監査へ分解 | Y1各AC |
| 03 §6 | 言語選択 | open | Rust/Python境界は保持、言語選択は未決 | ADR-003 |
| 03 §7（Q1–Q10） | Open Questions | open | [未決事項](traceability.md#未決事項一覧)へ正規化 | 個別設計時 |
| 03 §8 | Architecture Invariants | accepted with normalization | ADR-003/018および設計思想へ正規化する。凍結文書の「dependencyまたはResource Policyで順序を表す」という表現のうち、意味順序をresource claimへ持たせる部分は採用しない。意味順序はdependency edgeとguardだけ、resource claimはscheduler admissionと同時実行競合だけを表す | AC-ARC/PER/PHY/API, AC-EFX-002, AC-EFX-005 |
| 03 §9 | 最後に | legacy | 結語であり独立契約でない | 台帳参照 |
| [04 §1–§2](../drafts/handover-baseline/04-agentization-requirements-draft.md) | 目的・背景 | covered | 功能/構造の補完基準として保持 | 台帳全件 |
| 04 §3（§3.1–3.2） | プロダクトコンセプト | covered | [プロダクト](../product/README.md), REQ-PRD-001/005/006。会話中心から複数BehaviorとWeb身体面へ拡張 | AC-PRD-001–002, AC-PRD-012–015 |
| 04 §4（§4.1–4.6） | 起動、文脈、CLI、service、routing課題 | covered | Contributor、profile、Web、動的Provider、区間別遅延へ分解 | AC-ARC-009–013, AC-PRD-009–011, AC-NFR-001–003 |
| 04 §5 | 目的 | covered | REQ-PRD-001–006, REQ-FR-001–007, REQ-NFR-001, REQ-API-001–004 | AC-PRD-001–015 |
| 04 §6（§6.1–6.2） | 一般利用者・開発者 | covered | プロダクト要件 | AC-PRD-001 |
| 04 §7（UC-01–03） | 音声質問、連続命令、Web chat | covered | REQ-PRD-001/005/006, REQ-FR-001, REQ-API-001/002。Webは公開APIを使う身体面 | AC-PRD-001, AC-FR-001–002, AC-API-001–007 |
| 04 §7（UC-04–08） | model/provider切替 | accepted with normalization | 初期Agent adapterはCodexだけ、ProviderはCodex default経由OpenAI/Hoshikage/Ollama API、configured choiceをdispatch前にeffective routeへbindする。active turn rebindと自動fallbackは採用しない | AC-PRD-009–011, AC-PRD-017, AC-CFG-013 |
| 04 §7（UC-09–10） | Web切替・構成照会 | accepted | Web操作は公開APIから共通Commandへ入り、状態はProjection同期で参照。具体transportは未決 | AC-API-001–007, AC-PRD-014–015 |
| 04 §7（UC-11–12） | provider間会話継続・縮退 | rejected | Provider failureを新Conversationまたは自動fallbackで隠さずtyped terminal Failure/Recoveryにする。外部Thread再開はADR-022のexact ID/rebindとdurable AgentTurnBinding契約へ限定 | AC-PRD-017, AC-AGT-003–006 |
| 04 §8.1 | listend supervisor | rejected | 凍結05訂正とADR-003。supervisorでなくInbound Adapter | AC-FR-001 |
| 04 §8.2 | SBERT Router | accepted | ADR-008。候補/score/provenanceのみ返す | AC-ARC-009–010 |
| 04 §8.3 | yatagarasu-agent司令塔 | rejected | ADR-003。Kernel/ContextがStateを所有 | AC-ARC-003 |
| 04 §8.4–§8.7 | profile、model/provider切替状態 | covered | REQ-PRD-004、REQ-ARC-006。希望／実効routeとprofile/version固定 | AC-PRD-009–011, AC-ARC-012 |
| 04 §8.8 | 会話文脈引継ぎ | accepted with normalization | Y2 ConversationとCodex external Threadは別所有。Agent Session Contextがexact Thread ID/rebind/recoveryとdurable AgentTurnBindingを所有し、HomeはThread終端ではない。late A result/cancelはBを更新しない | AC-AGT-002–006 |
| 04 §8.9 | yatagarasu-web | accepted | ADR-014/019、REQ-PRD-006、REQ-API-001–004。管理画面に限定せずWeb身体面へ拡張し、直接Provider接続は禁止。複数browser/API mutationはclient idempotency key、same payload replay/different payload Conflict、restart後のInteraction ledgerで扱う | AC-API-001–015 |
| 04 §9（§9.1–9.4） | 固定Unix JSONL IPC | rejected | 凍結05訂正、ADR-003。transportはdomain型でない | 未決事項: IPC |
| 04 §10 | 非機能要件 | covered | 区間別latency、Failure、secret、API認証、Web継続同期へ分解 | AC-NFR-001–003, AC-FR-004, AC-SEC-001, AC-API-004–007, AC-API-011–014 |
| 04 §11 | 制約 | covered | capability bindingとY1分離 | AC-OPS-001, AC-OPS-009 |
| 04 §12 | 複数ユーザー認証、Internet公開 | accepted | Y2は一Server・一Workspace・一Owner。複数利用者RBACと認証なしの直接Internet公開は範囲外。Tailscale等を想定 | AC-API-011–014 |
| 04 §12 | その他の対象外項目 | open | スマホ専用app、並列Turn、料金routing、長期記憶刷新等は未決または延期として追跡 | 未決事項 |
| 04 §13（Phase 1–9） | 実装フェーズ・優先順位 | legacy | roadmap。機能/構造契約は上記へ採用 | planning時再評価 |
| 04 §14 | 優先順位根拠 | legacy | roadmap根拠であり独立契約でない | planning時再評価 |
| 04 §15 | 受入条件 | covered | 正本ACへ再割当 | traceability |
| 04 §16–§17 | 最終構成・定義 | covered | productとruntime boundaries。ただし会話Agentや固定構成を中心にせず、単一Qualiaの複数Behavior基盤へ再抽象化 | AC-PRD-001, AC-PRD-012–015, AC-FR-009–017 |
| [05 §1](../drafts/handover-baseline/05-agentization-architecture-review.md) | 結論 | accepted | ADR-003, ADR-007 | AC-ARC-002–004 |
| 05 §2 | 採用する価値 | covered | contributor/profile/Webの各要件 | AC-ARC-009–012 |
| 05 §3.1 | listend非supervisor | accepted | ADR-003 | AC-FR-001 |
| 05 §3.2 | Agent非司令塔 | accepted | ADR-003 | AC-ARC-003 |
| 05 §3.3 | Unix socketを前提にしない | accepted | ADR-003 | 未決事項: IPC |
| 05 §3.4 | Codex Thread IDを会話IDにしない | accepted | ADR-022。Conversation IDと履歴はYatagarasu所有で、Codex Thread IDとper-turn AgentTurnBindingはAgent Session Contextの保護されたexternal bindingである | AC-AGT-002–006 |
| 05 §3.5 | model切替を一Stateにしない | accepted | ADR-008, REQ-ARC-006 | AC-ARC-012 |
| 05 §4 | 更新後論理構成 | covered | architecture documents | AC-ARC-002–004 |
| 05 §5（§5.1–5.2） | SBERT/LLM拡張 | accepted | ADR-008/011。意味候補、Contributor、信頼境界、動的routeへ分割 | AC-ARC-009–011, AC-ARC-013, AC-ARC-018–020, AC-PRD-009–011 |
| 05 §6 | model/provider State | accepted | ADR-011/022。configured dynamic selectionは必須、初期Provider集合/no-auto-fallback/effective-route固定を定める | AC-PRD-009–011, AC-PRD-017, AC-AGT-001 |
| 05 §7 | 会話と記憶 | accepted | 所有、standing authorization、local既定auto-save、explicit memorize、LLM前のrecent/semantic retrieval、5目的、typed Presentation、初期有限fallbackをADR-017/019とREQ-MEM-001/REQ-OUT-001/REQ-CNV-001へ採用。MemoryはOwner deleteまで保持し、連続会話は延期 | AC-MEM-001–005, AC-OUT-001–004, AC-CNV-001–004 |
| 05 §8 | Web GUI | accepted | 共通Inbound境界をAPI優先のWeb身体面へ拡張。標準Webも同じAPIを使用 | AC-FR-001, AC-API-001–010 |
| 05 §9（§9.1–9.3） | Rust/Pythonと境界 | accepted | ADR-003。Python非所有 | AC-ARC-002 |
| 05 §10 | 改訂実装順 | legacy | roadmap | planning時再評価 |
| 05 §11 | 次に決めること | open | 未決事項一覧 | 個別設計時 |
| 05 §12 | 判定 | accepted | 本台帳の採否へ反映 | 台帳全件 |
| [06 §1](../drafts/handover-baseline/06-configuration-workspace-and-capability-operations.md) | 目的 | accepted | ADR-012、REQ-CFG-001–004 | AC-CFG-001–011 |
| 06 §2（§2.1–2.3） | Workspaceとprofile | accepted | ADR-012/014、REQ-CFG-001/003、REQ-API-004。XDG role分離、利用者資産保護、一Server・一Workspace・一Owner、実効profile固定 | AC-CFG-001–003, AC-CFG-007–008, AC-ARC-012, AC-API-013 |
| 06 §3（§3.1–3.3） | 設定、優先順位、secret | accepted | ADR-012、REQ-CFG-001、REQ-SEC-001。型付きconfig、Layer出所診断、secret全検査面 | AC-CFG-002–003, AC-SEC-001 |
| 06 §4 | Web GUI設定変更 | accepted | REQ-CFG-002、REQ-API-001/004。Command、schema／安全検証、atomic write、apply mode、Owner認証を採用。具体session方式は未決 | AC-CFG-004–006, AC-API-001–003, AC-API-011–014 |
| 06 §5（§5.1–5.3） | Capability配置/binding | accepted | ADR-007/012/020、REQ-CFG-004。初期deployment matrixはCodex同host必須、OpenAI経由route、Hoshikage/Ollamaと各adapterの個別配置、mandatory Codex workspace capabilityを定める | AC-CFG-009–014, AC-OPS-009 |
| 06 §6 | 初期Capability方針 | covered | source-agnostic Mimy、Adapter/binding | AC-OPS-009 |
| 06 §6.1 | Mimy STT | accepted | ADR-006 | Mimy境界テスト |
| 06 §6.2 | 自作projectの扱い | covered | 外部capabilityはPort/Adapter、所有なし | AC-ARC-004 |
| 06 §7 | Capability状態と縮退 | accepted with normalization | 能力広告、希望／実効route、配置modeを採用。auto fallbackと利用ごとのconsent UIは採用しない | AC-PRD-009–011, AC-PRD-017, AC-CFG-009–013 |
| 06 §8 | systemd/process管理 | open | process管理は配備判断 | 未決事項 |
| 06 §9 | セットアップ体験 | covered | Y1/Y2分離、標準Workspace、Capability配置 | AC-OPS-001, AC-CFG-001, AC-CFG-009–011 |
| 06 §10 | Upgrade/Migration | accepted | 利用者資産保護と明示migrationをREQ-CFG-003へ採用。具体engineは未決 | AC-CFG-007–008 |
| 06 §11 | 受入条件 | covered | 正本ACへ再割当 | traceability |
| 06 §12 | 未決事項 | open | traceability未決事項一覧 | 個別設計時 |
| [DOCS README](../drafts/handover-baseline/DOCS-README.md) §Documents | 文書導線 | covered | [docs README](../README.md) | markdown link check |
| DOCS README §Status | 実装状態を言い過ぎない | covered | architecture README | 文書レビュー |
| DOCS README §One Sentence | 一文の方針 | legacy | 要件ではなく要約 | 文書レビュー |
| [ROOT README](../drafts/handover-baseline/ROOT-README.md) | repository入口 | covered | root READMEを会話に閉じないBehavior基盤とWeb身体面の現在定義へ更新 | markdown link check |

## Yatagarasu 1実機機能要件

Y1のprimary source rootは`/home/tane/tools/yatagarasu` revision `66f73ec9bbfee4fdf5726d2869d6932771ccb5e6`（監査時worktree clean）、Zundaは`/home/tane/tools/yatagarasu/bin/zunda`である。以下のY1 inventory表のbacktick相対pathは、すべてこの明示rootから解決する（Y2 repository内のpathではない）。同名またはwrapperの呼出しは重複であり、primary機能数に加算しない。このrevisionをY1機能基準の再現可能なinventoryとして固定し、可変pathの内容だけで採否を変更しない。

| Primary source / 機能群 | 正規化した機能 | 状態 | 正本の行先・理由 | 検証 |
| `README.md`, `bin/yatagarasu` | テキストInteraction | covered | REQ-PRD-001, REQ-FR-001 | AC-PRD-001, AC-FR-001 |
| `python/listend.py`, `wakeword.py`, `listen_state.py` | 常時音声、wake、VAD/STT、turn確定/stop word | covered | REQ-PRD-001, ADR-006; Adapterは非所有 | AC-PRD-001 |
| `README.md:48–56`, `python/intent_router.py` | SBERT routingのmove-camera、view、recall | accepted | ADR-008。通常routingはSBERT候補生成から始める。Y1はkeyword gateをband分類前に適用しmiddle候補をLLMへ送るが、Y2のgrayはkeyword/rule gate後にresolution PolicyがLLMなし受理または別Decisionを決める | AC-ARC-009–010, AC-ARC-013 |
| `workspace/.codex/skills/move-camera`, `README.md:50–54` | move-camera（相対PTZ、calibration） | covered | ADR-008/009。calibrationはgray Candidate+校正候補固有gateが決定論的Policyに一致するとき、LLM request/ProposalなしでGraphへ解決する。絶対poseの証明にはしない | AC-FR-007–008, AC-PHY-007–009 |
| `workspace/.codex/skills/view`, `README.md:50–55` | view（captureしてLLM入力） | covered | ADR-009。capture/ArtifactRef guardを持つGraph | AC-PER-001–002, AC-PHY-009 |
| `workspace/.codex/skills/recall`, `README.md:50–55`, `bin/recall-context.sh` | recall（過去記憶検索） | accepted | Yatagarasu所有のConversation/Memory、enabled初期ConversationのLLM前retrieval、5目的のrecall、recent 3 + semantic 3、recent優先・競合理由・provenance、空結果をADR-017/REQ-MEM-001へ正規化。保存engineは未決、MemoryはOwner deleteまで保持 | AC-MEM-001–005 |
| `workspace/.codex/skills/memorize`, `workspace/AGENTS.md:15–16`, `bin/memorize.sh` | 明示依頼によるmemorizeと保存結果確認 | accepted | 明示memorizeは既定local auto-saveと分離し、standing authorization、Owner delete、無期限保持をREQ-MEM-001/REQ-DAT-001へ採用。利用ごとのUIは置かない | AC-MEM-002, AC-DAT-002 |
| `workspace/.codex/skills/tanechan-search`, `workspace/AGENTS.md:17,40–43` | tanechan-search（現在情報のURL検索） | accepted | Searchをallowlist、provenance、citation、Failure/no-results、内容分類別LLM transfer authorizationが別のCapabilityとしてREQ-NET-001/ADR-021へ正規化。具体allowlistは未決 | AC-NET-001–004 |
| `workspace/.codex/skills/tanechan-fetch`, `workspace/AGENTS.md:18` | tanechan-fetch（URL内容取得） | accepted | FetchをSearchと同じnetwork境界だが別CapabilityとしてREQ-NET-001/ADR-021へ正規化。取得本文はWorldStateを所有せず、retrieval許可とProvider転送許可を分離する | AC-NET-001–004 |
| `workspace/.codex/skills/skill-creator`, `README.md:56` | skill-creator（Codex Skill作成） | accepted with normalization | SkillCreatorを初期必須Codex capabilityとする。Codexは自身の権限でSkill資産を作成でき、Y2は追加承認を加えない。外部資産は正式Y2 Behavior/State所有へ自動昇格しない | ADR-007/015/023, AC-SCP-003, AC-PRD-016 |
| `workspace/.codex/skills/*`, `workspace/AGENTS.md` | Skillによるアプリ・データ・能力へのAI接続 | accepted | Skillを作業指示書、Proposal、Adapterのいずれにも限定せず、人とAIがアプリ所有の世界へ触れる接続面として正規化する | REQ-PRD-002, REQ-ARC-007, AC-PRD-003–004, AC-ARC-014–016 |
| `workspace/AGENTS.md:12–18,45` | compound move+viewと画像分析 | covered | move/capture/LLMを依存Graphとresource claimで表す。無条件手順にはしない | AC-PER-001–002, AC-PHY-009 |
| `bin/zunda` | VOICEVOX TTS、並列生成/再生 | covered | REQ-OPS-004、REQ-OPS-008（採用時）。並列synthesisでも順序付きplayback、上限、取消後非admission、OutcomeUnknown非resendを要求する | AC-OPS-007–008, 017, 020–021, 023 |
| `python/audio_prompt.py`, `tapovoice*` | prompt/playback | covered | Adapter結果Eventと取消境界。supported target別cancel、artifact cleanup/restart orphan cleanupを型付き結果で扱う | AC-OPS-014, 019–023 |
| `bin/memorize.sh`, `bin/recall-context.sh`, `external/SemanticMemory`, `README.md:40–47`, `docs/semanticmemory-ruri-v3-migration.md` | 記憶の保存/検索、Ruri v2/v3 migration/versioning | accepted with rejection | 保存/想起の所有、standing authorization、delete/retention境界、5目的とprovenanceを持つversion付き既定recall、enabled初期ConversationのLLM前retrieval、content class/方向別PolicyをREQ-MEM-001/REQ-DAT-001へ採用。Y2はY1 import job/API/Upgrade migrationを提供しない。同じ互換storeですでに可視なrecordだけをprovenance付きで扱う。具体schema/engineは未決 | AC-MEM-001–005, AC-DAT-001–005 |
| `README.md:115–145` | Codex/Claude/opencode実行engine | accepted with normalization | 初期Agent adapterはCodexのみ。複数推論能力の動的選択をREQ-PRD-004/ADR-011へ採用し、EngineはAdapter/Providerでありdomain Stateを所有しない。routeはconfigured choiceでbindしFailure/Recoveryを返し自動fallbackしない | AC-PRD-009–011, AC-PRD-017, AC-AGT-001 |
| `README.md:131–143` | Hoshikage profile、Token、readiness、network access | covered | ADR-011。local route候補と能力広告、profile固定を採用。secretはREQ-SEC-001。configured authorization/no-auto-fallbackは決定済みで、具体network/Provider credential/transportは未決 | AC-PRD-009–011, AC-PRD-017, AC-ARC-012, AC-SEC-001 |
| `bin/yatagarasu-doctor`, `workspace/.env.example`, `docs/setup-manual.md`, deploy files | capability診断、設定、配備 | covered | clean Linux setup、Capability選択/credential registration、一Owner/Workspace、secret非露出doctor、全ready後のwake→会話→Home E2EをREQ-SET-001/ADR-020へ追加。実装方式は未決 | AC-SET-001–003, AC-CFG-001–003, AC-CFG-009–011, AC-SEC-001 |
| `README.md` WakeWord節, `python/listen_state.py`, `python/tests/test_listend_wake_flow.py`, `docs/plan/livekit-wakeword-test-results.md` | prompt guard、空session、最初の発話、自己音声、Wake実測 | accepted | 一wake一命令、Acoustic Context唯一所有、「はい」の非transcript、実TTS自己ループ防止とTTS中Home/Stop検知、実発話fixture、Quality ProfileをREQ-ACOU-001/REQ-QPR-001/ADR-016/020へ正規化。RTSP resetは必須方式にしない | AC-ACOU-001–006, AC-QPR-001–003 |
| Y1の直接subprocess/network/filesystem制御 | 既存実装方式 | rejected | Y2 Coreへ移植しない。Port/Adapterに隔離 | AC-ARC-002, AC-ARC-004 |

## 補助的な既存事例

| Source | 観察した契約候補 | 状態 | Y2での扱い | 確認 |
| --- | --- | --- | --- | --- |
| `/home/tane/tools/familiar-ai` revision `d52fe8e0318f34272ad8d39350609b8108809348` | camera、移動、音声、記憶、LLM loop | legacy | 体験上の支持根拠のみ。ReAct主手順や外部状態所有は採用しない | source README |
| `/tmp/hoshikage-audit-20260802` revision `4faf65f686006c0543f8bdcf5c246d754133dc70` | liveness/readiness、capability広告、queue/admissionとinference Failure、terminal/disconnect、auth/secret redaction、generation/lease | covered | [ランタイム境界](../architecture/runtime-boundaries.md#外部能力python-workerprovider)のProvider boundary候補。初期Hoshikage route/no-auto-fallback/configured authorizationは正本契約に採用し、内部実装とtransportは未決 | REQ-PRD-004, REQ-AGT-001 |
