# ADR-018: EffectOccurrence、意味順序、profile settle、冪等性

- Status: Accepted
- Scope: Effect Graph identity/order、timing、API/Recovery冪等性

## Context

Effect値だけを仕事identityにすると、同じ内容を二回再生・撮影する必要がある場合に結果を誤相関する。生成順や中央の手順で順序を決めると、Graphの並行性と根拠が失われる。API重送と再起動復旧は同じ重複ではない。

## Decision

Graph頂点は一意な`EffectOccurrence` identityを持つ。同じEffect値の複数出現は別Occurrenceであり、別の結果Event/監査記録を持つ。意味順序はdependency edgeとguardだけで定義する。resource claimはscheduler admissionと同時実行競合だけを表し、順序を定義しない。

dispatch時にeffective profile/versionとprofileのsettle条件をOccurrenceへ固定する。settleは`EffectExecutionStarted`後にのみAssumed進行条件を満たせる時間条件であり、Observed完了の証拠ではない。API request冪等性と、recovery時のOccurrence照合/再dispatch冪等性は別key・別Policyで表す。

`right -> settle -> left`と`right -> settle -> right`は、それぞれのmoveを別Occurrenceとして表す。captureとinterpret/recallが必要なら、意味edgeは`move -> settle -> capture -> interpret/recall`とする。resource claimは競合防止であって順序を代用しない。

## Consequences

具体key形式、outbox、database、settle数値、reconciliationは未決である。AdapterはOccurrenceの結果Eventを返すだけで、Graph/WorldStateを変更しない。

## Related requirements

REQ-EFX-001、REQ-PER-001、REQ-PHY-002、REQ-OPS-003。
