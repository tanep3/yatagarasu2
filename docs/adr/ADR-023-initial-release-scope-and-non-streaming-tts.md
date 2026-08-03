# ADR-023: 初期release scopeとnon-streaming TTS

- Status: Accepted
- Scope: 初期製品の含む機能・延期機能・音声出力

## Context

streaming、長時間音声、継続会話を「拡張可能」とだけ書くと、初期Effect Graphへ未定義のchunk/queue/継続sessionを混入させる。

## Decision

初期TTSはnon-streamingとし、初期Effect Graphはaudio chunk、stream queue、chunk間backpressureを持たない。streaming TTSは次revisionの明示scopeとする。long-duration transcription、simultaneous interpretation、surveillance、continuous conversationは延期する。初期会話はREQ-CNV-001の有限一往復である。

初期Codex capabilityはSkillCreator、Search、Fetchを必須とする。Search/Fetchはnetwork capabilityとしてREQ-NET-001を守る。延期機能は、将来の正式Behavior version update、契約、effect graph、testを経るまで初期Behaviorやfallbackに暗黙追加しない。

## Consequences

初期実装とacceptanceは有限会話、non-streaming playback、明示的な停止/Recoveryだけを扱う。互換性のための抽象型は許すが、未採用streamingのqueue/workerをproduction graphへ導入しない。

## Related requirements

REQ-SCP-001、REQ-CNV-001、REQ-OPS-004、REQ-OPS-008、REQ-PRD-002、REQ-PRD-005。
