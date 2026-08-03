# ADR-016: Acoustic Context、一wake一命令、自己音声の境界

- Status: Accepted
- Scope: wake受理、audio session、pre-roll、prompt/discard/guard、空命令

## Context

Y1はwake後のprompt回り込み、RTSP bufferの遅延、最初の発話の欠落、dispatch後の自己音声再入力を実機で観測した。source workerへこの判断を渡すと、音声接続の都合がConversationやInteractionの生存期間を決めてしまう。

## Decision

Acoustic Contextがwake acceptance、session identity、pre-rollの選択window/cursor、保持/discard判断、prompt中discard、prompt guard、empty commandを唯一所有する。初期既定は一wake一命令であり、受理した命令の後はsessionを閉じる。自己音声、遅延buffer、再接続は次のwake/session/Interactionを暗黙に作らない。

Yata Wake、Mimy、RTSPその他のsource Adapterは、接続、raw audio bytes/ring buffer、推論、再接続、結果Eventを担当する。Acoustic Contextへ観測を返してよいが、wake受理、session、pre-roll選択、Interaction、Conversation、WorldStateを所有しない。prompt、pre-roll、guardの具体機構と数値は未決である。実profile fixtureはwake prompt「はい」をtranscriptへ入れず、最初の実発話を保ち、実TTSを新しい通常Wake/通常command/Interaction/LLMとして受理しないことを示さなければならない。独立したHome/Stop control検知はTTS中も生存する。

## Consequences

音声の自己ループをRTSP再接続という特定機構で「解決済み」とは主張しない。discard/empty/recoveredは型付き事実であり、無音にすることや再起動を成功と偽装しない。

## Related requirements

REQ-ACOU-001、REQ-PRD-001、REQ-OPS-005。

## Superseded assumptions

Y1 `listend.py`のRTSP consumer resetは有用な根拠だが、Y2で必須の自己ループ防止機構にはしない。ADR-006のsource-agnostic判断を補完する。
