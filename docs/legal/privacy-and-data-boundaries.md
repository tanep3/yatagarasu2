# privacyとデータ境界

Yatagarasu 2はmicrophone audio、transcript、camera observation、Interaction text、Conversation/Memory、diagnostic、capability設定、検索/取得結果を扱う可能性があります。この文書は設計上の境界を述べるもので、privacy policyまたは保証ではありません。

- domain modelは物理的不確実性を明示し、observationが確認済みだと仮定しない。
- secretをEvent、Projection、prompt、journal、通常ログへ書き込まない。
- 初期方針はlocal-first（configured standing authorizationがない限りlocalに留める）である。内容分類は少なくとも`Image`、`Audio`、`Transcript`、`Conversation`、`Memory`、`Artifact`である。`Local`/`Remote`は処理場所、`LocalToRemote`/`RemoteToLocal`は移送方向であり、内容分類と目的ごとのtransfer、retention、deletion、configured authorization Policyを別に評価する。README/setup/configのstanding disclosureとenabled configを許可とし、利用ごとの同意画面は置かない。disable/revocationは次の新規save/transferより前に効き、自動fallbackしない。
- Conversation ContextとMemory ContextはYatagarasu自身の履歴・記憶だけを所有する。外部Codex Skillアプリのデータ、Provider thread、検索先本文を所有移管しない。local auto-saveは既定ONでConversationの原発話と最終応答に限り、reflex commandはstructured operations logだけへ残しMemoryへ保存しない。MemoryはOwner deleteまで無期限に保持し、Y1 import/migrationは行わない。互換storeの旧recordはprovenance付きで示してよい。
- Artifactは論理ID、認可、lifetime、delete状態で参照し、filesystem path、storage locator、secretをProjection、Provider、外部Skillへ渡さない。
- Search/Fetchのnetwork取得authorizationと、取得内容をLLM/Providerへ送るLocalToRemote authorizationは別である。許可された取得にもsource、取得時点、citation、typed Failureを残し、取得内容を確認済み物理事実にしない。
- Webは一Ownerの認証sessionとread/operateだけのrevocable/reissuable tokenを要求し、認証なしの直接Internet公開を既定にしない。token plaintextはWebで一度だけ表示し、保護されたLinux administrator CLI以外へ再表示しない。reverse proxyはtrusted proxy/header sanitation/TLSが揃う場合だけ許可し、router port forwardingはunsupportedである。
- Artifactの削除はDecision→Effect→result Eventで扱う。TTS WAVとtemp captureはterminal/Recoveryおよび未解決dependentの条件を満たすときだけ削除し、saved ArtifactはOwner deleteまで残す。operations/audit/debug logの既定rolling retentionは30/90/7日であり、通常logはraw media、secret、full Conversation、SemanticMemoryを含めない。

このrepositoryは、concrete crypto implementation、data residency、法令・契約への適合、外部Providerごとの運用Policy詳細を保証しません。Memory/log/Artifactの保持とconfigured standing authorizationについては、承認済み要件を否定しません。
