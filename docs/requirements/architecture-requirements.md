# アーキテクチャ要件

## 目的: 外部能力を交換可能にしながら、検証可能なドメインモデルを保つ

### REQ-ARC-001 — 純粋なドメイン判断

RuleとTransitionは決定論的でI/Oを含まない。RuleはStateとEventを評価し、TransitionはStateを変換する。どちらもデバイス、モデル、Clock、filesystem、networkを直接呼ばない。

受入条件:

- AC-ARC-001: 具体的Adapterを構築せずに、焦点を絞ったテストがRuleを評価しTransitionを適用できる。
- AC-ARC-002: 静的依存チェックにより、domainコードがadapter、bootstrap、network、filesystem、clock、具体Providerをimportしないことを示せる。

### REQ-ARC-002 — 単一のState所有者と汎用Kernel

各Stateには名前を持つ所有者が一つだけある。Kernelは汎用法則を接続し、デバイス固有、会話固有、Provider固有の知性を所有しない。

受入条件:

- AC-ARC-003: 導入されるState型ごとに、契約上ちょうど一つの所有Contextを記す。
- AC-ARC-004: 新しいAdapterがWorldStateを直接変更せずに結果Eventを返せる。

### REQ-ARC-003 — 不変の仕事としてのEffectと結果Event

外部の仕事は不変で型付きのEffectで表す。AdapterはPortの背後でEffectを実行してよいが、型付き結果Eventまたは型付きFailureを返し、domain Stateを変更しない。

受入条件:

- AC-ARC-005: 試験用Effectがdispatch前に直列化可能、または値として比較可能である。
- AC-ARC-006: 成功、DefinitelyNotApplied、OutcomeUnknownの各経路が、互いに異なる結果データとしてKernelへ戻る。

### REQ-ARC-004 — ProposalはCommandではない

LLM、Codex、その他外部能力のProposalはProposalとして戻り、Effect Graphを変更またはEffectをdispatchする前にPolicy検証を通る。

受入条件:

- AC-ARC-007: 未承認のProposed EffectがPolicyにより拒否される、またはdispatchされないまま残る。
- AC-ARC-008: 承認済みProposalが、そこから生じる許可済みEffectと別の値として表現される。

### REQ-ARC-005 — 複数の意味候補を純粋に解決する

通常の意味routing機能では、SBERT（文埋め込み）を最初のcandidate（候補）生成とし、gray band（閾値間の帯域）の候補は
accept（受理）前に決定論的なkeyword/rule filter（キーワード/規則による絞込み）を通す。これは全機能に強いる滝型処理ではない。
機能はSBERT、純粋Rule、LLMなど一つ以上のcontributor（候補提供者）を明示capability Policyにより任意に組み合わせてよく、
rule-onlyまたはLLM-proposal-onlyの経路も有効である。単一のintent registry（意図登録簿）は置かない。SBERT Adapterは候補、score、
provenance（出所）だけを返す。意図別thresholdとgateは、名前を持つDecision Policy所有者のversion付きPolicy dataとする。
純粋なresolution Policyが候補なし、曖昧、競合、合成可能を区別する。

決定論的で承認済みのcontributorは許可済みEffect Graph断片を作ってよい。LLMまたはCodex SkillsはProposalを
返すだけであり、Policy前にStateを変更、Effectをdispatch、Graphを確定してはならない。camera calibrationは、SBERT candidateと
intent固有keyword/rule gateが決定論的Policyに一致した場合、LLM request/Proposalを作らずに完了しなければならない。これはGraphと
安全・capability Policyを迂回しない。

受入条件:

- AC-ARC-009: gray bandのSBERT candidateをintent固有keyword gateが決定論的Policyにより受理するcamera calibration fixtureが、LLM request/Proposalを一切作らず、Policy承認済みGraph断片だけを作る。
- AC-ARC-010: 競合、曖昧、候補なし、合成可能の各fixtureがresolution Policyの異なる明示的結果を得る。
- AC-ARC-011: LLM Proposalを拒否するfixtureが、State変更もdispatchも生まないことを示す。
- AC-ARC-013: 明示capability Policyでrule-onlyまたはLLM-proposal-onlyに割り当てたfixtureが、SBERTの必須実行を要求しないことを示す。

### REQ-ARC-006 — 実効profileをdispatch時に固定する

profileは外側のschemaを中立に保つ。Effectをdispatchする時点で選んだimmutable（不変）な実効profileとversionを
Effect/pending recordへ記録し、その後の設定変更で書き換えない。profile、Adapter、Provider、Projection、workerは
domain Stateの所有者ではない。

受入条件:

- AC-ARC-012: profile更新後も、既にdispatchされたEffectが記録済みのprofile/versionを保持する。

### REQ-PER-001 — Graphから導く順序

Effectの順序は命令的な主手順ではなく、Effect Graphの依存関係とresource claimで表す。

受入条件:

- AC-PER-001: 依存するEffectが、宣言されたすべての依存先が完了する前にはreadyにならない。
- AC-PER-002: 競合するresource claimを持つEffectが同時にdispatch可能にならない。

### REQ-PHY-001 — 物理的不確実性を明示する

物理結果はObserved、Assumed、DefinitelyNotApplied、OutcomeUnknownで表す。証拠なしにAssumedをObservedへ昇格してはならない。

受入条件:

- AC-PHY-001: カメラまたは再生のテストが、Observed結果を設定せずAssumed結果を保てる。
- AC-PHY-002: Recoveryが、明示的なPolicyまたは照合手順なしにOutcomeUnknownの物理Effectを自動再試行しない。

### REQ-PHY-002 — 暫定WorkingTime

Adapterが返し、Coreが受理した型付き`EffectExecutionStarted` Eventを起点として、ExpectedActionDurationはeffect/device profileにある単調なDurationを測る。`EffectExecutionStarted`は実行の試行/開始を確認するだけであり、物理的な完了または適用を確認しない。Eventより前のqueue時間はDurationを消費しない。Eventがなければtimerに基づくAssumed readinessは起こらない。依存Effectが安全にreadyになりうる最も早い時点を定めてよいが、完了の観測ではない。校正、安全margin、start Event不達時のtimeout/Failure Policyは未決である。

受入条件:

- AC-PHY-003: ClockPortに従い、依存Effectが宣言したDurationとmarginが経過する前はnot-readyのままである。
- AC-PHY-004: Durationの経過が、観測済みデバイス完了ではなくAssumed timing resultを生む。
- AC-PHY-005: Effectがqueue中で`EffectExecutionStarted`を受理していない間は、ClockPortを進めてもExpectedActionDurationを消費しない。
- AC-PHY-006: `EffectExecutionStarted`がないfixtureは、timerに基づくAssumed readinessを生まない。

### REQ-PHY-003 — 要求移動、姿勢、校正を分離する

相対移動の要求は、観測済みまたは推定済みのpose（姿勢・位置）と別の値である。証拠のない絶対poseを記録してはならない。
calibration（校正）は汎用capabilityであり、Adapter固有の結果Eventを返すが、現在のposeを証明しない。Assumedの後続Effectは、
明示されたPolicyが許す場合だけreadyになれる。

受入条件:

- AC-PHY-007: 相対移動要求の結果が、根拠なしの絶対poseを作らない。
- AC-PHY-008: calibration成功fixtureが現在poseのObserved事実を作らない。
- AC-PHY-009: Assumed結果を前提とするGraph edgeが、許可Policyなしではreadyにならない。
