# Yatagarasu 2 文書

ここはYatagarasu 2の現在の正本です。Yatagarasu 1の実機で検証済み機能要件と、凍結済みYatagarasu 2構造要件を補完的な基準資料として正規化しています。完成済みの製品や確定した実装を表すものではありません。

矛盾時の判断優先順位は、適用範囲を明記したAccepted ADR、要件、アーキテクチャ説明、プロダクト説明、基準資料です。これは基準資料を捨てる規則ではない。基準資料は原則採用し、除外は矛盾、後続資料による訂正、既知欠陥、意図的延期、範囲外の理由を[根拠監査台帳](requirements/source-audit.md)へ記す。矛盾を見つけた場合は、[トレーサビリティと論点](requirements/traceability.md)を起点に解消します。

- [プロダクト](product/README.md) — 届けたい体験と現在の状態
- [要件](requirements/README.md) — 観測可能な要求と受入条件
- [根拠監査台帳](requirements/source-audit.md) — 正本化した根拠、未採用事項、確認方法
- [アーキテクチャ](architecture/README.md) — ドメイン、境界、永続化の説明
- [Architecture Decision Records](adr/README.md) — 承認済み判断の適用範囲
- [法務・データ境界](legal/README.md) — 第三者コンポーネント候補とデータ境界
- [開発](development/agent-workflow.md) — 開発時の作業規約
- [引継ぎ時点の基準資料](drafts/handover-baseline/README.md) — 原則採用し、採否を監査したY2構造基準資料
