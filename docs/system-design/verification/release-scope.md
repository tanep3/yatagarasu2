# Release Scope（証拠取得前に固定する出荷範囲）

この文書は「何を試験し、何を出荷対象にするか」だけを固定します。Evidenceは含めません。

| Field | Value |
| --- | --- |
| Scope version | `unfixed` |
| Target release | `unfixed` |
| Requirements revision | `4df6fb1` |
| System design revision | `unfixed` |
| Verification revision | `unfixed` |
| Release source revision | `unfixed` |
| Status | `draft-not-runnable` |

| Obligation ID | Parent AC | Disposition | Scope Decision Ref | Decision SHA-256 | Scope Approval Ref | Approval SHA-256 | Profiles | Providers / Agent |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |

初期契約で許すDispositionは`required`と`excluded-by-owner`だけです。
`deferred-by-requirement`は、正本要件側に機械可読な`REQ/AC → future release`台帳ができるまで
使用禁止です。Owner承認だけで「要件上の延期」を名乗ることはできません。

`excluded-by-owner`は独立したScope DecisionとScope Approvalを必要とします。全行を設計義務台帳の
Obligation ID／Parent ACと一対一で照合します。
