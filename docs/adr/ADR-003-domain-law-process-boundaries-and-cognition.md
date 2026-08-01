# ADR-003: domainの法則、process境界、cognition

- Status: Accepted
- Scope: domain model、所有権、外部capability境界

## Context

systemは中央の手続き的controllerを再び作らずに、physical deviceとAIを協調させる必要があります。

## Decision

domain境界は設計判断であり、process境界はdeployment判断です。Stateの所有者はちょうど一つです。RuleとTransitionは純粋で、Effectは不変値、Adapterは結果Eventを返しWorldStateを変更しません。Kernelは汎用のまま保ちます。Effectの順序はGraph依存関係とresource claimで表します。LLM/CodexのProposalは信頼せず、Policy検証を要します。Python inferenceと外部capabilityはWorldState、plan、Provider state、conversation stateを所有しません。

## Non-decision / open

言語、IPC transport、process数、具体Providerは未決です。

## Consequences

新しい作業は主手順またはcapability固有Kernel logicではなく、型付き値、Policy、contributor、Port、Adapter、Projectionを追加します。

## Related requirements

REQ-FR-001、REQ-ARC-001、REQ-ARC-002、REQ-ARC-003、REQ-ARC-004、REQ-PER-001、REQ-OPS-005。

## Superseded assumptions

凍結04の`yatagarasu-agent`によるAgent/model/provider/thread stateの所有と固定Unix JSONL IPCは、このscopeでは置き換えます。
