# ADR-014: API優先のWeb身体面と単一Owner運用

- Status: Accepted
- Scope: 公開API、標準Web画面、継続同期、画面カスタマイズ、認証単位

## Context

Tapo本体で利用者入力に使えるのは主にカメラとマイクであり、音声だけでは機能選択、文字入力、映像・成果物表示、複数device選択、状態確認が不便である。Webを管理画面に限定すると、Yatagarasuの身体と機能拡張を不要に狭める。標準Webだけが非公開経路を使うと、利用者画面や外部clientを安全に交換できない。

## Decision

Webを、文字、タッチ、ボタン、画像、映像、状態、成果物を交換する正式な身体面とする。利用者向け全機能を認証された公開APIから利用可能にし、標準Web画面も同じAPIを使用する。APIは共通Command／Query／Projection／Event更新／Artifact／設定／Capability境界を通し、内部Effect、Adapter、WorldState、Providerへ直接到達させない。transport schemaはdomain型ではない。

標準Web画面はPCとスマートフォンへ対応し、現在Projectionとrevisionを取得した後、Qualia、進行、結果、ArtifactRefの更新を再読込なしで受け取る。欠落時は現在Projectionから再同期する。Web切断はActive Qualiaを終了させない。live media transportは状態更新列と分ける。

エンドユーザーへ許す製品内カスタマイズは、承認済み標準Web部品を使うHTML／CSSの配置と装飾までとする。任意JavaScriptまたはRust／Pythonによる振る舞い追加は許可しない。標準画面の機能改善はYatagarasu 2のversion updateで行う。

初期運用単位は一Server、一Workspace、一Ownerとする。複数利用者RBACを置かず、Owner認証sessionと、read/operateだけを持つ一種類のOwner Web API tokenを提供する。tokenは無期限でrevocable/reissuableであり、別利用者やadmin権限を表さない。Webはplaintext tokenを発行時に一回だけ表示し、以後masked表示にする。認可済みLinux server administrator CLIは、Linux permissionで保護された暗号化・回復可能secret storageからexact tokenを再表示できる。hash-only storageにせず、auditはtoken IDだけを記録する。

tokenはpassword reset、token管理/reveal、secret参照、Capability install、Skill enablement、security変更を許可しない。password resetはlocal Linux CLIだけから行い、新hashを保存して成功を返す前に全session/tokenをdurably revokeする。LAN内利用とTailscale等の私設networkを既定とし、network到達制御をYatagarasu認証と同一視しない。reverse proxyはconfigured trusted proxy、header sanitation、TLSがそろう場合だけ許可する。direct router port-forwardはunsupportedでありdoctorはfail-closed warning/rejectionを返す。

## Consequences

標準WebはAPIの公式client兼適合例となる。利用者は独自HTML／CSSを使えるが、振る舞い、権限、Rule、Effectを変更できない。高度な利用者は公開APIから独立clientを作れるが、Policyを迂回できない。管理者という別人格は置かず、Ownerが設定権限を持つ。Linux server administrator CLIはOS上の保守権限であり、API tokenの権限ではない。

## Non-decision / open

HTTP resource形状、OpenAPI採用、WebSocket／SSE／polling、media transport、API versioning、更新遅延、再接続時間、同時browser数、session/hash/暗号化storageの具体実装、trusted proxy設定方式、Tailscale identity連携、HTML template／Web component方式は未決である。

## Related requirements

REQ-PRD-006、REQ-API-001、REQ-API-002、REQ-API-003、REQ-API-004、REQ-FR-001、REQ-FR-006、REQ-CFG-001、REQ-SEC-001。
