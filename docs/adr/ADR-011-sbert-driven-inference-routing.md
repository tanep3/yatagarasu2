# ADR-011: SBERTによる動的LLM／Provider選択

- Status: Accepted
- Scope: Yatagarasu 2の製品positioning、推論能力選択、route状態

## Context

Yatagarasu 1は、SBERTによる意味の反射が、LLMへすべてを委ねる経路より大幅に短い体験を作れることを実証した。Yatagarasu 2では、速度重視の日常会話、Vision、高性能推論、local処理、外部Providerを使い分けたい。route選択をLLM自身へ委ねると、選択前の遅延、非決定性、意図しない外部送信、cost／privacy制御の低下が起きる。

## Decision

SBERTによる動的LLM／Provider選択をYatagarasu 2の必須製品能力とする。少なくともlocal推論能力とexternal推論能力を、具体製品名から分離したlogical profileとして構成できるようにする。SBERTは意味候補を返し、version付きDecision Policyが能力広告、可用性、privacy、同意を踏まえてrouteを解決する。route選択のためにLLM requestを必須にしない。この推論route Decisionは、ADR-008のBehavior選択Decisionと分ける。

preferred routeとeffective routeを別の型付き値とし、縮退、拒否、選択根拠を観測可能にする。dispatch時のeffective profileとversionはEffect／pending recordへ固定する。

## Non-decision / open

具体profile集合、閾値、model名、Provider再構成、active turn中の切替、Conversation再binding、fallback、利用者同意、privacy、cost Policy、Recovery、transportは未決である。

## Consequences

単一固定Agentしか選べず、local／external routeを構成できない実装は製品Baselineを満たさない。SBERT worker、Provider、LLMはroute Policy、Conversation、WorldStateを所有しない。routeの性能は因果区間ごとに計測し、数値budgetはspike後に定める。

## Related requirements

REQ-PRD-004、REQ-FR-007、REQ-NFR-001、REQ-ARC-005、REQ-ARC-006、REQ-ARC-008、REQ-CFG-004。

## Superseded assumptions

動的model／Provider routingを契約未決の将来能力として製品Baseline外へ置く解釈を置き換える。実装方式の未決と、製品能力の必須性を分離する。
