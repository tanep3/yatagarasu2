# ADR-022: Codex app-serverとAgent Session Context

- Status: Accepted
- Scope: 初期Agent adapter、Codex connection/thread、recovery境界

## Context

一turnごとに`codex exec`を起動すると、接続初期化、Thread継続、取消、遅延通知、reconnectを一つの会話処理へ隠してしまう。Codexの外部ThreadとY2 Conversationは同じIDでも同じ状態所有者でもない。

## Decision

初期Agent adapterはCodexのみとする。通常経路はruntime bootstrapがlong-lived `codex app-server`をstart/superviseし、connectionごとに一回だけinitialize handshakeを行う。turnごとの`codex exec`は通常経路に使わない。production transportはspike後にstdioまたはUnix socketから選び、WebSocketはexperimentalでproduction非対応とする。`doctor`はpinした互換Codex version/schemaとreadinessを検証する。

外部bindingを唯一所有するAgent Session Contextは、Codex Thread ID、connection/status、correlation、rebind/recovery状態と、external turnごとの耐久`AgentTurnBinding`を持つ。BindingはY2 Interaction ID、exact external Thread ID、外部が返したexternal turn/operation ID（未返却時はabsenceを明示）、Y2がdispatch前に発行するimmutable attempt/generation/correlation ID、lifecycle（`Planned`、`Requested`、`Started`、`Terminal`、`Interrupted`、`Recovery`）、pinしたprovider/profile/protocolを持つ。Provider内部stateやconversation textを所有しない。Y2 Conversationは複数の有限Interaction/Qualia/Homeをまたいで同じ外部Threadへbindでき、HomeまたはQualia終了はThread終了ではない。用語は`thread/start`、`thread/resume`、`turn/start`、`turn/interrupt`を使用する。

restart/reconnectでは記録済みの正確なThread IDへ`thread/resume`する。`--last`、暗黙new Thread、Y2 Conversation IDの転用を禁止する。`turn/interrupt` Effectはexact active Bindingのattempt/generationだけをtargetにする。dispatch直前にBindingがcurrentでなくなれば、stale cancelをrejected/no-effectとして記録して送らない。crashが外部turn ID返却より前に起きても、Y2-issued immutable correlationとBinding lifecycleを耐久化し、結果を別turnへ結び直さない。notification/deltaは相関したtyped progress/result Eventへ変換し、raw deltaを無制限journalへ保存しない。adapterはWorldStateを変更せずresult Eventだけを返す。

crash window、duplicate/late result、削除済みThread、resume mismatchは`RebindRequired`またはtyped Recoveryとして残し、新Threadを旧continuityとして黙って扱わない。同じThreadでturn Bが始まった後にturn Aの遅延/重複resultまたはcancelが届いても、AのBinding/Recovery/auditだけを更新し、BのState、Presentation、cancel、terminalを変更しない。Codex Thread IDは保護・redact対象であり、API、Projection、auditへ平文表示しない。warm/cold latency acceptanceは同じapp-server process/connectionと同じThreadが再利用されたことを証明する。

## Consequences

KernelはgenericなEffect/Event接続を保つ。PythonやCodexはY2のConversation、plan、provider state、WorldStateを所有しない。Provider routeの選択とno-fallbackはADR-011、初期scopeはADR-023に従う。

## Related requirements

REQ-AGT-001、REQ-CNV-001、REQ-QLI-001、REQ-SET-001、REQ-QPR-001、REQ-SEC-001。
