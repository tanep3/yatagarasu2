# ADR-021: 内容分類、処理場所・移送方向、Artifact、search/fetch、LLM転送authorization

- Status: Accepted
- Scope: local/remoteデータ境界、Artifact、外部network capability

## Context

自動保存、外部Provider、検索/取得、Artifactを一つの「外部アクセス」へ畳むと、どのデータがどこへ移るか、誰が削除できるか、出典を何として示すかを検証できない。

## Decision

初期方針をlocal-firstとし、configured standing authorizationがない限りdataをlocalに留める。`Image`、`Audio`、`Transcript`、`Conversation`、`Memory`、`Artifact`を少なくともcontent classとして持つ。一つのrequest/Artifactは非空の`ContentClassSet`を持ち、保存画像は`Image + Artifact`のように複数分類を同時に持つ。Data Classification Policy Contextが分類schema、導出Policy version、分類済みauthorization viewを唯一所有し、入力、派生、結合、検索取得、prompt組立で分類をunionする。Provider、Skill、Fetcher、Artifact Adapterは分類Stateを変更しない。Unknown、未分類、空集合、矛盾は拒否する。`Local`/`Remote`は処理場所、`LocalToRemote`/`RemoteToLocal`は移送方向であり、目的・方向・宛先について集合内の全content class authorizationが許可した場合だけEffectを作る（all-of/fail-closed）。利用ごとのconsent promptは置かない。Artifact Contextは論理Artifact ID、authorization、lifetime、delete状態を所有し、filesystem path/storage locatorを外部へ出さない。deleteはDecision -> Effect -> Adapter result Eventとして扱う。

SearchとFetchは独立Capabilityであり、allowlist、目的、provenance、citation、typed Failureを持つ。初期catalogのmanaged Search/FetchはY2管理の型付きTool/Portだけを実通信境界とし、Skill内Python/shellの直接通信をmanaged成功として受理しない。一般Skillは自身のgrantでnetworkを使えても、その出力はSearch/Fetch provenanceを持たないuntrusted external contentであり、通常の分類・移送Policyを通る。no-resultsはFailureと別の空成功である。network取得を許可しても、その内容をLLM/Providerへ送るには、content classごとの別のLocalToRemote transfer authorizationが必要である。取得内容を物理観測済み事実へ昇格しない。

## Consequences

具体的allowlist、Artifact store、citation format、Providerごとのmodel/credentialは未決である。standing authorizationはREADME/setup/configでdiscloseし、利用ごとの同意UIは置かない。Memory retentionはOwner deleteまでである。外部検索、Fetcher、LLM、Codex SkillはWorldState、Conversation、Memory、planを所有しない。

## Related requirements

REQ-DAT-001、REQ-NET-001、REQ-MEM-001、REQ-SEC-001。
