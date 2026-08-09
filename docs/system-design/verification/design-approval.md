# Design Approval Manifest

canonical contractの`accepted`を、同じ設計内容に対する独立審査とPrimary承認へ結び付けます。
Pilot C完了後に三本を同一revisionで再審査するまで、このManifestは実行不能です。

| Field | Value |
| --- | --- |
| System design revision | `unfixed` |
| Status | `draft-not-runnable` |

| Pilot | Status | Design IDs Ref | Design IDs SHA-256 | Architecture review Ref | Review SHA-256 | Primary approval Ref | Approval SHA-256 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Pilot A | pending | — | — | — | — | — | — |
| Pilot B | pending | — | — | — | — | — | — |
| Pilot C | pending | — | — | — | — | — | — |

各Refは`verification/approvals/`配下のversion管理されたArtifactで、対象Pilot、現在の
System design revision、判定、未解決Critical／High件数を記録します。Primary承認Artifactも
同じrevisionを参照します。設計本体を変更するとrevisionが変わるため、古い承認は自動的に無効です。
各Artifactには`Artifact type`、`Pilot`、`System design revision`を型付きfieldとして持たせ、
Reviewは`Verdict=PASS`と`Unresolved Critical / High=0`、Primary側は
`Primary approval=accepted`を持たせます。各Pilotは審査対象Design ID一覧とそのhashを持ち、
Review／Primary Artifactも同じ一覧を参照します。三本の一覧の和集合をslice参照Design ID集合と
完全照合します。同じRefの複数Pilotへの再利用は禁止します。
