# アーキテクチャ要件

## 目的

閉じた世界の「状態と遷移」を、外部作用と不確実性を持つ現実世界へ拡張しながら、世界の法則を純粋・検証可能に保つ。外部能力を交換しても、Coreの意味と状態所有を変えない。

### REQ-ARC-001 — 純粋なドメイン判断

RuleとTransitionは決定論的でI/Oを含まない。RuleはStateとEventを評価し、TransitionはStateを変換する。どちらもデバイス、モデル、Clock、filesystem、networkを直接呼ばない。

受入条件:

- AC-ARC-001: 具体的Adapterを構築せずに、焦点を絞ったテストがRuleを評価しTransitionを適用できる。
- AC-ARC-002: 機械生成した依存グラフまたはarchitecture testが、domain package／crateからadapter、bootstrap、I/O実装、FFI、具体Providerへの依存経路が存在しないことを、実装言語に依存しない形で示す。

### REQ-ARC-002 — 単一のState所有者と汎用Kernel

各Stateには名前を持つ所有者が一つだけある。Kernelは汎用法則を接続し、デバイス固有、会話固有、Provider固有の知性を所有しない。

受入条件:

- AC-ARC-003: 導入されるState型ごとに、契約上ちょうど一つの所有Contextを記す。
- AC-ARC-004: 新しいAdapterがWorldStateを直接変更せずに結果Eventを返せる。
- AC-ARC-017: 全State型がownership registryへ一度だけ登録され、重複・未登録がなく、非所有moduleから変更用constructor／reducerへ到達できないことをarchitecture testが示す。他ContextはEventまたは読取viewだけを利用する。

### REQ-ARC-003 — 不変の仕事としてのEffectと結果Event

外部の仕事は不変で型付きのEffectで表す。AdapterはPortの背後でEffectを実行してよいが、型付き結果Eventまたは型付きFailureを返し、domain Stateを変更しない。

受入条件:

- AC-ARC-005: 試験用Effectがdispatch前に直列化可能、または値として比較可能である。
- AC-ARC-006: 成功、DefinitelyNotApplied、OutcomeUnknownの各経路が、互いに異なる結果データとしてKernelへ戻る。

### REQ-ARC-004 — ProposalはCommandではない

LLM、Codex、Skillを介した外部主体、その他外部能力のProposalはProposalとして戻り、Effect Graphを変更またはEffectをdispatchする前にPolicy検証を通る。Skill自体をProposalと同一視してはならない。

受入条件:

- AC-ARC-007: 未承認のProposed EffectがPolicyにより拒否される、またはdispatchされないまま残る。
- AC-ARC-008: 承認済みProposalが、そこから生じる許可済みEffectと別の値として表現される。

### REQ-ARC-005 — 意味候補の生成と解決を分離する

通常の意味routingでは、SBERT（文埋め込み）を最初のCandidate（意味候補）生成に用いる。SBERT AdapterはCandidate、score、provenance（出所）だけを返し、State変更、Graph確定、dispatchを行わない。gray band（閾値間の帯域）のCandidateは、受理前に動作候補固有の決定論的keyword／Rule gateを通す。動作候補ごとのthresholdとgateはDecision Policy Contextが唯一所有するversion付きPolicy dataとし、純粋なresolution Policyが候補なし、曖昧、競合、合成可能を区別する。

すべての概念を正式Intentへ集約する中央の意味所有者は置かない。ただし、Candidate種別、Capability advertisement（能力広告）、Proposal schema、Effect型を発見するcatalogは持ってよい。catalogは発見と型互換性を扱い、意味の正解、State、Decision Policyを所有しない。

受入条件:

- AC-ARC-009: gray bandのCandidateに対し、動作候補固有gateが受理するfixtureと拒否するfixtureが、異なる明示的resolution結果を返す。
- AC-ARC-010: 競合、曖昧、候補なし、合成可能の各fixtureがresolution Policyの異なる明示的結果を得る。

### REQ-ARC-008 — Contributor構成をCapability Policyで決める

機能は、SBERT、純粋Rule、LLMなど一つ以上のContributor（候補提供者）を、明示的なCapability Policyにより組み合わせる。通常のSBERT-first経路を全機能へ強いる滝型処理にはしない。rule-only、SBERT-only、LLM-proposal-only、複数Contributorの合成を選べなければならない。

受入条件:

- AC-ARC-013: 明示Capability Policyでrule-onlyまたはLLM-proposal-onlyに割り当てたfixtureが、SBERTの必須実行を要求しないことを示す。
- AC-ARC-018: 同じ要求を異なるversionのCapability Policyへ与えるfixtureが、宣言されたContributor構成だけを起動し、Kernelへの条件分岐追加を要求しない。

### REQ-ARC-009 — 信頼境界によりGraph生成権限を制限する

決定論的で承認済みのContributorは、Policyが許可したEffect Graph断片を作ってよい。LLM、Codex、またはSkillを介した信頼できない外部主体はProposalを返し、Policy検証前にState変更、Effect確定、Graph確定、dispatchを行ってはならない。Skill自体をProposal生成者に限定しない。

受入条件:

- AC-ARC-011: LLM Proposalを拒否するfixtureが、State変更、Effect確定、Graph変更、dispatchのいずれも生まないことを示す。
- AC-ARC-019: 承認済み決定論Contributorと信頼できない外部主体へ同等のGraph断片を提案させるfixtureが、前者だけを宣言権限の範囲で受理し、後者にはPolicy検証を要求する。
- AC-ARC-020: Skillの読取観測、決定論的能力、AI由来Proposalの三経路が、それぞれObservation、許可済みGraph断片、未承認Proposalとして区別される。
- AC-ARC-028: Owner standing delegation、inactive Skill asset、version付きSkillExecutionGrant、activation、runtime Effectのfixtureが、Authorization Policy Contextだけをgrant所有者として示し、SkillCreator/Skill/LLMがgrantまたはY2 Behavior catalogを直接変更しない。

### REQ-ARC-006 — 実効profileをdispatch時に固定する

profileは外側のschemaを中立に保つ。Effectをdispatchする時点で選んだimmutable（不変）な実効profileとversionを
Effect/pending recordへ記録し、その後の設定変更で書き換えない。profile、Adapter、Provider、Projection、workerは
domain Stateの所有者ではない。

受入条件:

- AC-ARC-012: profile更新後も、既にdispatchされたEffectが記録済みのprofile/versionを保持する。

### REQ-ARC-007 — SkillをAIとアプリの接続面として分離する

Skillは、人が使うアプリ、データ、能力をAIへ公開する接続面として表現する。Skill、Contributor、Proposal、Effect、Adapterを同一概念へ畳んではならない。アプリが所有する状態をYatagarasu Coreへ移さず、読出しは型付き観測境界、AI由来の書込み・行動はProposalとPolicy検証、承認済み外部作業はEffectとAdapter結果Eventを通す。Skillの追加はKernelへの製品固有分岐を要求してはならない。

受入条件:

- AC-ARC-014: 試験用Skillの読出しが、アプリ所有の状態をCoreへ移さず、型付き観測または参照として返る。
- AC-ARC-015: 試験用Skillを介したAIの書込み提案が、Policy承認前にState変更、Effect確定、dispatchのいずれも起こさない。
- AC-ARC-016: 同じSkill契約を別の試験用Adapterへ再bindingしても、Kernelとdomain Ruleを変更しない。

### REQ-ARC-010 — Qualia Contextは活動身份とLifecycleだけを所有する

Qualia Contextは、Home、Starting、Active、Terminating、RecoveringのLifecycleと、現在のqualia session、behavior identity／version、開始・終了理由、適用Policy／profile version、機能固有Stateへの型付き参照を唯一所有する。この参照は、所有Context名とsession／correlation identityだけから成る不変かつ不透明な値であり、State値、可変参照、reducer、dispatch handleを含めてはならない。文字起こし本文、監視対象、会話履歴、device状態、Effect Graph、Artifact本体などをQualia Stateへ集約してはならない。機能固有Stateは名前を持つ別Contextが唯一所有する。

受入条件:

- AC-ARC-021: ownership registryがQualia Stateと三つの代表Behavior固有Stateの所有者を別々に一度だけ記録し、Qualia Contextから各Behavior reducerへ到達できないことをarchitecture testが示す。
- AC-ARC-022: Home、Starting、Active、Terminating、Recovering間の許可Transitionをtable-driven pure testで評価できる。永続化された非Home phaseは同じsessionのRecoveringへ入り、明示checkpointによるResumeだけが同じsessionをActiveへ戻せる。Owner判断待ちはRecoveringを維持し、終了／資源隔離は責任移管後にTerminatingを経てHomeへ進む。どの経路も二つのqualia sessionを非Homeにできない。
- AC-ARC-023: Qualia Stateが機能固有本文、media、device内部状態、Effect Graphを値として所有せず、識別子、version、Lifecycle、理由、所有Context名とsession／correlation identityだけの不変・不透明な型付き参照で構成されること、およびその参照からBehavior reducerやdispatchへ到達できないことを契約試験が示す。

### REQ-ARC-011 — 振る舞いを各Layerへの明示的な寄与として追加する

Yatagarasu 2の振る舞い追加は正式なversion updateとして行い、実行時pluginまたはエンドユーザーコードとして読み込まない。一つの振る舞いを巨大なBehavior objectまたは機能ごとのTraitへ閉じ込めず、必要な場合だけ、識別情報、意味候補、Command／Event／State／Rule／Transition／Policy／Effect、Application contributor、Projection、Port、Adapter、Bootstrap binding、設定schema、Web部品、migration、testを各Layerへ寄与する。既存能力の組合せだけで作れる振る舞いは新しいPort Traitを要求しない。新しい外部能力の抽象境界が必要な場合だけPort Traitを追加する。

受入条件:

- AC-ARC-024: 既存のカメラ、Artifact、Web表示能力だけを組み合わせる試験Behaviorが、Kernel条件分岐、新しいPort Trait、既存State所有者の変更なしに、意味候補、Policy、Graph contributor、Projection、API操作として追加できる。
- AC-ARC-025: 新しい試験外部能力を必要とするBehaviorが、domainから具体製品へ依存せず、Port Trait、Adapter、Bootstrap binding、結果Eventを追加して同じBehavior契約へ適合する。
- AC-ARC-026: 新しいBehaviorの適合検査が、identity／version、必要Capability、入力・出力面、routing contribution、State ownership、termination、Recovery、API、Web表示、設定、migration、traceabilityのうち該当項目を列挙し、該当しないLayerへの装飾的変更を要求しない。
- AC-ARC-027: エンドユーザーのHTML／CSS変更がownership registry、routing catalog、Rule、Policy、Effect型、Port、Adapter、Bootstrap bindingを増減できない。

### REQ-PER-001 — Graphから導く順序

Effectの意味順序は命令的な主手順ではなく、Effect Graphのdependency edgeとguardで表す。resource claimはscheduler admissionと同時実行競合だけを表し、順序を定義してはならない。

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
