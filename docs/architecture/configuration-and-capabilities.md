# 設定とCapability運用

設定は外側の文字列を集めたものではありません。どの値が、どのLayerから、どのschemaで採用され、いつ反映されるかを説明できる運用契約です。

## 保存するものの役割を分ける

LinuxではXDG Base Directoryに沿い、次を異なるrootへ置きます。

```text
config   -> config.toml、profile、secret参照
data     -> Workspace、Skill、media、model、artifact
state    -> snapshot、journal、conversation、pending/recovery state、operations/audit/debug log
cache    -> 再生成可能なmodel／推論cache
runtime  -> socket、一時file、process間の短命な情報

secret boundary -> configから参照する外部Secret Store、または保護されたconfig-scoped実装
```

この配置例は、Domain境界やprocess数を決めません。logはstate root内の分類であり第六のXDG rootではありません。operations/audit/debugは既定30/90/7日のrolling retentionとし、journal/pending/recovery/snapshotはそのcleanup対象にしない。secret boundaryも第六のXDG rootではありません。具体的な外部Secret Storeまたは保護されたconfig-scoped実装は未決ですが、`config.toml`にはsecret本文でなく参照だけを置き、平文値をEvent、Projection、journal、通常logへ入れません。重要なのは、配布Default、利用者資産、復旧すべき状態、削除可能cache、短命runtimeを同じ生存期間にしないことです。

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

初期製品の運用単位は一Server、一Workspace、一Ownerです。複数camera、browser、access tokenは同じWorkspaceとOwnerへ属し、複数利用者や複数Workspaceの選択機構を要求しません。

Yatagarasu 1の環境はY2のUpgrade対象にしません。

## Capability配置

Capabilityは`local-managed`、`remote`、`disabled`の論理モードで独立に配置します。配置はBootstrapのbindingであり、Domainの分岐ではありません。installation serverごとにservice/capabilityを個別選択し、全Y2 serverを自動installしません。Codexは公式installerで扱いbundleしません。

remote接続はhealth、能力広告、API versionを照合します。local-managedは対応version、license、checksum、healthを提示します。Dockerを一般利用者の必須条件にしません。Provider/mode設定は次Interactionからだけ反映し、active turnをrebindせず、remote障害時にもlocalや別Providerへ自動fallbackしません。

初期配置は次のmatrixに限定する。全行はendpoint/binding、health、version、必要credentialのreadinessを検証し、unsupported/未readyなら型付きFailureとする。`disabled`の依存Behaviorをreadyに見せず、全serviceを自動installしない。

| capability | 初期配置 |
| --- | --- |
| Codex app-server | Y2 Agent hostと同一hostで必須。公式installerで導入するlong-lived process。stdio/Unix socketはspike候補、remote/WSは初期unsupported。 |
| OpenAI | Codex経由のremote upstreamとしてselectedまたはdisabled。 |
| Hoshikage / Ollama API | 明示選択hostのlocal-managed、LAN/Tailscale remote、またはdisabled。 |
| Source/go2rtc、Wake、Mimy、TTS/VOICEVOX、SemanticMemory、device adapter | adapter対応範囲で個別local-managed/remote/disabled。未ready依存Behaviorはtyped readiness Failure。 |
| SkillCreator / Search / Fetch | 必須Codex workspace capability。Y2 installable Behavior/plugin serviceではない。 |

## Linux導入、doctor、Quality Profile

初期baselineはUbuntu 24.04 LTS、x86_64、Intel第8世代Core i5以上、RAM 8GB以上であり、外部serverは自身の要件を所有する。setupは一Server、一Workspace、一Ownerを作る。Capability選択、credential registration、logical modeとconfigから参照するsecret boundaryを明示し、secret本文をconfig、Event、Projection、journal、通常log、Artifact名へ出さない。`doctor`はSource、Wake、STT、SBERT、camera、TTS、Provider、Memory、Codex version/schemaごとの未設定、認証失敗、非互換、利用不能、ready、remedyを別の型付き診断として返し、configured authorizationなしのexternal transferを試行しない。

Quality Profileはversion付きでWake positive/near-negative/silence/self-audio、SBERT single/composite/negative/unrelated、warm/cold、CPU、RAM、endurance、reconnectの測定条件、結果、Failureを記録する。365日objectiveは計画、hardware/profile、途中evidence、spike後soak thresholdが揃う場合だけ主張できる。pre-roll/guard/settleは環境別の実測defaultをversion/configへ固定し、未計測ならrelease-readyではない。必要な測定または数値閾値が未設定でもrelease-readyではない。

規範的な受入条件は[設定・Workspace要件](../requirements/configuration-requirements.md)にあります。
