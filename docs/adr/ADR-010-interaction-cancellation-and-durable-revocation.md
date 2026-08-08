# ADR-010: Interaction取消とdurable revocation

- Status: Accepted
- Scope: cancel、遅延結果、dispatcher、Recovery、voice stop

## Context

取消要求、受理済みのInteraction取消、pending workの取消、実行中Adapterの結果、physical outcomeを一つの成功/失敗へ畳むと、遅延結果とrestartを安全に扱えない。

## Decision

`CancelRequested`は共通Inbound境界のCommandであり、Webのcancelは直ちにここへ投入する。音声Stop候補は、TTS再生中に限りADR-016の`StopSuppressionPolicy`を先に通る。抑止された候補から`CancelRequested`を作らないが、Web Cancelと音声／Web Homeは常に利用できる。Interaction Contextは取消受理を所有し、受理した事実を`CancellationAccepted` Eventとして記録する。Execution Contextはpending Graph workをdurable revokedにし、dispatcherはrestart後もrevoked recordをdispatchしない。cancelled Interactionは遅延Proposalを拒否する。

`ReturnToHomeRequested`はQualia終了を求める別Commandである。一つのQualiaに属する複数Interactionのadmission停止と終了処理を開始してよいが、Home要求の受理を各Interaction取消結果または物理停止結果と同一視しない。

dispatch済みphysical moveはnon-cancellableであり、下流をrevokedにして遅延したphysical resultを記録する。初期non-streaming音声のstopはLLM、pending TTS、開始済みplaybackのうちAdapterが対応する範囲だけに要求し、停止の観測を捏造しない。in-flight cancellation resultとphysical outcomeは別の型付き結果Eventである。OutcomeUnknownは自動retryしない。streamingのqueued playback/current chunkは次revisionのscopeである。

## Non-decision / open

Adapter別の次revision streaming chunk停止能力、cancel timeout、Interaction完了時刻、streaming TTSの実装・数値境界は未決である。初期releaseでのstreaming TTS採用はしない。

## Consequences

fixtureはWeb cancel、durable cancel/restart、dispatch済みmoveの下流revocationと遅延結果、cancel後Proposal拒否、未対応stopを検証する。

## Related requirements

REQ-FR-003、REQ-FR-006、REQ-OPS-003、REQ-OPS-004、REQ-OPS-006、REQ-OPS-008、REQ-OPS-009。

## Superseded assumptions

凍結02の一つの`CancelInteraction`結果で全Adapterとphysical outcomeを表せるという単純化は、このscopeでは採用しない。
