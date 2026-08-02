# ADR-003: domainの法則、process境界、cognition

- Status: Accepted
- Scope: domain model、所有権、外部capability境界

## Context

Yatagarasu 1が発見した機能世界を継承しながら、知識を中央の時間順controllerへ再集積せず、physical deviceとAIを協調させる必要があります。soukobanの閉じた世界ではRuleとTransitionで世界を記述できましたが、現実では外部作用と結果不明を追加する必要があります。

## Decision

Domain境界は設計判断であり、process境界はdeployment判断です。Stateの所有者はちょうど一つです。RuleとTransitionは純粋で、Transitionは内部で確定できる世界変換だけを扱います。外界への仕事は不変のEffectとし、Adapterは結果Eventを返しWorldStateを変更しません。Kernelは汎用のまま保ちます。Effectの順序はGraph依存関係とresource claimで表します。LLM/CodexのProposalは信頼せず、Policy検証を要します。Python inferenceと外部capabilityはWorldState、plan、Provider state、conversation stateを所有しません。

## Non-decision / open

言語、IPC transport、process数、具体Providerは未決です。

## Consequences

新しい作業は主手順またはcapability固有Kernel logicではなく、型付き値、Policy、contributor、Port、Adapter、Projectionを追加します。

## Related requirements

REQ-FR-001、REQ-ARC-001、REQ-ARC-002、REQ-ARC-003、REQ-ARC-004、REQ-ARC-008、REQ-ARC-009、REQ-PER-001、REQ-OPS-005。

## Superseded assumptions

凍結04の`yatagarasu-agent`によるAgent/model/provider/thread stateの所有と固定Unix JSONL IPCは、このscopeでは置き換えます。
