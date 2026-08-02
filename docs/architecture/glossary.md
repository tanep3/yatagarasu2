# 用語集

本文では、英語だけで意味が伝わりにくい語に日本語を添えます。この表は訳語を統一し、同じ構造を別の言葉で重複して作ることを防ぎます。

| 用語 | このプロジェクトでの意味 |
| --- | --- |
| WorldState（世界状態） | 判断時点でCoreが知っている状態の集合。すべての外部データを持つ巨大な袋ではない。 |
| Context（文脈境界） | 一つの意味領域と、その状態を唯一所有する境界。processとは限らない。 |
| Command（要求） | 受理、拒否、確認要求の対象となる依頼。まだ起きた事実ではない。 |
| Event（事実） | 過去に起きたことを表す不変値。結果Eventも含む。 |
| CancelRequested（取消要求） | 共通Inbound境界へ入るCommand。取消が受理された事実ではない。 |
| CancellationAccepted（取消受理） | Interaction Contextが取消を受理したことを表すEvent。外部処理や物理動作の停止証拠ではない。 |
| Rule（規則） | StateとEventをI/Oなしで評価する純粋な法則。 |
| Transition（遷移） | 内部Stateを次のStateへ決定論的に変える変換。 |
| Decision（決定） | Ruleが返す、TransitionとEffect Graphを含み得る判断値。 |
| Effect（外部作用） | 外界へ依頼する仕事を表す不変値。作成は実行や成功を意味しない。 |
| Effect Graph（外部作用グラフ） | Effect間の因果依存、guard、資源要求を表す構造。逐次手順書ではない。 |
| Proposal（提案） | LLMや外部能力が返す、まだPolicyで許可されていない実行候補。 |
| Policy（方針） | 候補や提案を受理、拒否、確認、合成する版付きの判断基準。 |
| Contributor（候補提供者） | SBERT、純粋Rule、LLMなど、意味解決へ候補や材料を寄与するもの。 |
| Skill（AI接続面） | 人が使うアプリ、データ、能力をAIへ公開し、同じ世界へ関われるようにする境界。 |
| Port（抽象接続口） | Applicationが外部能力へ要求する、具体製品に依存しない契約。 |
| Adapter（変換境界） | Portの値と具体製品・通信・入出力の表現を相互に翻訳するもの。 |
| Projection（参照表現） | EventやStateから作る、利用者・運用者向けの読取モデル。外部配達の証拠ではない。 |
| ArtifactRef（成果物参照） | 画像、音声、文字列などの成果物を、その存在・利用条件とともに参照する値。 |
| resource claim（資源要求） | カメラの首や音声出力など、Effectが排他的または有限に使う資源の宣言。 |
| guard（進行条件） | 先行結果に応じ、下流Effectを進行または停止する条件。 |
| snapshot（状態スナップショット） | commit済みWorldStateを復旧するための初期Source of Truth。 |
| journal（出来事記録） | 監査とProjection再構築の記録。外部作用の再実行源ではない。 |
| durable pending（永続待機仕事） | 再起動後も失ってはいけない、dispatch可能なEffect記録。 |
| Observed（観測済み） | 証拠により物理結果を確認した状態。 |
| Assumed（仮定済み） | 方針や時間により進行を許すが、物理観測はない状態。 |
| DefinitelyNotApplied（未適用確定） | 証拠により外部作用が適用されなかったと分かる状態。 |
| OutcomeUnknown（結果不明） | 適用済み・未適用のどちらとも安全に判断できない状態。 |

`intent`は外部製品やY1の実装を説明する場合に使うことがありますが、Y2 Coreへ単一の正式Intent登録簿を置くことは意味しません。Y2では、意味候補、動作単位の方針、解決結果を区別します。
