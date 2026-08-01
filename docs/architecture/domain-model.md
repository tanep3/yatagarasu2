# ドメインモデル

## Coreの値

将来のCoreは、Command、Event、Effect、Failure、Stateにclosed enumと明示的なvalue typeを用いるべきです。以下の名前は契約を説明するもので、言語またはstorage配置を決めるものではありません。

| 値 | 意味 |
| --- | --- |
| Command | Policyが受理または拒否できる要求。 |
| Event | Adapter結果を含む、過去に起きた事実。 |
| State | 判断に用いる、Context所有のsnapshot。 |
| Rule | State viewとEventからDecisionまたは無判断を返す純粋関数。 |
| Transition | StateからStateへの決定論的変換。 |
| Effect | 依存関係とresource claimを持つ不変の外部作業。 |
| Failure | 解析済み診断文字列ではない、型付き外部Failureデータ。 |

WorldStateは外部データすべてを詰め込む袋ではありません。大きなaudio、image、model、transcriptは必要に応じて型付きartifactで参照します。各State部分は名前を持つContextが所有し、Adapter、Python worker、LLM Provider、Projectionは所有も直接変更もしません。

## Stateの所有者

| State | 唯一の所有者 | 所有しないもの |
| --- | --- | --- |
| wake acceptanceとprompt lifecycle | Acoustic Context | Yata Wake、Mimy、voice Adapter |
| Interaction lifecycleとcancel | Interaction Context | Web、voice、CLI Adapter、LLM |
| Decision Policy version | Decision Policy Context | SBERT、LLM、profile |
| Effect Graph、durable pending、revoked | Execution Context | dispatcher、Adapter、journal replay |
| physical observationとpose | Physical Observation Context | camera Adapter、calibration capability |
| artifact lifecycle | Artifact Context | TTS、capture、Provider、filesystem Adapter |
| notification policy | Notification Policy Context | channel Adapter、Projection |

ここでのContextはStateの可変所有者です。Adapter、profile、Projection、Python worker、外部Providerは値または結果Eventを扱うだけで、いずれの行も所有しません。

## DecisionとEffect Graph

```text
WorldState + Event
  -> pure Rule
  -> Decision(Transition, Effect Graph)
  -> committed WorldState'
```

Effect Graphのedgeは前提条件を、resource claimは相互排他を表します。たとえばcaptureが完了/時刻の事実に依存するならcamera movementがcaptureに先行しますが、独立したmemory lookupは並行できます。schedulerはclaimの下でGraph上readyな仕事を選び、camera、speech、conversationの主手順を持ちません。

`move -> capture -> LLM`はこのGraphの例です。moveが`Failure`または`OutcomeUnknown`ならcaptureとLLMはguard（条件）によりblockされる。captureのFailureもLLMをblockする。LLM入力は有効で適用可能な`ArtifactRef`だけであり、`Assumed`を越えるedgeは明示Policyの許可が必要です。camera PTZ、capture、LLM requestなどのresource claimは各Effectに残ります。通知は同じGraphから生じても、silent Policyでは通知Effectだけを作らず、内部EventやProjectionを消しません。

## PolicyとProposal

model、Codex tool call、外部workerは`ProposedEffect`を提示してよいものとします。これはデータであり、許可済みCommandではありません。Policyが拒否、確認要求、許可済みEffectへの変換を決めます。これにより、Proposalの出所にかかわらず同じ境界を守ります。

## Contributorとresolution

通常の意味routingはSBERT candidate生成を第一段とし、gray band候補をaccept前に決定論的keyword/rule filterへ通します。これは必須の滝型ではない。capability Policyが明示すれば、一つの機能はSBERT、純粋Rule、LLMなど複数のcontributorを用い、rule-onlyまたはLLM-proposal-onlyにもできます。単一のintent registry（意図登録簿）はありません。SBERT Adapterが返すのはcandidate、score、provenanceだけです。intent別threshold/gateはDecision Policy Contextが所有するversion付きPolicy dataであり、純粋resolution Policyは候補なし、曖昧、競合、合成可能を明示Decisionへ変換します。

承認済みの決定論的contributorは許可済みGraph断片を作れます。calibrationはSBERT candidateとintent固有keyword gateが決定論的Policyに一致した場合、gray bandからLLM request/Proposalなしに解決しなければならず、安全/capability PolicyとGraphを迂回しません。LLM/Codex SkillsはProposalだけを返し、Policyの前に変更・確定・dispatchをしません。

## Profile、取消、通知

中立な外側schemaから選んだeffective profile（実効profile）は、dispatch時に不変値とversionとしてEffect/pending recordへcaptureします。後のprofile更新は既dispatchの値を変えません。

取消は`CancelRequested`、Interactionの取消受理、durable revocation、in-flight取消結果、physical outcomeを別のEvent/Stateで表します。遅延Proposalはcancelled Interactionへ適用しません。通知のoperation、plan、channel、wording、silentはNotification Policy Contextが所有し、通知Adapterの試行は配達の推測でなく型付き結果Eventを返します。Projectionは外部配達の証拠ではありません。

## 時刻と物理的事実

時刻はClockPortを通じて導入します。Adapterが返しCoreが受理する`EffectExecutionStarted`は、Effectの実行を試行/開始したという型付き結果Eventです。物理的な適用または完了を確認するEventではありません。`ExpectedActionDuration`はこのEventの受理からeffect/device profileの単調durationを測り、margin後にAssumedのreadiness事実を生んでよいものです。queueで待っていた時間は含めず、`EffectExecutionStarted`がなければtimerベースのAssumed readinessは生みません。要求した移動、音、captureをObserved事実には変えません。結果の語彙は[永続化と不確実性](persistence-and-uncertainty.md)を参照してください。

relative motion request（相対移動要求）はposeと別の値です。証拠のないabsolute pose（絶対姿勢・位置）は作りません。calibrationは汎用capabilityであって、成功Eventも現在poseの証明ではありません。
