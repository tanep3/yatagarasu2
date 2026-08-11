# Behavior・推論routeのcanonical contract

振る舞い選択とLLM/Provider route選択は別Decision、別Policy Ownerです。SBERTはCandidate/score/provenanceを返すだけで、State、Policy、effective routeを所有しません。

### SD-CTX-BRP-001 — Behavior Routing Policy Context

SBERT候補、gray zone gate、Contributor構成、候補なし時の`FallbackToConversation`のversion付きPolicyを唯一所有します。Provider/model routeを所有しません。

### SD-STA-BRP-001 — BehaviorRoutingPolicyState

```text
BehaviorRoutingPolicyState {
  state_revision, revisions, effective_revision,
  retained_revision_uses: Map<BehaviorRoutingRevisionUseId,
    RoutingRevisionUseRecord>
}
```

### SD-CTX-IRP-001 — Inference Routing Policy Context

論理Provider/model profile、preferred route、必須`ContextContinuity`、route rejection/no-fallbackのversion付きPolicyを唯一所有します。Behavior選択とruntime binding/readinessを所有しません。

### SD-STA-IRP-001 — InferenceRoutingPolicyState

```text
InferenceRoutingPolicyState {
  state_revision, revisions, effective_revision,
  retained_revision_uses: Map<InferenceRoutingRevisionUseId,
    RoutingRevisionUseRecord>
}

RoutingRevisionUseRecord {
  use_id, exact_policy_revision_ref, interaction_id,
  lifecycle: Acquired | ReleasePending | Released | Recovery,
  recovery_owner_ref?
}
```

### SD-RUL-BRP-001 — ResolveBehaviorRoute

独立制御語の後、宣言ContributorのCandidate、SBERT score/provenance、gray gate、pin済みPolicy revisionをpureに評価し、Selected、Composite、Ambiguous、Rejected、FallbackToConversationを返します。Policy拒否はConversation fallbackで迂回しません。

### SD-RUL-IRP-001 — ResolveInferenceRoute

```text
InferenceRouteDecision =
  Effective {
    preferred_route, exact_same_effective_route,
    policy_revision, binding_generation,
    readiness_observation_generation,
    context_continuity
  } |
  Rejected { preferred_route, reason }
```

pin済みInference Policyが選んだpreferred routeと同じrouteについて、current authorizationとfresh readinessを評価します。別Provider、別model、別mode、旧generationを代替に選びません。route選択のためのLLM requestを作りません。

### SD-TRN-BRP-001 — ApplyBehaviorRoutingPolicyConfiguration

CFG activation候補のexact Policy revisionをexpected BRP revisionへ適用し、旧revisionをretainedにします。既存InteractionのRevisionUseを保持します。

### SD-TRN-BRP-002 — ApplyBehaviorRoutingRevisionUse

exact Policy revisionのInteraction useをAcquired/Released/Recoveryへ進めます。current変更とuse解放を結び付けません。

### SD-TRN-IRP-001 — ApplyInferenceRoutingPolicyConfiguration

CFG activation候補のexact Policy revisionをexpected IRP revisionへ適用し、旧revisionをretainedにします。active turnのrouteをrebindしません。

### SD-TRN-IRP-002 — ApplyInferenceRoutingRevisionUse

exact inference Policy revisionのInteraction useをAcquired/Released/Recoveryへ進めます。Agent turn終端またはRecovery移管前のreleaseを拒否します。

### SD-RUL-RTE-001 — DecideRoutingRevisionUseRelease

Interaction terminal、Agent/Effect terminal、またはdurable Recovery handoffをpureに評価し、BRP/IRP useを同じdispositionへ進められる場合だけRelease/Recovery Decisionを返します。

### SD-PRJ-BRP-001 — BehaviorRoutingProjection

Policy revision、Contributor構成、Candidate、gate、selection/rejection/fallback理由を示します。

### SD-PRJ-IRP-001 — InferenceRoutingProjection

preferred route、effective routeまたは拒否、Policy revision、binding/readiness generation、ContextContinuity、no-fallback理由を示します。secret、endpoint credentialを表示しません。

## no-fallbackと非遡及

次を禁止します。

- `remote -> local-managed`、`local-managed -> remote`の暗黙切替
- Provider/model/profileの代替
- new generation失敗時のold generation再選択
- Codex失敗時のHoshikage/Ollama選択
- `Disabled`からの暗黙復帰
- stale readinessの利用
- Policy拒否のConversation/LLM迂回

新設定の適用が成立するまで旧effectiveを維持することは、代替選択ではなく原子性の保持です。新generation有効化後に利用不能となった場合はtyped Failureを返し、旧generationへ戻しません。
