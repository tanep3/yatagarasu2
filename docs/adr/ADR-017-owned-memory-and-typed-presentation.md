# ADR-017: Yatagarasu所有の記憶と型付きPresentation

- Status: Accepted
- Scope: Conversation/Memory所有、保存・想起、View/Recall出力

## Context

Y1は記憶の自動保存、明示memorize、recent/semantic recallを提供した。一方、Codex Skillアプリのデータ、Provider thread、検索内容をYatagarasuが所有すると、削除、保持、authorization、出所が曖昧になる。想起の空結果、翻訳後の提示、観測の説明も一つの文字列に畳めない。

## Decision

Conversation Contextは会話turn履歴、Memory ContextはYatagarasuの長期記憶と保存・削除状態を所有する。外部Codex Skillアプリのデータ、Provider thread、外部本文は外部の所有のまま参照する。README/setup/configのstanding disclosureとenabled configを保存・transfer authorizationとし、local auto-save既定ONは原発話と最終応答だけを保存する。利用ごとのconsent promptは置かない。明示`Memorize`は別の目的である。

Codex Threadは複数の有限Interaction/Homeを越えて推論へ影響する外部継続文脈であるが、Yatagarasuの正本Conversation/Memoryではない。Conversation Contextは原発話と最終応答の正本、Memory ContextはSemanticMemoryの保存・削除状態を所有し、Agent Session ContextはopaqueなThread bindingだけを所有する。通常Conversationのversion付き既定PolicyはSemanticMemoryを`recent=0`、`semantic=3`でprovenance付き取得し、継続中のCodex Threadへ追加する。件数は目的/profile別に設定でき、`recent=0`はThread内の過去turnを除外する意味ではない。自動保存は既定ONのまま維持する。

`RecallPurpose`はSummarize、ExistenceConfirm、TopicSearch、Compare、Contextualizeを区別し、目的別Policyはrecent/semantic件数を上書きできる。重複・競合はrecent優先で一度だけ示す。PresentationとOutputPurposeは閉じた型とし、Viewの9目的、Recallの5目的、空Recall、Failureを分ける。各目的は必要入力、許可surface、evidence/provenance、禁止presentationを持つ。翻訳系は提示変換であり、英語または原文を追加再生しない。

enabledな初期Conversation profileはconversational LLM request前にこの既定recallを行う。`CodexThread` routeでは選択された参照/provenanceを継続Threadへ追加し、`NoExternalContinuity` routeでは現在入力と選択参照だけをそのturnへ渡して外部継続を主張しない。retrieval Failure/disabledは型付きPolicy結果とし、記憶を捏造しない。current-image interpretationなどmemoryが関係しないBehaviorは、Behavior Policyで`NotApplicable`を明示できる。

SemanticMemory delete/resetは保存庫と将来注入へ効くが、すでにCodex Threadへ渡した内容を遡及消去しない。完全に外部文脈を切るOwner Thread resetは別Commandであり、durable barrier後に新Threadを開始して旧late resultを隔離する。Thread resetはSemanticMemoryを削除せず、SemanticMemory delete/resetもThread resetを暗黙実行しない。

## Consequences

外部Memory adapterは結果を返してもState所有者にならない。空RecallはFailureでもViewでもなく、利用者に欠損を明示できる。schema、保存engine、具体翻訳器は未決である。Memory retentionはOwner deleteまで、authorizationはstanding configであり利用ごとの同意画面は置かない。

## Related requirements

REQ-MEM-001、REQ-OUT-001、REQ-DAT-001、REQ-ARC-002。
