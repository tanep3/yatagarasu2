# アーキテクチャ

Yatagarasu 2のアーキテクチャは、既存の設計用語をロボットへ当てはめた一覧ではありません。動く実機から発見した世界を、次の人間とAIが同じように理解し、中央の巨大な手順へ戻さず拡張するための記述体系です。

次の順番で読むと、結論だけでなく導出まで追えます。

1. [設計思想](design-philosophy.md) — なぜこの構造なのか。理論、soukoban、Yatagarasu 1、Yatagarasu 2の連鎖
2. [ドメインモデル](domain-model.md) — 何が存在し、誰が状態を所有し、世界がどう変わるか
3. [ランタイム境界](runtime-boundaries.md) — 外界とどう接続し、設計上の境界と配置をどう分けるか
4. [永続化と不確実性](persistence-and-uncertainty.md) — 再起動、遅延、取消、結果不明をどう誠実に扱うか
5. [設定とCapability運用](configuration-and-capabilities.md) — 設定、Workspace、Upgrade、能力配置をどう守るか
6. [用語集](glossary.md) — 英語由来の用語と、日本語での意味を統一する

[要件](../requirements/README.md)は観測可能な義務を定め、[ADR](../adr/README.md)は矛盾を解いた承認済み判断を記録します。この説明文書だけで、新しい要件や決定を作ることはしません。
