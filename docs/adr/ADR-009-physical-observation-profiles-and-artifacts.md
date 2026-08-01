# ADR-009: 物理観測、profile、artifactの境界

- Status: Accepted
- Scope: 物理結果、pose、calibration、profile、move/capture/LLM Graph、artifact lifecycle

## Context

要求した相対移動、deviceの校正、capture、LLM入力を、証明済みの物理事実として混同すると安全なRecoveryと説明可能性を失う。

## Decision

物理結果はObserved、Assumed、DefinitelyNotApplied、OutcomeUnknownだけを用いる。相対移動要求はobserved/estimated poseと別に記録し、証拠のないabsolute poseを作らない。calibrationは汎用capabilityであり、Adapter固有の結果Eventを返すが現在poseの証明ではない。

profileの外側schemaは中立にし、dispatch時のimmutable effective profile/versionをEffectとpending recordにcaptureする。`move -> capture -> LLM`はEffect Graphであり、moveのFailure/OutcomeUnknownはcapture/LLMをblockする。capture FailureもLLMをblockし、LLMは有効で適用可能な`ArtifactRef`だけを入力にできる。Assumed後続は明示Policy時だけ許す。resource claimを保持する。Artifact Contextがartifact lifecycleを唯一所有する。

## Non-decision / open

calibrationの証拠水準、現在poseの照合、timing margin、reconciliation、profile候補とProvider routingは未決である。

## Consequences

camera/LLM/TTS Adapter、profile、worker、Provider、Projectionは物理観測、pose、artifact lifecycleを所有しない。実装はprofile不変性、Graph guard、ArtifactRef妥当性、Assumed許可をfixtureで示す。

## Related requirements

REQ-ARC-003、REQ-ARC-006、REQ-PER-001、REQ-PHY-001、REQ-PHY-003。

## Superseded assumptions

凍結01/03の移動完了または校正を現在poseの確定として扱える示唆は、このscopeでは採用しない。
