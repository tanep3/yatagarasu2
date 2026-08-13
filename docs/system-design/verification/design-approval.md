# Design Approval Aggregation Manifest

canonical contractの`accepted`を、審査対象のDesign ID、Version、canonical ref、definition hash、独立審査、Primary承認へ結び付けます。このManifestはglobal current system-design hashを承認単位にしません。

| Field | Value |
| --- | --- |
| Manifest version | `1` |
| Status | `active` |
| Aggregation | `append-only-content-addressed-approval-sets` |

| Approval set | Scope | Status | Design IDs Ref | Design IDs SHA-256 | Definitions Ref | Definitions SHA-256 | Architecture review Ref | Review SHA-256 | Primary approval Ref | Approval SHA-256 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| APR-PILOT-ABC-EE8F532A | Pilot A/B/C integrated change-set | accepted | docs/system-design/verification/approvals/SD-REV-PILOT-C-001-design-ids.txt | sha256:bb9634eedb025fe747e4e03829896861f8d2e94974431de2b5b5246d9cafd7b3 | docs/system-design/verification/approvals/SD-REV-PILOT-C-001-definitions.tsv | sha256:89c749815303b3aa6ca9e2bcf914dc36fa411c27fbb18f057ab84fb3cfea1fd9 | docs/system-design/verification/approvals/SD-ARCH-REVIEW-PILOTS-2026-08-13.md | sha256:47d2c87240afeec151860f3e35bfe847d6feb52c963c4e9a00887dc680cf329c | docs/system-design/verification/approvals/SD-OWNER-APPROVAL-PILOTS-2026-08-13.md | sha256:c9af5c289a9a7d566339cf02739785d04859ace6c557be3d3afca899bdb88674 |
| APR-WP01-ACOU-001-DF73500F | WP-01 Acoustic tranche TR-WP01-ACOU-001 | accepted | docs/system-design/verification/approvals/SD-REV-WP01-ACOU-001-design-ids.txt | sha256:3351545dc06c3c1691ca552d38bf8e4321e9a64eefeb1a7f53827b5d70553762 | docs/system-design/verification/approvals/SD-REV-WP01-ACOU-001-definitions.tsv | sha256:3d62d4eb76c736190bb34ae9a77237d2a0e2453d90009073eb699d771f0e7b7c | docs/system-design/verification/approvals/SD-ARCH-REVIEW-WP01-ACOU-001-2026-08-13.md | sha256:20a2bf72e6b0c466f4203db7f2f7adb731f3f0e3311d90ab39dd676d5aa6b366 | docs/system-design/verification/approvals/SD-OWNER-APPROVAL-WP01-ACOU-001-2026-08-13.md | sha256:3b86faf10199bc267486db97c1e63c8332efec13f652cc984287ff85e3be98a6 |
| APR-WP01-PER-GRAPH-001-11ADAE3D | WP-01 Persistence Graph tranche TR-WP01-PER-GRAPH-001 | accepted | docs/system-design/verification/approvals/SD-REV-WP01-PER-GRAPH-001-design-ids.txt | sha256:bca3f6c9bef36a79476c05b252c4a1cad3c3e3ff0a918dfad0abe66bb37c99f7 | docs/system-design/verification/approvals/SD-REV-WP01-PER-GRAPH-001-definitions.tsv | sha256:3f2efead185ffd4151771494bf6a9ead4d1304c859b176daefcda239603a9608 | docs/system-design/verification/approvals/SD-ARCH-REVIEW-WP01-PER-GRAPH-001-2026-08-14.md | sha256:7eac783bca0bda99a7ec6ea5a83e2bd23df2022216091f130356fd24ed68706e | docs/system-design/verification/approvals/SD-OWNER-APPROVAL-WP01-PER-GRAPH-001-2026-08-14.md | sha256:3182b3ae993b66d8089995e3833780e8139d79ce963afbea79afe6067b360615 |

## Aggregation rules

- `Approval set`はDesign IDs fileとDefinitions fileの実内容をこの順に連結してSHA-256したcombined content identityの先頭8桁を大文字化したsuffixを持つ。ID、Version、ref、definition hashのいずれを変えても別Approval setになる。
- 各Definitions Refは、Design ID、Version、canonical ref、definition block SHA-256を一行ずつ持つ。
- ReviewとPrimary Artifactは同じApproval set、Design IDs Ref/hash、Definitions Ref/hashを参照する。
- Definitions payloadは各ArtifactのreachableなSource commitから再生成でき、保存hashとcurrent canonical definitionの双方に一致しなければならない。
- review履歴の機械再現はSource commitがrepositoryからreachableであることを前提とする。commit欠落時は承認済みと推測せず、checkerがApproval setとcommitを明示して停止する。
- accepted trancheのReviewとPrimary Artifactは、同じ16列Obligation Review Ref/hashと、Tranche ID、Package ID exact set、親AC exact set、obligation semantic hash exact set、Approval set definitions exact setを一つのcontent-addressed Tranche Scope Refへ固定する。obligation reviewはreview Source commitとcurrentの双方から再生成一致を要求し、別trancheが無関係な既存Approval setを再利用することを禁止する。
- obligationが参照する全Design IDはそのtrancheのApproval set definitionsに含まれなければならない。integrated/common lawを同じreviewで固定できるよう余分なapproved definitionは許容するが、余分なdefinitionもApproval set identityとnon-driftの対象から外れない。
- 既存行、既存Artifact、既存Design ID file、既存Definitions fileへID／Versionを追加しない。後続trancheは新しいcontent-addressed行をappendする。
- HEADに存在する過去Approval setのManifest行と参照Artifactはbyte-for-byte不変とし、削除・置換をcheckerが拒否する。
- verification revisionはrootのmachine-readable TSVと`approvals/`直下のdefinition／obligation TSVも含み、承認入力の変更を検査revisionへ反映する。
- 同じDesign ID/versionを複数Approval setが参照してよいが、異なるdefinition hashを同じDesign ID/versionへ承認できない。
- 現在のauthorityに新しい`accepted` contractを加える場合、system-design FIXまでに少なくとも一つのaccepted Approval setがその現在のID/version/ref/hashを含まなければならない。
- `draft` contractはapproval coverage対象外であり、承認Artifactだけで`accepted`へ昇格しない。

Pilot checkerはPilot approval setのnon-driftだけを検査し、後続accepted contract追加でPilot承認を拡張しません。system-design FIX checkerは全accepted canonical definitionがManifestの和集合に含まれることを検査します。
