# ADR-021: 内容分類、処理場所・移送方向、Artifact、search/fetch、LLM転送authorization

- Status: Accepted
- Scope: local/remoteデータ境界、Artifact、外部network capability

## Context

自動保存、外部Provider、検索/取得、Artifactを一つの「外部アクセス」へ畳むと、どのデータがどこへ移るか、誰が削除できるか、出典を何として示すかを検証できない。

## Decision

初期方針をlocal-firstとし、configured standing authorizationがない限りdataをlocalに留める。`Image`、`Audio`、`Transcript`、`Conversation`、`Memory`、`Artifact`を少なくともcontent classとして持つ。`Local`/`Remote`は処理場所、`LocalToRemote`/`RemoteToLocal`は移送方向であり、content classと目的ごとにauthorization、retention、delete、transfer Policyを評価する。利用ごとのconsent promptは置かない。Artifact Contextは論理Artifact ID、authorization、lifetime、delete状態を所有し、filesystem path/storage locatorを外部へ出さない。deleteはDecision -> Effect -> Adapter result Eventとして扱う。

SearchとFetchは独立Capabilityであり、allowlist、目的、provenance、citation、typed Failureを持つ。no-resultsはFailureと別の空成功である。network取得を許可しても、その内容をLLM/Providerへ送るには、content classごとの別のLocalToRemote transfer authorizationが必要である。取得内容を物理観測済み事実へ昇格しない。

## Consequences

具体的allowlist、Artifact store、citation format、Providerごとのmodel/credentialは未決である。standing authorizationはREADME/setup/configでdiscloseし、利用ごとの同意UIは置かない。Memory retentionはOwner deleteまでである。外部検索、Fetcher、LLM、Codex SkillはWorldState、Conversation、Memory、planを所有しない。

## Related requirements

REQ-DAT-001、REQ-NET-001、REQ-MEM-001、REQ-SEC-001。
