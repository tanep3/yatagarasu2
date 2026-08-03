# ADR-005: 物理的不確実性、時刻、ストリーミング音声

- Status: Accepted
- Scope: 物理結果分類、暫定時刻、speech完了

## Context

deviceが完了を確認できないことがあり、durationは観測ではありません。

## Decision

物理結果はObserved、Assumed、DefinitelyNotApplied、OutcomeUnknownのまま扱います。Adapterが返しCoreが受理する`EffectExecutionStarted`は、dispatch/実行開始の試行を確認する結果Eventであり、物理的な適用または完了を確認しません。`ExpectedActionDuration`はこのEventの受理からeffect/device profile上の単調Durationを測り、依存先が安全にreadyになりうる最も早い時点までしか定めません。queue時間は含めず、EventがなければtimerベースのAssumed readinessは生じません。観測を作りません。初期releaseのTTSはnon-streamingであり、streaming TTSは次revisionの明示scopeとする。採用時の`PlaybackCompletionAssumed`も同じEvent受理後にClockPortの単調audio durationとmarginを用います。これは音響的観測ではありません。

## Non-decision / open

camera校正の証拠、reconciliation、時刻margin、start Event不達時のtimeout/Failure Policy、次revisionのstreaming TTS数値境界は未決です。

## Consequences

Recovery、timer、Adapterの実装は、仮定した物理完了をObservedとして報告してはなりません。

## Related requirements

REQ-PRD-003、REQ-PHY-001、REQ-PHY-002、REQ-PHY-003、REQ-OPS-004、REQ-OPS-008。

## Superseded assumptions

基準資料のtimer/settle表現を限定します。durationベースの完了はAssumedでありObservedではありません。
