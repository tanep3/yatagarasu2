# ADR-008: 複数contributorとPolicy解決

- Status: Accepted
- Scope: 意味候補、SBERT、direct reflex、LLM/Codex Proposal

## Context

Y1のSBERT routerは実機で有用な高速経路を示す一方、Y2は一つの意図登録簿または必須の滝型処理へ固定してはならない。

## Decision

通常の意味routing機能はSBERT candidate生成を第一段とし、gray band候補をaccept前に決定論的keyword/rule filterへ渡す。これは普遍的な滝型処理ではない。明示capability Policyにより、機能はSBERT、純粋Rule、LLMなど一つ以上のcontributorを用い、rule-onlyまたはLLM-proposal-onlyの経路も選べる。SBERT Adapterはcandidate、score、provenanceだけを返す。intent別thresholdとgateはDecision Policy Contextが唯一所有するversion付きPolicy dataである。純粋resolution Policyが候補なし、曖昧、競合、合成可能を明示Decisionにする。

承認済みの決定論的contributorは許可済みEffect Graph断片を作ってよい。camera calibrationはSBERT candidateとintent固有keyword gateが決定論的Policyに一致した場合、gray bandからLLM request/Proposalを作らずに完了しなければならないが、safety/capability Policy、Graph dependency、resource claimを迂回しない。LLM/Codex SkillsはProposalだけを返し、Policy前にState変更、Graph確定、dispatchをしない。

## Non-decision / open

具体的なintent集合、閾値、gate語彙、profileの選択規則、Provider routingは未決である。

## Consequences

SBERT、Python worker、LLM、ProviderはDecision Policy version、Interaction、Graph、profileを所有しない。routing fixtureはgray candidate+keyword gateによるcalibrationのLLM request/Proposalなしdirect path、候補なし、曖昧、競合、合成、拒否Proposal、rule-only、LLM-proposal-onlyを検証する。

## Related requirements

REQ-ARC-004、REQ-ARC-005、REQ-ARC-006。

## Superseded assumptions

凍結04のSBERT単独での状態変更、LLMを経ない固定順序、Agent所有のprovider/model状態はこのscopeでは採用しない。Y1はkeyword gateをscore band分類より前に適用し、middle候補をLLMへ送る。Y2はgray candidateをkeyword/rule gateで受理可能にする責任をDecision Policyへ明示し、LLMへ送るかはresolution Policyで決める。
