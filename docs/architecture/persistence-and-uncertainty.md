# 永続化と不確実性 — 現実について嘘をつかない

soukobanの閉じた世界では、Transitionを適用すれば次の世界が確定します。現実のロボットでは、Effectを送っても外界が変わったとは限らず、その結果を観測できないこともあります。さらに、送信と記録の途中でプロセスが止まる可能性があります。

したがってYatagarasu 2の永続化は、単に状態を保存する機能ではありません。「仕事を失わない」「勝手に二重実行しない」「分からない結果を成功へ変えない」を同時に守るための構造です。

## Snapshot、journal、durable pending

初期の永続Source of Truth（正となる情報源）は、commit済みsnapshotです。journalは監査とProjectionの再構築を支えますが、journalの再生から外部作用を再実行しません。

重要な不変条件は次です。

> commit済みsnapshotがEffectを実行可能にするなら、そのEffectのdispatch可能なpending recordも、snapshotとともに永続化されている。

Dispatcherは、この永続pending recordだけを読みます。これにより、commit後・dispatch前に停止しても仕事を失いません。一方で、journalからEffectを作り直して二重実行することも防ぎます。

transaction、outbox、idempotency、reconciliation、databaseの具体方式は未決です。どの方式を選んでも、この不変条件を満たす必要があります。

## 取消も永続化する

待機中の仕事が取り消された場合、Execution Contextはrevocation（取消済み状態）を同じ復旧境界で永続化します。再起動後もDispatcherはそれを送信しません。

すでに送信した物理Effectは止められないことがあります。遅れて届く結果は記録しますが、再起動や取消だけを理由に「止まった」「実行されなかった」「成功した」と推測しません。取消済みInteractionへ遅れて届いたProposalも適用しません。

## 開始Eventは、完了Eventではない

`EffectExecutionStarted`は、Adapterが実行を試みた、または開始したことを示す結果Eventです。物理的に適用されたこと、完了したことの証拠ではありません。

想定動作時間や音声時間は、CoreがこのEventを受理した後にだけ測ります。queueで待った時間は含めません。開始Eventが届かなければ、timerに基づくAssumedの準備完了・再生完了を作りません。Recoveryが開始Eventを推測して補ってもいけません。

## 物理世界の結果語彙

| 結果 | 意味 | 言ってよいこと |
| --- | --- | --- |
| Observed（観測済み） | 証拠が物理結果を確認した | 確認できた |
| Assumed（仮定済み） | 方針や時間により進行を許せるが、確認観測はない | 完了したと仮定して進む |
| DefinitelyNotApplied（未適用確定） | 証拠が、要求した作業は適用されなかったと示す | 実行されなかった |
| OutcomeUnknown（結果不明） | 適用済み・未適用のどちらにも安全に分類できない | 結果を確認できない |

時間が過ぎただけの結果はAssumedであり、Observedではありません。OutcomeUnknownは成功ではなく、明示的なPolicyまたは照合なしに自動再試行しません。物理作用の重複は、元に戻せない結果を生む可能性があるからです。

## Recovery境界

Recoveryは、commit済みsnapshotと永続pending workから内部状態を再構築します。その後、必要なら物理deviceとの照合を要求するか、Interactionを安全に失敗させます。

プロセスが再起動したという内部事実から、カメラ移動、再生停止、発話完了などの物理事実を導きません。

Starting、Active、Terminatingの非Home qualia sessionが復元された場合は、同じsessionをRecoveringとして公開します。安全なcheckpointと明示Policyがない既定Behaviorを自動再開せず、Homeへ終了するか、Owner判断を待つか、資源を隔離するかを型付き結果で決めます。

Qualiaは、未解決の外部作用を永続Recoveryへ引き渡した後にHomeへ戻れます。Homeは現在の非Home qualia sessionがない状態であり、すべての物理結果が観測済みという意味ではありません。遅い結果は元のqualia sessionへ相関して記録し、その後に始まったsessionのState、Effect、確定Projection、物理確認へ混入させません。

OutcomeUnknownの資源を再利用できるかは、物理結果の確かさとは別に判断します。例えばTapo相当の首振りは保守的なcooldown後にモーターを再利用できても、姿勢をObservedにしません。将来のmanipulatorは照合やOwner確認まで利用不能にできます。

## Artifactと通知も推測しない

Artifact Contextは、画像、音声、その他ArtifactRefの作成、利用可能性、参照中、削除、孤立成果物の回収を所有します。撮影失敗や無効なArtifactRefは、LLM Effectを実行可能にしません。cleanupは明示Effectと結果Eventで監査します。

通知も同じです。通知を試みた、外部へ届いた、届いたか分からないを分けます。Projectionに「通知済み」と表示したことは、利用者の端末へ届いた証拠ではありません。

ストリーミングTTSを採用する場合も、journalへ無制限の生chunkを保存せず、有界な監査参照と結果だけを残します。結果不明の音声やArtifactを自動再送しません。
