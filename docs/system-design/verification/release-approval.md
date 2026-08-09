# Release Manifest Approval

このArtifactはRelease Manifest全体をOwner判断へ固定します。Manifest自身にはこの承認を
埋め込まないため、自己参照しません。

| Field | Value |
| --- | --- |
| Artifact type | `release-manifest-approval` |
| Manifest version | `unfixed` |
| Target release | `unfixed` |
| Scope version | `unfixed` |
| Scope SHA-256 | `unfixed` |
| Manifest SHA-256 | `unfixed` |
| Requirements revision | `unfixed` |
| System design revision | `unfixed` |
| Verification revision | `unfixed` |
| Release source revision | `unfixed` |
| Owner approval | `pending` |

ManifestのDisposition、Profile、Provider／Agent、Evidenceを変更するとManifest SHA-256が
変わり、この承認は無効になります。Gateは現在の設計・検査revisionとも完全照合します。
