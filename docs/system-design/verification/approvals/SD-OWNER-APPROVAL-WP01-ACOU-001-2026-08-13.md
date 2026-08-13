# WP-01 Acoustic Primary / Owner approval

| Field | Value |
| --- | --- |
| Artifact type | `primary-approval` |
| Tranche | `TR-WP01-ACOU-001` |
| Approval set | `APR-WP01-ACOU-001-DF73500F` |
| Change set | `SD-REV-WP01-ACOU-001` |
| Source commit | `4126537ab4e220a0ce130431ebef1637ec5f414a` |
| System design revision | `sha256:b1f5f2708c71777cb7fc8ebb121fee210ecc5cbf9a2dc5748e1e1ec60d7d9080` |
| Design IDs Ref | `docs/system-design/verification/approvals/SD-REV-WP01-ACOU-001-design-ids.txt` |
| Design IDs SHA-256 | `sha256:3351545dc06c3c1691ca552d38bf8e4321e9a64eefeb1a7f53827b5d70553762` |
| Definitions Ref | `docs/system-design/verification/approvals/SD-REV-WP01-ACOU-001-definitions.tsv` |
| Definitions SHA-256 | `sha256:3d62d4eb76c736190bb34ae9a77237d2a0e2453d90009073eb699d771f0e7b7c` |
| Obligation Review Ref | `docs/system-design/verification/approvals/SD-REV-WP01-ACOU-001-obligations.tsv` |
| Obligation Review SHA-256 | `sha256:0b44b3a695e4e26d9748b6a35d7c9f55adda6ec157451ddf6ee462efc21b523a` |
| Tranche ID | `TR-WP01-ACOU-001` |
| Tranche Package IDs | `WP-01` |
| Tranche Scope Ref | `docs/system-design/verification/approvals/TR-WP01-ACOU-001-scope.tsv` |
| Tranche Scope SHA-256 | `sha256:8078495ee406a259fb3cb46d2047c75db0cac33d5ba507ab0ca2abe8b9fc9be4` |
| Approval date | `2026-08-13` |
| Owner statement | `Owner承認します。acceptedへ昇格し、次工程に進んで下さい。` |
| Primary approval | `accepted` |

Ownerは、独立architecture reviewをPASSした上記exact tranche definitionsを`accepted`へ昇格し、次工程へ進むことを承認しました。既accepted 4 definitionsは意味もlifecycleも変更せず、同じreview scopeで参照された新規82 definitionsだけを`draft`から`accepted`へ昇格します。このApproval setへ後からID、AC、obligation、Versionを追加しません。

この承認はproduction code、実機proof、Proof statusの`passing`、WP-01全体完了、system-design FIX、releaseを許可しません。WP-01は43 AC中の未完了ACを残すため`pilot-partial`を維持します。
