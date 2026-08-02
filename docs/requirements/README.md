# 要件

要件は、思想を美しく説明する文章ではありません。「何が観測できれば、Yatagarasu 2の要求を満たしたと言えるか」を定める契約です。

- [機能基準](functional-baseline.md) — Yatagarasu 1で発見した能力を、必須・契約未決・延期・非採用に分類する
- [プロダクト要件](product-requirements.md) — 利用者に届ける体験と機能
- [アーキテクチャ要件](architecture-requirements.md) — 世界の法則と、破ってはいけない境界
- [運用要件](operational-requirements.md) — 永続化、取消、音声、秘密情報、分離運用
- [API・Web要件](api-and-web-requirements.md) — 公開API、Web身体面、継続同期、画面カスタマイズ、Owner認証
- [設定・Workspace要件](configuration-requirements.md) — 設定層、原子的変更、Upgrade、Capability配置
- [トレーサビリティ](traceability.md) — 要件、受入条件、判断、未決事項の対応
- [根拠監査台帳](source-audit.md) — Y1と凍結ドラフトからの採用・保留・不採用

## 文書の役割分担

- **プロダクト文書**は、なぜ価値があるかを伝える。
- **アーキテクチャ文書**は、なぜその構造が導かれるかを説明する。
- **要件**は、何を守り、何を観測するかを定める。
- **ADR**は、どの矛盾をどの範囲で解いたかを記録する。

理論、soukoban、Yatagarasu 1、Yatagarasu 2という導出の連鎖は[設計思想](../architecture/design-philosophy.md)で扱います。要件本文では、そこから導かれた義務と受入条件だけを記します。

既存の要件IDと受入条件IDは意味を保ったまま維持します。変更する場合は、トレーサビリティと根拠監査台帳を同時に更新します。未決事項は、説明が深まったことを理由に確定事項へ変えません。

IDは一度割り当てた意味の安定性を優先するため、本文の掲載順と数値順が一致しない場合があります。欠番は要件漏れを意味しません。
