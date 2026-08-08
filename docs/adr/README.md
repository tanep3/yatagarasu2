# Architecture Decision Records（設計判断記録）

ADRは、設計思想を説明する文書ではなく、実際に生じた矛盾をどの範囲で解いたかを記録します。適用範囲を越えて、未決事項を確定する力はありません。

Yatagarasu 1の実機機能要件と、凍結済みYatagarasu 2構造要件は補完的な基準資料です。矛盾時は、もっとも具体的に適用できるAccepted ADR、正本要件、アーキテクチャ説明、プロダクト説明、基準資料の順で参照し、除外理由を[根拠監査台帳](../requirements/source-audit.md)へ残します。

| ADR | 解いた矛盾 |
| --- | --- |
| [ADR-001](ADR-001-document-authority-and-baseline.md) | Y1機能基準と凍結Y2構造基準を、どちらか一方へ縮めず統合する |
| [ADR-002](ADR-002-product-status-and-y1-isolation.md) | 動くY1を守りながら、未完成Y2を別系統で育てる |
| [ADR-003](ADR-003-domain-law-process-boundaries-and-cognition.md) | 中央司令塔やprocess配置をDomain構造と取り違えない |
| [ADR-004](ADR-004-snapshot-journal-and-durable-dispatch.md) | 再起動時に仕事を失わず、journalから勝手に再実行しない |
| [ADR-005](ADR-005-physical-uncertainty-timing-and-streaming-speech.md) | 時間経過や開始試行を物理完了の観測にしない |
| [ADR-006](ADR-006-wakeword-mimy-and-source-topology.md) | WakeWordをYatagarasuへ、汎用STTをMimyへ分ける |
| [ADR-007](ADR-007-capability-binding-and-deferred-scheduling.md) | 具体能力、Skill、Skill実行権限、将来自律入力をCoreの製品分岐へしない |
| [ADR-008](ADR-008-contributors-and-policy-resolution.md) | SBERT反射、規則、LLM提案を固定三段階や中央Intent登録簿へしない |
| [ADR-009](ADR-009-physical-observation-profiles-and-artifacts.md) | 移動要求、姿勢、校正、成果物、profileを一つの成功へ畳まない |
| [ADR-010](ADR-010-interaction-cancellation-and-durable-revocation.md) | 取消要求、停止結果、物理結果、遅延結果を区別する |
| [ADR-011](ADR-011-sbert-driven-inference-routing.md) | SBERTによる動的LLM／Provider選択を製品の必須positioningとして固定する |
| [ADR-012](ADR-012-configuration-workspace-and-upgrade.md) | 設定、Workspace、Upgrade、Capability配置を正本契約へ戻す |
| [ADR-013](ADR-013-single-active-qualia-and-home.md) | Active Qualiaを一つにし、Home・終了・Recoveryと自律神経を分ける |
| [ADR-014](ADR-014-api-first-web-body-and-owner-model.md) | WebをAPI優先の身体面とし、一Server・一Workspace・一Ownerで運用する |
| [ADR-015](ADR-015-behavior-extension-by-version-update.md) | 振る舞いを実行時pluginではなく正式version updateで各Layerへ追加する |
| [ADR-016](ADR-016-acoustic-context-one-wake-one-command.md) | wake受理、audio session、pre-roll、自己音声除去、TTS中Stop抑止をAcoustic Contextへ集約する |
| [ADR-017](ADR-017-owned-memory-and-typed-presentation.md) | Codex Thread、Yatagarasu記憶、外部Skillデータ、View/Recall提示を混同しない |
| [ADR-018](ADR-018-effect-occurrence-and-semantic-order.md) | 同値Effectの出現、意味順序、settle、二種類の冪等性を分離する |
| [ADR-019](ADR-019-finite-conversation-and-admission.md) | 初期会話を有限にし、Qualia/Interactionのadmission責務を分離する |
| [ADR-020](ADR-020-linux-setup-and-quality-profiles.md) | TC70/C210、初期Linux導入、doctor、実機E2E、実測品質をrelease契約にする |
| [ADR-021](ADR-021-data-classes-artifacts-and-network-capabilities.md) | 複合内容分類、処理場所・移送方向、Artifact境界、search/fetch、LLM転送authorizationを別Policyにする |
| [ADR-022](ADR-022-codex-app-server-agent-session.md) | Codex app-server、Thread継続・reset・compaction、Agent Session Context、typed recoveryをY2会話から分離する |
| [ADR-023](ADR-023-initial-release-scope-and-non-streaming-tts.md) | 初期scope、non-streaming TTS、延期機能を明示し、暗黙のstreaming/長時間処理を防ぐ |
