# 設計思想

## 構造がシステムを説明する

Yatagarasu 2は時系列のスクリプトではなく、発見したdomainから再構築します。有用な問いは「次にどのcomponentが動くか」ではありません。「どのStateが存在し、どの事実が起き、どのRuleが適用でき、どのTransitionが許可され、どの外部の仕事を要求するか」です。

この文書の文章は新たに書いたものです。2026-08-01のhandoverで提供され、読んだTane Channel Technology著『オブジェクト指向はなぜ挫折するのか』およびTane Channel Technology著*soukoban*から、利用者が許可した範囲で考え方を蒸留しています。原文は複製していません。ここおよびADRに記すプロジェクト規則は、両著作物の引用や内容についての主張ではありません。

## 法則

- Stateの所有者はちょうど一つであり、Contextは他者のStateへの可変アクセスではなく事実を交換する。
- Ruleは純粋な評価であり、Transitionは決定論的な変換である。
- Effectは外部の仕事を表す不変値である。Adapterは結果Eventを返し、WorldStateを変更しない。
- Kernelは法則を接続する。device、conversation、Provider固有の知性を持ち込まない。
- domain境界は設計判断であり、process境界は配備判断である。
- abstractionは正確性、latency、診断、Recovery、置換可能性、使いやすさのいずれかを改善しなければならない。装飾的abstractionは採用しない。

## Few-shot例（規範ではない）

以下は書き方を伝えるための例です。実行可能なscenario形式や、既存のtest harnessを主張するものではありません。

### 悪い例: 命令的な主手順

```text
if request == "look right":
  camera.move_right()
  sleep(1)
  image = camera.capture()
  answer = provider.ask(image)
  speaker.play(answer)
```

この一つの手順に、順序、Failure、resource競合、不確実性が隠れます。

### 良い例: 値とGraphのedge

```text
Event: InteractionAccepted
Rule: view request -> Decision
Transition: record requested direction
Effects: MoveCamera, WaitForExpectedActionDuration, CaptureImage, AskAgent, PlaySpeech
Graph: MoveCamera -> wait -> CaptureImage -> AskAgent -> PlaySpeech
Claims: camera.ptz, camera.capture, audio.output
```

Graphはなぜ仕事が待機するかを記録し、Adapterはreadyになった各Effectを結果Eventへ変えます。

### 不適用: 人為的なGraph化

```text
Rule: configuration value is invalid -> reject Command with InvalidRequest
```

ここには物理的な仕事も順序もありません。一つだけのEffect Graphを足すのは装飾的abstractionであり、純粋なvalidation Decisionで十分です。

## 将来の実行可能scenario形式

将来、検証可能な例は少なくとも次を持つ形式で記述します。

```text
Scenario ID
Initial snapshot
Inbound Command/Event
Expected Decisions / Effect Graph
Adapter result Events
Final snapshot / Projection
```

この形式のリンクは、実装とテストが存在した時点でtested codeへ向けます。現時点で、そのharnessまたはtest済みscenarioが存在するとは主張しません。
