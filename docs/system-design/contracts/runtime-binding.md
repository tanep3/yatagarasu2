# Runtime binding・Profile・readinessのcanonical contract

この契約は、Capabilityごとの`local-managed / remote / disabled`配置、binding generation、fresh readiness、使用中generationの保持、Physical/Quality Profileの唯一Ownerを定めます。横断`Capability Context`は作らず、各Capabilityは自分のStateだけを変更します。Codex app-serverは例外ではなく、既存`SD-CTX-AGT-001`が所有します。

### SD-MOD-RBI-001 — RuntimeBindingAlgebra

```text
CapabilityMode = LocalManaged | Remote | Disabled

SpecificRuntimeState {
  state_revision,
  bindings: Map<BindingGeneration, BindingGenerationRecord>,
  readiness: Map<BindingGeneration, ReadinessObservationRecord>,
  binding_uses: Map<BindingUseId, BindingUseRecord>,
  candidate_slots: Map<CapabilityCandidateSlotKey,
    CapabilityCandidateSlotRecord>,
  candidate_admission_results: Map<CandidateAdmissionIdentity,
    CandidateAdmissionResultRecord>
}

CapabilityCandidateSlotKey {
  capability_ref, mode, adapter_class
}

CapabilityCandidateSlotRecord {
  slot_identity,
  slot_revision,
  cardinality_limit: 1,
  lifecycle:
    Free |
    Held {
      holder_generation,
      named_interval_lease_id,
      acquired_by_event_ref
    } |
    Quarantined {
      holder_generation,
      named_interval_lease_id,
      cleanup_custody_ref,
      terminal_event_ref,
      owner_recovery_or_replacement_policy_required: true
    }
}

CandidateAdmissionResultRecord {
  admission_identity, payload_digest,
  exact_slot_key,
  slot_precondition:
    Absent |
    Existing { expected_slot_revision },
  result: Admitted { generation, event_ref } |
    Busy { holder_generation, holder_lifecycle, event_ref } |
    Quarantined { holder_generation, event_ref } |
    Conflict,
  event_ref
}

BindingGenerationRecord {
  generation, configuration_application_ref,
  mode: CapabilityMode, contract_version,
  candidate_probe_profile_ref,
  candidate_probe_profile_use_ref,
  lifecycle:
    Candidate {
      stage: Planned | MaterializedAwaitingProbe |
        StagedReady {
          configuration_application_id,
          desired_revision, atomic_group_id,
          materialization_event_ref,
          readiness_event_ref,
          readiness_valid_until_mark
        } | Recovery
    } |
    RejectingCleanup {
      configuration_application_id, desired_revision,
      atomic_group_id, configuration_step_id,
      failure_event_refs,
      cleanup_graph_id, cleanup_occurrence_id,
      cleanup_operation_id, cleanup_custody_id,
      stage: Planned | InFlight | Recovery,
      recovery_custody_ref:
        RequiredWhen<Recovery, RecoveryCustodyId>
    } |
    Effective | Retiring | Retired |
    Rejected | OutcomeUnknown | Recovery | Quarantined
}

ReadinessObservationRecord {
  binding_generation, probe_generation,
  observed_mark, valid_until_mark,
  freshness_policy_ref, advertised_contract_version,
  result: Ready | NotConfigured | AuthenticationFailed |
    Incompatible | Unavailable | Disabled | Unsupported
}

BindingUseRecord {
  binding_use_id, binding_generation,
  effect_occurrence_id, dispatch_attempt_id,
  lifecycle: Acquired | ReleasePending | Released | Recovery | Quarantined,
  recovery_custody_ref: RequiredWhen<Recovery | Quarantined, RecoveryCustodyId>,
  release_or_quarantine_evidence_ref?
}
```

`BindingUse`はExecution resource leaseではなく、binding generationを退役させてよいかを示す耐久証拠です。EXEはrefだけを持ちます。Recovery/Quarantinedはexact EXE custodyを必須とし、`SD-PER-EXE-005`がleaseをQuarantinedにしたのにUseだけRecoveryへ残す状態を構築できません。

初期契約のcandidate cardinalityは`CapabilityCandidateSlotKey`ごとに1です。slot identityは`Hash(owner_context_id, capability_ref, mode, adapter_class)`で決定論的に導出し、該当Capabilityのruntime ownerだけがslot mapとrevisionを所有します。release seedまたは認証済みLinux管理者CLIがRCP Profileを登録してもslotを先行生成せず、valid current Passing Profileに対する最初のcandidate admissionだけが`SD-PER-RBI-007`のcompare-not-exists CASで`slot_revision = 0`のHeld slotを原子生成します。

`Candidate.*`、`RejectingCleanup.*`、`OutcomeUnknown`、`Recovery`、RCP use未解放の`Rejected`、および`Quarantined` generationはslotを解放しません。candidateがEffectiveへactivationされるか、安全なRejectedへ終端してRCP useがReleasedとなった場合だけFreeへ戻します。Quarantined slotはmap上の既存entryであり、Absentへ読み替えたり自動解放したりせず、明示Owner recovery/replacement Policyなしに後続candidateを受理しません。

Materialize／Probe成功はcandidateを`StagedReady`にするだけで、`Effective`にはしません。candidate、旧effective generation、CFG effective snapshotの切替は、同じatomic groupの全targetが成功した後に`SD-PER-CFG-004`だけが原子的に行います。

### SD-PRF-RBI-001 — RuntimeCandidateProbeCapabilityProfile

```text
RuntimeCandidateProbeCapabilityProfile {
  profile_identity, profile_revision,
  capability_ref, mode, adapter_class,
  coexistence:
    ParallelCandidateProbeSupported |
    RequiresGlobalRestart,
  candidate_cleanup:
    CleanupRequired { cleanup_contract_ref } |
    NoCleanupRequiredWhen {
      no_artifact_proof_requirement_ref
    },
  candidate_cardinality:
    SingleCandidate |
    ProvenMultiCandidate {
      max_candidates,
      resource_isolation_proof_requirement_ref
    },
  evidence_requirement_ref,
  provenance
}
```

旧effective generationを利用中のままcandidateをmaterialize/probeできるか、materialize後に不採用となったcandidateのcleanup契約、candidate cardinalityと資源分離証明を、Capability／mode／Adapter classごとに宣言する不変・version付きProfile本文です。proof statusとevidence ledgerは本文へ埋め込まず、`SD-CTX-RCP-001`が同じrevision recordとして所有します。`ParallelCandidateProbeSupported`、`NoCleanupRequiredWhen`、`ProvenMultiCandidate`は測定・障害注入を含むevidence requirementを満たすまでrelease-readyではありません。後二者は「Probeが失敗したから実体はない」「別generationだから隔離されている」という推測ではなく、exact evidenceが各proof requirementを満たす場合だけ使えます。

初期releaseはProfileが`ProvenMultiCandidate`でもcardinality 1だけを実装します。将来multi-candidateを導入する場合は、RCP owner上のimmutable cardinality、resource-isolation proof、RevisionUse、Owner採用記録をすべて新revisionとして通し、slot/resource modelと受入条件をversion upしなければなりません。`RequiresGlobalRestart`は欠損値や悲観的な一時fallbackではなく、そのruntime実装の正式能力です。特にsingleton local-managed processの世代共存は実装前spikeで証明し、未証明を暗黙に`ParallelCandidateProbeSupported`として扱いません。

### SD-CTX-RCP-001 — Runtime Candidate Probe Profile Context

`SD-PRF-RBI-001`の不変revision、provenance、proof evidence/status、BindingGenerationごとのRevisionUse、retention/GC lifecycleを唯一所有します。Capability runtime owner、CFG、Adapter、Bootstrap、Projectionは変更しません。

### SD-STA-RCP-001 — RuntimeCandidateProbeProfileState

```text
RuntimeCandidateProbeProfileState {
  state_revision,
  revisions: Map<RuntimeCandidateProbeProfileRevisionRef,
    RuntimeCandidateProbeProfileRevisionRecord>,
  current_by_profile_identity,
  revision_uses: Map<RuntimeCandidateProbeProfileRevisionUseId,
    RuntimeCandidateProbeProfileRevisionUseRecord>,
  ingress_operations: Map<RcpProfileIngressOperationId,
    RcpProfileIngressOperationRecord>,
  applied_seed_artifacts: Map<RcpProfileSeedArtifactId,
    RcpProfileSeedArtifactDigest>
}

RuntimeCandidateProbeProfileRevisionRecord {
  immutable_profile: SD-PRF-RBI-001,
  content_digest, provenance,
  evidence_ledger,
  proof_status: BlockedBySpike | Passing,
  lifecycle: RegisteredCurrent | SupersededRetained |
    GcEligible | GarbageCollected
}

RuntimeCandidateProbeProfileRevisionUseRecord {
  use_id, exact_profile_revision_ref,
  runtime_owner_context_id, capability_ref, binding_generation,
  lifecycle: Acquired | Released,
  terminal_disposition?: Retired | Rejected | Quarantined,
  terminal_event_ref?
}

RcpProfileIngressOperationRecord {
  operation_id, idempotency_key, command_kind,
  authorization_evidence_ref, payload_digest,
  lifecycle: Committed | Rejected,
  committed_event_refs?, rejection_reason?
}
```

profile本文、digest、provenanceは登録後に変更しません。proof evidenceはappend-onlyで、`BlockedBySpike → Passing`だけを許します。Passing後に前提が変わった場合は本文やstatusを巻き戻さず、新しいBlockedBySpike revisionを登録します。RevisionUseがAcquiredのrevisionはSuperseded後も保持し、BindingGenerationがRetired、Rejected、Quarantinedのいずれかへ終端するまでrelease/GCしません。

### SD-MOD-RCP-001 — RuntimeCandidateProbeProfileIngressContract

```text
RcpProfileSeedArtifactManifest {
  seed_artifact_id, seed_schema_version,
  release_or_migration_identity,
  artifact_digest, provenance,
  trust_verification_evidence_ref,
  entries: NonEmptyList<{
    immutable_profile: SD-PRF-RBI-001,
    profile_content_digest,
    requested_initial_proof: BlockedBySpike |
      PassingWithEvidence<RcpProofEvidenceBundle>
  }>
}

RcpProofEvidenceBundle {
  evidence_bundle_id, evidence_schema_version,
  exact_profile_revision_ref, evidence_requirement_ref,
  environment_fingerprint,
  adapter_build_digest,
  measurement_evidence_refs,
  failure_injection_evidence_refs,
  artifact_digests,
  acceptance_ref,
  evidence_bundle_digest
}

RcpProfileIngressAuthorization =
  TrustedReleaseMigrationSeed {
    release_or_migration_manifest_ref,
    verified_seed_artifact_id,
    verified_artifact_digest,
    trust_authority_fact_ref
  } |
  AuthenticatedLinuxAdministrator {
    linux_principal_ref, host_identity_ref,
    authentication_fact_ref, authorization_scope_ref
  }
```

組込みProfileと組込みproofは、version付きrelease/migration seed Artifactからだけ導入します。ローカルProfileの追加とproof再検証は、認証済みLinux管理者Commandからだけ受理します。authorizationは文字列の`source=CLI`やAdapter自己申告ではなく、信頼されたrelease/migration検証境界またはlocal-host認証境界が発行したexact Factで検証します。Web/API、runtime Adapter、Skill、LLM、Bootstrapの直接State変更、通常のProbe成功は登録・proof昇格の入口になりません。

### SD-CMD-RCP-001 — ProvisionRuntimeCandidateProbeProfileSeed

```text
ProvisionRuntimeCandidateProbeProfileSeed {
  operation_id, idempotency_key, expected_rcp_state_revision,
  manifest: RcpProfileSeedArtifactManifest,
  authorization: TrustedReleaseMigrationSeed
}
```

初回setupまたはversion付きmigrationが、検証済みseed manifest全体を一度だけ適用するCommandです。filesystem path、署名material、Adapter DTOをDomain型へ持ち込みません。

### SD-CMD-RCP-002 — AdministerRuntimeCandidateProbeProfile

```text
AdministerRuntimeCandidateProbeProfile {
  operation_id, idempotency_key, expected_rcp_state_revision,
  authorization: AuthenticatedLinuxAdministrator,
  action:
    RegisterBlockedRevision {
      immutable_profile: SD-PRF-RBI-001,
      profile_content_digest, provenance
    } |
    PromoteProof {
      exact_profile_revision_ref,
      evidence: RcpProofEvidenceBundle
    }
}
```

ローカル追加は必ずBlockedBySpikeで登録し、Passingは別の`PromoteProof` Commandと証拠で昇格します。Web/API用token、browser session、Skill grant、runtime Adapter credentialをLinux管理者認証の代用にしません。

### SD-EVT-RCP-001 — RuntimeCandidateProbeProfileRegistered

profile identity/revision、immutable digest、Capability/mode/Adapter class、coexistence、evidence requirement、provenance、initial `BlockedBySpike` statusをRCP ownerが固定したEventです。同じidentity/revision/digestは冪等、異digestはConflictです。

### SD-EVT-RCP-002 — RuntimeCandidateProbeProfileProofPassed

exact profile revision、evidence requirement、採用した測定／障害注入evidence refs、そのdigest、Owner acceptance refを固定し、proofがPassingへ進められる事実を表します。AdapterのReady、Probe成功、自己申告だけから生成しません。

### SD-EVT-RCP-003 — RuntimeCandidateProbeProfileIngressRejected

operation/idempotency identity、command kind、payload digest、`UnauthorizedIngress | InvalidSeedArtifact | InvalidEvidence | RevisionConflict | IdempotencyConflict`の型付きreasonを固定します。既存profile、proof、use、seed ledgerを変更しません。

### SD-EVT-RCP-004 — RuntimeCandidateProbeProfileIngressCommitted

`SeedProvisioned | AdminRevisionRegistered | AdminProofPromoted`、exact operation/idempotency identity、authorization evidence、payload digest、生成した`SD-EVT-RCP-001/002` refsを固定します。Profile登録やproof昇格の代替Eventではなく、入口と原子的commitを監査する相関Eventです。

### SD-RUL-RCP-001 — ValidateRuntimeCandidateProbeProfileRegistration

`SD-RUL-RCP-004`が許可したexact seed entryまたはadmin RegisterBlockedRevisionと、typed profile本文、schema/version、Capability/mode/Adapter class、coexistence、candidate cleanup contract/no-artifact proof requirement、candidate cardinality/resource-isolation proof requirement、evidence requirement、provenance、identity/revision/content digestをpureに検証します。新revisionはBlockedBySpikeで登録し、同じprofile identityのprior currentをSupersededRetainedへ進めます。同一revision同一digestはReplay、異digestはConflictです。許可済みingress correlationなしにRegistration Decisionを返しません。

### SD-RUL-RCP-002 — DecideRuntimeCandidateProbeProfileProofPromotion

`SD-RUL-RCP-004/005`が許可したexact seed Passing entryまたはadmin PromoteProofと、exact RegisteredCurrent revision、BlockedBySpike status、evidence requirement、測定／障害注入evidence、Owner acceptanceをpureに評価し、全条件成立時だけ`PromoteToPassing`を返します。欠損、別revision、stale/Superseded、Adapter自己申告、許可済みingress correlationなしからPassingを返しません。PassingからBlockedへ戻すDecisionはなく、前提変更は新revision登録で表します。

### SD-RUL-RCP-003 — DecideRuntimeCandidateProbeProfileRetention

exact revisionと全RevisionUseをpureに評価します。BindingGeneration登録時はRegisteredCurrentかつPassing revisionだけを`AcquireUse`、そのgenerationがRetired/Rejected/QuarantinedになったOwner Eventがある場合だけ`ReleaseUse`、SupersededRetainedかつ全Use Releasedの場合だけ`MarkGcEligible`を返します。Rejectedでは、M DefinitelyNotApplied、profile/resultが証明したno-artifact、またはcleanup terminal evidenceを持つexact `SD-EVT-RBI-008`を必須にします。`RejectingCleanup`、Effective/Retiring/Recovery/OutcomeUnknown generation、欠損/stale ref、Projection件数からrelease/GCしません。

### SD-RUL-RCP-004 — AuthorizeRuntimeCandidateProbeProfileIngress

Command variant、exact authorization Fact issuer/scope、seed artifact identity/digestまたはLinux principal/host、operation/idempotency key、expected RCP revisionをpureに検証します。seed Commandにはrelease/migration trust Fact、admin Commandにはlocal-host Linux administrator Factだけを許可します。Web/API、Adapter/Skill/LLMの自己申告、kind labelだけのCLI、期限切れまたは別host/scopeのFactは`RejectIngress`です。同じoperation/idempotency/payload digestはReplay、同じidentityの異digestはIdempotencyConflictです。

### SD-RUL-RCP-005 — ValidateRuntimeCandidateProbeProofEvidence

exact profile revision、evidence schema/version、evidence requirement、candidate cleanup/no-artifact proof requirement、candidate cardinality/resource-isolation proof requirement、environment fingerprint、adapter build digest、測定・障害注入Artifact refs/digests、acceptance ref、bundle digestをpureに照合します。seed内Passingにもadmin `PromoteProof`にも同じRuleを適用し、欠損、別revision、改変digest、Adapter Ready/Probe resultだけのbundle、自己署名acceptanceを拒否します。`NoCleanupRequiredWhen`を含むProfileはno-artifact premise、`ProvenMultiCandidate`は宣言cardinality全体の資源分離を証明するfixture/evidenceをbundleに必須とします。検証できるのは証拠の完全性と相関であり、外部測定をRule内で実行しません。

### SD-TRN-RCP-001 — RegisterRuntimeCandidateProbeProfileRevision

`SD-RUL-RCP-001`と`SD-EVT-RCP-001`だけを適用し、不変revision recordをBlockedBySpike/RegisteredCurrentとして登録し、prior currentをSupersededRetainedへ進めます。`SD-PER-RCP-002/003`外では適用せず、Adapter結果、runtime State、CFGを変更しません。

### SD-TRN-RCP-002 — ApplyRuntimeCandidateProbeProfileProofPromotion

`SD-RUL-RCP-002`とexact `SD-EVT-RCP-002`だけを適用し、BlockedBySpikeからPassingへ一度だけ進め、evidence ledgerへ採用evidenceを追記します。`SD-PER-RCP-002/003`外では適用せず、Profile本文、provenance、coexistenceを変更しません。

### SD-TRN-RCP-003 — ApplyRuntimeCandidateProbeProfileRevisionUse

`SD-RUL-RCP-003`に従い、exact BindingGenerationのUseをAcquiredまたはReleasedへ一度進めます。missing/stale/Blocked profileの取得、Retired/Rejected/Quarantined前の解放、別generationのterminal Eventを拒否します。runtime Stateを変更しません。

### SD-TRN-RCP-004 — CollectRuntimeCandidateProbeProfileRevision

SupersededRetained、全Use Released、audit retention成立時だけGcEligibleを経てGarbageCollected tombstoneへ進めます。identity/revision/digest/provenance/evidence summaryは監査用に保持し、Acquired Useのあるrevisionを削除しません。

### SD-TRN-RCP-005 — ApplyRuntimeCandidateProbeProfileIngressRecord

exact `SD-EVT-RCP-003/004`だけをoperation ledgerへ一度適用します。Committedでは生成したprofile/proof Event refsとseed artifact identity/digestを、Rejectedではtyped reasonだけを固定します。Profile/proof本文は`SD-TRN-RCP-001/002`だけが変更し、このTransitionは代行しません。

### SD-PER-RCP-001 — RuntimeCandidateProbeProfileRevisionUseUoW

RCPとCapability固有runtime ownerのexpected revision、exact profile revision/use、binding generationを全CASするRevisionUse componentです。candidate BindingGeneration登録時の`SD-RUL-RCP-003`／`SD-TRN-RCP-003.AcquireUse`は`SD-PER-RBI-007`だけが合成し、generation record、candidate slot Held、BindingChange Graph、NamedInterval slot leaseと同じSnapshot revisionへcommitします。AcquireUse branchは単独commitできません。BindingGenerationがRetired、Rejected、Quarantinedのいずれかへ終端するときだけ、exact owner terminal Eventと`ReleaseUse`を同じretirement/recovery/known-failure/cleanup UoWへcommitします。

一つでもprofile missing、Superseded/stale、BlockedBySpike、candidate slot Busy/Quarantined、revision競合ならcandidate generation登録全体を棄却します。crash後にgenerationだけ、slotだけ、profile useだけ、releaseだけを残しません。同じgeneration/profile/use identityの同値再送はreplay、異payloadはConflictです。Adapter、Bootstrap、ProjectionからこのTransitionへ到達しません。

### SD-PER-RCP-002 — RuntimeCandidateProbeProfileSeedProvisioningUoW

RCP expected revision、exact seed artifact identity/digest、未適用seed、operation/idempotency ledgerを全CASします。`SD-RUL-RCP-004`でrelease/migration trustを検証し、manifest全entryへ`SD-RUL-RCP-001`を、Passing指定entryへ`SD-RUL-RCP-005/002`を適用します。全`SD-EVT-RCP-001`、必要な`SD-EVT-RCP-002`、一つの`SD-EVT-RCP-004.SeedProvisioned`、`SD-TRN-RCP-001/002/005`、seed ledgerを同じSnapshot revisionへcommitします。一entryでも不正・競合なら全体を`SD-EVT-RCP-003`として拒否し、一部Profileや一部Passingを残しません。

初回setupはcandidate計画前にこのUoWを完了します。seed欠落・検証失敗・crash時はRCP未準備のままとし、RestartAdapterを拒否します。同じartifact/operation/idempotency/payload digestは同じcommit結果を返し、同じidentityの異digestはConflictです。Snapshot commit後だけackし、crash後はoperation ledgerから再開してseedを二重適用しません。

### SD-PER-RCP-003 — RuntimeCandidateProbeProfileAdministrationUoW

RCP expected revision、提示されたauthorization evidence、operation/idempotency ledger、exact action payloadを全CASします。`SD-RUL-RCP-004`を必須とし、認証成功時のRegisterBlockedRevisionは`SD-RUL-RCP-001`と`SD-TRN-RCP-001`、PromoteProofは`SD-RUL-RCP-005/002`と`SD-TRN-RCP-002`を、一つの`SD-EVT-RCP-004`と`SD-TRN-RCP-005`とともに同じSnapshot revisionへcommitします。未認証、Web/API由来、別host/scope、Adapter自己申告、証拠不備は`SD-EVT-RCP-003`だけを記録し、Profile/proofを変更しません。

同じoperation/idempotency/payload digestはreplay、同じidentityの異payloadはConflict、terminal後のlate Commandは既存結果を返します。crash後にProfileだけ、Passingだけ、ingress ledgerだけを残さず、Snapshot commit後だけCLIへ結果を返します。

### SD-PRT-RCP-001 — RuntimeCandidateProbeProfileAdministrationIngress

入力境界は、version付きrelease/migration seed verifierとlocal-host Linux administrator CLI Adapterだけを実装として許可します。前者はartifact/manifest digestとtrust Fact、後者はOS認証済みprincipal/host/scope FactをCommandへ変換します。HTTP/Web/API AdapterをこのPortへwireせず、Port実装はProfile/proof Stateを変更せずCommandをapplication境界へ渡すだけです。読取Projectionは別境界で提供できますが、runtime approvalやPassing操作は提供しません。

### SD-MOD-RBI-002 — RuntimeBindingExecutionPayload

```text
RuntimeBindingPlannedPayload =
  MaterializeRuntimeBindingPlan {
    owner_context_id, capability_ref, candidate_generation,
    mode: CapabilityMode, contract_ref, secret_refs,
    stable_operation_id
  } |
  ProbeRuntimeBindingPlan {
    owner_context_id, capability_ref, exact_binding_generation,
    probe_generation, required_api_version, required_capabilities,
    credential_purpose_refs, freshness_policy_ref,
    stable_operation_id
  } |
  CleanupRuntimeBindingCandidatePlan {
    owner_context_id, capability_ref, exact_candidate_generation,
    failed_stage: Probe,
    failure_event_refs,
    cleanup_contract_ref,
    exact_rcp_profile_revision_ref,
    exact_rcp_profile_revision_use_ref,
    cleanup_custody_id,
    stable_operation_id
  } |
  CancelRuntimeBindingChangePlan {
    owner_context_id, capability_ref, exact_binding_generation,
    target_operation_id,
    target_operation_kind: Materialize | CandidateCleanup | Retire,
    cancellation_policy_ref, stable_cancel_operation_id
  } |
  RetireRuntimeBindingPlan {
    owner_context_id, capability_ref, retiring_generation,
    all_binding_uses_released_fact_ref,
    stable_operation_id
  } |
  QueryRuntimeBindingOperationPlan {
    owner_context_id, capability_ref, exact_binding_generation,
    target_operation_id,
    target_operation_kind: Materialize | CandidateCleanup | Cancel | Retire,
    stable_query_operation_id
  } |
  ReconcileRuntimeBindingPlan {
    owner_context_id, capability_ref, exact_binding_generation,
    target_operation_id,
    target_operation_kind: Materialize | CandidateCleanup | Cancel | Retire,
    query_evidence_ref, probe_evidence_refs,
    stable_reconcile_operation_id
  } |
  AwaitRuntimeBindingDeadlinePlan {
    owner_context_id, capability_ref, exact_binding_generation,
    target_operation_id,
    target_operation_kind: Materialize | Probe | CandidateCleanup | Cancel | Retire |
      Query | Reconcile,
    stage, deadline_policy_ref
  } |
  CodexRuntimeProbePlan {
    runtime_generation: CodexAppServerRuntimeGeneration,
    probe_generation, required_protocol, required_schema,
    workspace_binding_ref, freshness_policy_ref
  } |
  CodexRuntimeQueryPlan {
    runtime_generation: CodexAppServerRuntimeGeneration,
    probe_generation,
    exact_target_probe_operation_id
  } |
  CodexRuntimeDeadlinePlan {
    runtime_generation: CodexAppServerRuntimeGeneration,
    target_adapter_operation_id, stage, deadline_policy_ref
  }

RuntimeBindingDispatchPayload =
  MaterializeRuntimeBinding |
  ProbeRuntimeBinding |
  CleanupRuntimeBindingCandidate |
  CancelRuntimeBindingChange |
  RetireRuntimeBinding |
  QueryRuntimeBindingOperation |
  ReconcileRuntimeBinding |
  AwaitRuntimeBindingDeadline |
  CodexRuntimeProbeDispatch {
    exact_runtime_generation, exact_probe_generation,
    required_protocol, required_schema, workspace_binding_ref,
    stable_operation_id
  } |
  CodexRuntimeQueryDispatch {
    exact_runtime_generation, exact_probe_generation,
    exact_target_probe_operation_id, stable_query_operation_id
  } |
  CodexRuntimeDeadlineDispatch {
    exact_runtime_generation, exact_target_adapter_operation_id,
    stage, anchor_mark, duration
  }

RuntimeBindingResultPayload =
  MaterializeRuntimeBindingObserved(SD-EVT-RBI-001.MaterializationObserved) |
  RuntimeReadinessObserved(SD-EVT-RBI-002 payload) |
  RuntimeBindingCandidateCleanupObserved(SD-EVT-RBI-001.CandidateCleanupObserved) |
  RuntimeBindingCancelObserved(SD-EVT-RBI-004.CancellationObserved) |
  RuntimeBindingRetirementObserved(SD-EVT-RBI-001.RetirementObserved) |
  RuntimeBindingQueryObserved(SD-EVT-RBI-004.QueryObserved) |
  RuntimeBindingReconcileObserved(SD-EVT-RBI-004.ReconciliationObserved) |
  CodexRuntimeObserved(SD-EVT-AGT-007 payload) |
  RuntimeBindingDeadlineElapsed {
    owner_context_id, capability_ref, exact_binding_generation,
    exact_target_operation_id, target_operation_kind,
    stage, deadline_policy_ref, observed_mark
  }
```

`SD-EFX-RBI-001`〜`008`と`SD-EFX-AGT-007`〜`008`はこのclosed familyへ全域変換されます。RBI dispatch variantは各`SD-EFX-RBI-*`の同名型そのものであり、Effectを別の汎用operation DTOへ写し替えません。Codex resultはAGT ownerへ、その他はexact runtime ownerへ入り、共通ExecutionやAdapterがreadyまたはcleanup完了を決めません。

| Effect | Planned variant | Dispatch variant | Result variant / owner Event |
| --- | --- | --- | --- |
| `SD-EFX-RBI-001` | `MaterializeRuntimeBindingPlan` | `MaterializeRuntimeBinding` | `MaterializeRuntimeBindingObserved` |
| `SD-EFX-RBI-002` | `ProbeRuntimeBindingPlan` | `ProbeRuntimeBinding` | `RuntimeReadinessObserved` |
| `SD-EFX-RBI-008` | `CleanupRuntimeBindingCandidatePlan` | `CleanupRuntimeBindingCandidate` | `RuntimeBindingCandidateCleanupObserved` |
| `SD-EFX-RBI-003` | `CancelRuntimeBindingChangePlan` | `CancelRuntimeBindingChange` | `RuntimeBindingCancelObserved` |
| `SD-EFX-RBI-004` | `RetireRuntimeBindingPlan` | `RetireRuntimeBinding` | `RuntimeBindingRetirementObserved` |
| `SD-EFX-RBI-005` | `QueryRuntimeBindingOperationPlan` | `QueryRuntimeBindingOperation` | `RuntimeBindingQueryObserved` |
| `SD-EFX-RBI-006` | `ReconcileRuntimeBindingPlan` | `ReconcileRuntimeBinding` | `RuntimeBindingReconcileObserved` |
| `SD-EFX-RBI-007` | `AwaitRuntimeBindingDeadlinePlan` | `AwaitRuntimeBindingDeadline` | `RuntimeBindingDeadlineElapsed` |
| `SD-EFX-AGT-007` | `CodexRuntimeProbePlan` | `CodexRuntimeProbeDispatch` | `CodexRuntimeObserved(ProbeObserved)` |
| `SD-EFX-AGT-008` | `CodexRuntimeQueryPlan` | `CodexRuntimeQueryDispatch` | `CodexRuntimeObserved(ProbeOperationQueryObserved)` |
| Codex probe/query deadline | `CodexRuntimeDeadlinePlan` | `CodexRuntimeDeadlineDispatch` | `RuntimeBindingDeadlineElapsed` |

各dispatch Effectは同名のplanned value全体を`planned: XxxPlan`として埋め込み、claim時にだけ解決できるexact contract/secret/evidence、clock anchor/duration、policy bindingを追加します。したがってplanned fieldを選択的にコピーして落とすconstructorは公開しません。表にない組合せ、Effectとresult variantが一致しない組合せ、RuntimeControl payloadへの変換はcompile時に表現不能とします。

## Capability固有Owner

### SD-CTX-SRC-001 — Source Runtime Context

音声／映像Sourceのbinding、readiness、BindingUseを唯一所有します。

### SD-STA-SRC-001 — SourceRuntimeState

`SpecificRuntimeState<SourceCapability>`です。

### SD-TRN-SRC-001 — ApplySourceRuntimeTransition

Sourceのexact generationに対するbinding/readiness/use/result Eventだけをexpected revisionへ適用します。

### SD-CTX-WAK-001 — Wake Runtime Context

Wakeのbinding、readiness、BindingUseを唯一所有します。

### SD-STA-WAK-001 — WakeRuntimeState

`SpecificRuntimeState<WakeCapability>`です。

### SD-TRN-WAK-001 — ApplyWakeRuntimeTransition

Wakeのexact generationに対するEventだけをexpected revisionへ適用します。

### SD-CTX-STT-001 — STT Runtime Context

STTのbinding、readiness、BindingUseを唯一所有します。

### SD-STA-STT-001 — SttRuntimeState

`SpecificRuntimeState<SttCapability>`です。

### SD-TRN-STT-001 — ApplySttRuntimeTransition

STTのexact generationに対するEventだけをexpected revisionへ適用します。

### SD-CTX-SBR-001 — SBERT Runtime Context

SBERTのbinding、readiness、BindingUseを唯一所有します。

### SD-STA-SBR-001 — SbertRuntimeState

`SpecificRuntimeState<SbertCapability>`です。

### SD-TRN-SBR-001 — ApplySbertRuntimeTransition

SBERTのexact generationに対するEventだけをexpected revisionへ適用します。

### SD-CTX-DEV-001 — Device Runtime Context

camera等のdevice Adapter binding、readiness、BindingUseを唯一所有します。物理結果と姿勢を所有しません。

### SD-STA-DEV-001 — DeviceRuntimeState

`SpecificRuntimeState<DeviceCapability>`です。

### SD-TRN-DEV-001 — ApplyDeviceRuntimeTransition

Deviceのexact generationに対するEventだけをexpected revisionへ適用します。

### SD-CTX-TTS-001 — TTS Runtime Context

TTSのbinding、readiness、BindingUseを唯一所有します。playback occurrenceは所有しません。

### SD-STA-TTS-001 — TtsRuntimeState

`SpecificRuntimeState<TtsCapability>`です。

### SD-TRN-TTS-001 — ApplyTtsRuntimeTransition

TTSのexact generationに対するEventだけをexpected revisionへ適用します。

### SD-CTX-MBP-001 — Memory Provider Runtime Context

SemanticMemory backendのbinding、readiness、BindingUseを唯一所有します。logical Memory recordは所有しません。

### SD-STA-MBP-001 — MemoryProviderRuntimeState

`SpecificRuntimeState<MemoryProviderCapability>`です。

### SD-TRN-MBP-001 — ApplyMemoryProviderRuntimeTransition

Memory backendのexact generationに対するEventだけをexpected revisionへ適用します。

### SD-CTX-PRV-001 — Inference Provider Runtime Context

Hoshikage/Ollama等の非Codex Provider binding、readiness、BindingUseを唯一所有します。Codex app-serverとAgent turnは所有しません。

### SD-STA-PRV-001 — InferenceProviderRuntimeState

`SpecificRuntimeState<InferenceProviderCapability>`です。

### SD-TRN-PRV-001 — ApplyInferenceProviderRuntimeTransition

非Codex Providerのexact generationに対するEventだけをexpected revisionへ適用します。

`SD-TRN-SRC-001`、`SD-TRN-WAK-001`、`SD-TRN-STT-001`、`SD-TRN-SBR-001`、`SD-TRN-DEV-001`、`SD-TRN-TTS-001`、`SD-TRN-MBP-001`、`SD-TRN-PRV-001`は、それぞれのState ownerだけが実行できる唯一mutatorです。各Transitionは`SD-RUL-RBI-005`による`Candidate.MaterializedAwaitingProbe → Candidate.StagedReady`、`SD-RUL-RBI-006`による`Candidate.StagedReady → Effective`／旧`Effective → Retiring`、`SD-RUL-RBI-009`による`Candidate.* → Rejected | RejectingCleanup.Planned`、`SD-RUL-RBI-010`による`RejectingCleanup → Rejected | RejectingCleanup.Recovery | Quarantined`を実装します。activationは`SD-PER-CFG-004`、known failure初期処理は`SD-PER-RBI-005`、cleanup結果は`SD-PER-RBI-006`またはRecovery用`SD-PER-RBI-003`内だけで適用し、Adapter結果取込、単独commitから呼びません。横断Runtime Contextまたは共通RBI Transitionは作りません。

## Profile Owner

### SD-CTX-DPF-001 — Physical Capability Profile Context

`SD-PRF-PHY-001 PhysicalCapabilityProfile`の本文、revision lifecycle、effective device class binding、RevisionUseを唯一所有します。

### SD-STA-DPF-001 — PhysicalCapabilityProfileState

```text
PhysicalCapabilityProfileState {
  revisions: Map<PhysicalCapabilityProfileRevisionRef,
    PhysicalCapabilityProfileRevisionRecord>,
  effective_by_device_class,
  revision_uses
}

PhysicalCapabilityProfileRevisionRecord {
  profile: SD-PRF-PHY-001,
  quality_profile_ref, provenance,
  lifecycle: Candidate | Effective | SupersededRetained | GcEligible
}
```

### SD-TRN-DPF-001 — RegisterPhysicalCapabilityProfileRevision

schema検証済みcandidate revisionを登録します。

### SD-TRN-DPF-002 — ActivatePhysicalCapabilityProfileRevision

QPR readinessとexpected DPF revisionを検証し、exact revisionをdevice classのeffectiveへ進め、旧revisionを`SupersededRetained`にします。

### SD-TRN-DPF-003 — ApplyPhysicalProfileRevisionUse

Camera Graph、Effect、Recoveryのexact RevisionUseをAcquired/Released/Recoveryへ進めます。UseがあるrevisionをGC eligibleにしません。

### SD-CTX-QPR-001 — Quality Profile Context

測定evidence、threshold、hardware/input/profile version、Owner採否、release readinessを唯一所有します。

### SD-STA-QPR-001 — QualityProfileState

```text
QualityProfileState {
  revisions, measurement_evidence,
  readiness_decisions, revision_uses
}
```

### SD-TRN-QPR-001 — ApplyQualityProfileTransition

必須測定、threshold、hardware/input/profile version、Owner採否を純粋に検証し、欠測、未実施、FailureをReadyにしません。RevisionUseがあるrevisionは保持します。

### SD-PER-DPF-001 — PhysicalProfileRevisionUseReleaseUoW

DPF、QPR、EXE、ART、PHYのexpected revisionとexact Camera Graphを全CASし、Graph terminalまたはdurable Recovery責任移管を根拠に`SD-TRN-DPF-003`と`SD-TRN-QPR-001`でProfile/QPR useを同時にReleasedまたはRecoveryへ進めます。片方だけのrelease、Artifact dependentが残るrelease、OutcomeUnknown責任未割当でのreleaseを拒否し、crash後は同じuse IDから再開します。

## Rule・Event・Effect

### SD-RUL-RBI-001 — ValidateFreshRuntimeBinding

exact binding/probe generation、同一clock epochのcurrent mark、`valid_until_mark`、API/contract/credential、広告Capability、modeをpureに検証します。`Disabled`、stale、非互換をReadyにしません。intent commit後のexpiryは既存Effectへ遡及せず、後続claimだけを拒否します。

### SD-RUL-RBI-002 — DecideBindingUseRelease

Occurrence terminalかつexternal result/cancel責任確定なら`Release`、OutcomeUnknownのdurable Recovery移管ならexact custody付き`TransferToRecovery`を返します。RecoveryをReleasedへ読み替えません。custody resolutionがDefinitelyApplied/DefinitelyNotAppliedならReleased、StillUnknownならQuarantinedへ進めるDecisionは`SD-PER-EXE-005`内でだけ採用します。

### SD-RUL-RBI-003 — DecideBindingGenerationDrainCompletion

`Acquired | ReleasePending | Recovery | Quarantined`のUseが一件も残らない場合だけ`LastUseReleased`を返します。Recovery/Quarantinedは解放済みと数えません。

### SD-RUL-RBI-004 — ResolveRuntimeBindingUncertainty

candidate generation、stable operation ID、一回限りのmaterialize/cancel/query/reconcile結果、fresh probeをpureに評価し、StageCandidateReady、KeepCandidateMaterializedAwaitingProbe、KeepPreviousEffective、RetireCandidate、RejectCandidate、QuarantineGenerationを返します。CandidateCleanupの通常結果とQ/R evidenceは`SD-RUL-RBI-010`が専有し、このRuleはcleanup完了を決めません。MaterializeのDefinitelyAppliedとfresh Readyが揃っても`StageCandidateReady`までであり、EffectiveへのDecisionは返しません。OutcomeUnknownからmaterialize/retireや次照会を再生成せず、確定不能ならQuarantineGenerationへ閉じ、旧generationへの自動fallbackも行いません。

### SD-RUL-RBI-005 — ValidateRuntimeBindingCandidateStaging

exact candidate generation、configuration application／desired revision／atomic group、RCP ownerが保持するexact `SD-PRF-RBI-001` revision/use、Passing proof、candidate slot Held/holder generation/NamedInterval lease、MaterializeのDefinitelyApplied、exact generationのfresh Ready、contract／credential／Capability整合、runtime owner revisionをpureに検証します。成立時だけ`StageCandidate`を返し、profile missing/Superseded/stale/Blocked、use欠損、slot/holder/lease不一致、Materialize受付、Probe欠落、stale readiness、別atomic group、Failure／OutcomeUnknownからStagedReadyを作りません。既存effective generationを変更するDecisionは返しません。

### SD-RUL-RBI-006 — ValidateStagedRuntimeCandidateActivation

CFG atomic activation時点のmark、exact `Candidate.StagedReady`、configuration application／desired revision／atomic group、RCP owner上のexact current profile revision/use/Passing proof、candidate slot Held/holder generation/NamedInterval lease、materialization／readiness Event、readiness有効期限、expected previous effective generation、runtime owner revisionをpureに再検証します。成立時だけowner固有Transition用`ActivateStagedCandidateAndReleaseSlot`を返します。profile missing/Superseded/stale/Blocked、use欠損、slot/holder/lease不一致、readiness stale、Recovery、Quarantined、別group、既にEffective、old effective不一致を拒否し、再Probeなしの期限延長や単独activationを許しません。

### SD-RUL-RBI-007 — DecidePostActivationGenerationDrain

`SD-PER-CFG-004`のactivation candidate上で、旧EffectiveからRetiringへ進むexact generationと、そのgenerationに属する全`BindingUseRecord`をpureに評価します。`Acquired | ReleasePending | Recovery | Quarantined`が0件なら`DrainAlreadyComplete`、一件以上なら`AwaitLastUseRelease`を返します。別generationのUse、未commit candidate generation、ProjectionのUse数を根拠にしません。`Quarantined`を解放済みと数えません。

### SD-RUL-RBI-008 — AuthorizeRuntimeCandidateProbeStrategy

exact candidate/profile revision、RCP owner revision/current mapping、apply mode、current effective generation、Capability ownerの全BindingGeneration map、exact `CapabilityCandidateSlotKey`のlookup結果`Absent | Present(record)`、candidate admission identityをpureに評価します。RCP上でprofileがRegisteredCurrent/Passing、そのprofileのcapability/mode/adapter classがexact slot keyと一致し、`RestartAdapter`で`ParallelCandidateProbeSupported`かつproof requirement成立し、全generationに未解放candidateがない場合だけadmissionを許可します。slotがAbsentなら決定論的slot identityとinitial revision 0を持つ`AuthorizeSingleCandidateSlotCreationAndAdmission`、既存slotがFreeならexpected slot revisionを持つ`AuthorizeSingleCandidateAdmission`を返します。RevisionUseはこのDecision後に`SD-PER-RBI-007`でslot/generation/Graphと原子取得するため、未取得をこのRuleが成功扱いしません。

`Candidate.* | RejectingCleanup.* | OutcomeUnknown | Recovery`、RCP use未解放のRejected、またはその他の非終端・未解放candidate generationが一つでもあれば、holder generation/lifecycleを含むtyped `CandidateSlotBusy`を返します。slotまたはholder generationがQuarantinedならtyped `CandidateSlotQuarantined`を返し、明示Owner recovery/replacement Policyなしに後続candidateを許可しません。Quarantined entryをAbsentとしてslot生成Decisionへ進めません。slotがAbsentなのに該当generationが存在する、slotがFreeなのに未解放candidateが存在する、またはHeld holderとgeneration/RCP use/NamedInterval leaseが一致しない場合は`CandidateSlotStateConflict`です。Projection件数を使いません。

初期契約ではProfileのcardinality宣言にかかわらずslot capacityを1として評価します。将来multi-candidateはRCPのversion付きcardinality/resource-isolation proofとOwner採用、slot/resource契約version upなしに許可しません。profile missing/Superseded/stale/Blockedは`ProfileNotReady`、profileとslot keyのcapability/mode/adapter class不一致は`ProfileKeyMismatch`を返し、いずれもslot生成Decisionを返しません。`RequiresGlobalRestart`はtyped `UnsupportedApplyMode`を返して`RestartRuntime`へ自動書換えしません。Ownerがdesired設定で明示的に`RestartRuntime`を選んだ場合だけ、CFGはglobal restart契約へ進めます。

### SD-RUL-RBI-009 — DecideRuntimeBindingCandidateKnownFailure

exact normal BindingChange generation、configuration application／desired revision／atomic group／step、RCP profile/use、M/P Occurrenceとdurable result inboxをpureに評価します。Mが`DefinitelyNotApplied`で`Failed | DefinitelyNotApplied`なら`RejectImmediately(NoMaterializedArtifact)`を返します。MがDefinitelyApplied後のPがfreshな`NotConfigured | AuthenticationFailed | Incompatible | Unavailable | Disabled | Unsupported`を返した場合は、immutable Passing profileが`NoCleanupRequiredWhen`を宣言し、exact P/result evidenceがそのno-artifact proof requirementを満たすときだけ`RejectImmediately(ProfileProvedNoArtifact)`、それ以外は`BeginCandidateCleanup`を返します。

MのPartiallyApplied／OutcomeUnknown、Pの結果欠損・stale・別generation、cancel/recovery中、既にStagedReady/Effective/Rejected/Quarantinedには返しません。これら不明結果はRecoveryへ渡し、既知Failureからfallback、再materialize、Passing取消を導きません。「Pが失敗した」という事実だけをno-artifact proofにしません。

### SD-RUL-RBI-010 — ResolveRuntimeBindingCandidateCleanup

exact `RejectingCleanup` generation、cleanup operation/custody、immutable cleanup profile、`SD-EVT-RBI-001.CandidateCleanupObserved`またはQ/R evidenceをpureに評価します。`Cleaned + DefinitelyApplied`、または`NoArtifact + DefinitelyNotApplied`かつprofileのno-artifact proof requirementを満たす場合だけ`CompleteRejectedAndRelease`を返します。PartiallyCleaned、Failed/OutcomeUnknown、result欠損・別operation・別generationは`TransferCleanupToRecovery`、一回限りのQ/R後も確定不能なら`QuarantineCandidate`です。AdapterのSuccess文字列だけ、Probe failure、deadline経過をcleanup完了に読み替えません。

### SD-EVT-RBI-001 — RuntimeBindingObserved

```text
RuntimeBindingObserved =
  MaterializationObserved {
    owner_context_id, capability_ref, exact_candidate_generation,
    stable_operation_id, mode, advertised_contract_version,
    result: Applied | DefinitelyNotApplied | PartiallyApplied | Failed,
    certainty: DefinitelyApplied | DefinitelyNotApplied | OutcomeUnknown,
    evidence_ref?
  } |
  CandidateCleanupObserved {
    owner_context_id, capability_ref, exact_candidate_generation,
    stable_cleanup_operation_id, cleanup_custody_id,
    cleanup_contract_ref,
    result: Cleaned | NoArtifact | PartiallyCleaned | Failed,
    certainty: DefinitelyApplied | DefinitelyNotApplied | OutcomeUnknown,
    no_artifact_proof_ref?, evidence_ref?
  } |
  RetirementObserved {
    owner_context_id, capability_ref, exact_retiring_generation,
    stable_operation_id, all_binding_uses_released_fact_ref,
    result: Retired | DefinitelyNotApplied | PartiallyApplied | Failed,
    certainty: DefinitelyApplied | DefinitelyNotApplied | OutcomeUnknown,
    evidence_ref?
  }
```

Materialize、candidate cleanup、Retireを同じ成功値へ圧縮せず、exact generationとstable operation/custodyを失いません。`NoArtifact`はimmutable profileが宣言したproof requirementに適合するevidenceを必須にします。

### SD-EVT-RBI-002 — RuntimeReadinessObserved

```text
RuntimeReadinessObserved {
  owner_context_id, capability_ref,
  exact_binding_generation, exact_probe_generation,
  stable_operation_id,
  required_api_version, required_capabilities,
  advertised_api_version, advertised_capabilities,
  credential_readiness,
  observed_mark, valid_until_mark, freshness_policy_ref,
  result: Ready | NotConfigured | AuthenticationFailed |
    Incompatible | Unavailable | Disabled | Unsupported,
  evidence_ref?
}
```

Clock Adapterが返したmarkとprobe resultをowner Contextが受理したEventです。freshnessはRuleが導きます。

### SD-EVT-RBI-003 — AllBindingUsesReleased

Retiring generationのUseが0件になった事実をruntime ownerが一度だけ発行します。activation時点ですでに0件なら`SD-PER-CFG-004`、最後のUse解放で0件になったなら`SD-PER-RBI-001`が、exact Event、Guard Fact、deterministic retirement Graph/Occurrenceを原子commitします。両経路は同じgeneration-derived identityを用い、二重発行しません。

### SD-EVT-RBI-004 — RuntimeBindingRecoveryObserved

```text
RuntimeBindingRecoveryObserved =
  CancellationObserved {
    owner_context_id, capability_ref, exact_binding_generation,
    target_operation_id, target_operation_kind,
    stable_cancel_operation_id,
    result: Cancelled | Unsupported | RejectedStale | Failed,
    certainty: DefinitelyApplied | DefinitelyNotApplied | OutcomeUnknown
  } |
  QueryObserved {
    owner_context_id, capability_ref, exact_binding_generation,
    target_operation_id, target_operation_kind,
    stable_query_operation_id,
    observed_state: NotStarted | InProgress | Applied |
      PartiallyApplied | Retired | Failed | Unknown,
    certainty: DefinitelyApplied | DefinitelyNotApplied | OutcomeUnknown,
    evidence_ref?
  } |
  ReconciliationObserved {
    owner_context_id, capability_ref, exact_binding_generation,
    target_operation_id, target_operation_kind,
    stable_reconcile_operation_id,
    query_evidence_ref, probe_evidence_refs,
    observed_state: NotStarted | Applied | PartiallyApplied |
      Retired | Diverged | Unknown,
    certainty: DefinitelyApplied | DefinitelyNotApplied | OutcomeUnknown,
    evidence_ref?
  }
```

query/reconcile/cancelを別variantにし、effective generationを決めません。

### SD-EVT-RBI-005 — RuntimeBindingRecoveryResolved

exact owner/capability/generation/target operation/custodyについて、`DefinitelyApplied | DefinitelyNotApplied | StillUnknown`と`Release | Quarantine`、採用したquery/cancel/reconcile evidenceを固定したruntime owner Eventです。StillUnknownはQuarantineだけを許します。DefinitelyAppliedはmaterialize/candidate cleanup/retire等の元operation kindと別々に解釈し、旧generation fallbackを意味しません。CandidateCleanupのDefinitelyNotAppliedは、no-artifact proofを伴わなければReleaseを許可しません。

### SD-EVT-RBI-006 — RuntimeBindingCandidateStaged

```text
RuntimeBindingCandidateStaged {
  owner_context_id, capability_ref,
  candidate_generation,
  configuration_application_id,
  desired_revision, atomic_group_id,
  materialization_event_ref,
  readiness_event_ref,
  readiness_valid_until_mark
}
```

Capability固有Runtime ownerがcandidateの準備完了を確定したEventです。有効化、旧generationのretirement、CFG effective snapshot更新を意味しません。

### SD-EVT-RBI-007 — RuntimeBindingGenerationActivated

```text
RuntimeBindingGenerationActivated {
  owner_context_id, capability_ref,
  activated_generation,
  previous_effective_generation?,
  configuration_application_id,
  desired_revision, atomic_group_id
}
```

`SD-PER-CFG-004`でCapability固有owner TransitionとCFG activationが原子的にcommitされたときだけ発行します。Adapter、RBI Graph、RBI Recovery、CFG Transition自身は発行しません。

### SD-EVT-RBI-008 — RuntimeBindingCandidateRejected

```text
RuntimeBindingCandidateRejected {
  owner_context_id, capability_ref, candidate_generation,
  configuration_application_id, desired_revision,
  atomic_group_id, configuration_step_id,
  failed_stage: Materialize | Probe,
  materialization_event_ref?, readiness_event_ref?,
  rejection_reason,
  rcp_profile_revision_use_ref,
  safe_release_basis:
    MaterializeDefinitelyNotApplied |
    ProfileProvedNoArtifact |
    CleanupDefinitelyApplied |
    CleanupDefinitelyNotAppliedWithNoArtifactProof,
  cleanup_resolution_event_ref?,
  preserved_effective_generation?,
  resolution_identity
}
```

通常BindingChangeの確定FailureをCapability固有ownerが安全に`Rejected`へ終端したEventです。old effective generation、CFG effective snapshot、Profile proofの変更を意味しません。M DefinitelyApplied後のP known-negativeでは、profile/resultがno artifactを証明するか、cleanupが確定するまで生成しません。OutcomeUnknown、Adapter受付、Projection推測から生成しません。

### SD-EVT-RBI-009 — RuntimeBindingCandidateCleanupPlanned

```text
RuntimeBindingCandidateCleanupPlanned {
  owner_context_id, capability_ref, candidate_generation,
  configuration_application_id, desired_revision,
  atomic_group_id, configuration_step_id,
  failure_event_refs,
  cleanup_graph_id, cleanup_occurrence_id,
  cleanup_operation_id, cleanup_custody_id,
  cleanup_contract_ref,
  rcp_profile_revision_use_ref,
  preserved_effective_generation?,
  resolution_identity
}
```

M DefinitelyApplied後のP known-negativeを、即時Rejectedではなく明示cleanup lifecycleへ移したowner Eventです。CFG step Failedとcleanup Graph登録の相関を固定し、RCP use解放やcleanup完了を意味しません。

### SD-EVT-RBI-010 — RuntimeBindingCandidateAdmissionResolved

```text
RuntimeBindingCandidateAdmissionResolved =
  CandidateAdmitted {
    admission_identity, payload_digest,
    owner_context_id, capability_ref,
    slot_key,
    slot_precondition:
      Absent |
      Existing { expected_slot_revision },
    committed_slot_identity,
    committed_slot_revision,
    candidate_generation,
    rcp_profile_revision_ref,
    rcp_profile_revision_use_ref,
    binding_change_graph_id,
    candidate_slot_named_interval_lease_id
  } |
  CandidateAdmissionRejected {
    admission_identity, payload_digest,
    owner_context_id, capability_ref,
    slot_key,
    slot_precondition:
      Absent |
      Existing { expected_slot_revision },
    reason:
      CandidateSlotBusy {
        holder_generation, holder_lifecycle
      } |
      CandidateSlotQuarantined {
        holder_generation, terminal_event_ref
      } |
      CandidateSlotStateConflict |
      UnsupportedApplyMode |
      ProfileNotReady |
      ProfileKeyMismatch
  }
```

candidate slot admissionの成功またはtyped Busy/Quarantined拒否をCapability固有ownerが固定します。Rejected variantはcandidate generation、Graph、RCP use、leaseを作ったことを意味しません。

### SD-EFX-RBI-001 — MaterializeRuntimeBinding

```text
MaterializeRuntimeBinding {
  planned: MaterializeRuntimeBindingPlan,
  exact_candidate_generation, exact_contract_ref, exact_secret_refs,
  correlation
}
```

`mode`をAdapter既定値へ落とさない不変Effectです。

### SD-EFX-RBI-002 — ProbeRuntimeBinding

```text
ProbeRuntimeBinding {
  planned: ProbeRuntimeBindingPlan,
  exact_binding_generation, exact_probe_generation,
  exact_contract_ref, exact_credential_refs,
  correlation
}
```

exact generationのhealth、API version、credential readiness、Capability advertisementを要求します。

### SD-EFX-RBI-008 — CleanupRuntimeBindingCandidate

```text
CleanupRuntimeBindingCandidate {
  planned: CleanupRuntimeBindingCandidatePlan,
  exact_candidate_generation,
  exact_cleanup_contract_ref,
  exact_cleanup_custody_id,
  correlation
}
```

materialize済みだが不採用となったcandidateの外部runtimeだけをcleanupする不変Effectです。old effective generationを対象にせず、cleanup結果を成功と仮定しません。Adapterは`CandidateCleanupObserved`を返し、Domain StateやRCP useを変更しません。

### SD-EFX-RBI-003 — CancelRuntimeBindingChange

```text
CancelRuntimeBindingChange {
  planned: CancelRuntimeBindingChangePlan,
  exact_binding_generation,
  exact_target_operation_id,
  exact_cancellation_policy_ref, correlation
}
```

取消対象と取消操作自身のstable IDを分け、Supported/Unsupported/OutcomeUnknownを結果Eventで返します。

### SD-EFX-RBI-004 — RetireRuntimeBinding

```text
RetireRuntimeBinding {
  planned: RetireRuntimeBindingPlan,
  exact_retiring_generation,
  verified_all_binding_uses_released_event_id,
  correlation
}
```

exact `AllBindingUsesReleased` evidenceをEffectへ固定し、満たすRetiring generationだけを退役依頼します。OutcomeUnknownでRetiredを主張しません。

### SD-EFX-RBI-005 — QueryRuntimeBindingOperation

```text
QueryRuntimeBindingOperation {
  planned: QueryRuntimeBindingOperationPlan,
  exact_binding_generation,
  exact_target_operation_id,
  correlation
}
```

materialize、candidate cleanup、cancel、retireのOutcomeUnknownをexact target operation IDで照会します。新しい外部操作を開始しません。

### SD-EFX-RBI-006 — ReconcileRuntimeBinding

```text
ReconcileRuntimeBinding {
  planned: ReconcileRuntimeBindingPlan,
  exact_binding_generation,
  exact_target_operation_id,
  exact_query_event_id, exact_probe_event_ids,
  correlation
}
```

exact query観測とprobe evidenceから、candidate cleanupを含むcandidate/effective/retiring generationの外部状態を検証依頼します。activate、fallback、cleanup完了、retireのDecisionは返しません。

### SD-EFX-RBI-007 — AwaitRuntimeBindingDeadline

```text
AwaitRuntimeBindingDeadline {
  planned: AwaitRuntimeBindingDeadlinePlan,
  exact_binding_generation,
  exact_target_operation_id,
  anchor_mark, duration, exact_deadline_policy_ref, correlation
}
```

stage、anchor、durationをclaim時に固定します。deadlineは未適用を証明せずOutcomeUnknown/Recoveryを生成します。

### SD-PRT-RBI-001 — RuntimeBindingPort

Capability固有Adapterがmaterialize/candidate cleanup/cancel/retire/query/reconcileを実装し、共通`PortResultEnvelope`を返します。横断Capability Serviceではありません。candidate cleanupはexact generation/operation/custodyを受け取り、`Cleaned | NoArtifact | PartiallyCleaned | Failed`とcertainty/evidenceを返します。

### SD-GPH-RBI-001 — RuntimeBindingChangeGraph

```text
RuntimeBindingGraphForm =
  BindingChange {
    M MaterializeRuntimeBinding,
    P ProbeRuntimeBinding,
    C CancelRuntimeBindingChange [cancel path],
    Q QueryRuntimeBindingOperation [OutcomeUnknown],
    R ReconcileRuntimeBinding [query evidence後],
    T RetireRuntimeBinding [old generation drain後],
    D AwaitRuntimeBindingDeadline per external occurrence
  } |
  CandidateCleanup {
    K CleanupRuntimeBindingCandidate,
    Q QueryRuntimeBindingOperation [OutcomeUnknown],
    R ReconcileRuntimeBinding [query evidence後],
    D AwaitRuntimeBindingDeadline per external occurrence
  } |
  FreshProbeOnly {
    P ProbeRuntimeBinding or ProbeCodexAppServerRuntime,
    D AwaitRuntimeBindingDeadline
  }

BindingChange dependencies: P<-M terminal DefinitelyApplied; R<-Q terminal; Tは同じatomic groupのRuntimeBindingGenerationActivated factとAllBindingUsesReleased factでguard
CandidateCleanup dependencies: R<-Q terminal; Kはexact RuntimeBindingCandidateCleanupPlanned owner factでguard
FreshProbeOnly guards: exact target generation and owner-issued probe request fact
resources:
  M/K claim CapabilityGeneration:Exclusive + ContinueNamedIntervalLease(CapabilityCandidateSlot, holder generation)
  P claim CapabilityGeneration:Shared + ContinueNamedIntervalLease(CapabilityCandidateSlot, holder generation)
  Q/R claim CapabilityGeneration + CapabilityCandidateSlot through the same Recovery custody
  C/T claim their exact CapabilityGeneration:Exclusive
```

future factはproducer occurrenceとruntime owner Event kindを宣言します。BindingChangeのcandidate generation/Graph登録は`SD-PER-RBI-007`だけが行い、`SD-RUL-RBI-008`でruntime ownerの全generationとcandidate slotを検査した後、`SD-PER-RCP-001`のRevisionUse取得をgeneration record、slot Held、Graph、NamedInterval slot leaseと同じcommitへ合成します。`ParallelCandidateProbeSupported`かつproof requirement成立、slot Free、未解放candidate不在の場合だけ旧effectiveとcandidateの並行存在を許可します。profile missing/Superseded/stale/Blocked、use取得失敗、slot Busy/Quarantined、`RequiresGlobalRestart`ではgeneration/Graphを作らず、typed rejectionを返し、RestartRuntimeへ暗黙fallbackしません。

M DefinitelyNotAppliedの確定Failureとprofile/resultがno artifactを証明したfailureは、`SD-PER-RBI-005`で即時Rejectedへ安全終端できます。M DefinitelyApplied後のP known-negativeでcleanupが必要な場合は、同UoWがCFG stepをFailedへ進めつつcandidate/RCP useを保持し、次の決定論的identityで`CandidateCleanup` Graph、K Occurrence、pending、exclusive lease/custodyを登録します。

```text
candidate_cleanup_graph_id = Hash(
  owner_context_id, candidate_generation,
  known_failure_resolution_identity,
  "runtime-candidate-cleanup-v1")
candidate_cleanup_operation_id = Hash(
  candidate_cleanup_graph_id, "cleanup")
candidate_cleanup_custody_id = Hash(
  candidate_cleanup_graph_id, "custody")
```

KがDefinitelyApplied、またはDefinitelyNotAppliedと宣言済みno-artifact proofを返した場合だけ`SD-PER-RBI-006`でRejected/RCP use Releasedへ進めます。K OutcomeUnknownまたはdeadline winnerは`SD-PER-EXE-004`で同じcleanup custodyへ責任移管し、Q/Rを各最大一Occurrence・一attemptだけ登録します。Recovery中はcandidateを`RejectingCleanup.Recovery`、candidate slotをHeld、RCP useをAcquired、CapabilityGenerationとNamedInterval slot leaseを同じcustody占有のまま維持します。Q/R後に確定すればReleased、StillUnknownならcandidate/custody/generation lease/slot lease/slotをQuarantinedへ終端してRCP useを`Released(Quarantined)`とします。別candidateのcleanup graph/custody/operation identityを共有しません。

M/Pが正常完了しても`SD-PER-RBI-004`でcandidateをStagedReadyへ進めるだけで、Graph、Adapter、result取込はEffectiveを作りません。通常BindingChangeのOutcomeUnknownまたはdeadline winnerは`SD-PER-EXE-004`でCapabilityGenerationの通常leaseをRecovery custodyへ移し、同じcustodyのQ/C/Rへ各最大一Occurrence・一attemptのprivileged claimを与えます。cancelは未dispatchをrevokeし、in-flight M/TへCを計画しますが、CancelledからDefinitelyNotAppliedを捏造しません。Q/C/Rはcustody自身の旧exclusive leaseにblockされず、他の通常claimは引き続き拒否されます。R後も確定不能ならgenerationとleaseをQuarantinedへ終端し、別mode/generationへfallbackしません。

Q/C/R terminal evidenceは通常BindingChangeでは`SD-RUL-RBI-004`、CandidateCleanupでは`SD-RUL-RBI-010`で評価し、各runtime owner Transitionが`SD-EVT-RBI-005`を導きます。materializeがDefinitelyAppliedと解決しても、fresh probeがあればStagedReady、なければMaterializedAwaitingProbeへ進めるだけです。`SD-PER-RBI-003`がcustody出口を原子commitするまでgeneration/leaseを通常利用へ戻しません。

`FreshProbeOnly`はrestart後のreadiness再確認にも使います。各instanceとP occurrenceはExecution Graphとしてこの契約が所有し、RST Graphのnodeにはしません。非Codex Pは`SD-EFX-RBI-002`、Codex Pは`SD-EFX-AGT-007`を使いますが、どちらも`RuntimeBindingPlannedPayload/DispatchPayload/ResultPayload`へ閉じます。結果Eventとreadiness Stateはそれぞれexact runtime ownerが所有し、RSTはowner-issued Guard Factだけを参照します。

### SD-PRT-RBI-002 — RuntimeProbePort

health/version/readiness Observationだけを返し、ready DecisionとDomain State変更を行いません。

### SD-PER-RBI-001 — FinalBindingUseReleaseAndRetirementUoW

runtime/AGTとEXEのexpected revision、exact Retiring generation、exact BindingUse、terminalまたはRecovery handoff、retirement未登録を全CASします。terminalならUseをReleased、Recovery handoffならexact custody ref付きRecoveryへ進めます。最後のReleased Useならowner State/Event、`AllBindingUsesReleased` Guard Factの`SD-TRN-EXE-007`適用、deterministic retirement Graph/Occurrence/pendingを同一State Snapshot revisionへcommitします。Recovery/Quarantined Useを最後のreleaseと数えず、duplicateでretirement occurrenceを増やしません。

activationと同時に0-useが確定して`SD-PER-CFG-004`が同じretirement identityを登録済みなら、このUoWは既存結果を返します。activationと最後のUse解放が競合した場合は両方がruntime owner/EXE revisionをCASし、勝者だけがgeneration-derived `AllBindingUsesReleased` Event/Graphを登録し、敗者は再読込後に同値replayとします。同じidentityの異payloadはConflictです。

`BindingUseAcquired`は取得元Occurrence自身のready guardに使いません。取得はdispatch claimのCAS結果であり、Factは因果的downstream、retention、recoveryだけが利用できます。

### SD-PER-RBI-002 — NonCodexRuntimeDispatchAcquisitionUoW

SRC/WAK/STT/SBR/DEV/TTS/MBP/PRVのうち対象runtime owner State revision、exact effective generation、fresh readiness observation、retiring/recoveryでないlifecycle、EXE revision、ready occurrenceを全CASします。全て成立した場合だけowner Transitionによる`BindingUse(Acquired)`、immutable runtime bindingを持つdispatch payload、EXE attempt/dispatch intent/outboxを同じSnapshot revisionへcommitします。Resume provenanceがある場合は`SD-PER-EXE-006`を同じUoWへ合成します。一つでも競合・stale・unreadyなら全て棄却し、BindingUseだけ、intentだけ、resume requestだけClaimedを残しません。Codex runtimeは`SD-PER-AGT-001`だけを使用します。

### SD-PER-RBI-003 — RuntimeBindingRecoveryResolutionUoW

exact runtime owner、RCP、EXEのexpected revision、candidate slot revision/holder/NamedInterval lease、capability/generation/target operation/custody、一回限りのQ/C/R terminal inbox、`SD-RUL-RBI-004`またはcleanup用`SD-RUL-RBI-010` Decision、`SD-EVT-RBI-005`を全CASします。owner Transitionによるmaterialize candidateのMaterializedAwaitingProbe／StagedReady／Rejected／Quarantined、candidate cleanupの`RejectingCleanup.Recovery → Rejected | Quarantined`、retirement対象のRetired／Quarantined、同じcustodyを参照する全BindingUseのReleased/Quarantined、terminal generationでの`SD-PER-RCP-001` profile use release、`SD-PER-EXE-005`のcustody Active→Reconciled→ReleasedまたはQuarantined、元/recovery Occurrence終端、全generation/slot lease release/quarantineを同じSnapshot revisionへcommitします。

CandidateCleanupがDefinitelyApplied、またはDefinitelyNotAppliedかつimmutable profile/result proofがno artifactを証明した場合だけ`SD-EVT-RBI-008`、`ReleaseUse(Rejected)`、candidate slot `Held → Free`、NamedInterval slot lease Releasedを生成します。一回限りのQ/R後もStillUnknownならcandidate/custody/generation lease/slot lease/slotをQuarantined、RCP useを`Released(Quarantined)`へ同時終端します。materialize RecoveryからEffectiveへ直接進めず、StillUnknown時にgeneration、BindingUse、profile use、cleanup custody、candidate slotのいずれかだけをRecoveryへ残すことを拒否します。同値duplicateは同じ結果を返し、異payload/late generationを隔離します。

### SD-PER-RBI-004 — RuntimeBindingCandidateStagingUoW

Capability固有runtime owner、RCP、EXEのexpected revision、exact candidate／application／desired revision／atomic group、candidate slot revision/Held holder/NamedInterval lease、pin済み`SD-PRF-RBI-001` revision/use、Passing proof、MaterializeのDefinitelyApplied、exact fresh Probe resultを全CASします。`SD-RUL-RBI-008`がParallelCandidateProbeを許可し、`SD-RUL-RBI-005`が成立した場合だけ、対象ownerの`SD-TRN-*-001`、`SD-EVT-RBI-006`、Materialize／Probe Occurrenceと一時generation leaseの終端を同じSnapshot revisionへcommitします。candidate slot/NamedInterval leaseはStagedReady後もHeld/Activeのまま保持します。既存effective generation、CFG State、旧generation lifecycle、retirement occurrenceは変更しません。一件でもProfile missing/Superseded/stale/Blocked、use欠損、slot/holder/lease不一致、proof未成立、Probe欠落、readiness stale、Failure、OutcomeUnknown、別group、revision競合があれば全棄却し、Staged Eventだけ、candidateだけStagedReadyを残しません。crash後はcandidate generationとresult inbox keyから全体を再開します。

### SD-PER-RBI-005 — RuntimeBindingCandidateKnownFailureUoW

Capability固有runtime owner、RCP、EXE、CFGのexpected revision、candidate slot revision/Held holder/NamedInterval lease、exact candidate／application／desired revision／atomic group／configuration step、M/P result inbox、Graph/Occurrence/lease、pin済みRCP profile/revision useを全CASします。両branchともM/Pのexact terminal化、未dispatch P/Deadline/残余normal occurrenceのrevoke、`SD-TRN-CFG-003`と`SD-EVT-CFG-004.Failed`によるexact step終端を同じSnapshot revisionへcommitし、old effective generationとCFG effective group/snapshotを変更しません。

`SD-RUL-RBI-009.RejectImmediately`では、M DefinitelyNotAppliedまたはimmutable profile/resultのno-artifact proofを根拠に、owner固有Transitionと`SD-EVT-RBI-008`によるcandidate `Rejected`、`SD-RUL-RCP-003`／`SD-TRN-RCP-003.ReleaseUse(Rejected)`、candidate slot `Held → Free`、全normal CapabilityGeneration leaseとNamedInterval slot leaseのreleaseを同じcommitに含めます。

`SD-RUL-RBI-009.BeginCandidateCleanup`ではcandidateを`RejectingCleanup.Planned`へ進め、`SD-EVT-RBI-009`、決定論的`CandidateCleanup` Graph/K Occurrence/pending、cleanup operation/custody、K用exclusive CapabilityGeneration leaseを同じcommitへ登録します。このbranchではcandidate slot HeldとNamedInterval slot lease、RCP RevisionUseをAcquiredのまま保持し、candidate `Rejected`、`SD-EVT-RBI-008`、`ReleaseUse`を生成しません。M/P用generation leaseからK用generation leaseへの切替も同じcommitであり、cleanup custody/slotなしに外部runtimeをorphan化しません。

他targetのStagedReady candidate、RCP profile/proofを変更しません。MのPartiallyApplied/OutcomeUnknown、Pの不明結果、既存recovery custody、別generation/step、stale resultはこのUoWへ入れずRecoveryまたは隔離へ渡します。同じresolution identityと同じpayloadのduplicateは既存結果を返し、異payloadはConflictです。Repeated failed candidateはcandidate generationを含む別cleanup graph/operation/custody identityを持ち、先行candidateのcleanupを再利用しません。

crash後はresolution identityとresult inboxからUoW全体を再実行し、即時branchではcandidateだけRejected、RCP useだけReleased、slotだけFree、CFG stepだけFailed、Occurrenceだけterminal/revoked、leaseだけReleasedを、cleanup branchではCFG stepだけFailed、candidateだけRejectingCleanup、Graph/Kだけ、custody/generation leaseだけ、slot/NamedInterval leaseだけを残しません。Snapshot commit後だけresultをackします。

### SD-PER-RBI-006 — RuntimeBindingCandidateCleanupResolutionUoW

Capability固有runtime owner、RCP、EXEのexpected revision、candidate slot revision/Held holder/NamedInterval lease、exact `RejectingCleanup` generation、cleanup graph/operation/custody、K Occurrence/attempt/result inbox、exclusive generation lease、RCP profile/revision useを全CASします。`SD-RUL-RBI-010.CompleteRejectedAndRelease`では、owner固有Transition、safe basis付き`SD-EVT-RBI-008`、`SD-TRN-RCP-003.ReleaseUse(Rejected)`、candidate slot `Held → Free`、K terminal、cleanup custody/generation lease/NamedInterval slot lease Releasedを同じSnapshot revisionへcommitします。cleanup DefinitelyNotAppliedは、exact resultとimmutable profileがno artifactを証明する場合だけこのbranchへ入れます。

OutcomeUnknown、PartiallyCleaned、deadline winnerでは`SD-PER-EXE-004`を合成し、candidateを`RejectingCleanup.Recovery`、candidate slotをHeld、cleanup custodyをActive、RCP useをAcquiredのまま保ち、generation leaseとNamedInterval slot leaseを同じcustodyへ移管し、そのcustodyのQ/Rを各最大一Occurrence・一attempt登録します。UoWはCFG stepを再適用せず、old effective/snapshotを変更しません。同じcleanup resultのduplicateは同じ結果、異payloadはConflict、K terminal後のlate resultはexact cleanup inboxへ隔離します。

crash後はcleanup operation/custody/result identityから全体を再開し、Rejectedだけ、RCP use releaseだけ、slot Freeだけ、K terminalだけ、custody/generation lease/slot lease releaseだけ、またはRecovery custodyだけを残しません。

### SD-PER-RBI-007 — RuntimeBindingCandidateRegistrationUoW

Capability固有runtime owner、RCP、EXEのexpected revision、runtime ownerの全BindingGeneration map、exact slot keyの`compare-not-exists | existing slot revision`、candidate admission identity/payload digest、current profile identity/revision/current mapping/proofを全CASします。candidate admission resultの同値replayを最初に解決し、既存Admitted/Rejectedならslot lookupを再実行せず同じ結果を返します。`SD-RUL-RBI-008`を必須評価し、許可Decisionの場合だけ、owner固有Transitionと`SD-EVT-RBI-010.CandidateAdmitted`によるcandidate generation登録、`SD-PER-RCP-001`を合成したexact RCP RevisionUse取得、BindingChange Graph/M/P/Deadline Occurrence/pending、`CapabilityCandidateSlot(slot_key)`のgeneration-lifecycle NamedInterval exclusive leaseを同じSnapshot revisionへcommitします。

`AuthorizeSingleCandidateSlotCreationAndAdmission`では、valid current Passing RCP Profileのcapability/mode/adapter classがexact slot keyと一致することを再検証し、Capability runtime ownerのslot mapにkeyが存在しないことをcompare-not-exists CASして、決定論的slot identity、`slot_revision = 0`、lifecycle Heldをcandidate admissionと同じcommitで初めて生成します。`AuthorizeSingleCandidateAdmission`では既存Free slotのexpected revisionをCASしてHeldへ進めます。profile missing/Superseded/stale/Blocked、profile key mismatch、RCP current mapping競合ではAbsent slotを生成しません。release seed/admin CLIはProfileだけを登録し、このUoW以外からslotを作れません。

slot leaseのrelease guardは、candidateがEffectiveへactivationされた同一UoW、またはsafe RejectedとRCP use Releasedが同時成立したUoWだけです。cleanup/Recovery中はleaseを保持し、QuarantinedではleaseとslotをQuarantinedへ進めます。M/P/Kのnormal dispatchはexact holder generationの同じNamedInterval leaseを継続利用し、Q/Rは同leaseとgeneration leaseを同じRecovery custodyのprivileged claimとして保持します。

`CandidateSlotBusy | CandidateSlotQuarantined | CandidateSlotStateConflict | ProfileNotReady | ProfileKeyMismatch`では`SD-EVT-RBI-010.CandidateAdmissionRejected`とadmission resultだけをcommitし、candidate generation、Graph、RCP use、slot、slot leaseを作りません。同じadmission identity/payloadは既存Admitted/Rejected結果を返し、異payloadはConflictです。同じAbsent slotへの異なる並行admissionは同じkeyのcompare-not-exists CASにより一方だけがslot revision 0を生成し、敗者は再評価後にtyped Busyを記録します。slot holder終端とadmissionはruntime owner/slot/RCP/EXE revisionをCASし、一方だけが勝ちます。cleanup terminalが先なら再評価後に新candidateを受理でき、Busy拒否が先ならcleanup側が再試行してslotを解放した後、別の明示admission retryだけを受理します。profile supersedeとadmissionはRCP owner revision/current mappingのCASで一方だけが勝ち、supersedeが先なら旧profileからslotを作らずProfileNotReady、admissionが先ならexact RevisionUseが旧revisionをretention対象として保持します。

crash後はadmission identityから全体を再開し、Absent branchのslot revision 0だけ、generationだけ、slot Heldだけ、RCP useだけ、Graphだけ、NamedInterval leaseだけを残しません。

### SD-REC-RBI-001 — RuntimeBindingRecovery

materialize/candidate cleanup/cancel/retireのOutcomeUnknownをstable operation IDでQ→Rへ照会し、fresh probeとowner Decisionが一致するまでStagedReady/effective/retired/Rejectedを主張しません。materializeがDefinitelyAppliedでもCandidate.MaterializedAwaitingProbeまたはStagedReadyまでで、Effectiveは`SD-PER-CFG-004`だけが作ります。candidate cleanupでは`SD-PER-RBI-003`でcustodyをReleasedまたはQuarantinedへ終端するまで`RejectingCleanup.Recovery`、candidate slot、NamedInterval slot lease、RCP useを保持します。確定不能generationはRecoveryとして新規Useと後続candidate admissionを拒否し、既存Useの責任だけを保持します。自動再送と旧generation fallbackは禁止です。

### SD-PRJ-RBI-001 — RuntimeBindingProjection

Capability固有のmode、generation、lifecycle、Use数、candidate slotのFree/Held/Quarantinedとholder generationを示します。`RejectingCleanup`ではcleanup stage/custody、NamedInterval slot lease、RCP use保持を表示し、RejectedやReleasedへ先取りしません。

### SD-PRJ-RBI-002 — ReadinessProjection

probe generation、fresh/stale、contract version、typed readiness、remedyを示し、secretとendpoint credentialを表示しません。
