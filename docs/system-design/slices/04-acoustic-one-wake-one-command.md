# WP-01 Acoustic — 一wake一命令と再生中Stop抑止

このsliceはREQ-ACOU-001のAC-ACOU-001〜007を、[Acoustic canonical contract](../contracts/acoustic-interaction.md)と既存Execution／Conversation契約へ接続するreview用の縦断索引です。canonical payload、owner、guardを再定義しません。要件基準はcommit `4df6fb1`、設計方法の依存はaccepted tranche `TR-PILOT-ABC`です。

## Problem framingとowner

Y1で観測した問題は、wake後promptの回り込み、pre-rollから最初の発話が落ちること、空session、遅延buffer／reconnect、実TTSの自己再入力です。source resetという処理順ではなく、Acoustic Contextの選択State、pure Rule、immutable Effect、typed result Eventとして表します。

| State／事実 | 唯一owner | 非owner |
| --- | --- | --- |
| wake acceptance、session、immutable pre-wake history、post-wake collection cursor/interval、retain subrange、guard、empty | SD-CTX-ACO-001 | source／TTS／STT Adapter、Kernel |
| 登録Stop語、Stop Policy version | SD-CTX-ACO-001 | audio Adapter、Execution |
| playback occurrence→canonical全文／Policy version binding | SD-CTX-EXE-001（SD-STA-EXE-002のInjectV1内） | Acoustic、Conversation、TTS Adapter |
| pre-Interaction Acoustic Graph／occurrence／lease／custody | SD-CTX-EXE-001（SD-STA-EXE-002） | Acoustic、Kernel、Adapter |
| raw bytes／ring buffer／connection | source Adapter operational state | Core Context |
| Interaction admission／cancel | SD-CTX-INT-001 | Acoustic、source worker |
| Conversation text／turn | SD-CTX-CNV-001 | Acoustic、Python worker |

## Commands、Events、Decision

- Inbound observations/result: SD-EVT-ACO-001〜006、009〜013。候補と外部結果でありCommandではない。
- Acoustic owner facts: SD-EVT-ACO-007、008、014。
- Outbound Commands: accepted commandだけSD-CMD-INT-002、voice HomeはSD-CMD-QLI-001、unsuppressed voice StopはSD-CMD-INT-001。
- Web Home／Cancel: Acousticを経由せず既存共通Commandへ入り、StopSuppressionPolicyの対象外。
- Pure Decisions: SD-RUL-ACO-001〜012。State mutationとI/Oを持たない。
- Transitions: SD-TRN-ACO-001〜008だけがAcoustic Stateを変更する。Execution／Interaction／Conversationを直接変更しない。

## Atomic Design Obligations

| Obligation ID | Parent AC | Joint group | Parent contribution | Canonical Design IDs | Proof type | Negative case | Target profile / scope | Accounting status | Design status | Proof status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| DO-ACO-001A | AC-ACOU-001 | JG-ACO-OWNER | full | SD-CTX-ACO-001, SD-STA-ACO-001, SD-TRN-ACO-001, SD-TRN-ACO-002, SD-TRN-ACO-003, SD-TRN-ACO-007, SD-TRN-ACO-008 | architecture/pure | owner重複、Adapter／KernelからState変更 | 共通Core | accounted-for | designed | planned |
| DO-ACO-001B | AC-ACOU-001 | JG-ACO-OWNER | full | SD-PRT-ACO-001, SD-PRT-ACO-002, SD-MOD-ACO-001, SD-MOD-ACO-003, SD-RUL-ACO-008, SD-RUL-ACO-011 | architecture/contract | raw buffer所有をhistory/post-wake collection判断所有へ昇格、両intervalを混同 | source境界 | accounted-for | designed | planned |
| DO-ACO-001C | AC-ACOU-001 | JG-ACO-EXECUTION-V2 | full | SD-MOD-EXE-004, SD-STA-EXE-002, SD-MOD-EXE-005, SD-RUL-EXE-008, SD-TRN-EXE-017, SD-PER-EXE-009, SD-PRJ-EXE-001, SD-PRF-EXE-001, SD-FAIL-EXE-001 | architecture/contract/crash-recovery | V1 complete recordのfield欠落、resume request/commit統合、revocation key drift、Graph内Occurrence複製owner、in-flight identity消失 | Execution V2 snapshot境界 | accounted-for | designed | planned |
| DO-ACO-002A | AC-ACOU-002 | JG-ACO-FIRST-SPEECH | full | SD-RUL-ACO-002, SD-RUL-ACO-008, SD-RUL-ACO-011, SD-RUL-ACO-012, SD-EVT-ACO-004, SD-EVT-ACO-011, SD-EFX-ACO-003, SD-EFX-ACO-004, SD-PRF-ACO-001 | pure/integration | historyをpost-wakeへ延長、prompt/guard全span discard、query issuer欠落、prompt failureでsession未終端 | 実profile | accounted-for | designed | planned |
| DO-ACO-002B | AC-ACOU-002 | JG-ACO-ONE-COMMAND | full | SD-RUL-ACO-003, SD-TRN-ACO-003, SD-GPH-ACO-001, SD-CMD-INT-002, SD-PER-ACO-001 | pure/concurrency/crash-recovery | 一wakeから二Submit、emptyなのにT生成、無音fixtureだけで合格 | 初期one-wake-one-command | accounted-for | designed | planned |
| DO-ACO-002C | AC-ACOU-002 | JG-ACO-GRAPH-EXTENSION | full | SD-MOD-ACO-002, SD-RUL-ACO-009, SD-RUL-ACO-012, SD-EVT-EXE-009, SD-RUL-EXE-007, SD-TRN-EXE-016, SD-PER-EXE-008, SD-GPH-ACO-001 | architecture/pure/concurrency | future cursor payload、prompt resultが複数/無分岐、Acoustic subject四field不一致でlease継続、typed close/custodyでCなし | Execution V2 Graph | accounted-for | designed | planned |
| DO-ACO-003A | AC-ACOU-003 | JG-ACO-DISCARD | full | SD-RUL-ACO-002, SD-RUL-ACO-003, SD-EVT-ACO-007, SD-FAIL-ACO-001 | pure/integration | empty／prompt／lateを成功commandまたは無記録にする | 共通 | accounted-for | designed | planned |
| DO-ACO-003B | AC-ACOU-003 | JG-ACO-RECONNECT | full | SD-EVT-ACO-002, SD-RUL-ACO-006, SD-TRN-ACO-005, SD-REC-ACO-001 | pure/crash-recovery | reconnectから新wake/session/Interactionを暗黙生成 | source reconnect | accounted-for | designed | planned |
| DO-ACO-004A | AC-ACOU-004 | JG-ACO-PROFILE | full | SD-POL-ACO-001, SD-STA-ACO-001, SD-EFX-ACO-001, SD-EVT-ACO-008, SD-RUL-ACO-007, SD-TRN-ACO-006 | architecture/contract/pure | pre-roll／guard数値やflush方式をCoreへ固定、途中version読替 | 実source profile | accounted-for | designed | planned |
| DO-ACO-004B | AC-ACOU-004 | JG-ACO-CORRELATION | full | SD-PRJ-ACO-001, SD-PRF-ACO-001, SD-EVT-ACO-007 | projection/real-device | wake、prompt、最初の発話、command、discardの相関欠落 | 実profile | accounted-for | designed | blocked-by-spike |
| DO-ACO-005A | AC-ACOU-005 | JG-ACO-REAL-AUDIO | full | SD-GPH-ACO-001, SD-RUL-ACO-002, SD-EFX-ACO-002, SD-EFX-ACO-004, SD-PRF-ACO-001 | integration/real-device | 「はい」をtranscriptへ混入、最初の発話欠落 | 実profile | accounted-for | designed | blocked-by-spike |
| DO-ACO-005B | AC-ACOU-005 | JG-ACO-SELF-AUDIO | full | SD-RUL-ACO-001, SD-RUL-ACO-004, SD-MOD-ACO-001, SD-POL-ACO-002 | pure/integration/real-device | 実TTS waveformから通常wake／Interaction／LLM、Home/Stop経路停止 | 実profile | accounted-for | designed | blocked-by-spike |
| DO-ACO-005C | AC-ACOU-005 | JG-ACO-EMPTY | full | SD-RUL-ACO-003, SD-TRN-ACO-003, SD-CMD-QLI-001, SD-PRJ-ACO-001 | pure/integration | 空命令からLLM/body Effect、通知をAcousticへ直結 | 共通 | accounted-for | designed | planned |
| DO-ACO-006A | AC-ACOU-006 | JG-ACO-STOP-POLICY | full | SD-POL-ACO-002, SD-RUL-ACO-004, SD-EVT-ACO-007 | pure | Stop語あり全文で利用者Stopだけ特別に通す | 全対応profile | accounted-for | designed | planned |
| DO-ACO-006B | AC-ACOU-006 | JG-ACO-STOP-CONTROL | full | SD-RUL-ACO-004, SD-POL-ACO-003, SD-EVT-ACO-014, SD-TRN-ACO-004, SD-PER-ACO-002, SD-CMD-INT-001, SD-CMD-QLI-001 | pure/integration/crash-recovery | replayで二Cancel、同ID異payload受理、比較不能を抑止と記録、Web Home/Cancel抑止 | 共通 | accounted-for | designed | planned |
| DO-ACO-006C | AC-ACOU-006 | JG-ACO-TC70-GATE | full | SD-PRF-ACO-001, SD-PRJ-ACO-001 | real-device/measurement/owner-gate | 実測またはOwner採否なしでTC70 release-ready | TC70初期release | accounted-for | designed | blocked-by-spike |
| DO-ACO-006D | AC-ACOU-006 | JG-ACO-C210-GATE | full | SD-PRF-ACO-001, SD-PRJ-ACO-001 | real-device/measurement/owner-gate | C210未達でTC70をblock、または証拠なしでC210対応主張 | C210対応profile | accounted-for | designed | blocked-by-spike |
| DO-ACO-007A | AC-ACOU-007 | JG-ACO-BINDING-OWNER | full | SD-CTX-ACO-001, SD-CTX-EXE-001, SD-STA-ACO-001, SD-STA-EXE-002, SD-MOD-ACO-001, SD-RUL-ACO-005, SD-EVT-ACO-008, SD-TRN-ACO-006, SD-PER-ACO-001 | architecture/pure | binding二重所有、dispatch後Policy/current全文読替 | Acoustic／Execution V2 | accounted-for | designed | planned |
| DO-ACO-007B | AC-ACOU-007 | JG-ACO-ADAPTER-RULE | full | SD-EVT-ACO-006, SD-RUL-ACO-004, SD-PRT-ACO-001, SD-PRT-ACO-003 | architecture/contract/pure | TTS/STT Adapterが抑止Decision／State所有 | audio境界 | accounted-for | designed | planned |
| DO-ACO-007C | AC-ACOU-007 | JG-ACO-RECOVERY | full | SD-STA-EXE-002, SD-PRF-EXE-001, SD-EFX-ACO-007, SD-EFX-ACO-008, SD-EFX-ACO-009, SD-EFX-ACO-010, SD-RUL-ACO-010, SD-TRN-ACO-008, SD-GPH-ACO-002, SD-REC-ACO-001 | concurrency/crash-recovery | 別generation targetへcancel/custody/lease release、V1 unknown/custodyの復旧field欠落、crash後blind retry、cancelを停止成功化、unknown lease解放 | 共通 | accounted-for | designed | planned |

## Effect Graphとresource claims

通常Graphはwake時initial O/P/deadlineだけを持ち、SD-RUL-ACO-009→SD-PER-EXE-008でG、T、C、Recoveryを確定factごとにatomic extensionします。`audio.input.session`はexact named interval fieldsでOからT/Cへ継続し、`audio.output`はPのexclusive resourceです。Home／Web CancelをGraph dependencyにしません。

## Failure、cancel、restart、late result

| Scenario | Expected result |
| --- | --- |
| wake duplicate／open session中wake | typed discard、第二sessionなし |
| pre-wake historyとpost-wake collection | historyはwake anchorでimmutable。collectionは別intervalとしてwake後に進み、historyを延長しない |
| prompt direct/query全result | RUL-ACO-012のSafe／Bypass／TypedClose／Custody exact一分岐。EVT-ACO-011もissuerになり、全分岐でP/input lease終端 |
| prompt spanとguard後の最初の実発話 | prompt/guard subrangeだけdiscard。guard後speechまたはguard-crossing suffixをretain |
| empty transcript | Empty Event、Home Command一件、LLM/body Effectなし |
| command commit後の遅延buffer | AfterCommandCommitted discard、Graph／Interaction再開なし |
| source reconnect | old epochを閉じ、SourceRecovered／Quarantine。新wakeなし |
| prompt OutcomeUnknown | 再再生せずquery/custody。prior safe startなしならG/Tを作らずCへ閉じる |
| source operation OutcomeUnknown | exact query一回、確定不能ならresource Quarantine |
| commit後outbox前crash | 同じstable Commandを再公開し二Interactionなし |
| duplicate result同payload／異payload | no-op／Conflict quarantine |
| voice candidate replay同payload／異payload | same processed Event/outbox replay／Conflict quarantine。二Cancelなし |
| clock-domain/profile比較不能 | exact overlapを主張せずtyped temporal unknown。normal wakeはfail-safe discard、voice Stopは推測Cancelなし |
| playback中Stop語あり | 実利用者Stopも含めSuppress。Web Home/Cancel・音声Homeは生存 |
| playback中Stop語なし | exact InteractionへCancel Command。TTS waveformは通常wakeにならない |
| playback binding欠落／version不一致 | typed invariant violation、推測抑止／Cancelなし、Web controlsは生存 |
| Home／Cancelとsource result race | owner revision winner一件、late resultは元session auditだけ |
| Execution V1→V2 migration crash | commit前V1Active／commit後V2Activeの一方だけ。in-flight identity、lease、custody、outboxを保持 |

## Proof designとapproval boundary

- deterministic: owner registry、Policy、wake/span/Stop Rule、Transition、duplicate、late、restart、Graph cycle/resource fixture。
- contract: source／prompt／boundary Adapterがresult Eventだけを返し、State reducerへ到達しない。
- real-device: prompt「はい」、first speech、self TTS、Stop語あり／なし、実利用者Stop、reconnect、late buffer。
- release gate: TC70 spike evidence＋Owner採否。C210は対応主張profileだけの独立gate。

このsliceは`TR-WP01-ACOU-001`のreview入力です。architecture challenge、Primary／Owner approval、accepted昇格、production implementation、実機passingを主張しません。

## Open questionsとnon-goals

設計を止める新しいOwner判断はありません。pre-roll／guardの数値、source方式、TC70/C210実測値と採否は既存のspike／release gateへ残します。continuous conversation、streaming TTS、process／IPC／storage決定、Y1環境へのY2混在は対象外です。
