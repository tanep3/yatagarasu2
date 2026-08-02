# 運用要件

## 目的

仕事を失わず、勝手に再実行せず、物理事実・取消・通知を根拠なく言い過ぎない形で安全に進化する。

要件IDは意味の安定性を優先するため、本文順と数値順が一致しない場合がある。

### REQ-OPS-001 — Yatagarasu 1の分離

Yatagarasu 2の開発中もYatagarasu 1は稼働を継続し、別系統として保つ。未完成のYatagarasu 2コードを本番ロボット環境へ混在させない。Yatagarasu 1は旧版ではなく、実機機能要件を検証し続ける基準系として扱う。

受入条件:

- AC-OPS-001: リリースまたは配備チェックリストがYatagarasu 2の独立環境を示し、Yatagarasu 1本番環境を対象から除外する。

### REQ-OPS-002 — 初期永続化のSource of Truth

初期の永続化Source of Truthはcommit済みsnapshotとする。journalは監査とProjection再構築に用い、journal replayは外部side effectを再実行しない。

受入条件:

- AC-OPS-002: fixtureにおいて、commit済みsnapshotからのrestart再構築が同じdomain Stateを保つ。
- AC-OPS-003: fixtureのjournal/Projection replayがAdapter dispatchを一切起こさない。

### REQ-OPS-003 — dispatch可能な仕事を永続化する

snapshotのcommitによりEffectがreadyになるなら、そのEffectのdispatch可能なpending recordをcommit済みStateとともに永続化する。dispatcherは永続化済みpending recordだけをdispatchする。Recoveryは仕事を黙って失わず、journal replayだけで再生成もしない。保存機構は意図的に未決とする。

受入条件:

- AC-OPS-004: commit後かつdispatch前の停止を模擬しても、Recovery可能な永続pending recordが残る。
- AC-OPS-005: dispatcherが、永続pending recordを持たないready Effectを拒否する。
- AC-OPS-006: fixtureのRecoveryが、選択されたidempotency/照合Policyのもとでpending recordを一度dispatchし、journal replayをside effectの源にしない。

### REQ-OPS-004 — 音声再生の開始・仮定完了・取消結果

一括再生かストリーミング再生かにかかわらず、再生Adapterが返しCoreが受理した`EffectExecutionStarted`から、PlaybackCompletionAssumedはClockPortの単調audio durationとmarginを測る。このEventは再生の試行／開始を示すだけで、音が聞こえたことや再生完了の観測ではない。Event前のqueue時間は消費せず、EventがなければtimerベースのAssumed completionは起こらない。取消結果と物理的な再生停止も区別する。start Event不達時のtimeout／Failure Policyと数値境界は未決である。ストリーミングTTS固有の追加条件はREQ-OPS-008だけに置く。

受入条件:

- AC-OPS-007: playback fixtureが、単調durationとmarginの経過後にだけAssumed completionを生む。
- AC-OPS-008: cancellation fixtureが、観測がない限りObserved playback stopを主張せず、選ばれたcancel結果を記録する。
- AC-OPS-010: playback fixtureは`EffectExecutionStarted`の受理前にqueue時間を経過させてもaudio durationを消費しない。
- AC-OPS-011: `EffectExecutionStarted`を返さないplayback fixtureはtimerベースのAssumed completionを生まない。

### REQ-OPS-006 — durableな取消と遅延結果

`CancelRequested` Command、Interactionが中止を受理した`CancellationAccepted` Event、pending workのdurable revocation（永続取消）、in-flight workの取消結果、
物理結果を区別する。dispatch済みの物理移動はnon-cancellable（取消不可）であり、下流の仕事をrevokedにし、遅い結果は記録する。
音声のstopは必要であり、LLM、保留TTS、queued playback、現在chunkのうちAdapterが対応するものだけへ適用する。停止を捏造してはならない。
中止済みInteractionは遅いProposalを拒否し、revoked recordはrestart後も残りdispatcherはdispatchしない。OutcomeUnknownは自動retryしない。

受入条件:

- AC-OPS-012: durable cancel/restart fixtureがrevoked pending recordを復元し、dispatcherがそれをdispatchしない。
- AC-OPS-013: dispatched moveの取消fixtureが下流をrevokedにし、遅い物理結果を記録する。
- AC-OPS-014: cancel後に届いたProposalまたは未対応のplayback stopが、承認済み仕事または架空の停止観測を作らない。
- AC-OPS-019: table-driven fixtureが、LLM、pending TTS、queued playback、current chunkの各supported targetへ別々のcancel Effect/requestを作り、unsupported targetにはstopを捏造しないこと、cancel結果Eventがphysical outcomeと別であることを示す。

### REQ-OPS-007 — 通知は方針と結果Eventで扱う

通知のoperation、plan、channel、wording、silentは名前を持つNotification Policy所有者の設定である。silentはnotification Effectだけを抑止し、
内部事実またはProjectionを抑止しない。Projectionは外部配達の証拠ではない。通知の試行は型付き成功またはFailureの結果Eventを返す。

受入条件:

- AC-OPS-015: silent fixtureが内部の完了・Failure Projectionを残し、notification Effectだけを作らない。
- AC-OPS-016: 通知Adapterの成功、Failure、未確認配達の各結果が型付きEventとして記録される。

### REQ-OPS-008 — 条件付きのストリーミングTTS

ストリーミングTTSを採用する場合、句読点・長さ・時間によるsegmentation、並列synthesisと順序付きplayback、bounded queue/backpressure
（上限付き待ち行列・逆圧）、LLM/chunk上限をPolicyで定める。無言dropは禁止する。cancel後に到着したchunkと後続chunkの扱い、artifact cleanup、
restart時の安全なorphan cleanup、監査参照をEffect Graphと型付き結果Eventで表す。OutcomeUnknownのartifactまたは音声は再送しない。
journalへ無制限のraw provider chunkを記録しない。

受入条件:

- AC-OPS-017: 採用済みfixtureが上限到達を型付きbackpressure結果として返し、chunkを無言で捨てない。
- AC-OPS-018: cancelとcleanup fixtureが到着済み/後続chunkの規則、artifact lifecycle結果、監査参照を記録する。
- AC-OPS-020: cancel後に到着したlate chunkと将来chunkをadmitまたはdispatchしないfixtureが、型付き取消/cleanup結果を残す。
- AC-OPS-021: parallel synthesis fixtureが、完了順にかかわらず元の順序でplaybackをdispatchする。
- AC-OPS-022: restart orphan cleanup fixtureが、参照中または監査に必要なArtifactRefを保存し、回収可能なorphanだけをcleanupする。
- AC-OPS-023: OutcomeUnknown artifactまたは音声のfixtureが、自動resendを一切行わない。

### REQ-SEC-001 — secretとデータ露出

secretをEvent、Projection、prompt、journal、通常ログへ含めない。WebはREQ-API-004のOwner認証と取消可能tokenを要求する。具体session方式、TLS／reverse proxy、memory保持、privacy policyは暗黙の保証ではなく、未決の設計作業である。

受入条件:

- AC-SEC-001: canary secretを入力するredaction fixtureが、Event、Projection、永続journal、診断Artifact、Providerへ送信直前のRequest／prompt、通常ログの全検査面に、平文または既知の派生表現を含まないことを確認する。

### REQ-OPS-005 — capability bindingをdomain外に保つ

具体capabilityの選択とtransport bindingはadapter/bootstrapで行う。cronは延期し、source固有のaudio詳細によってsource adapterにdomain所有権を与えない。

受入条件:

- AC-OPS-009: 試験用Port実装を再bindingしてもdomain RuleまたはTransitionが変わらない。

### REQ-OPS-009 — Qualia終了と物理Recoveryを分離する

クオリアは、新規仕事のadmission停止、pending仕事のdurable revocation、成果物確定、資源解放または永続Recoveryへの責任移管を終えた場合にHomeへ戻れる。HomeはActive Qualiaがないことを意味し、すべての外部作用が観測済みであることを意味しない。OutcomeUnknownの外部作用は自動再送せず、自律神経のRecoveryが追跡する。該当資源の再利用条件はeffect／device profileのversion付きRecovery Policyが`ImmediatelyReusable`、`ReusableAfterCooldown`、`ReusableAfterReconciliation`、`OwnerConfirmationRequired`、`Unavailable`から決める。資源の再利用可能性と、物理結果・姿勢の確かさを混同しない。

受入条件:

- AC-OPS-024: restart fixtureが永続化されたStarting、Active、Terminatingと永続仕事を同じqualia sessionのRecoveringとして復元し、明示的に安全なcheckpointを持たない既定Behaviorを自動再開しない。`ResumeFromCheckpoint`は同じsessionをActiveへ戻し、`AwaitOwnerDecision`はRecoveringを維持し、`TerminateToHome`または`QuarantineResource`は責任移管後にTerminatingを経てHomeへ解決する。
- AC-OPS-025: `旧sessionをHomeへ終了 -> 新sessionを開始 -> 旧Effectの遅い結果を受信`するfixtureが、OutcomeUnknownを自動retryせず、遅い結果を旧sessionのRecovery／Physical Observation記録だけへ相関する。その結果は、現在sessionのState、Effect Graph、Effect、確定Projection、物理確認状態を変更または生成しない。
- AC-OPS-026: Tapo相当の移動profile fixtureが、保守的なcooldown後にモーター資源を再利用可能にしても、姿勢または移動結果をObservedへ昇格せず、必要時に校正または照合を要求する。
- AC-OPS-027: `OwnerConfirmationRequired`または`Unavailable`のresourceを必要とする新しいQualia開始fixtureが、HomeであってもCapability不足として拒否される一方、そのresourceを使わないQualiaは開始できる。
