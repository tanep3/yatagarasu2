# ADR-008: 複数contributorとPolicy解決

- Status: Accepted
- Scope: 意味候補、SBERT、direct reflex、LLM/Codex Proposal

## Context

Y1のSBERT routerは、意味空間を使う反射が実機体験を大きく高速化することを示しました。一方、Y2はすべての概念を一つの正式Intent登録簿へ集約したり、SBERT→規則→LLMを必須の滝型処理へしたりしてはなりません。

## Decision

通常の意味routing機能はSBERT candidate生成を第一段とし、gray band候補をaccept前に決定論的keyword/rule filterへ渡す。これは普遍的な滝型処理ではない。明示capability Policyにより、機能はSBERT、純粋Rule、LLMなど一つ以上のcontributorを用い、rule-onlyまたはLLM-proposal-onlyの経路も選べる。SBERT Adapterはcandidate、score、provenanceだけを返す。動作候補ごとのthresholdとgateはDecision Policy Contextが唯一所有するversion付きPolicy dataである。これは中央の正式Intent登録簿ではない。純粋resolution Policyが候補なし、曖昧、競合、合成可能を明示Decisionにする。

承認済みの決定論的contributorは許可済みEffect Graph断片を作ってよい。camera calibrationはSBERT candidateと校正候補に固有のkeyword gateが決定論的Policyに一致した場合、gray bandからLLM request/Proposalを作らずに完了しなければならないが、safety/capability Policy、Graph dependency、resource claimを迂回しない。LLM、Codex、またはSkillを介した信頼できない外部主体はProposalを返し、Policy前にState変更、Graph確定、dispatchをしない。Skill自体はProposal生成者に限定されない。

## Non-decision / open

具体的な動作候補の集合、閾値、gate語彙、profileの選択規則は未決である。動的LLM／Provider選択の必須性はADR-011が定め、具体routing機構は同ADRの未決事項とする。

## Consequences

SBERT、Python worker、LLM、ProviderはDecision Policy version、Interaction、Graph、profileを所有しない。routing fixtureはgray Candidateとgate、候補なし、曖昧、競合、合成を検証する。Contributor構成、信頼境界、calibration反射は分割した要件で検証する。

## Related requirements

REQ-PRD-004、REQ-FR-004、REQ-ARC-004、REQ-ARC-005、REQ-ARC-006、REQ-ARC-008、REQ-ARC-009。

## Superseded assumptions

凍結04のSBERT単独での状態変更、LLMを経ない固定順序、Agent所有のprovider/model状態はこのscopeでは採用しない。Y1はkeyword gateをscore band分類より前に適用し、middle候補をLLMへ送る。Y2はgray candidateをkeyword/rule gateで受理可能にする責任をDecision Policyへ明示し、LLMへ送るかはresolution Policyで決める。
