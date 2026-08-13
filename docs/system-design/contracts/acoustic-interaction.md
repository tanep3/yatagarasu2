# Acoustic interactionのcanonical contract

この文書は、通常wake候補を一命令へ閉じるAcoustic Contextと、再生中の音声Stop候補を扱う契約の唯一の正式定義です。根拠はREQ-ACOU-001、Accepted ADR-006／016、Y1の`listen_state`／`listend`実機知見です。具体source、transport、buffer、process、pre-roll長、guard長、flush／reconnect方式をCoreへ固定しません。

CommandとEventを混同しません。wake、source、prompt、guard、transcript、制御語は外界で起きた観測Eventです。Acoustic Contextのpure Ruleが受理した一命令だけを既存`SD-CMD-INT-002 SubmitInteraction`へ、音声Homeを既存`SD-CMD-QLI-001 ReturnToHomeRequested`へ、抑止されなかった音声Stopを既存`SD-CMD-INT-001 CancelRequested`へ変換します。Web Home／CancelはAcoustic Contextを経由せず同じ共通Command境界へ入り、`StopSuppressionPolicy`で拒否しません。

## Context、State、read view

### SD-CTX-ACO-001 — Acoustic Context

wake acceptance、通常音声session identity、pre-roll選択window/cursor、logical audio spanのretain／discard、prompt guard、empty command、登録Stop語、`StopSuppressionPolicy` version、音声候補からのCommand生成可否を唯一所有します。初期releaseでは同時に一つだけ通常wake sessionをOpenにできます。Home／Stop候補検知は通常sessionと別の常時生存経路であり、第二のsessionを作りません。

source Adapterは接続、raw audio bytes、ring buffer、source-local cursor、推論、再接続を所有できますが、Acoustic State、Interaction、Conversation、WorldStateを変更しません。Execution Contextはspeech playback occurrenceとそのcanonical回答全文／Policy version bindingを所有します。Acoustic Contextはそのread viewを読むだけです。

### SD-STA-ACO-001 — AcousticState

```text
AcousticState {
  policy_revisions: Map<AcousticPolicyVersion, AcousticPolicyRecord>,
  stop_policy_revisions: Map<StopSuppressionPolicyVersion,
    StopSuppressionPolicyRecord>,
  current_policy_revision,
  current_stop_policy_revision,
  sessions: Map<AcousticSessionId, AcousticSessionRecord>,
  accepted_candidate_ids: Set<AcousticCandidateId>,
  voice_control_processed: Map<AcousticCandidateId,
    VoiceControlProcessedRecord>,
  state_revision
}

AcousticSessionRecord {
  session_id, wake_candidate_event_id, acoustic_generation,
  source_binding: {
    logical_source_id, source_epoch,
    source_profile_version, adapter_binding_generation
  },
  pinned_acoustic_policy_version,
  pinned_stop_policy_version,
  selection: {
    wake_anchor_cursor,
    historical: {
      requested_pre_roll_profile_ref, available_history_window?,
      selected_history_window?, immutable_history_end_cursor?,
      history_selection_digest?
    },
    post_wake_collection: {
      interval_start_cursor: wake_anchor_cursor,
      observed_through_cursor, finalized_end_cursor?,
      collection_decision_digest?
    },
    retained_selections: List<{
      span_ref, retained_cursor_subrange,
      origin: HistoricalPreWake | PostWakeCollection
    }>,
    discard_records: List<{ span_ref?, cursor_range, reason, source_event_id }>
  },
  prompt: { occurrence_id, lifecycle,
    outcome_partition?: SafeGuardIssuer | DefiniteBypass |
      TypedCloseFailure | CustodyQuarantine,
    terminal_action_status },
  guard: { boundary_ref, lifecycle },
  transcript: NotRequested | Requested(occurrence_id) |
    Empty | Accepted { canonical_text, source_result_event_id } |
    Failed | OutcomeUnknown,
  outbound_command?: {
    command_kind, stable_command_id, payload_fingerprint, outbox_status
  },
  recovery?: AcousticRecoveryRecord,
  lifecycle: WakeAccepted | Opening | Collecting | Transcribing |
    CommandCommitted | Empty | Closing | Recovering | Closed | Quarantined
}

VoiceControlProcessedRecord {
  candidate_id, payload_fingerprint,
  temporal_evidence_digest, pinned_stop_policy_version,
  target_resolution: HomeNotApplicable |
    PlaybackBound {
      playback_occurrence_id, exact_interaction_id,
      execution_subject_digest, execution_state_revision
    } |
    InteractionViewSelected {
      exact_interaction_id, interaction_view_revision,
      eligible_set_digest
    } |
    NoCancellableInteraction { interaction_view_revision,
      eligible_set_digest } |
    TemporalUnknown {
      evidence_digest, reason,
      pinned_stop_policy_version
    } |
    UnresolvedInvariant { evidence_digest },
  decision_event_id, decision_digest,
  outbox: None | { command_id, command_fingerprint, status },
  suppression_audit?: {
    playback_occurrence_id, canonical_response_digest,
    stop_policy_version, normalization_rule_version,
    matched_term_digest?, temporal_relation
  }
}

AcousticDiscardReason = DuplicateCandidate | BusyWithOpenSession |
  OverlapsOwnedPrompt | WithinPromptGuard | OverlapsOwnedPlayback |
  BeforeSelectedWindow | AfterCommandCommitted | ClosedSession |
  StaleSourceEpoch | ReconnectDiscontinuity | DuplicateOrLateResult |
  TemporalOverlapUnknown
```

`selected_history_window`は`[.., wake_anchor_cursor)`だけのimmutable historical windowで、post-wake cursorへ延長しません。`post_wake_collection`は`[wake_anchor_cursor, finalized_end_cursor)`の別intervalです。`retained_selections`はAdapter所有raw bufferへのopaque logical refとAcoustic ownerが選んだsubrangeでありbytesを所有しません。prompt／guardと重なるsubrangeだけを除外し、speech spanがguardを跨ぐ場合もguard後suffixを保持できます。`source_profile_version`、Policy versions、source epochはsession受理時に固定し、途中の設定変更や再接続で書き換えません。

### SD-MOD-ACO-001 — SpeechAcousticBindingView

```text
SpeechAcousticBindingView {
  playback_occurrence_id,
  execution_subject,
  exact_interaction_id,
  canonical_response_full_text,
  stop_suppression_policy_version,
  normalization_rule_version,
  playback_lifecycle,
  playback_interval_evidence: AcousticTemporalEvidence
}

CancellableInteractionReadView {
  interaction_state_revision,
  entries: Set<{
    interaction_id,
    lifecycle: Admitted | Running | Cancelling | Terminal | Recovering,
    cancellation_already_recorded: Boolean
  }>,
  view_digest
}
```

`SpeechAcousticBindingView`は`SD-STA-EXE-002 ExecutionStateV2`の`InjectV1`として保持されたexact `SD-EFX-AUD-001 PlayNonStreamingSpeech` occurrenceのplanned payload、`policy_refs`、result lifecycleからだけ導きます。`execution_subject`が`InjectV1(InteractionSubject(InteractionExecutionSubject))`で、そのsubject内の`interaction_id`とoccurrence／Graph／correlationが一致する場合だけ`exact_interaction_id`を導出できます。Management／Acoustic subject、部分一致、別generation、payload内の別targetはtyped invariant violationであり、current Interactionへ読み替えません。Execution V2 activation前のaccepted V1 snapshotでは同じ情報を`SD-PRJ-EXE-001`互換view経由で読めますがAcoustic admissionを開始しません。別Stateを複製せず、canonical全文、exact Interaction、Policy versionをGraph登録前に固定し、dispatch後の応答編集またはcurrent Policyへの読み替えを拒否します。

`CancellableInteractionReadView`は`SD-CTX-INT-001`が所有する`SD-STA-INT-001`から、同じowner revisionで導くread-only valueです。`Admitted | Running`かつ取消未記録だけをcancellableとし、Acoustic ContextはこのStateを複製／変更しません。`Cancelling | Terminal | Recovering`を暗黙のcurrent targetへ昇格せず、同revision内の重複ID、矛盾lifecycle、digest不一致をtyped invariant violationにします。

### SD-MOD-ACO-002 — AcousticGraphContributionV2

```text
AcousticGraphContributionV2 =
  AddGuardWait { safe_prompt_boundary, G, G_deadline,
    declared_facts, issuer_contract } |
  AddTranscription { selected_history_window,
    post_wake_collection_interval, retained_selections: NonEmptySet,
    selection_fact, T, T_deadline,
    exact_named_lease_continuation } |
  AddClose { terminal_reason, discard_through_cursor, C, C_deadline,
    exact_named_lease_continuation } |
  AddRecovery { target_operation_id, recovery_occurrence,
    recovery_deadline, custody_ref }
```

各variantは追加時点で確定したimmutable payloadだけを持ち、future span／cursor、closure、current Policy lookupを持ちません。`declared_facts`はfact ID、型、同sessionのissuer owner Event ID、issuer contractを列挙します。lease continuationは`existing_lease_id`、`resource=audio.input.session`、`mode=Exclusive`、`named_interval_ref=session_id`、`holder_ref=AcousticSessionSubject { session_id, wake_candidate_event_id, source_epoch, acoustic_generation }`、`holder_fact_id=SourceSessionOpened`をexactに持ちます。四fieldのいずれかが違えば別holderです。

### SD-MOD-ACO-003 — AcousticTemporalEvidence

```text
AcousticTemporalEvidence {
  schema_version, clock_domain_id, clock_domain_epoch,
  interval_or_mark, capture_profile_version,
  producer_binding_generation, evidence_ref
}
```

wake、span、promptの安全な開始境界、guard、playback、Voice Controlはこの共通schemaを使います。exactな順序／重なりを主張できるのはschema version、clock domain／epoch、capture profile versionが全て一致し、interval orderingが検証できる場合だけです。不一致または欠落は`TemporalRelationUnknown`であり、Adapterのoverlap hintを確定事実へ昇格しません。

## Event

### SD-EVT-ACO-001 — WakeCandidateObserved

```text
WakeCandidateObserved {
  event_id, candidate_id, logical_source_id, source_epoch,
  source_profile_version, candidate_span_ref, candidate_cursor_range,
  candidate_kind: NormalWake,
  overlapping_owned_playback_occurrence_ids,
  temporal_evidence: AcousticTemporalEvidence,
  adapter_observation_ref
}
```

Adapterによる候補観測であり、wake受理、session開始、利用者由来を意味しません。重複、stale epoch、active prompt／playbackとの重なりはpure Ruleが判定します。

### SD-EVT-ACO-002 — AcousticSourceObserved

```text
AcousticSourceObserved =
  SpanAvailable {
    event_id, session_id, logical_source_id, source_epoch,
    span_ref, cursor_range, observation_kind,
    overlapping_prompt_occurrence_ids,
    overlapping_playback_occurrence_ids,
    temporal_evidence: AcousticTemporalEvidence
  } |
  CollectionBoundaryObserved {
    event_id, session_id, logical_source_id, source_epoch,
    observed_through_cursor,
    boundary_kind: SilenceAfterSpeech | SessionLimit | ExplicitClose,
    temporal_evidence: AcousticTemporalEvidence
  } |
  SourceReconnected {
    event_id, logical_source_id, prior_source_epoch, new_source_epoch,
    adapter_binding_generation, observed_cursor
  }
```

`observation_kind`は`SpeechCandidate | Silence | Unknown`の候補でありretain／discardやemptyを決めません。reconnectは新wakeでもsource recovery成功でもなく、Acoustic Ruleへの入力です。

### SD-EVT-ACO-003 — AcousticSourceOperationResolved

```text
AcousticSourceOperationResolved {
  execution: ExecutionCorrelation,
  session_id, source_epoch, stable_source_operation_id,
  result:
    SessionOpened { available_history_window, cursor_at_open,
      temporal_evidence: AcousticTemporalEvidence } |
    TranscriptObserved { canonical_text, consumed_span_refs } |
    EmptyTranscript { consumed_span_refs } |
    SessionClosed { discard_through_cursor } |
    Failed(AcousticSourceFailure) |
    OutcomeUnknown(AcousticSourceFailure)
}
```

Effectのresult Eventです。Adapterはwake時点以前の利用可能history範囲とcursorを観測するだけでselected history windowやpost-wake collection終端を返しません。Acoustic pure Ruleが両intervalとretain subrangeを決め、Adapterは空を受理するか、Interactionを作るかを決めません。

### SD-EVT-ACO-004 — WakePromptPlaybackResolved

```text
WakePromptPlaybackResolved {
  execution, session_id, stable_prompt_operation_id,
  result:
    Started { safe_output_started_boundary: AcousticTemporalEvidence } |
    CompletedAssumed { terminal_evidence: AcousticTemporalEvidence,
      prior_started_event_ref? } |
    DefinitelyNotApplied { failure, safe_non_application_boundary } |
    Cancelled { cancellation_evidence,
      application_evidence: DefinitelyNotApplied(boundary) |
        MayHaveStarted(prior_started_event_ref?) } |
    Failed { failure, may_have_started,
      prior_started_event_ref?, safe_non_application_boundary? } |
    OutcomeUnknown { failure, last_evidence? }
}
```

prompt intentやqueue時刻をguard開始境界にしません。direct result単独では分岐せず、prior progressとquery resultを含む`SD-RUL-ACO-012`のtotal partitionだけがG、bypass、typed close、custodyを決めます。

### SD-EVT-ACO-005 — AcousticGuardBoundaryElapsed

```text
AcousticGuardBoundaryElapsed {
  execution: ExecutionCorrelation,
  session_id, boundary_ref, source_epoch,
  elapsed_mark: AcousticTemporalEvidence,
  result: Elapsed | Failed | OutcomeUnknown
}
```

session受理時にpinした境界についてのClock Port結果です。Rule／Transitionがclockを読みません。Elapsed前のqueue時間をguard経過として扱いません。

### SD-EVT-ACO-006 — VoiceControlCandidateObserved

```text
VoiceControlCandidateObserved {
  event_id, candidate_id,
  candidate: Home | Stop,
  source_span_ref, source_epoch,
  observed_interval: AcousticTemporalEvidence,
  target_interaction_hint?,
  overlapping_playback_occurrence_ids,
  adapter_observation_ref
}
```

候補EventであってCommandではありません。`target_interaction_hint`はsource Adapterが観測した非権威のhint/evidenceにすぎず、Cancel targetでもfallbackでもありません。AdapterはHome／Stop候補を返せますが、Stop抑止、Cancellation target、Home受理を決定しません。

### SD-EVT-ACO-007 — AcousticDecisionRecorded

```text
AcousticDecisionRecorded =
  WakeAccepted { session_id, candidate_id, pinned_revisions } |
  InputDiscarded { session_id?, candidate_or_span_id, reason } |
  RetainedSelectionFinalized { session_id,
    selected_history_window, immutable_history_end_cursor,
    post_wake_collection_interval,
    retained_selections_digest, cardinality: Zero | NonEmpty } |
  PromptOutcomeClassified { session_id, prompt_occurrence_id,
    partition, issuer_event_refs, terminal_action } |
  SourceRecovered { session_id?, prior_epoch, new_epoch, consequence } |
  CommandCommitted { session_id, stable_submit_interaction_id,
    canonical_text_digest } |
  EmptyCommandRecorded { session_id, reason } |
  VoiceHomeForwarded { candidate_id, stable_home_command_id } |
  VoiceStopSuppressed { candidate_id, playback_occurrence_id,
    stop_policy_version, matched_registered_term: true } |
  VoiceStopForwarded { candidate_id, exact_interaction_id,
    target_basis: PlaybackExecutionSubject { playback_occurrence_id } |
      InteractionOwnerReadView { interaction_state_revision,
        eligible_set_digest },
    stable_cancel_command_id, cancel_reason, target_evidence_digest } |
  VoiceStopNoCancellableInteraction { candidate_id,
    interaction_state_revision, eligible_set_digest } |
  VoiceControlInvariantViolation { candidate_id, violation,
    evidence_digest } |
  VoiceControlConflict { candidate_id, existing_payload_fingerprint,
    conflicting_payload_fingerprint } |
  VoiceControlTemporalUnknown { candidate_id, possible_playback_ids,
    evidence_digest, reason, pinned_stop_policy_version } |
  AcousticRecoveryRequired { session_id, occurrence_id,
    recovery_reason, custody_ref? } |
  AcousticSessionClosed { session_id, terminal_reason }
```

Acoustic ownerの確定事実です。`VoiceStopSuppressed`は利用者発話と自己音声を識別した事実を持ちません。`VoiceStopForwarded`の`exact_interaction_id`は後続のEvent、ledger、outbox、`SD-CMD-INT-001 CancelRequested.interaction_id`まで不変です。`VoiceStopNoCancellableInteraction`は「現在対象」を作らないno-effectの確定事実です。`CommandCommitted`はInteraction admission、Conversation開始、LLM実行を意味せず、同じstable Commandをoutboxへ確定した事実です。

## Policy、Rule、Decision、Transition

### SD-POL-ACO-001 — AcousticSessionPolicy

version付き閉じたPolicyとして、one-wake-one-command、pre-roll selection rule、prompt content ref、prompt discard rule、guard boundary profile ref、empty normalization、late／duplicate／reconnect classification、session close ruleを持ちます。具体の長さ、buffer方式、flush、transport、source製品名はPolicy型へ直書きせず、実測済みsource profileのopaque value refとしてpinします。未計測profileをrelease-readyとしません。

### SD-POL-ACO-002 — StopSuppressionPolicy

```text
StopSuppressionPolicyRecord {
  version, registered_stop_terms: NonEmptySet<CanonicalTerm>,
  normalization_rule_version,
  active_during: ExactSpeechPlaybackOccurrence,
  decision: SuppressWhenCanonicalResponseContainsAnyRegisteredTerm
}
```

回答全文と登録語を同じnormalization ruleで比較します。一語でも含めば、candidateが利用者由来でも自己音声でも抑止します。含まれなければStop候補をCancellationへ渡します。Web Home／Cancelと音声HomeはこのPolicyの入力ではありません。

### SD-POL-ACO-003 — AcousticTemporalAmbiguityPolicy

common clock evidenceが比較不能ならexact overlap／non-overlapを主張しません。normal wakeがowned prompt／playbackと重なり得る場合は`TemporalOverlapUnknown`としてdiscardし、sessionを作りません。Stopがactiveまたはlate-owned playbackと重なり得る場合は`VoiceControlTemporalUnknown`をdurable auditへ記録し、音声Cancelを推測生成しません。Web Home／Cancelと音声Homeは常に生存します。typed unknownを`VoiceStopSuppressed`または「利用者発話」として記録しません。

### SD-RUL-ACO-001 — DecideWakeAcceptance

`AcousticState`、`WakeCandidateObserved`、pin可能なPolicy/source profile view、`SpeechAcousticBindingView`をpureに評価し、`AcceptWake | DiscardWake(reason)`を返します。重複、open session中、stale epoch、owned prompt／speech playback intervalと重なる通常wakeはdiscardします。再生結果がすでにTerminalでもcandidate観測intervalが再生intervalに重なるlate bufferを同じ理由でdiscardします。重なりは`SD-MOD-ACO-003`の比較可能なexact occurrence intervalで検証し、比較不能で重なり得る候補は`SD-POL-ACO-003`へ従います。accepted candidate一件からsession一件だけを作ります。

### SD-RUL-ACO-002 — DecideAcousticSpanDisposition

exact session、source epoch、`SD-RUL-ACO-008`が固定したhistorical window、`SD-RUL-ACO-011`のpost-wake collection interval、prompt occurrence、guard boundary、`AcousticSourceObserved`をpureに評価し、`RetainSubrange | DiscardSubrange(reason) | RejectStale | TemporalUnknown`を返します。pre-wake historyをpost-wakeへ延長せず、prompt／guardと重なるsubrangeだけをdiscardし、guard後の最初の実発話全体またはguardを跨いだsuffixを保持します。

### SD-RUL-ACO-003 — DecideOneWakeCommand

guard Elapsed、finalized history/collectionからretain済みsubrange集合、exact transcript result、session／Policy revisionsをpureに評価し、次の閉じたDecisionを返します。

```text
OneWakeCommandDecision =
  CommitSubmitInteraction { stable_command_id, canonical_text,
    payload_fingerprint } |
  CloseEmpty { stable_home_command_id, empty_reason } |
  RequireRecovery { reason } |
  RejectLateOrDuplicate
```

空白／promptだけ／空結果は`CloseEmpty`です。`CommitSubmitInteraction`は一session最大一件で、以後のspan／transcript結果をdiscardします。空またはRecovery中にLLM、body Effect、第二Interactionを作りません。利用者通知は別Notification Policyの寄与であり、このDecisionへ埋め込みません。

### SD-RUL-ACO-004 — DecideVoiceControlCandidate

Homeはplayback binding、Interaction view、Adapter hint、Stop Policyを読まず常に`ForwardHome`へ進めます。Stopは候補のobserved intervalに重なるexact speech playback occurrenceを最大一件に検証し、次のclosed Decisionのexact一つをpureに返します。

```text
VoiceControlDecision =
  ForwardHome { stable_home_command_id } |
  SuppressStop { playback_occurrence_id, stop_policy_version,
    evidence_digest } |
  ForwardCancel { exact_interaction_id,
    reason: VoiceStopDuringOwnedPlayback | VoiceStopOutsideOwnedPlayback,
    target_basis, target_evidence_digest,
    stable_cancel_command_id,
    cancel_command_payload: CancelRequested {
      interaction_id: exact_interaction_id,
      source: VoiceControl,
      requested_event_id: candidate.event_id
    } } |
  NoCancellableInteraction { interaction_state_revision,
    eligible_set_digest } |
  TemporalUnknown { possible_playback_ids, evidence_digest,
    reason, pinned_stop_policy_version } |
  InvariantViolationRequireRecovery { violation, evidence_digest }
```

exact playbackが一件ある場合は、immutable `SpeechAcousticBindingView.execution_subject`から導出した`exact_interaction_id`だけをtargetにします。subjectがInteractionでない、subject／occurrence／correlationのInteractionが不一致、または存在する`target_interaction_hint`が導出targetと不一致なら`InvariantViolationRequireRecovery`です。全文に登録Stop語があれば`SuppressStop`、なければそのexact IDを持つ`ForwardCancel`です。

exact playbackがないStopは、同一revisionの`CancellableInteractionReadView`から`Admitted | Running`かつ取消未記録のexact ID集合を作ります。cardinalityが一件で、存在する`target_interaction_hint`もそのIDと一致する場合だけ、そのIDを`ForwardCancel`へpinします。0件かつhint absenceなら`NoCancellableInteraction`としてCommandを作りません。複数件、重複ID、矛盾lifecycle、revision／digest不整合、0件なのにhintあり、exact-oneとhint不一致は`InvariantViolationRequireRecovery`です。Adapter hintが集合選択を上書きせず、0件または複数件を一件へ狭めません。

overlapping playbackにbinding欠落、Policy version欠落、複数overlap、normalization不一致があれば`InvariantViolationRequireRecovery`だけを返し、比較不能なtemporal evidenceなら`TemporalUnknown`だけを返し、推測で抑止／Cancelを作りません。この状態はspeech occurrence登録時に拒否すべき整合性違反であり、Web Home／Cancelと音声Homeは引き続き共通境界から受理します。

candidateをRuleが読む時点でplaybackがTerminalでも、candidateの`observed_interval`がimmutable playback interval evidenceに重なるなら「再生中に得た候補」として同じpin済みbindingで判定します。現在lifecycleだけを見てlate candidateを通常wake／unsuppressed Stopへ昇格しません。一度commitしたDecisionのreplay、outbox再公開、late result、cancelとのraceでは保存済みexact targetを使い、更新後のInteraction read viewから別の「current」を再選択しません。

### SD-RUL-ACO-005 — ValidateSpeechAcousticBinding

final response canonicalization結果、planned `PlayNonStreamingSpeech` occurrence、current Acoustic stop Policy view、Execution expected revisionをpureに検証します。canonical回答全文、exact occurrence、Stop Policy version、同じnormalization rule version、および`InteractionExecutionSubject`から導出したexact Interaction IDが`PlannedEffectSpec`へ固定される場合だけGraph登録を許可します。Management／Acoustic subject、subject／payload／correlationのInteraction不一致、空の全文、mutable refだけ、current-version lookup、別occurrence binding、dispatch後bindingを拒否します。

### SD-RUL-ACO-006 — DecideAcousticRecovery

exact session／occurrence／attempt、source epoch、terminal query/reconcile evidence、late/duplicate inbox結果をpureに評価し、`DefinitelyApplied | DefinitelyNotApplied | Quarantine`を返します。確定不能を成功／空命令／未実行へ昇格せず、同じsource operationをblind retryしません。reconnectは旧sessionを新epochへ付け替えず、旧sessionの残余をdiscardして`SourceRecovered`またはQuarantineを確定します。

### SD-EVT-ACO-008 — AcousticPolicyRevisionRegistered

```text
AcousticPolicyRevisionRegistered {
  event_id, configuration_application_id,
  acoustic_policy_version, stop_policy_version,
  normalization_rule_version,
  profile_value_refs, expected_prior_revision,
  activation: NextSessionAndNextSpeechOccurrence
}
```

Acoustic ownerがPolicy revisionを登録した事実です。active sessionまたは既存speech occurrenceへ遡及適用したことを意味しません。数値、Stop語本文、secretを通常Projectionへ含めません。

### SD-RUL-ACO-007 — ValidateAcousticPolicyRevision

型検証済みconfiguration application、expected Acoustic revision、versionの単調性、Stop語集合、normalization rule、profile value refsをpureに検証し、`RegisterPolicyRevision | RejectPolicyRevision`を返します。未計測profileをrelease-readyへ昇格せず、既存versionの異payload、active session／speech bindingのpin変更、製品名によるCore分岐を拒否します。

### SD-RUL-ACO-008 — DecidePreRollSelection

pin済みpre-roll profile、`wake_anchor_cursor`、`SessionOpened.available_history_window/cursor_at_open`、同じschema/domain/epoch/profileのtemporal evidenceをpureに評価し、`SelectHistory { selected_history_window, immutable_history_end_cursor=wake_anchor_cursor, decision_digest } | SelectionUnavailable | TemporalRelationUnknown`を返します。historyはavailable historyとのintersectionで`[.., wake_anchor_cursor)`に限定し、post-wake collection cursorを混入しません。

### SD-RUL-ACO-009 — BuildAcousticGraphContribution

Acoustic owner Event、exact session pins、現在のimmutable Graph digestをpureに評価し`SD-MOD-ACO-002`の一variantまたは`NoContribution`を返します。wake時はO／Pとそのdeadlineだけです。`SD-RUL-ACO-012.SafeGuardIssuer/DefiniteBypass`後にG、immutable historyとfinalized post-wake intervalとnon-empty retained selections確定後にT、zeroならTなしでC、TypedCloseFailure/CustodyQuarantineならTなしでC/recovery、T／command／empty／failureのterminal fact後にCを作ります。

### SD-RUL-ACO-010 — DecideAcousticOccurrenceWinner

O／P／G／T／Cまたはquery/cancelのresult、deadline、revocation、cancel result、inbox identityをpureに競合判定し、`AcceptCanonicalResult | DeadlineWon | CancellationConfirmed | RequireQuery | Quarantine | IgnoreLateDuplicate | Conflict`を返します。success/failure/timeout/cancel/OutcomeUnknownの一terminal winnerだけを許可し、deadline後のlate successを現在sessionへ適用しません。OutcomeUnknown、crash後intent、unsupported cancelはsuccess／failureへ推測せずquery/custodyへ移します。

### SD-RUL-ACO-011 — DecidePostWakeCollection

`wake_anchor_cursor`、immutable selected history、current post-wake collection interval、Span／CollectionBoundary observations、prompt／guard interval evidence、pin済みcollection profileをpureに評価します。`AdvanceObservedThrough | RetainSubrange | DiscardSubrange | FinalizeCollection | TemporalRelationUnknown`を返し、historical windowを変更しません。prompt／guardと重なるcursor subrangeだけをdiscardし、guard境界を跨ぐSpeechCandidateではguard後suffixを`PostWakeCollection`としてretainします。finalized endはwake anchor以上、observed-through以下で一度だけ固定します。

### SD-RUL-ACO-012 — ClassifyWakePromptOutcome

exact Pのdirect progress/result、`SD-EVT-ACO-011` query result、`SD-EVT-ACO-013` cancel result、prior Started evidence、common temporal pinsをpureに評価し、次の四variantのexact一つだけを返します。

| Legal evidence | Exact partition |
| --- | --- |
| direct/query `Started`、`TerminalAfterStart`、またはCompleted/Failed/Cancelled/OutcomeUnknown/StillUnknown/QueryFailed/QueryOutcomeUnknownにvalid prior Startedあり | `SafeGuardIssuer { boundary, issuer_event_ref, prompt_terminal: Known | QueryCustody }` |
| direct/query `DefinitelyNotApplied`、Failed `may_have_started=false`かつsafe non-application boundary、CancelledのDefinitelyNotApplied | `DefiniteBypass { source_open_boundary, issuer_event_ref }` |
| CompletedAssumedにprior Startedなし、TerminalWithoutStart、Failed `may_have_started=true`でprior Startedなし、Cancelled MayHaveStartedでprior Startedなし、malformed false-without-boundary | `TypedCloseFailure { reason, terminal_evidence }` |
| direct OutcomeUnknown、StillUnknown、QueryFailed／QueryOutcomeUnknown、cancel OutcomeUnknownのうちusable prior Startedなし | `CustodyQuarantine { custody_ref, query_state, reason }` |

同じevidenceを二variantへ入れず、incomparable boundaryはsafe issuerへ昇格しません。`SafeGuardIssuer`はGを許可しますが`QueryCustody`ならP output leaseのquery／quarantineを別途終端します。`TypedCloseFailure`はT／Commandを作らずCをmaterializeします。`CustodyQuarantine`はP leaseをcustodyへ移し、必要なqueryとCをmaterializeします。全variantはP output leaseをconfirmed terminal releaseまたはquarantineへ、input session leaseをC confirmed closeまたはC custody quarantineへ必ず終端させます。

### SD-EVT-ACO-009 — AcousticOperationDeadlineElapsed

O／P／G／T／Cまたはquery/cancelのexact operation、pin済みbounded deadline ref、common clock evidence、`Elapsed | Failed | OutcomeUnknown`を返すClock Port resultです。Elapsedは対象作用が未実行／失敗した事実ではなく、`SD-RUL-ACO-010`の競合入力です。

### SD-EVT-ACO-010 — AcousticSourceQueryResolved

exact O／T／C operation queryについて`DefinitelyApplied(canonical_result) | DefinitelyNotApplied | StillUnknown`を返します。元operationの成功Eventへ偽装せず、same stable operation／attempt／custody identityを持ちます。

### SD-EVT-ACO-011 — WakePromptQueryResolved

```text
WakePromptQueryResolved =
  Started { safe_output_started_boundary } |
  DefinitelyNotApplied { safe_non_application_boundary } |
  TerminalAfterStart { safe_output_started_boundary,
    terminal_evidence, terminal_kind } |
  TerminalWithoutStart { terminal_evidence, terminal_kind } |
  StillUnknown { last_evidence? } |
  QueryFailed { failure, last_evidence? } |
  QueryOutcomeUnknown { failure, last_evidence? }
```

exact P queryのresultでありpromptを再生しません。このEventのStarted／DefinitelyNotApplied／TerminalAfterStartも`SD-RUL-ACO-012`が検証した場合は正式なguard issuerです。TerminalWithoutStartは開始時刻を捏造せずtyped closeへ、StillUnknown／query failure／query unknownはprior safe Startedがなければcustody quarantineへ進みます。

### SD-EVT-ACO-012 — AcousticSourceCancellationResolved

exact source operation cancelについて`CancellationConfirmed | AlreadyTerminal(canonical_result) | Unsupported | Failed | OutcomeUnknown`を返します。cancel intentを停止成功へ昇格せず、Unsupported／unknownはqueryまたはcustody quarantineへ進めます。

### SD-EVT-ACO-013 — WakePromptCancellationResolved

exact prompt operation cancelについて`CancellationConfirmed(terminal_evidence) | AlreadyTerminal(canonical_result) | Unsupported | Failed | OutcomeUnknown`を返します。開始済み音声の物理消音をcancel intentから推測しません。

### SD-EVT-ACO-014 — VoiceControlProcessed

candidate ID、payload fingerprint、temporal evidence digest、pin済みPolicy、closed Decision、decision Event ID、target resolution basis、exact Interaction IDまたはtyped no-target/invariant、outbox command identity／fingerprintまたはsuppression audit digestを持つAcoustic owner Eventです。`ForwardCancel`では`CancelRequested` payload全体を含むdecision digestへexact targetをpinします。同ID同fingerprint replayは同Event／outbox identityを返し、新規Eventを作らずInteraction viewを再読しません。同ID異fingerprintは`VoiceControlConflict`だけを記録してCommandを出しません。

### SD-TRN-ACO-001 — ApplyWakeAcceptance

`SD-RUL-ACO-001.AcceptWake`をexpected revisionへ適用し、stable session ID、candidate dedupe、source/profile/Policy/schema pins、selection requestを一度登録します。同じUoWで確定payloadだけのinitial O／P／O-deadline／P-deadline GraphをExecution V2へ登録します。G／T／Cを先に作らず、同時open session、同candidateから二session、pinの後付けを拒否します。Effectを直接実行しません。

### SD-TRN-ACO-002 — ApplySourceAndGuardObservation

`SD-RUL-ACO-002`、`SD-RUL-ACO-008`、`SD-RUL-ACO-011`とexact source／prompt／guard observationだけを適用し、immutable historical window、別のpost-wake collection cursor/interval、logical retained subranges、typed discard recordを決定論的に進めます。historyをcollectionで上書きせず、raw bytesをStateへ取り込みません。

### SD-TRN-ACO-003 — ApplyOneWakeCommandDecision

`SD-RUL-ACO-003`のDecisionを一度だけ適用します。Commitならsessionを`CommandCommitted`へ進め、同じstable `SubmitInteraction` Commandをdurable outboxへ記録します。Emptyなら`Empty`と同じstable `ReturnToHomeRequested`を記録します。どちらもclose occurrenceをreadyにし、二件目のCommand、Interaction、LLM/body Effectを作りません。

### SD-TRN-ACO-004 — ApplyVoiceControlDecision

`SD-EVT-ACO-014`とpayload fingerprintをexpected revisionへ適用します。未処理IDならledger、decision Event、`ForwardHome`／exact-target `ForwardCancel`のoutbox、または`SuppressStop`／`NoCancellableInteraction`／typed temporal unknown／invariantのauditを原子的に記録します。TemporalUnknownはevidence digest、reason、判定に使ったPolicy pinを専用`target_resolution` variantへ保存し、Invariantへ畳みません。ForwardCancelのEvent、ledger、outbox、Command payloadのinteraction ID、reason、evidence digestが一致しなければ全体を拒否します。同ID同fingerprintは保存済みEvent／outboxをreplayして新規Commandを作らずtargetを再解決せず、同ID異fingerprintはConflict／QuarantineとしてCommandを作りません。Acoustic session、Execution occurrence、Interaction Stateを直接変更しません。

### SD-TRN-ACO-005 — ApplySourceRecoveryDecision

exact active recoveryだけを、`DefinitelyApplied | DefinitelyNotApplied | Quarantined`の終端へ進めます。旧source epochのlate resultをaudit/discardへ隔離し、新epochの`SourceRecovered`を記録しても旧sessionを再Openしません。Quarantined resourceを再利用可能とせず、別のwake／Interactionを生成しません。

### SD-TRN-ACO-006 — ApplyAcousticPolicyRevision

`SD-RUL-ACO-007.RegisterPolicyRevision`とexact `SD-EVT-ACO-008`だけをexpected revisionへ適用し、両Policy mapとcurrent revisionsを一段進めます。active sessionと登録済みspeech occurrenceのpinは変更しません。同version同payloadはno-op、同version異payloadはConflictです。prompt再生、source Effect、Stop Decisionを実行しません。

### SD-TRN-ACO-007 — ApplyPreRollSelection

`SD-RUL-ACO-008.SelectHistory`とexact `SessionOpened`だけをexpected Acoustic revisionへ適用し、selected historical window、immutable history end、decision digestを一度固定します。post-wake collection startは別fieldへwake anchorを固定し、historyへ追加しません。Adapter observationがavailable history、wake anchor、source epoch、temporal pinsを満たさなければtyped failureへ進めます。

### SD-TRN-ACO-008 — ApplyAcousticOccurrenceWinner

`SD-RUL-ACO-010`のwinnerとPについての`SD-RUL-ACO-012` partitionをexact occurrence／attempt／deadline／cancel identityへ一度適用し、prompt partition、Acoustic lifecycle、terminal fact、recovery custody、late/duplicate auditを進めます。Graph extensionが必要なら`SD-RUL-ACO-009`と`SD-PER-EXE-008`を同じdurable commitへ渡します。terminal O failureはleaseをreleaseし、O success後はC confirmed terminalまでnamed input leaseを保持し、unknownはcustodyへ移してQuarantineします。P outputはconfirmed terminal releaseまたはcustody quarantine、input sessionはC confirmed closeまたはC custody quarantineの一方へ必ず終端します。

## EffectとEffect Graph

### SD-EFX-ACO-001 — OpenAcousticSourceSession

stable source operation ID、session ID、logical source ID、source epoch、source/profile/Policy/temporal-schema pins、requested pre-roll profile ref、`wake_anchor_cursor`、correlationを持ちます。historical selectionやpost-wake endを持たず、raw buffer方式やpathを持ちません。

### SD-EFX-ACO-002 — PlayWakePrompt

exact prompt occurrence、version付きprompt content ref、non-streaming profile binding、safe-start evidence schema/profile pins、correlationを持ちます。初期canonical promptはprofileで「はい」に解決されますが、transcript入力へ加えません。

### SD-EFX-ACO-003 — AwaitAcousticGuardBoundary

safe prompt startまたはDefinitelyNotApplied owner factからpureに導いたabsolute monotonic boundary ref、issuer Event/fact ID、common clock schema/profile pins、session／source epoch、correlationを持ちます。Rule内sleepやwall-clockを要求しません。

### SD-EFX-ACO-004 — TranscribeRetainedAcousticSpans

exact session/source epoch、immutable `selected_history_window`、別のfinalized `post_wake_collection_interval`、Acoustic ownerがretainしたnon-empty `{span_ref, retained_cursor_subrange, origin}`、selection Event/digest、source profile／transcription binding、exact lease continuation、correlationを持ちます。prompt／guard／discard subrangeを含めず、Adapterにretain判断を委ねません。

### SD-EFX-ACO-005 — CloseAcousticSourceSession

exact session/source epoch、stable close operation ID、discard-through cursor、terminal reason、exact named lease continuation fields、correlationを持ちます。flushまたはreconnectを必須方式にせず、Adapterが選んだ方式の結果を`SD-EVT-ACO-003`で返します。

### SD-EFX-ACO-006 — QueryAcousticSourceOperation

OutcomeUnknownとなったexact source operation ID、occurrence／attempt、source epoch、一回限りのstable query ID、correlationを持ちます。open、transcribe、closeを再実行しません。

### SD-EFX-ACO-007 — AwaitAcousticOperationDeadline

target operation/occurrence ID、wakeまたはowner Eventから導出したabsolute common-clock boundary、pin済みbounded budget/profile/schema、stable deadline operation ID、correlationを持ちます。対象作用をcancel／失敗とみなさず`SD-EVT-ACO-009`だけを返します。

### SD-EFX-ACO-008 — QueryWakePromptOperation

OutcomeUnknownとなったexact prompt operation／attempt、started evidenceがあればその境界、一回限りのstable query ID、correlationを持ちます。promptを再生しません。

### SD-EFX-ACO-009 — CancelWakePromptPlayback

Home／Cancel／deadline winnerが指定したexact prompt operation／attempt、stable cancellation ID、reason、bounded deadline、correlationを持ちます。物理消音成功をpayloadに含めません。

### SD-EFX-ACO-010 — CancelAcousticSourceOperation

Home／Cancel／deadline winnerが指定したexact O／T／C operation／attempt、stable cancellation ID、reason、bounded deadline、correlationを持ちます。source closureまたはlease releaseをpayloadから推測しません。

### SD-GPH-ACO-001 — OneWakeOneCommandGraph

```text
OneWakeOneCommandGraph {
  initial_at_WakeAccepted:
    O  OpenAcousticSourceSession
    OD AwaitAcousticOperationDeadline(target=O)
    P  PlayWakePrompt
    PD AwaitAcousticOperationDeadline(target=P)
    O -> P; O -> PD; O/OD compete; P/PD start-boundary compete
    P/PD requires SourceSessionOpened {
      issuer_event = SD-EVT-ACO-003.SessionOpened,
      accepted_by = SD-TRN-ACO-008, fact_id, session_id, source_epoch }

  contribution_after_safe_prompt_boundary:
    AddGuardWait(G, GD)
    G requires GuardIssuerFact {
      issuer_event = SD-EVT-ACO-007.PromptOutcomeClassified,
      partition = SafeGuardIssuer OR DefiniteBypass,
      evidence_event includes SD-EVT-ACO-004 direct result OR
        SD-EVT-ACO-011.Started/TerminalAfterStart/DefinitelyNotApplied,
      source_event_ids, fact_id, evidence_schema/profile pins
    }

  contribution_after_selection_and_guard:
    GuardBoundaryElapsed issuer = SD-EVT-ACO-005.Elapsed
    RetainedSelectionReady issuer =
      SD-EVT-ACO-007.RetainedSelectionFinalized
    selected_history_window immutable before wake_anchor_cursor
    post_wake_collection_interval finalized independently
    retained_selections non-empty => AddTranscription(T, TD)
    retained_selections empty     => AddClose(C, CD), T absent

  contribution_after_prompt_partition:
    TypedCloseFailure => AddClose(C, CD), G/T absent
    CustodyQuarantine => AddRecovery(P-query/custody) AND
                         AddClose(C, CD), G/T absent

  contribution_after_terminal_facts:
    T canonical terminal issuer = SD-EVT-ACO-003
    Command/Empty/failure/cancel/recovery issuer = SD-EVT-ACO-007
    exact terminal fact => AddClose(C, CD)

  exact lease:
    O acquires Exclusive(audio.input.session, named=session_id)
    T/C continue { existing_lease_id, resource, mode,
      named_interval_ref=session_id,
      holder_ref=AcousticSessionSubject {
        session_id, wake_candidate_event_id,
        source_epoch, acoustic_generation },
      holder_fact_id=SourceSessionOpened }
    P claims Exclusive(audio.output)
}
```

wake commitで未来のspan/cursorを必要とするT/Cを捏造しません。pre-wake historyはwake anchorでimmutableに閉じ、post-wake collectionを別intervalとして進めます。prompt intentだけではGを作らず、direct/query resultは`SD-RUL-ACO-012`のexact一partitionからのみ寄与します。TypedCloseFailure／CustodyQuarantineも必ずCをmaterializeし、empty branchはTなしで閉じられます。全operation/query/cancelは対応するbounded deadlineを持ちます。

### SD-GPH-ACO-002 — AcousticSourceRecoveryGraph

OutcomeUnknownの元O／T／Cには`QueryAcousticSourceOperation`、Pには`QueryWakePromptOperation`を最大一Occurrenceだけatomic contributionし、各queryにもdeadlineを対応させます。Home／Cancel／deadline winnerでin-flightならexact prompt/source cancellationを一件だけ追加し、結果unknown/unsupportedならqueryへ進めます。確定できなければcustodyと該当leaseをQuarantineし、元operation、prompt、SubmitInteractionを再送しません。Home／Web Cancel自体をRecovery Graphの依存nodeにしません。

## Port、永続化、Projection、Failure、Recovery、proof

### SD-PRT-ACO-001 — AcousticCandidateIngressPort

常時sourceからnormal wake、span／reconnect、Home／Stop候補を対応する`SD-EVT-ACO-*`へ翻訳します。外部schema、model score、buffer pointerをDomain型にせず、stable candidate/event identity、logical source/epoch/cursor、`SD-MOD-ACO-003` evidenceを付けます。外部targetを得た場合も`target_interaction_hint`という非権威evidenceとしてだけ渡し、current Interaction lookup、target選択、wake受理、discard、Stop suppression、Command生成を実装しません。

### SD-PRT-ACO-002 — AcousticSourcePort

open、Acousticが選択／retainしたsubrangeのtranscription、close、exact operation query/cancelを外部sourceへ翻訳し、対応する003/010/012 resultだけを完全なExecution correlation付きで返します。open時はpre-wake available historyだけを観測し、history selection、post-wake collection終端、retain subrangeを決定しません。raw bufferはAdapter operational stateです。

### SD-PRT-ACO-003 — WakePromptPort

`PlayWakePrompt`、exact query/cancelをnon-streaming再生へ翻訳し、対応する004/011/013 resultだけを返します。安全なobservable output start boundaryをcommon temporal schemaで返し、queue/intentをStartedへ昇格しません。prompt wording、session State、discard cursorを所有せず、再生結果からtranscriptを生成しません。

### SD-PRT-ACO-004 — AcousticBoundaryPort

pin済みguard／operation deadline boundaryを待ち、`SD-EVT-ACO-005`または009だけを返します。具体clock、timer、processをCoreへ漏らさず、elapsed前やStarted未受理の時間を消費済みにしません。

### SD-PER-ACO-001 — DurableAcousticBoundary

次を原子的なcommit境界として要求します。

- wake acceptance、Policy/profile/schema use、Acoustic session、initial O/P/deadline Graph／pendingを同じrevisionへ登録する。G/T/Cを未来payloadで登録せず、sessionだけ、Graphだけを残さない。
- historical selection、post-wake collection progress/finalization、retain/discard subranges、`RetainedSelectionFinalized`をAcoustic expected revisionへcommitし、historyを遡及変更しない。
- prompt direct/query/cancel inbox、prior progress、`SD-RUL-ACO-012` exact partition、`PromptOutcomeClassified`、G/C/recovery contribution、P/input lease terminal intentを同時commitし、分類だけまたはlease未終端だけを残さない。
- owner factごとの`SD-RUL-ACO-009` contribution、Acoustic progress、`SD-EVT-EXE-009`、immutable Occurrence/edge/guard/deadlineを`SD-PER-EXE-008`で同時commitする。
- Command／Empty Decision、Acoustic owner Event、session terminal intent、同じstable `SubmitInteraction`または`ReturnToHomeRequested` outboxを同時commitする。crash後は同じCommand identityを再公開し、二Interactionを作らない。
- final speech Graph登録時、`SD-RUL-ACO-005`に適合するcanonical全文／Stop Policy versionをexact `PlayNonStreamingSpeech` planned occurrenceへ固定し、`SD-TRN-EXE-001`と同じExecution commitに保存する。Acoustic Stateへbindingを複製しない。
- final speech Graph登録時、playback occurrenceの`InteractionExecutionSubject`からexact Interaction IDを導出し、planned payload／correlationとの一致を検証する。Management／Acoustic subjectまたは不一致targetを持つspeech occurrenceは登録せず、後のvoice candidateで補完しない。
- Acoustic Policy revision登録はconfiguration application identity、expected revisions、`SD-EVT-ACO-008`、`SD-TRN-ACO-006`を同時commitし、active session／speech occurrenceの既存pinを書き換えない。
- Port resultは`SD-PER-EXE-002`のstable inbox keyで先に保存し、Acoustic／Execution Transitionを同じSnapshot revisionへ適用する。同値duplicateはno-op、異payloadはConflict quarantineとする。

### SD-PER-ACO-002 — DurableVoiceControlDecisionUoW

candidate inbox、full payload fingerprint、temporal evidence digest、pin済みPolicy/binding、playback branchのExecution binding revision/digestまたはplayback外branchのInteraction owner read revision/digest、pure Decision、`SD-EVT-ACO-014`、processed ledger、suppression audit、必要なHome/exact-target Cancel outboxを一つのAcoustic expected-revision commitへ保存します。`ForwardCancel`ではexact Interaction ID、target basis、reason、evidence digest、`CancelRequested` payload fingerprintを全artifactで一致させます。commit前crashは未処理、commit後crashは同じEvent/outbox identityを復元します。同candidate ID同fingerprint replayは保存済み結果を返し、Interaction Stateが変化していてもtargetを再選択しません。同ID異fingerprintはConflict quarantine、outbox未送信はsame stable exact-target commandだけを再公開します。抑止auditは全文／Stop語を保存せずdigestとpinを保存します。0件選択はdurable `NoCancellableInteraction`でoutboxなし、複数／不整合はdurable invariantでoutboxなしです。

### SD-PRJ-ACO-001 — AcousticSessionProjection

session／candidate correlation、logical source/profile/Policy versions、wake受理、immutable historical window、別のpost-wake collection interval、prompt outcome partition、guard、最初のretain subrangeの存在、command commit、discard reason、empty、voice controlの`Forwarded(exact interaction) | Suppressed | NoCancellableInteraction | TemporalUnknown | InvariantViolation`、Recovery／Quarantine、proof gate statusを投影します。raw audio、buffer pointer、canonical回答全文、登録Stop語、secret、transport IDを公開しません。

### SD-FAIL-ACO-001 — AcousticFailure

```text
AcousticFailure =
  SourceUnavailable | SourceEpochMismatch | SelectionUnavailable |
  PromptPlaybackFailed | PromptSafeBoundaryUnavailable |
  PromptOutcomeCustodyQuarantined | GuardBoundaryUnavailable |
  TranscriptionFailed | EmptyCommand | OperationOutcomeUnknown |
  DuplicateOrConflictingResult | LateAfterTerminal |
  PlaybackBindingInvariantViolation | PolicyRevisionUnavailable |
  CancellationTargetInvariantViolation |
  TemporalRelationUnknown | DeadlineElapsed | CancellationFailed |
  GraphContributionConflict | ExecutionV2Unavailable |
  ResourceQuarantined
```

Failure、empty、discard、source recovered、OutcomeUnknownを相互変換しません。結果不明からwake、Interaction、再生成功、source closureを推測しません。

### SD-REC-ACO-001 — AcousticRecovery

| Node | Success／canonical failure | Timeout／OutcomeUnknown／crash after intent | Cancel／late／duplicate | lease terminal |
| --- | --- | --- | --- | --- |
| O | Openedならselectionへ。DefinitelyNotApplied failureならclose不要 | exact source query。StillUnknownはinput custody quarantine | in-flightはexact cancel→query。late same payloadはaudit、conflict隔離 | failure確定はrelease、Openedはsession holderへ継続 |
| P | RUL-ACO-012 Safe/BypassだけG。TypedCloseFailureはTなしC | direct unknownはexact query、同prompt再生なし。query unknownはP custody quarantineとC | cancelも同じtotal partition。late/duplicateはwinner後audit | canonical terminalでoutput release、unknownはoutput quarantine。全branchでinputはC close/quarantine |
| G | Elapsedならselection/spansを評価。Failedはclose failure reason | deadline/OutcomeUnknownはtyped unknownとしてCをmaterialize、first speechを未観測扱いで捨てない | revoke後late Elapsedはaudit、同値duplicate no-op | timer leaseはwinnerでrelease |
| T | Transcript/Empty/Failed fact後にCommand/Empty/C | exact source query、blind re-transcribeなし。StillUnknownはinput custody quarantine | exact cancel→query。late canonical resultはterminal winner後適用しない | input named leaseはCまで継続、unknown quarantine |
| C | SessionClosedでClosed | exact source query。StillUnknownはsource/input quarantine | cancel unsupported/unknownはquery。late same close no-op、conflict隔離 | confirmed Closedだけrelease、unknown release禁止 |
| query/cancel | canonical resultを元node winnerへ | bounded deadline後StillUnknownならcustody/resource quarantine | duplicate same no-op、conflict隔離 | confirmed terminalだけrelease |

crash後はdurable session、V2 Graph extensions、outbox、inbox、processed ledger、custodyから再構築します。未dispatch occurrenceだけを同じidentityでdispatchでき、intent後作用はblind retryしません。commit途中のGraph contributionは全体なし／全体ありのどちらかで、同じextension ID/digestから再開します。

Home受理またはcancelled Interactionは`ExecutionRevocationTargetV2.AcousticSessionTarget/AcousticOccurrenceTarget`へ四field完全一致のtargetを発行してpending descendantをrevokeし、in-flight source/prompt作用へexact cancelをmaterializeします。RecoveryCustodyRecordV2、ResourceLeaseV2、GraphRecordV2のsubjectも同じ四fieldでなければ接続／releaseせず、停止済みと偽らずclose/query/quarantineへ移管します。Recovery中も音声／Web HomeとWeb Cancelの共通経路を閉じません。

### SD-PRF-ACO-001 — AcousticProfileProofContract

実profile fixtureはsource/profile/Policy/normalization versions、wake candidate、prompt、guard、最初の実発話、retain/discard cursor、command／empty、reconnect、late buffer、実TTS playback occurrence、Stop候補、Web control、結果Eventを相関します。固定無音またはFakeだけで実機条件を合格にしません。

deterministic cursor fixtureは少なくとも次を固定します。`H=[h0,wake)`をimmutable historical selection、`K=[wake,k1)`をpost-wake collection、`P=[p0,p1)`をprompt、`G=[p1,g1)`をguard、first speech `S=[s0,s1)`を`g1 <= s0`として、Hを変更せずP/GだけdiscardしSをretainします。別fixtureで`s0 < g1 < s1`を与え、S全体を捨てず`[g1,s1)` suffixをretainします。両fixtureともT payloadのhistory／collection intervalとretained subrangeがAcoustic Decisionへ一致し、Adapterがwindowを選びません。

prompt partition fixtureはdirect 5 terminal/progress variantsとOutcomeUnknown、query 7 variants、prior Started有無、cancel variantsをcross-productし、各caseがSafeGuardIssuer／DefiniteBypass／TypedCloseFailure／CustodyQuarantineのexact一つ、P output lease terminal、Cによるinput session terminalへ到達することを検証します。

TC70初期releaseは、Stop語あり／なしの回答全文、自己音声、実利用者Stop、同時発話、近似語、遅延bufferを含む実測と、そのevidenceに対するOwner採否を必須release gateにします。数値、採否、passingをこの設計では記入しません。C210はrelease-readyを主張するprofileだけが同じ独立gateを満たし、未達／欠測はC210 profileを非readyにしますがTC70 gateを変更しません。製品名はproof/profile metadataに限定し、Core Policy分岐へ入れません。

voice cancellationのtable fixtureは、(a) playback overlapかつInteraction subject一致、(b) non-Interaction subject、(c) subject／hint不一致、(d) playback外でcancellable 0／1／複数、(e) same candidate replay、(f) decision後に元target terminal＋別Interaction開始、(g) cancel/outbox/late raceを含みます。(a)と(d=1)だけが一件のexact `CancelRequested`を作り、0件は`NoCancellableInteraction`、複数／不整合はtyped invariantとなります。replay／late／raceは保存済みtargetを別のcurrent Interactionへ読み替えず、Homeの全fixtureはtarget解決を通りません。

## 明示的non-goals

- pre-roll／guardの数値、flush／reconnect、source、IPC、process、storage engineの決定
- 実音声から利用者発話と自己音声を確実に識別したという主張
- RTSP resetを唯一の自己ループ防止機構にすること
- continuous conversation、streaming TTS、長時間transcription
- Acoustic Context、source worker、KernelによるConversation／Interaction／WorldState所有
- 実機proof、TC70/C210採否、release-ready、production implementationの主張
