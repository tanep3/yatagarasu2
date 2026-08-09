# 共通Presentation値契約

この文書は、Yatagarasu内部で確定した意味をWeb、文字、音声へ提示するための
共通value shapeを定義します。CameraとConversationはpayload variantを寄与しますが、
配達成否、Projection State、Conversation Stateをこの値へ混ぜません。

```text
ReleasePresentationPayload =
  CameraPresentationPayload |
  ConversationPresentationPayload

Presentation<P> {
  presentation_id,
  output_purpose,
  payload: P,
  evidence_refs,
  allowed_surfaces: NonEmptySet<WebProjection | Text | Voice>,
  policy_version
}
```

`P`はrelease時に閉じた直和型です。CameraとConversationが別々の外枠を定義せず、
同じsurface Policy、Projection revision、publication結果契約を再利用します。
Presentationは外部配達成功の証拠ではありません。
