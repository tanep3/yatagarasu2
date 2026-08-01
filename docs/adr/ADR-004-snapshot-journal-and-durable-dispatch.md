# ADR-004: snapshot、journal、durable dispatch

- Status: Accepted
- Scope: 初期永続化、dispatch、Recovery意味論

## Context

仕事をreadyにするcommit済みStateは、commitとdispatchの間でその仕事を失ってはなりません。

## Decision

初期永続化はsnapshotをSource of Truthにします。journalはauditとProjectionを支え、side-effect replayを駆動しません。snapshotのcommitがEffectをreadyにするなら、dispatch可能なpending recordをsnapshotとともにdurableにします。dispatcherはdurable pending workだけをdispatchします。Recoveryは仕事を黙って失わず、journal replayによって再生成もしません。

## Non-decision / open

database、transaction/outbox機構、migration、idempotency、reconciliation機構は未決です。

## Consequences

永続化の変更は、stop/Recovery testによりdurable-pending invariantを示さなければなりません。

## Related requirements

REQ-OPS-002、REQ-OPS-003、REQ-ARC-003。

## Superseded assumptions

外部Effectをjournal replayで再発行してよいとする基準資料の示唆は置き換えます。
