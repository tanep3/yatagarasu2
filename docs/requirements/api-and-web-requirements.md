# API・Web要件

## 目的

Webを管理画面の付属物ではなくYatagarasuの身体面として扱う。利用者向け能力をAPIから利用可能にし、標準Web画面、利用者が調整した画面、将来の外部クライアントが、Policyや状態所有を迂回せず同じYatagarasuへ接続できるようにする。

### REQ-API-001 — 利用者向け全機能を公開APIから利用可能にする

利用者が音声または標準Web画面から開始、操作、停止、参照、設定できる機能は、認証された公開APIから同じ意味で利用できなければならない。標準Web画面もこの公開APIを使用する。公開APIはCommand、Query、Projection、Event更新、Artifact、設定、Capability発見の境界を提供してよいが、内部Effect、Adapter、WorldState変更、Providerへ直接到達する裏口を提供してはならない。transport schemaはdomain型と分離する。

受入条件:

- AC-API-001: 標準Web画面から行う代表操作が、公開APIのtransport値から、音声等の別Inbound Adapterと同じ型付きCommand境界へ変換される。
- AC-API-002: API適合試験が、内部Effectの直接dispatch、Adapter直接呼出し、WorldStateの直接変更を拒否し、安全・権限・Capability Policyを通過した操作だけを受理する。
- AC-API-003: architecture testが、API request／response schemaを変更または別transportへ交換してもdomain型とRuleの変更を要求せず、domainがWeb frameworkまたはtransport schemaへ依存しないことを示す。

### REQ-API-002 — Webへ現在状態と更新を継続同期する

標準Web画面は、再読込を要求せず、現在のクオリア、Lifecycle、進行、型付き結果、成果物参照、対象deviceの利用状態を継続的に参照できなければならない。接続時は現在のProjectionと単調増加するrevisionを取得し、その後の更新を受け取る。欠落または順序不整合を検出した場合は現在Projectionから再同期する。Web接続の切断はActive Qualiaを終了させない。具体transportと数値遅延は技術検証後に決める。

受入条件:

- AC-API-004: 接続fixtureが現在Projectionとrevisionを取得し、その後のQualia開始、進行、結果、ArtifactRef更新を再読込なしで同じrevision列として受け取る。
- AC-API-005: 更新欠落、順序逆転、切断を模擬するfixtureが、現在Projectionから再同期し、Active Qualiaを取消・再開始せず、重複表示を確定事実として扱わない。
- AC-API-006: lifecycle、最終結果、Failure、Home／取消結果、ArtifactRefは再接続後に参照できる。未確定文字断片、細かな進捗、生media frameを同じ永続Event列へ無制限に保存しない。
- AC-API-007: live映像または音声を提供する構成が、状態更新のrevision列とmedia transportを区別し、一方の切断を他方の物理結果として扱わない。

### REQ-API-003 — 標準Web画面と画面カスタマイズを分離する

製品はPCとスマートフォンへ対応する標準Web画面を提供する。対応するviewport幅、入力方式、必須部品はversion付きUI profileで公開する。標準画面の機能改善はYatagarasu 2のversion updateとして配布する。利用者は承認済みの標準Web部品を独自HTML／CSSで配置・装飾できるが、任意JavaScript、Rust、Python、domain型、Rule、Effect、Adapter、API権限を追加または置換してはならない。エンドユーザーによる振る舞い追加と実行時plugin機構はYatagarasu 2の範囲外とする。

受入条件:

- AC-API-008: UI profileが対応viewportの最小・最大幅、入力方式、必須部品を定義し、その境界値を用いるresponsive UI testが、Home、現在Qualia、主要操作、進行、Failure、成果物を操作または参照できることを示す。
- AC-API-009: 利用者fixtureが独自HTML／CSSから承認済みWeb部品の配置と外観を変更できる一方、新しいCommand種別、API権限、実行コード、振る舞いを導入できない。
- AC-API-010: 不正または非互換な利用者画面を読み込めない場合も、標準Web画面と常設Home操作を利用できる。

### REQ-API-004 — 一つのOwnerを認証し、接続単位のtokenを管理する

初期製品は、一つのYatagarasu Server、一つのWorkspace、一人のOwnerを運用単位とする。管理者と一般利用者を分ける複数利用者RBACは提供しない。Ownerは保存時に平文としない資格情報でWeb sessionを確立でき、外部クライアントには取消可能なaccess tokenを発行できる。tokenは別利用者を表さず、Ownerが許可した接続を表す。LAN内運用を既定とし、外部からの利用はTailscale等の私設network併用を想定する。認証を理由に秘密情報をWeb frontendへ渡してはならない。

受入条件:

- AC-API-011: 未認証fixtureが状態、Artifact、操作、設定APIを利用できず、Owner sessionまたは有効tokenだけが許可範囲のAPIへ到達する。
- AC-API-012: token取消fixtureが新規requestを拒否し、既存のQualia、Workspace、Owner identityを削除または変更しない。
- AC-API-013: setup fixtureが一つのWorkspaceと一人のOwnerを作成し、複数利用者、role、organizationを要求しない。複数browser／token／deviceは同じOwnerとWorkspaceに属する。
- AC-API-014: deployment fixtureが認証なしの直接Internet公開を既定にせず、LANまたは私設networkの到達範囲とYatagarasu認証を別々に診断表示する。

## 技術検証後に決めること

WebSocket、Server-Sent Events、polling、media transport、API versioning方式、revision配信の数値遅延、再接続時間、同時browser数、password session方式、token scopeの細分化、Tailscale identity連携は未決である。
