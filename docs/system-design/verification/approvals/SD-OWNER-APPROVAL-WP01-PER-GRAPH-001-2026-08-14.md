# WP-01 Persistence Graph Primary / Owner approval

| Field | Value |
| --- | --- |
| Artifact type | `primary-approval` |
| Tranche | `TR-WP01-PER-GRAPH-001` |
| Approval set | `APR-WP01-PER-GRAPH-001-11ADAE3D` |
| Change set | `SD-REV-WP01-PER-GRAPH-001` |
| Source commit | `751717f70a700492b0954b67e9a6bc2790e11e8f` |
| System design revision | `sha256:de71dc55c75143825d90b2e5a1d88deff554bf78e04f14e5e79565fa9a10f5e0` |
| Design IDs Ref | `docs/system-design/verification/approvals/SD-REV-WP01-PER-GRAPH-001-design-ids.txt` |
| Design IDs SHA-256 | `sha256:bca3f6c9bef36a79476c05b252c4a1cad3c3e3ff0a918dfad0abe66bb37c99f7` |
| Definitions Ref | `docs/system-design/verification/approvals/SD-REV-WP01-PER-GRAPH-001-definitions.tsv` |
| Definitions SHA-256 | `sha256:3f2efead185ffd4151771494bf6a9ead4d1304c859b176daefcda239603a9608` |
| Dependency Manifest Ref | `docs/system-design/verification/approvals/SD-REV-WP01-PER-GRAPH-001-dependencies.tsv` |
| Dependency Manifest SHA-256 | `sha256:3a92f0d7f979c1854c28be14aee7bff8720d88b7d49cbf4ae94c664a9a3fc1cd` |
| Obligation Review Ref | `docs/system-design/verification/approvals/SD-REV-WP01-PER-GRAPH-001-obligations.tsv` |
| Obligation Review SHA-256 | `sha256:2c0674806236964b1ed4850413312201356cf851a2c494ba58e9e89ae4225058` |
| Tranche ID | `TR-WP01-PER-GRAPH-001` |
| Tranche Package IDs | `WP-01` |
| Tranche Scope Ref | `docs/system-design/verification/approvals/TR-WP01-PER-GRAPH-001-scope.tsv` |
| Tranche Scope SHA-256 | `sha256:41ac97754503021dfe7c5289829e745c13a6c9b11f75c979bc34f9594971eed2` |
| Approval date | `2026-08-14` |
| Owner statement | `続けて下さい` |
| Owner instruction interpretation | `TR-WP01-PER-GRAPH-001をacceptedへ昇格し、次工程へ進む承認` |
| Primary approval | `accepted` |

Owner指示は、Architecture challengerのCritical 0／High 0 PASSと、minor correctionが修正済みCLOSEDとなった外部PASSを前提に、上記exact trancheをacceptedへ昇格して次工程へ進む承認として固定します。

Approval set内の新規62 R3 definitionsだけを`draft`から`accepted`へ昇格します。review closure内の既accepted 601 definitions、accepted V1/V2、Pilot、AcousticのApproval setとArtifactは変更しません。このApproval setへ後からID、AC、obligation、Versionを追加しません。

この承認はproduction code、実proof、Proof statusの`passing`、WP-01全体完了、system-design FIX、release、次trancheの設計着手を許可しません。次trancheは候補選定後、acceptance challenger PASSを得るまで設計を開始しません。
