# ランタイム境界

## 依存方向

```text
domain <- application <- ports <- adapters
                     \- bootstrap wires concrete implementations
```

Domainはproduct、protocol、filesystem、network、clock、microphone、camera、GPU、Providerへ依存しません。Applicationは抽象Portを知ってよいものとします。Adapterは具体入出力を変換し、具体bindingを選ぶのはBootstrapだけです。

## Contextと所有権

Acoustic Contextはwake acceptanceとprompt lifecycleを所有します。held Mimy listening sessionのcreate/releaseをcommandしてよく、Mimyはtranscription関連の事実を返します。MimyはInteraction、conversation、plan、Provider、WorldStateを所有しません。

Yata WakeはMimyの外側にあるYatagarasu Adapterです。Yata WakeとMimyは接続/buffer状態を独立して所有します。両者はfan-out sourceを利用できます。raw physical microphoneはfan-outを提供するか、配備が互換性のあるsingle-consumer topologyを用いなければなりません。どのAdapterも同時に独立消費できると仮定しません。

Mimyは汎用でsource-agnosticなSTT capabilityです。go2rtc source adapterは可能な入力sourceの一つであり、必須の直接接続でもdomain ruleでもありません。

## 外部capability境界

Python inference workerなどのcapabilityはPortを通じて型付き要求を受け、型付きobservation、Proposal、Failureを返します。WorldState、plan、Provider state、conversation stateを所有しません。IPCは延期します。domain契約を変えずに計測後に選べますが、そのtransport schemaをdomain型にしてはなりません。

Hoshikageのrevision `4faf65f686006c0543f8bdcf5c246d754133dc70`は、Provider境界の検討材料として、livenessとreadinessの分離、capability advertisement（能力広告）、queue/admission Failureとinference Failureの分離、terminal streamとdisconnectの分離、auth/secret redaction（認証・秘匿情報の伏せ字）、generation/lease（世代・貸出し）を示す。これらは採用済みのHoshikage内部契約ではない。Y2のprovider routing、利用者同意、privacy、process、transportはOPENである。

## 音声とスケジューリング

ストリーミングTTSの採用と優先度はOPENである。採用時だけ、`PlaybackCompletionAssumed`は再生Adapterから返りCoreが受理した`EffectExecutionStarted`の後に、ClockPortの単調audio durationとmarginから導く。このEventは再生の試行/開始であり、音響的観測ではない。queue時間は含めず、EventがなければAssumed completionは起こらない。start Event不達時のtimeout/Failureと数値境界はPolicyの未決事項である。

中止はWebを含む全Inbound Adapterが共通の`CancelRequested`境界へ入れる。physical moveはdispatch後に取消不能であり、下流Graph nodeをrevokedにし、結果が遅れても結果Eventとして記録する。voice stopはLLM、pending TTS、queued playback、current chunkのうちAdapterがサポートする範囲だけへ要求し、未対応の停止を成功または観測として捏造しない。

採用時は句読点・長さ・時間によるsegment、並列synthesisと順序付きplayback、bounded queue/backpressure、LLM/chunk上限、cancel後の到着済み/後続chunk、artifact cleanupを、Effect Graphと結果Eventで扱う。raw provider chunkをjournalへ無制限に保存しない。

cronその他のscheduled autonomyは将来の作業です。第二の制御経路ではなく、Inbound Adapterとして導入します。
