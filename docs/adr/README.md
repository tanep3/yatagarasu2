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
| [ADR-007](ADR-007-capability-binding-and-deferred-scheduling.md) | 具体能力、Skill、将来自律入力をCoreの製品分岐へしない |
| [ADR-008](ADR-008-contributors-and-policy-resolution.md) | SBERT反射、規則、LLM提案を固定三段階や中央Intent登録簿へしない |
| [ADR-009](ADR-009-physical-observation-profiles-and-artifacts.md) | 移動要求、姿勢、校正、成果物、profileを一つの成功へ畳まない |
| [ADR-010](ADR-010-interaction-cancellation-and-durable-revocation.md) | 取消要求、停止結果、物理結果、遅延結果を区別する |
| [ADR-011](ADR-011-sbert-driven-inference-routing.md) | SBERTによる動的LLM／Provider選択を製品の必須positioningとして固定する |
| [ADR-012](ADR-012-configuration-workspace-and-upgrade.md) | 設定、Workspace、Upgrade、Capability配置を正本契約へ戻す |
| [ADR-013](ADR-013-single-active-qualia-and-home.md) | Active Qualiaを一つにし、Home・終了・Recoveryと自律神経を分ける |
| [ADR-014](ADR-014-api-first-web-body-and-owner-model.md) | WebをAPI優先の身体面とし、一Server・一Workspace・一Ownerで運用する |
| [ADR-015](ADR-015-behavior-extension-by-version-update.md) | 振る舞いを実行時pluginではなく正式version updateで各Layerへ追加する |
