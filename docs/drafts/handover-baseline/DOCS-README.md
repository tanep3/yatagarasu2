# Yatagarasu 2 Architecture Notes

このディレクトリは、Yatagarasu 2のアーキテクチャとプロダクト要件を育てる場所です。

現時点では実装仕様を確定していません。Yatagarasu 1の運用から得た知見を、
Tane Channel Technologyの「処理ではなく、構造と状態遷移を記述する」という思想で
再構成し、Agent化の要件と結び付けながら育てる議論用の正本です。

## Documents

1. [00-architecture-vision.md](00-architecture-vision.md)
   - なぜYatagarasu 2が必要か
   - 美しさの基準
   - システム全体の輪郭
2. [01-domain-and-execution-model.md](01-domain-and-execution-model.md)
   - State / Event / Rule / Transition / Effect
   - 複合Intentの実行モデル
   - 音声、Web、CLIの統合
3. [02-boundaries-and-runtime.md](02-boundaries-and-runtime.md)
   - 境界、Port、Adapter
   - 並行実行、障害、永続化、監視
   - 配置とプロセス構成
4. [03-evolution-plan-and-open-questions.md](03-evolution-plan-and-open-questions.md)
   - Yatagarasu 1から継承する資産
   - 段階的な検証案
   - 未決事項
5. [04-agentization-requirements-draft.md](04-agentization-requirements-draft.md)
   - 常駐Codex、Web GUI、モデル／Provider切替の要求原典
   - 今後のレビューで変更される要件ドラフト
6. [05-agentization-architecture-review.md](05-agentization-architecture-review.md)
   - Agent化要件と既存アーキテクチャの統合方針
   - Rust CoreとPython Inference Adapterの推奨境界
   - 拡張可能なRouter、Effect、モデル選択の構造
7. [06-configuration-workspace-and-capability-operations.md](06-configuration-workspace-and-capability-operations.md)
   - XDG準拠の設定、Workspace、State配置
   - Web GUI設定と型付きTOML
   - Native管理、Local／Remote Capability、Mimy連携
   - Setup、systemd、Upgrade、縮退運転

## Status

- 文書種別: Architecture and Product Requirements
- 状態: Discussion Draft
- 初版作成日: 2026-07-28
- 最終更新日: 2026-07-31
- 対象: Yatagarasu 2。Yatagarasu 1とは別repository、別実機で開発する

## One Sentence

> Yatagarasu 2は、命令を順番に処理するプログラムではなく、ロボットの世界、世界を
> 観測して得られる事実、適用可能な規則、可能な状態遷移、そして外界へ依頼するEffectを
> 型で記述した実行可能モデルである。
