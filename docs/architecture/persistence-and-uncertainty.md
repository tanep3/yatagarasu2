# 永続化と不確実性

## Snapshot、journal、pending dispatch

初期の永続Source of Truthはcommit済みsnapshotです。journalは監査とProjection再構築を支えます。journalのreplayは外部side effectを再実行しません。

重要なintegrity invariantは次のとおりです。

> commit済みsnapshotがEffectをreadyにするなら、そのEffectのdispatch可能なpending recordはsnapshotとともにdurableである。

dispatcherはこのdurable pending recordだけを読みます。Recovery時に仕事を黙って失わず、journal replayで再生成もしません。transaction、outbox、idempotency、reconciliationの具体機構は未決です。将来の作業は特定database機能を仮定せず、このinvariantを示さなければなりません。

pending recordが取消対象になると、Execution Contextはdurable revocationを同じRecovery境界で記録する。dispatcherはrevoked recordをdispatchしない。dispatch済みphysical Effectの遅い結果は記録するが、restartや取消を根拠に停止・未適用・成功を推測しない。cancelled Interactionへ遅れて届くProposalは拒否する。OutcomeUnknownは自動retryしない。

`EffectExecutionStarted`はAdapterが返しCoreが受理する、dispatch/実行開始の試行を表す結果Eventです。`ExpectedActionDuration`と再生のaudio durationは、このEventをCoreが受理した後にだけ測ります。queue時間は測定に含めず、このEventを受理しなければtimerベースのAssumed readiness/completionは生じません。このEventは物理的な適用または完了の証拠ではありません。Event不達時のtimeout/Failure Policyは未決です。RecoveryがEventを推測して生成してはなりません。

## 物理世界の結果語彙

| 結果 | 意味 |
| --- | --- |
| Observed | 証拠が物理結果を確認している。 |
| Assumed | Policy/timerにより進行してよいが、確認観測はない。 |
| DefinitelyNotApplied | 証拠が要求した物理作業は適用されなかったと示す。 |
| OutcomeUnknown | 適用済み/未適用のいずれにも安全に分類できない。 |

`OutcomeUnknown`は成功完了ではなく、明示的Policyまたはreconciliationなしに自動retryしてはなりません。durationに基づくreadiness結果は`Assumed`であり、`Observed`ではありません。

## Recovery境界

Recoveryはcommit済みsnapshotとdurable pending workからStateを再構築します。物理deviceを照合するか、Interactionを安全に失敗させてよいものとします。processがrestartしただけでcamera movement、playback stop、その他の物理完了を推論しません。

## Artifactと通知の監査境界

Artifact Contextが`ArtifactRef`の作成、利用可能性、cleanup、orphan cleanupのlifecycleを所有する。capture Failureまたは無効・不適用な`ArtifactRef`はLLM Effectをreadyにしない。cleanupは明示Effectと型付き結果Eventで監査し、OutcomeUnknown artifactを自動再送しない。streaming TTSを採用する場合もjournalには有界な監査参照と結果だけを保存し、無制限のraw provider chunkを保存しない。

通知の成功、Failure、未確認配達は結果Eventである。Projectionは通知を表示しても、外部への配達を証明しない。
