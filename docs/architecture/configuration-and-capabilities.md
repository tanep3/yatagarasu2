# 設定とCapability運用

設定は外側の文字列を集めたものではありません。どの値が、どのLayerから、どのschemaで採用され、いつ反映されるかを説明できる運用契約です。

## 保存するものの役割を分ける

LinuxではXDG Base Directoryに沿い、次を異なるrootへ置きます。

```text
config   -> config.toml、secrets、profile
data     -> Workspace、Skill、media、model、artifact
state    -> snapshot、journal、conversation、log
cache    -> 再生成可能なmodel／推論cache
runtime  -> socket、一時file、process間の短命な情報
```

この配置例は、Domain境界やprocess数を決めません。重要なのは、配布Default、利用者資産、復旧すべき状態、削除可能cache、短命runtimeを同じ生存期間にしないことです。

## 型付き設定とLayer

主設定はschema検証される`config.toml`とします。環境変数はservice、CI、診断、一時上書きに使えますが、主設定と採用元を隠す巨大な文字列集合にはしません。

```text
組込みDefault
-> system config
-> user config.toml
-> active Profile
-> environment override
-> CLI override
```

実効値だけでなく、どのLayer、file、override種別から採用したかをsecretなしで診断します。実効profileはdispatch時にEffectへ固定し、後の設定変更で過去の仕事を変えません。

## 変更はCommandとして扱う

Web Gatewayは設定fileを直接編集しません。

```text
UpdateConfiguration Command
  -> schema validation
  -> safety validation
  -> atomic persistence
  -> ConfigurationChanged Event
  -> apply modeに応じた反映
```

反映方法は`immediate`、`restart_adapter`、`restart_runtime`、`next_interaction`を区別します。検証または保存に失敗した場合は、以前の完全な設定を維持します。

## WorkspaceとUpgrade

配布Defaultと、利用者が変更したWorkspace、AGENTS、Skill、人格、media、記憶、設定を分けます。Upgradeは利用者資産を黙って上書きしません。schema変更はbackupまたは復旧点を持つ明示migrationとして扱います。

Yatagarasu 1の環境はY2のUpgrade対象にしません。

## Capability配置

Capabilityは`local-managed`、`remote`、`disabled`の論理モードで配置します。配置はBootstrapのbindingであり、Domainの分岐ではありません。

remote接続はhealth、能力広告、API versionを照合します。local-managedは対応version、license、checksum、healthを提示します。Dockerを一般利用者の必須条件にしません。remote障害時にlocalへfallbackするかはprivacyと利用者同意を含むPolicyであり、未決です。

規範的な受入条件は[設定・Workspace要件](../requirements/configuration-requirements.md)にあります。
