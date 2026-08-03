# ADR-012: 設定、Workspace、Upgrade、Capability配置

- Status: Accepted
- Scope: 設定の役割、Linux配置、変更、Upgrade、Capability配置モード

## Context

Yatagarasu 1は複数の製品とserviceを組み合わせて価値を実現した一方、多数の値を`.env`と固定Workspaceへ集める方式は、導入、診断、Web変更、Upgradeを難しくする。凍結06は、設定、ユーザー資産、状態、cache、runtimeを分離し、一つの製品として扱う構造を要求している。

## Decision

LinuxではXDG Base Directoryの役割に従い、config、data／Workspace、state、cache、runtimeを分離する。主設定はschema検証する型付き`config.toml`とし、環境変数は一時override等に限定する。設定Layerの優先順位と各実効値の採用元を診断可能にする。

設定変更はUpdateConfiguration Command、schema／安全検証、原子的保存、ConfigurationChanged Eventを通す。反映方法は`immediate`、`restart_adapter`、`restart_runtime`、`next_interaction`を区別する。Upgradeは配布Defaultと利用者資産を分離し、利用者変更を黙って上書きしない。

Capability配置は`local-managed`、`remote`、`disabled`とし、Bootstrap bindingで解決する。Dockerを一般利用者の必須条件または標準管理単位にしない。

## Non-decision / open

Windows／macOS配置、具体schema／atomic write library、secret store、local supervisor、installer、migration engineは未決である。remote fallbackと利用ごとのprivacy同意画面は初期契約で採用しない。

## Consequences

`.env`だけを主設定とし、値の採用元を説明できない実装は適合しない。Webが設定fileを直接書き換える実装、部分書込みを有効化する実装、UpgradeでユーザーWorkspaceを上書きする実装も適合しない。配置変更でDomain Ruleは変えない。

## Related requirements

REQ-CFG-001、REQ-CFG-002、REQ-CFG-003、REQ-CFG-004、REQ-ARC-006、REQ-OPS-005、REQ-SEC-001。

## Superseded assumptions

凍結06の設定・Workspace・Upgrade要求を、profile固定、secret非露出、bindingだけへ縮約する正本解釈を置き換える。凍結06 §6.1のMimy直接go2rtc所有はADR-006が引き続き置き換える。
