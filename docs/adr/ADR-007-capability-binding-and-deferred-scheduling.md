# ADR-007: capability bindingと延期したscheduling

- Status: Accepted
- Scope: 外部capability binding、Proposal、将来のschedule input

## Context

具体productとscheduled jobをdomainの法則へ漏らしてはなりません。また、Skillを単なる作業指示、Proposal、Adapterのいずれかへ縮めると、人とAIがアプリの世界を共有する拡張境界を失います。

## Decision

具体capabilityはadapter/bootstrapで抽象Portへbindします。Y2 Behaviorはdomain/application/ports/adaptersへ寄与するversion付きrobot機能であり、Codex SkillはCodexの作業能力またはアプリ/AI接続面である。この二つを同じ拡張単位にしない。初期Codex capabilityにはSkillCreator、Search、Fetchを含める。Ownerはversion付きstanding delegationにより、SkillCreatorへSkill資産の作成とSkill単位の初期実行grant構成を包括委任する。作成ごとの承認UIは置かない。Skill assetはinactive staging、grant検証/commit、activation Eventを経て初めて実行可能にし、片方だけの部分状態を実行させない。

Authorization Policy Contextがstanding delegationとversion付き`SkillExecutionGrant`を所有する。作成済みSkillはgrant範囲内でWorkspace外のread/write、network、secret、外部operation、副作用を実行できるが、自身または別Skillのgrantを拡大しない。権限変更はSkillCreator再構成またはOwner config/CLIから別Commandとして開始する。その外部ファイルは、明示的な正式Y2 Behavior version updateなしに、信頼済みBehavior、Rule、Policy、Port、Effect、ownership registry、catalogを変更しない。初期catalogのmanaged Search/FetchはREQ-NET-001の型付きY2 Tool/Portだけを実通信境界とし、allowlist、provenance、処理場所・移送direction、configured authorizationを通る。これは一般Skillが自身のgrant内で行うnetwork operationを禁止するものではないが、その結果をmanaged Search/Fetch成功へ偽装できない。LLM、Codex tool、Codex Skill、その他外部capabilityからのProposalはPolicy検証を要する。決定論的で承認済みのcontributorは許可済みGraph断片を作れても、外部capabilityはStateを所有しない。cron/scheduled autonomyは延期し、導入時は同じCommand/Event境界を使うInbound Adapterにします。

## Non-decision / open

Codexの具体transport候補と互換version範囲はADR-022、Provider routeはADR-011、Owner認証はADR-014が定めます。Codex Skillのファイル形式、配布、rollback機構はCodexが所有する。Skill単位grantをCodex app-serverのturn-scoped permission profile、型付きTool、隔離workerのどれで強制するかはspikeで決めるが、Owner standing delegation、Skill自己拡大禁止、部分状態非実行の契約を弱めない。

## Consequences

具体Provider、source、transportをdomain typeにせず、Policyを迂回させません。

## Related requirements

REQ-PRD-002、REQ-SKL-001、REQ-ARC-004、REQ-ARC-005、REQ-ARC-007、REQ-OPS-005、REQ-SEC-001、REQ-API-004、REQ-FUT-001。

## Superseded assumptions

凍結04の固定IPCとdirect tool-dispatchの仮定は、このscopeでは置き換えます。
