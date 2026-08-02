# ADR-013: 単一Active QualiaとHome復帰

- Status: Accepted
- Scope: 製品活動状態、入力所属、終了、Recovery

## Context

会話、文字起こし、同時通訳、見守りなどを同時にActiveにすると、一つの音声が命令か処理対象か、どの機能をHomeで終了するか、マイク・カメラ・GPUを誰が使うかが曖昧になる。一方、Home／Stop検知、永続化、診断、認証、Web同期まで活動とともに停止させることはできない。

## Decision

Yatagarasu全体で現在の非Home qualia sessionは0または1とする。これはLifecycleのActive phaseだけでなく、Starting、Active、Terminating、Recoveringにある現在session全体を指す。Qualiaは、Yatagarasuが現在どの振る舞いとして世界を知覚し活動しているかを表す。Homeは現在sessionがない基本待受状態であり、Home以外では別Qualia開始要求をBusyとして拒否する。

Qualia Contextは活動identityとLifecycleだけを所有し、Behavior固有Stateを集約しない。Home／Stop検知、永続化、Recovery、診断、認証、Web同期は自律神経として並行稼働するが、第二のQualiaまたは製品固有司令塔にならない。

設定可能な音声制御語とWebの常設Home操作は共通の`ReturnToHomeRequested` Commandを生む。既定音声は「ヤタガラス、ホーム」とする。Home要求の受理、Qualia終了、外部作用の取消、物理結果を分ける。

Qualiaは、未解決の外部作用を永続Recoveryへ引き渡した後にHomeへ戻ってよい。Homeは物理作用がすべて観測済みであることを意味しない。OutcomeUnknownは自動再送せず、資源再利用条件をeffect／device別Recovery Policyで決める。

## Consequences

文字起こし中の通常音声は文字起こしへ所属し、Home制御語だけが独立経路から割り込める。別Qualiaへ自動切替する終了・開始連鎖は初期Baselineに含めない。複数deviceは一つのQualiaが選択または合成して利用でき、複数Qualiaを意味しない。

再起動時に永続化されたStarting、Active、Terminatingを見つけた場合は、まず同じqualia sessionをRecoveringとして公開する。既定は自動再開ではなく、安全に終了してHomeへ戻ることである。明示checkpointとPolicyがあるBehaviorだけが`Recovering -> Active`を選べる。Owner判断待ちはRecoveringを維持し、終了または資源隔離は責任移管後にTerminatingを経てHomeへ進む。

## Non-decision / open

Lifecycle Eventの最終型名、Home語句の別名、制御語検知方式、終了timeout、Behavior別checkpoint、資源再利用Policyの具体値、会話Qualiaの一回／継続境界は未決である。

## Related requirements

REQ-FR-005、REQ-FR-006、REQ-ARC-010、REQ-OPS-006、REQ-OPS-009、REQ-API-002。
