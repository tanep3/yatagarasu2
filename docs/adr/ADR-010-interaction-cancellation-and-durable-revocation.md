# ADR-010: Interaction取消とdurable revocation

- Status: Accepted
- Scope: cancel、遅延結果、dispatcher、Recovery、voice stop

## Context

取消要求、受理済みのInteraction取消、pending workの取消、実行中Adapterの結果、physical outcomeを一つの成功/失敗へ畳むと、遅延結果とrestartを安全に扱えない。

## Decision

`CancelRequested`は共通Inbound境界のCommand/Eventであり、Webのcancelは直ちにここへ投入する。Interaction Contextは取消受理を所有する。Execution Contextはpending Graph workをdurable revokedにし、dispatcherはrestart後もrevoked recordをdispatchしない。cancelled Interactionは遅延Proposalを拒否する。

dispatch済みphysical moveはnon-cancellableであり、下流をrevokedにして遅延したphysical resultを記録する。voice stopはLLM、pending TTS、queued playback、current chunkのうちAdapterが対応する範囲だけに要求し、停止の観測を捏造しない。in-flight cancellation resultとphysical outcomeは別の型付き結果Eventである。OutcomeUnknownは自動retryしない。

## Non-decision / open

Adapter別の現在chunk停止能力、cancel timeout、Interaction完了時刻、streaming TTS採用と数値境界は未決である。

## Consequences

fixtureはWeb cancel、durable cancel/restart、dispatch済みmoveの下流revocationと遅延結果、cancel後Proposal拒否、未対応stopを検証する。

## Related requirements

REQ-FR-003、REQ-OPS-003、REQ-OPS-004、REQ-OPS-006、REQ-OPS-008。

## Superseded assumptions

凍結02の一つの`CancelInteraction`結果で全Adapterとphysical outcomeを表せるという単純化は、このscopeでは採用しない。
