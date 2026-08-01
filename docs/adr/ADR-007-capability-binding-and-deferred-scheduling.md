# ADR-007: capability bindingと延期したscheduling

- Status: Accepted
- Scope: 外部capability binding、Proposal、将来のschedule input

## Context

具体productとscheduled jobをdomainの法則へ漏らしてはなりません。

## Decision

具体capabilityはadapter/bootstrapで抽象Portへbindします。LLM、Codex tool、外部capabilityからのProposalはPolicy検証を要します。決定論的で承認済みのcontributorは許可済みGraph断片を作れても、外部capabilityはStateを所有しません。cron/scheduled autonomyは延期し、導入時は同じCommand/Event境界を使うInbound Adapterにします。

## Non-decision / open

Provider routing、利用者同意、privacy/memory policy、Web authentication/TLS、IPCとprocess managementは未決です。

## Consequences

具体Provider、source、transportをdomain typeにせず、Policyを迂回させません。

## Related requirements

REQ-ARC-004、REQ-ARC-005、REQ-OPS-005、REQ-SEC-001、REQ-FUT-001。

## Superseded assumptions

凍結04の固定IPCとdirect tool-dispatchの仮定は、このscopeでは置き換えます。
