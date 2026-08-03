# ADR-015: 振る舞いを正式version updateで拡張する

- Status: Accepted
- Scope: Yatagarasu 2の機能追加単位、Layer寄与、エンドユーザー拡張範囲

## Context

Yatagarasu 2は会話BOTに閉じず、文字起こし、同時通訳、見守り、Web完結機能、将来の複眼や身体を追加できる必要がある。一方、Yatagarasu 2でエンドユーザー向けplugin言語や安全な任意コード実行環境まで提供すると、権限、State所有、Recovery、migration、互換性が別製品規模になる。機能ごとに巨大なBehavior classやTraitを追加する方式も、既存の構造分離を壊す。

## Decision

Yatagarasu 2のBehavior追加は、Rust／Python／Web資産を含み得る正式なversion updateとして行う。Y2 Behaviorはdomain/application/ports/adaptersへ寄与するrobot機能である。実行時pluginとエンドユーザーによるY2 Behavior追加は範囲外とし、必要ならYatagarasu 3で検討する。

振る舞いは一つの万能objectではなく、必要なLayerへの明示的な寄与として追加する。寄与候補はidentity／version、必要Capability、入力・出力面、SBERT Candidateとgate、Command／Event／State／Rule／Transition／Policy／Effect、Application contributor、Projection、Port、Adapter、Bootstrap binding、設定schema、Web部品、migration、test、traceabilityである。

既存能力の組合せだけなら新しいPort Traitを追加しない。新しい外部能力の抽象境界が必要な場合だけPort TraitとAdapterを追加する。KernelへBehavior名の中央条件分岐を追加しない。State所有者は追加後も一つであり、transport schemaをdomain型にしない。

## Consequences

機能追加は通常の製品設計、review、test、Upgradeとして扱われる。Codex SkillはCodexの作業能力またはアプリ/AI接続面であり、Y2 Behaviorとは別である。Codexが自身の権限で`SKILL.md`、Python、Web、scriptを作ることにY2は追加の承認・制限層を加えない。ただし、その外部資産は正式version updateなしにBehavior catalog、ownership registry、Rule、Policy、Effect、Portを変更しない。公開APIを使う外部clientは作成できるが、Yatagarasu内部へ新しい信頼済み振る舞いを注入しない。

## Non-decision / open

将来の宣言的macro、外部automation、Yatagarasu 3のplugin model、Behavior descriptorの具体schema、code organization、compile-time registration方式は未決である。

## Related requirements

REQ-PRD-005、REQ-ARC-002、REQ-ARC-011、REQ-API-001、REQ-API-003、REQ-CFG-002、REQ-CFG-003。
