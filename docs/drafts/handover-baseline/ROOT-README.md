# Yatagarasu 2

Yatagarasu 2は、Yatagarasu 1の実機運用で発見したドメインを、
State、Event、Rule、Transition、Effectとして再構築する次世代実装です。

現行Yatagarasuとは別repository、別service、別実機で開発します。
TC70上のYatagarasu 1を安定運用版として維持し、C210をYatagarasu 2の検証機とします。

現在は要件とアーキテクチャを検討する段階です。

設計文書の入口:

- [docs/README.md](docs/README.md)
- [Agent化要件ドラフト](docs/04-agentization-requirements-draft.md)
- [Agent化要件のアーキテクチャレビュー](docs/05-agentization-architecture-review.md)
- [設定・Workspace・Capability運用](docs/06-configuration-workspace-and-capability-operations.md)
