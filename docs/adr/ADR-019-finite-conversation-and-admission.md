# ADR-019: 有限Fallback ConversationとQualia/Interaction admission

- Status: Accepted
- Scope: 初期会話、Fallback、Qualia開始/Home、Interaction入力/取消

## Context

候補なしを会話へ送る初期体験には価値があるが、暗黙の継続会話やqueueまで導入すると、何が現在のQualiaを開始・終了し、どの入力が取消可能かが曖昧になる。

## Decision

初期`FallbackToConversation`は、Homeで有効Behavior候補がない場合だけ純粋resolutionが返す。一入力・一最終応答の有限Conversation Interactionを実行し、response generation terminal、final Projection publish、Memory save terminalまたはdurable Failure/Recovery handoff後にHomeへ戻る。物理TTSのheard completionは待たず、playback OutcomeUnknownはRecoveryへ引き渡す。履歴は残るが、継続会話は将来のBehaviorである。Policy拒否をfallbackで迂回しない。

Qualia Contextだけがsession開始/Home復帰を、Interaction Contextだけが入力受理、耐久request-idempotency ledger、cancelを所有する。ledgerはAPI client key、payload fingerprint、replay可能な型付きresult、status、lifecycleを持ち、Rejected、AcceptedNoEffect、Pending、Completedをrestart後も区別する。admission Ruleは両者のviewを読む純粋関数である。非Homeでの開始要求はBusyであり、暗黙queueはない。browser/API mutationはclient idempotency keyを必須とし、同一key/同一payloadは同じ結果をreplayしてEffectを重複せず、同一key/異payloadはConflictとする。voiceはAPI keyを要求されず、Adapter/Interaction Contextがserver-assigned input identityを付与する。ledgerはExecution Contextのdurable pending EffectOccurrence recordとRecovery keyとは別である。現在Qualiaの通常入力はBehavior Policyが決め、HomeとWeb Cancelは常に優先する。TTS再生中の音声Stop候補だけはADR-016の`StopSuppressionPolicy`を先に通り、抑止時はCancel Commandを作らない。Web Cancelと音声／Web Homeはこの例外の影響を受けない。

## Consequences

会話、Qualia、Interactionを同義にしない。continuous conversation、Behavior controlの具体語彙、terminal/recovery event名は未決である。

## Related requirements

REQ-CNV-001、REQ-QLI-001、REQ-FR-005–007、REQ-OPS-009。
