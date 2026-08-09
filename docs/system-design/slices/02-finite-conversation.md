# Pilot B — 有限Conversation・外部Thread・SemanticMemory

このsliceは[canonical contract](../contracts/finite-conversation.md)を観測可能な因果列へ接続します。型、owner、guardを再定義しません。

## 対象scenario

Homeで有効なBehavior候補がなく、`FallbackToConversation`がPolicy拒否ではない形で決定された地点から開始します。

```text
Initial snapshot
  Home
  no current non-Home Qualia
  authenticated raw input event recorded
  no Interaction admission decision committed yet
  Conversation/Memory/Agent route configuration snapshot available

Inbound
  SD-CMD-INT-002 -> SD-RUL-INT-001
  accepted decision only -> SD-CMD-CNV-001

Atomic open
  SD-RUL-INT-001
  SD-TRN-QLI-001 + SD-TRN-INT-001 + SD-TRN-CNV-001
  SD-GPH-CNV-001 registration
  committed by SD-PER-CNV-001

Memory and Agent
  SD-RUL-MEM-001 -> SD-EFX-MEM-001 -> SD-EVT-MEM-001
  SD-RUL-MEM-002 / SD-RUL-MEM-003 fix selection
  SD-RUL-AGT-001 fixes exact continuity and SD-STA-AGT-001 binding
  SD-EFX-AGT-001 or SD-EFX-AGT-002
  SD-EVT-AGT-001 / SD-EVT-AGT-002

Explicit Recall
  SD-CMD-INT-002 -> SD-RUL-INT-001
  accepted -> Qualia/Interaction atomic open
  -> SD-CMD-MEM-004 -> SD-GPH-MEM-001
  failure/empty -> deterministic Presentation without Agent
  selected records -> purpose-bound Agent proposal with provenance

Final response and Home
  SD-RUL-AGT-002 -> SD-EVT-CNV-002
  SD-EFX-OUT-001 + SD-EFX-MEM-002 + optional SD-EFX-AUD-001
  SD-RUL-CNV-002 -> SD-TRN-CNV-003 -> SD-TRN-QLI-001

Final snapshot
  Conversation retains original utterance and accepted final response
  Memory retains save/delete state and provenance
  Agent Session retains opaque binding, not Thread body
  Qualia is Home after terminal/handoff guards
```

## Owner決定済みPolicy

- 通常ConversationのSemanticMemory取得Failureは、別保存先へfallbackせず`ContinueNormalConversationWithoutMemory`として同じInteractionを継続する。
- 明示Recallの取得FailureはAgentへ渡さず、Yatagarasuが決定論的`RecallUnavailable`をpublishする。
- 明示Thread resetは、旧in-flight turnへ取消要求を作り、取消完了を待たずdurable Recoveryへ引き渡した後にbarrierをcommitし、新Threadを開始する。
- Thread resetはSemanticMemoryとConversation履歴を削除しない。通常HomeではThread resetしない。

## Atomic Design Obligation

| Obligation | Parent AC | Joint group | Parent contribution | Design contracts | Proof | Negative case | Scope | Accounting | Design | Proof status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| DO-CNV-001 | AC-CNV-001 | JG-CNV-E2E | full | SD-GPH-CNV-001, SD-RUL-CNV-002, SD-PRJ-CNV-001 | integration | 複数入力、Presentation重複、Home未復帰 | 初期有限会話 | accounted-for | designed | planned |
| DO-CNV-002 | AC-CNV-002 | JG-CNV-ADMISSION | full | SD-RUL-INT-001 | pure | Policy拒否をfallback | 共通 | accounted-for | designed | planned |
| DO-CNV-003 | AC-CNV-003 | JG-CNV-ISOLATION | full | SD-STA-CNV-001, SD-STA-AGT-001, SD-GPH-CNV-001 | integration | 次Interactionが旧Graph/cancelを再利用 | 共通 | accounted-for | designed | planned |
| DO-CNV-004A | AC-CNV-004 | JG-CNV-TERMINAL | full | SD-RUL-CNV-002, SD-EFX-OUT-001, SD-EFX-MEM-002 | pure/integration | publish/save前Home | 初期有限会話 | accounted-for | designed | planned |
| DO-CNV-004B | AC-CNV-004 | JG-CNV-TERMINAL | full | SD-EFX-AUD-001, SD-REC-CNV-001 | integration | heard完了待ち、OutcomeUnknown放置 | 初期音声 | accounted-for | designed | planned |
| DO-MEM-001 | AC-MEM-001 | JG-CNV-OWNER | full | SD-CTX-CNV-001, SD-CTX-MEM-001, SD-CTX-AGT-001 | architecture | 外部AdapterがState変更 | 共通 | accounted-for | designed | planned |
| DO-MEM-002A | AC-MEM-002 | JG-CNV-SAVE | full | SD-RUL-CNV-001, SD-EFX-MEM-002, SD-STA-MEM-001 | pure/integration | raw Proposal/reflex保存 | 共通 | accounted-for | designed | planned |
| DO-MEM-002B | AC-MEM-002 | JG-CNV-SAVE | full | SD-EFX-MEM-003, SD-TRN-MEM-003, SD-TRN-MEM-004, SD-TRN-MEM-005, SD-TRN-MEM-006, SD-TRN-MEM-007, SD-TRN-MEM-008, SD-REC-MEM-001 | integration | 明示save、revocation後save、delete/reset後再注入 | 共通 | accounted-for | designed | planned |
| DO-MEM-003A | AC-MEM-003 | JG-CNV-RECALL | full | SD-STA-MEM-001, SD-RUL-MEM-001 | pure | 既定件数が0/3でない | 通常会話 | accounted-for | designed | planned |
| DO-MEM-003B | AC-MEM-003 | JG-CNV-RECALL | full | SD-RUL-MEM-002, SD-EVT-MEM-001 | pure | semanticをrecentより優先、空とFailure混同 | 共通 | accounted-for | designed | planned |
| DO-MEM-004 | AC-MEM-004 | JG-CNV-RECALL | full | SD-CMD-INT-002, SD-RUL-INT-001, SD-CMD-MEM-004, SD-GPH-MEM-001, SD-RUL-MEM-001, SD-RUL-MEM-002, SD-PRJ-MEM-001 | pure/integration | admission/idempotency迂回、purpose外記憶を現在事実化、失敗時LLM呼出し | 明示Recall | accounted-for | designed | planned |
| DO-MEM-005A | AC-MEM-005 | JG-CNV-GRAPH | full | SD-GPH-CNV-001, SD-EFX-MEM-001, SD-EFX-DAT-001, SD-RUL-AGT-001 | integration | retrieval/content許可確認前Agent dispatch、Adapter隠れI/O | 共通 | accounted-for | designed | planned |
| DO-MEM-005B | AC-MEM-005 | JG-CNV-CONTINUITY | full | SD-EFX-AGT-001, SD-EFX-AGT-002 | contract | Threadなしrouteが継続を主張 | 共通 | accounted-for | designed | planned |
| DO-MEM-005C | AC-MEM-005 | JG-CNV-FAILURE | full | SD-RUL-MEM-003, SD-EFX-OUT-001 | pure/integration | 通常会話停止、明示RecallをLLMが捏造 | Owner決定済み | accounted-for | designed | planned |
| DO-MEM-006A | AC-MEM-006 | JG-CNV-RESET | full | SD-CMD-MEM-003, SD-CMD-AGT-001, SD-TRN-AGT-002 | pure/integration | reset相互連動 | 共通 | accounted-for | designed | planned |
| DO-MEM-006B | AC-MEM-006 | JG-CNV-RESET | full | SD-RUL-AGT-004, SD-REC-AGT-002 | crash-recovery | barrier後旧Thread使用、late result再結合 | 共通 | accounted-for | designed | planned |
| DO-QLI-001A | AC-QLI-001 | JG-CNV-OWNER | full | SD-CTX-QLI-001, SD-CTX-INT-001, SD-RUL-INT-001 | architecture/pure | owner重複 | 共通 | accounted-for | designed | planned |
| DO-QLI-001B | AC-QLI-001 | JG-CNV-IDEMPOTENCY | full | SD-STA-INT-001 | contract | API keyとEffect attemptを共用 | 共通 | accounted-for | designed | planned |
| DO-QLI-002 | AC-QLI-002 | JG-CNV-ADMISSION | full | SD-RUL-INT-001, SD-STA-QLI-001 | pure | Busy時queue/Graph生成 | 共通 | accounted-for | designed | planned |
| DO-QLI-003 | AC-QLI-003 | JG-CNV-CONTROL | full | SD-CMD-QLI-001, SD-RUL-INT-001 | pure | Behavior PolicyがHome/Web Cancelを抑止 | 共通 | accounted-for | designed | planned |
| DO-QLI-004A | AC-QLI-004 | JG-CNV-IDEMPOTENCY | full | SD-CMD-INT-002, SD-STA-INT-001, SD-TRN-INT-001 | concurrency | 同一key異payload、voice identity欠落 | 共通 | accounted-for | designed | planned |
| DO-QLI-004B | AC-QLI-004 | JG-CNV-IDEMPOTENCY | full | SD-STA-INT-001, SD-PER-CNV-001 | crash-recovery | admission結果とlifecycleを混同、restart後再実行 | 共通 | accounted-for | designed | planned |
| DO-AGT-001 | AC-AGT-001 | JG-CNV-ADAPTER | full | SD-PRT-AGT-001, SD-MOD-CNV-001 | contract/spike | turnごとprocess起動、initialize重複 | 初期Agent | accounted-for | designed | blocked-by-spike |
| DO-AGT-002 | AC-AGT-002 | JG-CNV-CONTINUITY | full | SD-STA-AGT-001, SD-EFX-AGT-001 | integration | HomeでThread終了 | 共通 | accounted-for | designed | planned |
| DO-AGT-003A | AC-AGT-003 | JG-CNV-RECOVERY | full | SD-STA-AGT-001, SD-PER-CNV-001 | crash-recovery | crash-before-IDを別turnへbind | 共通 | accounted-for | designed | planned |
| DO-AGT-003B | AC-AGT-003 | JG-CNV-RECOVERY | full | SD-REC-AGT-001, SD-REC-AGT-002 | crash-recovery | --last、暗黙new Thread | 共通 | accounted-for | designed | planned |
| DO-AGT-004A | AC-AGT-004 | JG-CNV-CANCEL | full | SD-RUL-AGT-003, SD-EFX-AGT-003, SD-EVT-AGT-003 | pure/contract | stale cancel dispatch | 共通 | accounted-for | designed | planned |
| DO-AGT-004B | AC-AGT-004 | JG-CNV-REDACTION | full | SD-EVT-AGT-001, SD-PRJ-AGT-001 | contract | raw delta/Thread ID漏洩 | 共通 | accounted-for | designed | planned |
| DO-AGT-005 | AC-AGT-005 | JG-CNV-OWNER | full | SD-CTX-AGT-001, SD-PRT-AGT-001 | architecture/measurement | 別Contextがbinding所有 | 共通 | accounted-for | designed | planned |
| DO-AGT-006 | AC-AGT-006 | JG-CNV-ISOLATION | full | SD-RUL-AGT-006, SD-TRN-AGT-006, SD-TRN-EXE-008, SD-REC-AGT-001 | concurrency | timeoutと成功の二重採用、turn A late結果がBを変更 | 共通 | accounted-for | designed | planned |
| DO-AGT-007A | AC-AGT-007 | JG-CNV-RESET | full | SD-RUL-AGT-004, SD-TRN-AGT-002, SD-REC-AGT-002 | crash-recovery | reset crash、Memory暗黙削除 | 共通 | accounted-for | designed | planned |
| DO-AGT-007B | AC-AGT-007 | JG-CNV-COMPACTION | full | SD-CMD-AGT-002, SD-EVT-AGT-005, SD-TRN-AGT-004, SD-TRN-AGT-005, SD-PRJ-AGT-001 | integration | compaction後Full主張、route gap隠蔽 | 共通 | accounted-for | designed | planned |
| DO-AGT-008 | AC-AGT-008 | JG-CNV-CONTINUITY | full | SD-RUL-AGT-001, SD-EFX-AGT-001, SD-EFX-AGT-002 | integration | route gap turnをThread履歴化 | 共通 | accounted-for | designed | planned |
| DO-AGT-009 | AC-AGT-009 | JG-CNV-CONTINUITY | full | SD-EFX-AGT-002, SD-EFX-AGT-003, SD-PRT-AGT-002 | contract/integration | Thread absence欠落、停止捏造 | 共通 | accounted-for | designed | planned |
| DO-OPS-014 | AC-OPS-014 | JG-CNV-CANCEL | partial | SD-RUL-AGT-002, SD-REC-AGT-001 | pure | cancel後Proposal承認 | Agent部分 | accounted-for | designed | planned |
| DO-OPS-019 | AC-OPS-019 | JG-CNV-CANCEL | partial | SD-RUL-AGT-003, SD-EFX-AGT-003 | pure/integration | unsupported取消を停止成功化 | Agent部分 | accounted-for | designed | planned |
| DO-OPS-029 | AC-OPS-029 | JG-CNV-NOTICE | full | SD-RUL-NOT-001, SD-EFX-NOT-001, SD-EVT-NOT-001, SD-PRT-NOT-001 | pure/integration | Web/Home/反射で通知、silent無視 | 初期会話 | accounted-for | designed | planned |
| DO-OPS-030 | AC-OPS-030 | JG-CNV-NOTICE | full | SD-GPH-CNV-001, SD-EFX-NOT-001, SD-EVT-NOT-001, SD-TRN-EXE-003 | pure/integration | 通知FailureでAgent停止、final音声と相関混同 | 初期会話 | accounted-for | designed | planned |
| DO-OPS-015 | AC-OPS-015 | JG-CNV-NOTICE | full | SD-STA-NOT-001, SD-RUL-NOT-001, SD-PRJ-CNV-001 | pure/integration | silentで内部Projectionまで抑止 | 共通通知 | accounted-for | designed | planned |
| DO-OPS-016 | AC-OPS-016 | JG-CNV-NOTICE | full | SD-EVT-NOT-001, SD-TRN-EXE-003, SD-REC-NOT-001 | contract/integration | Policy Stateへ結果を混入、成功・Failure・OutcomeUnknownを圧縮 | 共通通知 | accounted-for | designed | planned |
| DO-OPS-024 | AC-OPS-024 | JG-CNV-RECOVERY | partial | SD-REC-CNV-001, SD-TRN-QLI-001 | crash-recovery | restart後自動再開 | 初期会話 | accounted-for | designed | planned |
| DO-OPS-025 | AC-OPS-025 | JG-CNV-ISOLATION | partial | SD-REC-AGT-001, SD-TRN-AGT-001 | crash-recovery | 旧session結果が新session更新 | Agent部分 | accounted-for | designed | planned |
| DO-FR-009 | AC-FR-009 | JG-CNV-QUALIA | full | SD-STA-QLI-001, SD-TRN-QLI-001 | pure | Home以外で開始受理 | 共通 | accounted-for | designed | planned |
| DO-FR-010 | AC-FR-010 | JG-CNV-QUALIA | full | SD-RUL-INT-001 | pure | Busy時Effect/queue生成 | 共通 | accounted-for | designed | planned |
| DO-FR-012 | AC-FR-012 | JG-CNV-HOME | partial | SD-CMD-QLI-001 | contract | 音声/Webで別Command | 共通Command部分 | accounted-for | designed | planned |
| DO-FR-013 | AC-FR-013 | JG-CNV-HOME | full | SD-RUL-CNV-002, SD-EVT-QLI-001 | pure/integration | termination結果圧縮 | 初期会話 | accounted-for | designed | planned |
| DO-ARC-021 | AC-ARC-021 | JG-CNV-OWNER | partial | SD-CTX-QLI-001, SD-CTX-CNV-001, SD-CTX-MEM-001, SD-CTX-AGT-001 | architecture | Qualiaが本文所有 | Pilot B owner | accounted-for | designed | planned |
| DO-ARC-022 | AC-ARC-022 | JG-CNV-QUALIA | full | SD-TRN-QLI-001, SD-REC-CNV-001 | pure | 非Home二session、無checkpoint resume | 共通 | accounted-for | designed | planned |
| DO-ARC-023 | AC-ARC-023 | JG-CNV-OWNER | full | SD-STA-QLI-001 | architecture | opaque refからreducer到達 | 共通 | accounted-for | designed | planned |
| DO-OUT-002 | AC-OUT-002 | JG-CNV-PRESENTATION | partial | SD-EFX-OUT-001, SD-PRJ-CNV-001 | integration | RecallEmpty/Failure混同 | Conversation/Recall部分 | accounted-for | designed | planned |
| DO-OUT-004 | AC-OUT-004 | JG-CNV-PRESENTATION | partial | SD-RUL-MEM-002, SD-RUL-MEM-003 | pure | provenance欠落を別purpose化 | Recall部分 | accounted-for | designed | planned |
| DO-SEC-001 | AC-SEC-001 | JG-CNV-REDACTION | partial | SD-STA-AGT-001, SD-PRJ-AGT-001, SD-MOD-CNV-001 | architecture/contract | Thread ID/raw delta/plain secret露出 | Pilot B面 | accounted-for | designed | planned |
| DO-SCP-001 | AC-SCP-001 | JG-CNV-AUDIO | partial | SD-EFX-AUD-001, SD-GPH-CNV-001 | integration | chunk/queue/backpressure生成 | 初期会話音声 | accounted-for | designed | planned |
| DO-SET-003 | AC-SET-003 | JG-CNV-E2E | partial | SD-GPH-CNV-001, SD-PRJ-CNV-001 | real-device | Fakeだけ、Home欠落 | 有限会話部分 | accounted-for | designed | blocked-by-spike |
| DO-ARC-019B | AC-ARC-019 | JG-CNV-PROPOSAL | partial | SD-EVT-AGT-002, SD-RUL-AGT-002, SD-RUL-CNV-003, SD-EFX-TOL-001, SD-PRT-AGT-001, SD-PRT-TOL-001 | pure/integration | Agent tool要求をAdapterが直接実行 | Agent Proposal部分 | accounted-for | designed | planned |
| DO-ARC-020B | AC-ARC-020 | JG-CNV-PROPOSAL | partial | SD-EVT-AGT-002, SD-RUL-AGT-002 | pure | Observation、許可Graph、未承認Proposalの混同 | Agent Proposal部分 | accounted-for | designed | planned |
| DO-DAT-001B | AC-DAT-001 | JG-CNV-AUTH | partial | SD-RUL-AGT-005, SD-EFX-DAT-001, SD-EVT-DAT-002, SD-PRT-DAT-001 | pure/contract | 複合分類の一部許可、失効許可でProvider送信 | Conversation/Memory部分 | accounted-for | designed | planned |
| DO-CNV-004C | AC-CNV-004 | JG-CNV-TERMINAL | full | SD-GPH-CNV-001, SD-RUL-CNV-004, SD-REC-OUT-001, SD-PER-CNV-001 | integration/crash-recovery | Agent失敗・timeout・Projection commit失敗で永久Active | 初期有限会話 | accounted-for | designed | planned |
| DO-EFX-004B | AC-EFX-004 | JG-CNV-EXECUTION | partial | SD-STA-EXE-001, SD-RUL-CNV-003, SD-PER-EXE-001, SD-PER-EXE-002 | architecture/integration | Conversation専用dispatcher、共通結果envelope未使用 | Pilot B Effect | accounted-for | designed | planned |
| DO-SKL-002B | AC-SKL-002 | JG-CNV-TOOL | partial | SD-RUL-TOL-002, SD-EFX-TOL-001, SD-EFX-TOL-002, SD-EFX-TOL-003, SD-EVT-TOL-001, SD-RUL-TOL-001, SD-PRT-TOL-001, SD-REC-TOL-001 | pure/contract/integration | dispatch前revocation無視、grant外副作用、tool無期限停止、cancel/timeout後late結果採用 | Skill実行部分 | accounted-for | designed | planned |

## Failure、取消、Recovery scenario

| Scenario | Expected result |
| --- | --- |
| 通常RecallでSemanticMemory unavailable | `ContinueWithoutMemory`を固定し、記憶0件でAgentへ進む。別Memoryへfallbackしない |
| 明示RecallでSemanticMemory unavailable | Agent Effectなしで`RecallUnavailable`をpublish |
| 明示Recall selected後にAgent failure/timeout/cancel | provenanceなしの成功を捏造せず`RecallFailure`をpublishしHomeへ収束 |
| selected Memoryのcontent authorization失効 | Agentへ本文を渡さず型付き拒否／Failure Presentationへ収束 |
| Agent request intent後・external ID前crash | 新request/new Threadを作らず元BindingをRecovery |
| Agent成功とdeadlineが近接 | 同一revisionのwinner一件だけを採用し、loserをlate evidenceへ隔離 |
| turn A後にturn B、A late result | AのBinding/Recoveryだけを更新しBを変更しない |
| tool proposalが連続 | 同じOccurrenceへ戻らずfresh `Uk -> Ak+1`を追加。budget/deadlineで有限終端 |
| cancel後Proposal | response/toolとして承認せず旧Bindingへ隔離 |
| Thread reset中に旧turn active | cancel要求、durable handoff、barrier、fresh continuityの順。cancel terminalは待たない |
| reset barrier後crash | 旧Threadをfuture turnへ戻さずRecovery |
| Memory reset後に旧save成功 | 旧generationへ隔離しrecordを復活させない |
| explicit save/delete/reset後にduplicate結果 | pending mutation／stable operation ID一致の一件だけを適用 |
| ThinkingNotice Failure | Agent requestを止めない |
| playback OutcomeUnknown | Homeを物理完了の証拠にせずRecoveryへ相関 |

## Proof design

- pure: admission、Recall Policy/selection/failure、Proposal validation、cancel、Home guard。
- architecture: 五Contextのowner、Adapter/Projectionからreducer到達不能、Codex固有operationのCore非依存。
- contract: SemanticMemory、persistent Agent、no-continuity Provider、publish、non-streaming audio。
- integration: retrieval→Agent→Proposal→publish/save→Home、route切替、ThinkingNotice非blocking。
- concurrency: idempotency、同Thread turn、cancel、late/duplicate、reset barrier。
- crash-recovery: crash-before-external-ID、inbox-before-ack、Memory generation、Thread reset。
- measurement/real-device: long-lived app-server再利用、warm/cold、wakeからHomeまでのE2E。

## Change impact

- persistent Thread対応Agentを交換する場合、`SD-PRT-AGT-001` Adapter/Profile/Bootstrapだけを変更し、Conversation/Memory/Qualia法則を変えない。
- Thread非対応Providerを交換する場合、`SD-PRT-AGT-002`だけを変更し、継続を偽装しない。
- Memory engine/server配置を交換する場合、`SD-PRT-MEM-001` Adapterだけを変更し、logical record/generation/Policyを変えない。
- continuous conversationを将来追加する場合、別Behavior version、別Graph、別受入義務とし、初期有限Graphを黙って拡張しない。
