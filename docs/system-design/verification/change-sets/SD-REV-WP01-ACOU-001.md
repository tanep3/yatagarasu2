# SD-REV-WP01-ACOU-001 — WP-01 Acoustic review candidate

このArtifactは、全214 AC横展開の最初の通常trancheとして、REQ-ACOU-001のAC-ACOU-001〜007をarchitecture challengeへ渡す変更集合とapproval入力を固定します。review verdict、Primary／Owner approval、accepted昇格、production implementation、実機proofは記録しません。

## Candidate identity

- lifecycle: `review-pending`
- tranche: `TR-WP01-ACOU-001`
- package: `WP-01`
- dependency: `TR-PILOT-ABC`
- requirement baseline: `4df6fb1`
- accepted method basis: `8b1bf9807e3f191339c98aefa2ed500fc3f0bdd5`
- candidate system-design revision: `sha256:96bc4444f05e47514c62be8b1107e23e396b3e97626e3fbe2d86c8e3820d806f`
- review source commit: `unbound — reviewer must bind a committed source revision`
- approval set: `unassigned — content-address after review source is bound`
- contract write authority: `one WP-01 Acoustic write owner; overlapping writers prohibited`
- parent AC count: `7 / 12`
- atomic obligation count: `20 / 30`

## Content-addressed review inputs

| Input | Ref | SHA-256 | Meaning |
| --- | --- | --- | --- |
| Design IDs | `docs/system-design/verification/approvals/SD-REV-WP01-ACOU-001-design-ids.txt` | `sha256:15b47c6c124161fa0ea80eb9cee947fbb0c5d8248f3c08304f59057e3052a1be` | 78 new draft definitions plus 4 reused accepted definitions |
| Definitions | `docs/system-design/verification/approvals/SD-REV-WP01-ACOU-001-definitions.tsv` | `sha256:564951be78f18189a6dda1fcc4f1cf14b750661229f19084b79acb1885e05ef5` | version、canonical ref、definition meaning hash |
| Obligation review | `docs/system-design/verification/approvals/SD-REV-WP01-ACOU-001-obligations.tsv` | `sha256:ae54a3440db3ff3a168b4063b003134e58479b88472e70daa03d5448cc8278f9` | 20行、16 semantic columns |
| Tranche scope | `docs/system-design/verification/approvals/TR-WP01-ACOU-001-scope.tsv` | `sha256:af3922deae9850b84217be9eaaa5395e479273e54900e6b09b1c1333be17e279` | exact WP-01／7 AC／20 DO／82 definitions |

これらはcandidate WORKTREEから生成したreview inputであり、Accepted Approval Artifactではありません。architecture reviewはcommit済みsourceから全4入力を再生成し、一致した場合だけreview verdictを記録します。Primary／Owner approvalはarchitecture PASS後に別Artifactとして作り、Design Approval Manifestへappendします。

## Problem framing

Y1のprompt回り込み、最初の発話欠落、空session、遅延buffer、再接続、実TTS自己入力を、source resetや中央listen loopではなくAcoustic Stateとpure Decisionへ移します。外部仕事はEffect Graphへ、Failure／OutcomeUnknownはresult EventとRecovery custodyへ残します。

## Affected contexts and owners

- Acoustic Contextだけがwake acceptance、session、immutable pre-wake history、別のpost-wake collection interval、retain/discard subrange、guard、empty、Stop terms／Policy versionsを所有します。
- Execution Contextだけがexact speech playback occurrence→canonical全文／Policy version bindingとpre-Interaction Acoustic Graphをversioned `ExecutionStateV2`に所有します。mutable V1/V2 Stateを並立させません。
- Interaction／Qualia／Conversationの既存ownerとHome／Web Cancel境界は変更しません。
- source／TTS／STT Adapterはraw buffer／connectionまたは外部operationだけを所有し、candidate／result Eventを返します。

## Proposed domain contract

- canonical contract: `contracts/acoustic-interaction.md`
- versioned Execution extension: `contracts/execution-acoustic-v2.md`
- acceptance slice: `slices/04-acoustic-one-wake-one-command.md`
- new draft definitions: 78（Acoustic contract 64、Execution V2 contract 14）
- reused accepted definitions: `SD-CMD-INT-001`, `SD-CMD-INT-002`, `SD-CMD-QLI-001`, `SD-CTX-EXE-001`

Commandは受理後の依頼、Eventは候補／観測／結果／owner factです。Adapter候補を直接Commandにせず、pure RuleのStop／wake／empty DecisionとAcoustic Transitionを通します。Kernelはpayload意味、device、Conversation、Providerを判断しません。

## Effect Graph

`SD-GPH-ACO-001`はwake時に確定payloadだけのO/P/deadlineを登録し、safe prompt boundary、retained selection、terminal owner factの後にpure contribution Ruleとatomic Execution V2 extensionでG/T/Cを追加します。empty branchにはTがありません。exact named lease fieldsとtyped guard issuerが因果を表します。`SD-GPH-ACO-002`はOutcomeUnknown operationへの一回限りquery/cancel、deadline、quarantineだけを持ち、元操作をblind retryしません。

## Failure and recovery

empty、discard、Failure、OutcomeUnknown、source recoveredを別variantに保ちます。O/G/P/T/C、query/cancelにbounded deadlineを持たせ、success/failure/timeout/cancel/unknown/crash/late/duplicateのwinnerとlease release/quarantineを明示します。voice control processed ledger、suppression audit、outboxは一つのUoWで、same replayとfingerprint conflictを分けます。

## Implementation boundaries

Coreの追加対象は型、pure Rule／Transition、Graph／Policy／Projection契約です。Applicationはdurable UoW／outboxとPortを接続し、Adapterはsource、prompt、boundaryの外部表現をresult Eventへ翻訳し、Bootstrapだけが具体bindingを組みます。production code、crate、process、IPC、storage、source製品はこのtrancheで決めません。

Compatibility impactはExecution schema V1→V2のoffline atomic snapshot migrationです。全V1 accepted complete recordをclosed `InjectV1*` variantへlosslessに写し、pending outbox/inbox、attempt、lease、custody、Guard、Graph topology、identityを保持します。resume request／commitは別map／別wrapperのまま、revocationは`RevocationId` canonical keyと元V1 target keyを同時に保持します。active／terminal／revoked／unknown／custody／resume fixtureはV1→V2→V1の全field／key round-tripを検証します。V2 activation後はV1 mutable runtimeへdowngradeせず、V1 AdapterへAcoustic variantを送信しません。この変更definitionはPilot approvalを流用せず本trancheの82-definition review inputに含めます。

ExecutionStateV2の全top-level mapはGraphRecordV2、OccurrenceRecordV2、DispatchAttemptV2、ResourceLeaseV2、RecoveryCustodyRecordV2、GuardFactRecordV2、CheckpointResumeRequestRecordV2、ExecutionResumeCommitRecordV2、RevocationRecordV2、V1CompatibilityRecord、AcousticGraphExtensionRecordのclosed concrete typeだけを格納します。Occurrenceのmutable canonical storeはtop-level一箇所だけで、Native Graph／extensionはIDs、topology、immutable declaration／commit factに限定します。AcousticSessionSubjectはsession ID、wake event ID、source epoch、generationの四field identityであり、Graph／Occurrence／lease／revocation／custody／extensionを部分一致で接続しません。V1 compatibility projectionはAcoustic recordをV1 recordへ部分投影しません。

## Testable acceptance criteria

1. 7 parent ACが20 DOへ完全分解され、各DOはWP-01／`TR-WP01-ACOU-001`へexact-one assignmentを持つ。
2. Acoustic ownerとExecution playback binding ownerが一意で、Adapter／Kernel／Python workerからState mutationへ到達しない。
3. pre-wake historyをwake anchorでimmutableに閉じ、別のpost-wake collection intervalからprompt/guard subrangeだけを除外し、guard後first speechまたはguard-crossing suffixを保持する。
4. prompt direct/query/cancel resultはSafe／Bypass／TypedClose／Custodyのexact一分岐となり、EVT-ACO-011 issuer、P output lease、input session close/quarantineまで終端する。
5. Stop語あり全文では実利用者Stopも抑止し、なしではvoice StopをCancellationへ渡す。Web Home／Cancelとvoice Homeは常に生存する。
6. speech bindingはexact occurrence、canonical全文、Stop Policy／normalization versionsをdispatch前にpinし、current versionへ読み替えない。
7. TC70実測＋Owner採否とC210独立profile gateはProofへ残り、Designをblockedにせずpassing／release-readyを主張しない。
8. accepted V1定義を変更せず、Execution V2のclosed concrete records、四field Acoustic identity、complete-record InjectV1 migration、resume分離、RevocationId／元target key、全field round-trip、whole-record compatibility rejection、downgrade blockをこのtranche approval setだけに含める。
9. review-pendingでもdefinitions／obligations／scopeのhash、source/current再生成、obligation→definition closureを`check-ac-expansion.sh`が検証し、approvalを意味しない。
10. review-pendingで通る全artifact checkがPASSし、system-design FIX検査だけは未accepted／未coveredを理由にFAILする。

## Architecture challenge inputs

Reviewerは少なくとも次を反証します。

- normal wake overlap discardがAdapterの「自己音声」断定に依存していないか。
- prompt OutcomeUnknownでもfirst speechを不当に常時discardする隠れ手順がないか。
- active playback binding欠落時のtyped invariant violationがWeb controlを閉じないか。
- source reconnect、outbox crash、duplicate／late resultから第二session／Interactionが作れる経路がないか。
- `SpeechAcousticBindingView`がExecution Stateの複製ownerになっていないか。
- Effect Graphがacyclicで、prompt successをtranscriptionの誤guardにしていないか。
- wake時Graphにfuture span/cursor payloadがなく、pure contributionとAcoustic/Execution atomic commitがconstructibleか。
- Execution V2 migrationがV1 in-flight identity/outbox/lease/custodyをlosslessに保持し、Acoustic variantをV1 Adapterへ漏らさないか。
- V1 active／terminal／revoked／unknown／custody／resume fixtureが全field／keyをround-tripし、GraphがOccurrence lifecycleの第二ownerになっていないか。
- Voice Control ledgerがsame replayを一度だけ再公開し、異fingerprint conflictとsuppression auditをdurableに残すか。
- TC70／C210、source、transport、raw buffer、clockがCore型またはKernel分岐へ漏れていないか。
- cancel／HomeとOutcomeUnknown resource custodyが外部停止を捏造していないか。

Critical／Highが一件でも残る場合は`challenge-pending`へ進めずcandidateを改訂します。PASS、reviewer identity、source commit、reviewed system-design revisionは別architecture-review Artifactだけに記録します。

## Owner approval inputs

既存Accepted判断を変更しません。Ownerへ後続承認時に提示する事実は次です。

- 実TTS回答全文に登録Stop語があれば、実利用者Stopも抑止され得る既存の意図的制約。
- TC70は実測＋Owner採否前に初期release不可。現時点の採否は未決。
- C210は対応を主張するprofileだけが独立gateを満たし、未達はTC70をblockしない。
- pre-roll／guard数値、flush／reconnect方式は未決で、profile spike後に固定する。

このcandidateから生じた新規Owner decision requestは0件です。architecture PASS後も、Primary／Ownerの明示承認なしにdraftをacceptedへ昇格しません。

## Open questions and explicit non-goals

open questionsは実測profile値、TC70採否、C210対応profile採否だけで、いずれもDesign contractを停止しません。continuous conversation、streaming TTS、production implementation、実機proof生成、数値／採否の代行、Y1環境へのY2混在、commit作成はnon-goalです。
