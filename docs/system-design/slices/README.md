# 縦断設計

このディレクトリには、観測可能scenarioからproof designまでを縦に接続した設計sliceを置きます。

sliceはcanonical contractの定義場所ではありません。State、Command、Event、Effect、Graph、Port、Projectionの意味は[設計契約索引](../00-design-authority.md)が示す唯一の定義を参照します。

各sliceは次を記録します。

```text
対象Requirement / AC / Atomic Obligation
Initial snapshot
Inbound Command / Event
Expected Decision / Graph ID
Adapter result Event IDs
Final snapshot / Projection IDs
Failure / cancellation / recovery cases
Proof design
Change impact
Accounting status
Design status
Proof status
Evidence / blocker
```

例示時系列を中央workflow、固定dispatcher順、runtime descriptorへ昇格させません。

pilotとして次の三本を作成し、[Design Pilot Gate](../verification/pilot-gate.md)で
設計横展開の可否を判定します。実装・release証拠は
[Implementation / Evidence Gate](../verification/implementation-evidence-gate.md)で別に判定します。

- [01-camera-observation.md](01-camera-observation.md)
- [02-finite-conversation.md](02-finite-conversation.md)
- `03-configuration-capability.md`
