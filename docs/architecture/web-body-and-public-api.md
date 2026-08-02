# Web身体面と公開API

## WebもYatagarasuの身体である

Tapoはカメラ、マイク、スピーカー、首を持ちます。Webは文字入力、ボタン、タッチ、画面、画像、映像、成果物、通知を持ちます。Webは管理者用の付属画面ではなく、利用者とYatagarasuを結ぶ双方向の身体面です。

振る舞いは物理デバイスだけ、Webだけ、または両方で成立してよいものです。

```text
Tapo完結       音声会話、相対移動、音声案内
Web完結        テキスト操作、Skill利用、履歴・成果物参照
Hybrid         live映像操作、文字起こし表示、検知通知
```

Webを開くこと、現在状態をQueryすること、画面内を移動することだけではQualiaを開始しません。Web完結Behaviorの開始CommandをPolicyが受理したときに、そのBehaviorがActive Qualiaになります。各browserの表示画面と、Yatagarasu全体のActive Qualiaを同じStateにしません。

## APIが正式境界である

利用者向け能力は公開APIから利用でき、標準Web画面も同じAPIを使います。

```text
標準Web / 利用者HTML / 外部client
  -> 認証された公開API
  -> transportから型付きCommand / Queryへ変換
  -> Rule / Policy
  -> Effect Graph
  -> Adapter
  -> 結果Event / Projection
```

公開APIは内部Effectの直接dispatch、Adapter直接呼出し、WorldState変更を許しません。API schemaは外側のtransport値でありdomain型ではありません。

## 現在状態と更新を同期する

Web接続時は、現在Projectionと単調増加するrevisionを取得し、その後の更新を受け取ります。更新欠落や順序不整合があれば、現在Projectionから再同期します。Web切断はActive Qualiaを終了しません。

Lifecycle、最終結果、Failure、Home／取消結果、ArtifactRefは再接続後も参照できるようにします。一時進捗、未確定文字断片、生media frameを同じ永続Event列へ無制限に保存しません。live映像・音声のtransportは状態更新列と分けられます。

具体的なWebSocket、SSE、polling、media transportと数値budgetは技術検証後に決めます。

## 標準画面と利用者画面

Yatagarasu 2はPCとスマートフォンへ対応した標準Web画面を提供します。利用者は、Yatagarasuが承認した標準Web部品を独自HTML／CSSで配置・装飾できます。

利用者画面は任意JavaScript、Rust、Python、Rule、Effect、API権限を追加しません。標準画面の機能改善と新しいWeb部品はYatagarasu 2のversion updateとして配布します。不正な利用者画面があっても標準画面とHome操作を失いません。

## 一Server、一Workspace、一Owner

初期製品は、一つのServer、一つのWorkspace、一人のOwnerを運用単位にします。管理者と一般利用者を分けません。複数browser、取消可能なaccess token、複数cameraは、同じOwnerとWorkspaceへ属します。

Owner sessionとaccess tokenはYatagarasu APIの認証です。LANやTailscaleは到達範囲を制御します。この二つを同一視しません。初期状態で認証なしにInternetへ直接公開しません。

規範的な条件は[API・Web要件](../requirements/api-and-web-requirements.md)にあります。
