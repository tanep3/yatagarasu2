# Change Impact Matrix

この表は、変動箇所を正しい境界へ隔離できているかを検証する設計成果物です。

設計段階の記載は`predicted`（予測）または`planned-proof`（検証計画）です。実装後のarchitecture test、差分test、contract testが通るまで`verified`（検証済み）と表記しません。

| Change case | Predicted changed Design IDs / modules | Must not change | Planned proof | Status |
| --- | --- | --- | --- | --- |
| 新しいカメラ機種を追加する | device Profile、Adapter、Bootstrap binding、機種固有contract test | Kernel、相対移動Command、物理結果語彙、Graph ready Rule | 同一Port contractへ別Adapterをbindingするarchitecture/contract test | `predicted` |
| Providerを切り替える | Provider Profile、Adapter binding、Capability advertisement | Conversation正本、AgentTurnBinding法則、no-auto-fallback Policy | `CodexThread`／`NoExternalContinuity`のtable-driven integration test | `predicted` |
| 既存能力だけでBehaviorを追加する | routing contribution、Graph contribution、Projection/Web部品、適合表 | Kernel、新しいPort Trait、既存State owner | compile-time contributionとarchitecture diff test | `predicted` |
| 新しい外部能力を使うBehaviorを追加する | 新Port、Adapter、Bootstrap binding、結果Event、contract test | Domainから具体製品への依存、Kernelの製品分岐 | dependency testとFake/real Adapter contract test | `predicted` |
| Web更新transportを交換する | Web transport Adapter、gateway設定、再接続contract test | 公開Command/Query意味、Projection schema、Domain Event | SSE/WebSocket/polling候補を同一API contractへ適合させるtest | `planned-proof` |
| persistence実装を交換する | snapshot/pending repository Adapter、migration、recovery integration test | snapshot＋pending原子境界、journal非dispatch、EffectOccurrence identity | crash-window test suiteを新Adapterへ再実行 | `planned-proof` |

pilot設計で具体Design IDが確定した時点で、一般名をID参照へ置き換えます。表をruntime routingへ使用しません。
