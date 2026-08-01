# ADR-002: プロダクト状態とY1の分離

- Status: Accepted
- Scope: 公開するproduct状態と環境分離

## Context

Yatagarasu 2の設計中もYatagarasu 1には運用上の価値があります。

## Decision

Yatagarasu 2は要件・設計段階であり、導入できるproductではありません。目・耳・口を持つAI robot体験とcognition-runtimeの志を持ちますが、完成したOSを主張しません。Yatagarasu 1は稼働を継続して分離し、未完成Y2 codeを本番robot環境へ入れません。

## Non-decision / open

release時期、対応hardware、価格、deployment機構は決めていません。

## Consequences

公開文書は段階を率直に示し、Y1の運用詳細をY2の約束として示しません。

## Related requirements

REQ-PRD-001, REQ-OPS-001。

## Superseded assumptions

凍結04の目標完成構成と`listend.service`によるrolloutは、現在のproduct約束ではありません。
