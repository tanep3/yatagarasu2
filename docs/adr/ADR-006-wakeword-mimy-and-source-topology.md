# ADR-006: WakeWord、Mimy、source topology

- Status: Accepted
- Scope: wake/STT所有権とaudio source topology

## Context

wake recognitionとspeech-to-textには、STT serviceへdomain所有権を渡さない独立したlifecycle制御が必要です。

## Decision

Yata WakeはMimyの外側にあるYatagarasu Adapterです。Yata WakeとMimyは接続/buffer stateを独立して所有し、fan-out sourceを使えます。Acoustic Contextはwake acceptance/promptを所有し、held Mimy sessionのcreate/releaseをcommandします。Mimyは汎用でsource-agnosticとし、go2rtcはsource adapterの一例です。raw microphoneはfan-outを提供するか、互換性のあるsingle-consumer topologyを使わなければなりません。

通常WakeWordと、Active Qualiaへ割り込むHome／Stop制御語は異なる意味を持ちます。実装を共有しても、Home制御語は通常の候補なしfallbackへ送らず、共通`ReturnToHomeRequested`へ変換します。既定語句は「ヤタガラス、ホーム」です。

## Non-decision / open

具体source実装、API、buffering機構、IPCは未決です。

## Consequences

MimyはInteraction、conversation、plan、Provider、WorldStateを所有できません。go2rtcへの必須直接接続は仮定しません。

## Related requirements

REQ-FR-006、REQ-ARC-002、REQ-OPS-005。

## Superseded assumptions

凍結06 §6.1のMimyによる直接go2rtc接続/source・ring buffer常時所有、および凍結02 §2.1のVoice GatewayによるVAD/STT所有は、このscopeでは置き換えます。
