# 設定・Workspace要件

## 目的

Yatagarasu 2を利用者には一つの製品として見せながら、設定、秘密情報、ユーザー資産、実行状態、cache、外部Capabilityの配置を混同しない。設定を単なる文字列群として扱わず、型、出所、変更方法、反映時点を検証可能にする。

### REQ-CFG-001 — 設定の役割、Layer、出所を分離する

永続設定、秘密情報、ユーザー資産、実行状態、cache、一時runtimeデータは、役割ごとに異なる保存rootへ分離する。LinuxではXDG Base Directoryに従う。主設定はschemaで型検証する`config.toml`とし、環境変数はservice、CI、診断、一時上書きの入力に限定する。組込みDefault、system設定、user設定、active Profile、environment override、CLI overrideの解決順を明示し、各実効値の採用元を診断できなければならない。

受入条件:

- AC-CFG-001: Linux適合試験が、config、data／Workspace、state、cache、runtimeの各データを対応するXDG rootへ分離し、同じ書込先へ混在させないことを示す。
- AC-CFG-002: schema fixtureが、型、既定値、validation、secret、read-only、apply modeを持つ設定定義により、正しい`config.toml`を受理し、不正な型または未知の必須値を拒否する。
- AC-CFG-003: Layer競合fixtureが定義済み優先順位で一つの実効値を選び、値、採用Layer、元ファイルまたはoverride種別をsecretなしで診断表示する。

### REQ-CFG-002 — 設定変更を検証し、原子的に適用する

Webその他の入力境界は設定ファイルを直接編集せず、型付きUpdateConfiguration Commandを投入する。schema検証と安全検証を通過した変更だけを原子的に保存し、`immediate`、`restart_adapter`、`restart_runtime`、`next_interaction`のapply modeに従って反映する。失敗時は以前の有効設定を保持する。

受入条件:

- AC-CFG-004: Web変更fixtureがUpdateConfiguration Command、schema／安全検証、原子的保存、ConfigurationChanged Eventの順に境界を通り、Web Adapterから直接filesystem更新を行わない。
- AC-CFG-005: 保存失敗または検証失敗を注入しても、再読込後に以前の完全な設定が有効であり、部分書込みを残さない。
- AC-CFG-006: 各apply modeのfixtureが、変更前後、反映方法、必要な再起動範囲をProjectionへ示し、指定範囲を越えて再起動しない。

### REQ-CFG-003 — Upgradeでユーザー資産を保護する

配布Defaultと利用者が変更したWorkspace、AGENTS、Skill、人格設定、media、記憶、設定を分離する。Upgradeは利用者資産を黙って上書きまたは削除してはならず、schema／version移行が必要な場合は、事前検証、backupまたは復旧点、結果報告を持つ明示的migrationとして扱う。

受入条件:

- AC-CFG-007: 利用者変更済みWorkspaceを持つUpgrade fixtureが、配布Defaultを更新しても利用者ファイルの内容と所有関係を保持する。
- AC-CFG-008: migration失敗fixtureが以前の利用可能な設定または復旧点を保持し、部分移行を有効状態として公開しない。

### REQ-CFG-004 — Capability配置を論理モードとして選択する

Capabilityの配置は`local-managed`、`remote`、`disabled`の論理モードとして設定し、Coreの分岐にしない。Bootstrapが実装、配置、endpoint、認証をPortへbindingする。remote接続時はhealth、能力広告、互換versionを照合し、不一致を明示Failureまたは縮退判断へ変換する。Dockerを一般利用者の必須条件または標準管理単位にしない。

受入条件:

- AC-CFG-009: 同じCapability契約をlocal-managed、remote、disabledへ切り替えるfixtureが、domain Rule／Transitionを変更せず異なるBootstrap bindingを作る。
- AC-CFG-010: remote能力照合fixtureが、期待するAPI versionまたは能力を欠くendpointを型付き不一致として拒否またはPolicyへ縮退提案し、暗黙に互換扱いしない。
- AC-CFG-011: local-managedの配備fixtureが、対応version、license情報、取得物checksum、health結果を提示し、UninstallまたはUpgradeでユーザーデータを既定削除しない。container runtimeがなくても適合可能である。

## 未決の詳細

Windows/macOSの保存root、具体schema library、secret store、atomic write機構、local worker supervisor、installer／package形式、remoteからlocalへの自動fallbackとprivacy同意は未決である。
