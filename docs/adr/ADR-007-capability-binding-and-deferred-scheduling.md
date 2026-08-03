# ADR-007: capability bindingと延期したscheduling

- Status: Accepted
- Scope: 外部capability binding、Proposal、将来のschedule input

## Context

具体productとscheduled jobをdomainの法則へ漏らしてはなりません。また、Skillを単なる作業指示、Proposal、Adapterのいずれかへ縮めると、人とAIがアプリの世界を共有する拡張境界を失います。

## Decision

具体capabilityはadapter/bootstrapで抽象Portへbindします。Y2 Behaviorはdomain/application/ports/adaptersへ寄与するversion付きrobot機能であり、Codex SkillはCodexの作業能力またはアプリ/AI接続面である。この二つを同じ拡張単位にしない。初期Codex capabilityにはSkillCreator、Search、Fetchを含める。Codexは自身に与えられた権限の範囲で`SKILL.md`、Python、Web、scriptを作成してよいが、Y2はその作成に別の承認層・制限層を加えない。

その外部ファイルは、明示的な正式Y2 Behavior version updateなしに、信頼済みBehavior、Rule、Policy、Port、Effect、ownership registry、catalogを変更しない。Search/FetchもREQ-NET-001のallowlist、provenance、処理場所・移送direction、configured authorizationを通る独立Capabilityである。LLM、Codex tool、Codex Skill、その他外部capabilityからのProposalはPolicy検証を要する。決定論的で承認済みのcontributorは許可済みGraph断片を作れても、外部capabilityはStateを所有しない。cron/scheduled autonomyは延期し、導入時は同じCommand/Event境界を使うInbound Adapterにします。

## Non-decision / open

Codexの具体transport候補と互換version範囲はADR-022、Provider routeはADR-011、Owner認証はADR-014が定めます。Codex Skillの形式、実行権限、配布、rollbackはCodexが所有するmechanismであり、Y2 Behavior/plugin設計の未決事項ではない。Y2はそれらを自身に与えられたCodex権限として従い、追加の承認・制限を加えない。Y2側で互換性を実装する必要があるのは、pinしたCodex/app-server versionが新規作成Skillをどうdiscover/reloadしavailabilityをどう報告するかだけであり、これによりY2 Behavior所有権を得ない。

## Consequences

具体Provider、source、transportをdomain typeにせず、Policyを迂回させません。

## Related requirements

REQ-PRD-002、REQ-ARC-004、REQ-ARC-005、REQ-ARC-007、REQ-OPS-005、REQ-SEC-001、REQ-API-004、REQ-FUT-001。

## Superseded assumptions

凍結04の固定IPCとdirect tool-dispatchの仮定は、このscopeでは置き換えます。
