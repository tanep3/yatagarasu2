# Release Evidence Ledger（実装・証拠台帳）

出荷範囲の正本は[Release Scope](release-scope.md)です。この台帳は固定済みscopeへEvidenceを
接続するだけで、Disposition、Profile、Provider／Agentを変更できません。

| Field | Value |
| --- | --- |
| Manifest version | `unfixed` |
| Target release | `unfixed` |
| Scope version | `unfixed` |
| Scope SHA-256 | `unfixed` |
| Requirements revision | `4df6fb1` |
| System design revision | `unfixed` |
| Verification revision | `unfixed` |
| Release source revision | `unfixed` |
| Status | `draft-not-runnable` |

| Obligation ID | Parent AC | Disposition | Profiles | Providers / Agent | Evidence Ref | Evidence SHA-256 | Proof status |
| --- | --- | --- | --- | --- | --- | --- | --- |

`required`行だけProof=`passing`と型付きEvidenceを要求します。`excluded-by-owner`行は
Proof=`not-applicable`で、Evidenceを持ちません。全行の先頭5列をRelease Scopeと完全照合します。

Evidence Artifactは`Artifact type=implementation-evidence`、Obligation ID、Parent AC、
System design revision、Verification revision、Release source revision、Canonical Design IDs、Proof type、Execution revision、
Execution command / procedure、Hardware、Configuration snapshot、Profiles、Providers / Agent、
Result=passing、Result summaryを持ちます。slash区切りのProof typeごとに
`Proof <type> Artifact`と`Proof <type> SHA-256`を持ち、全typeをAND条件で検査します。

各Proof Artifactは空ファイルを禁止します。`real-device`は`real-device-result`として
Device profile、Test procedure、Observed result、Failure cases、Missing observationsを持ちます。
`measurement`は`measurement-result`としてHardware、Configuration snapshot、
正のSample count、Metrics、Missing samplesを持ちます。他のProof typeもそれぞれの型付きschemaを
満たし、一つの汎用Artifactで複数typeを代用しません。

全Proof Artifactは共通fieldとしてObligation ID、Parent AC、Release source revision、
Verification revision、Execution revision、Profiles、Providers / Agent、Execution command / procedureを持ち、
Evidence wrapperと完全一致させます。real-deviceのDevice profileはProfiles、Test procedureは
wrapperの手順と一致させます。measurementのHardwareとConfiguration snapshotもwrapperと一致させます。
