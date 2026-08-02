# ADR-007: capability bindingと延期したscheduling

- Status: Accepted
- Scope: 外部capability binding、Proposal、将来のschedule input

## Context

具体productとscheduled jobをdomainの法則へ漏らしてはなりません。また、Skillを単なる作業指示、Proposal、Adapterのいずれかへ縮めると、人とAIがアプリの世界を共有する拡張境界を失います。

## Decision

具体capabilityはadapter/bootstrapで抽象Portへbindします。Skillは、人が使うアプリ、データ、能力をAIへ公開する接続面であり、Skill、Contributor、Proposal、Effect、Adapterを分離します。アプリの状態所有をCoreへ移しません。LLM、Codex tool、Skillを介した外部主体、その他外部capabilityからのProposalはPolicy検証を要します。決定論的で承認済みのcontributorは許可済みGraph断片を作れても、外部capabilityはStateを所有しません。cron/scheduled autonomyは延期し、導入時は同じCommand/Event境界を使うInbound Adapterにします。

## Non-decision / open

Provider routing、利用者同意、privacy/memory policy、Web authentication/TLS、IPCとprocess managementは未決です。Skillの具体形式、transport、認証・認可、Skill作成時の検証、配備、rollback、安全方針も未決です。

## Consequences

具体Provider、source、transportをdomain typeにせず、Policyを迂回させません。

## Related requirements

REQ-PRD-002、REQ-ARC-004、REQ-ARC-005、REQ-ARC-007、REQ-OPS-005、REQ-SEC-001、REQ-FUT-001。

## Superseded assumptions

凍結04の固定IPCとdirect tool-dispatchの仮定は、このscopeでは置き換えます。
