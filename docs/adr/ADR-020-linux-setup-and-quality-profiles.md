# ADR-020: 初期Linux導入とQuality Profile

- Status: Accepted
- Scope: 初期運用単位、secret/doctor、実機E2E、品質測定

## Context

Y1はLinux、Owner相当の運用設定、複数Capability、doctor、WakeのCPU/遅延実測を持つ。しかし個別machineの設定値をY2の一般契約にすると再現性と安全性を失う。

## Decision

初期対応platformはUbuntu 24.04 LTS、x86_64、Intel第8世代Core i5以上、RAM 8GB以上とし、外部serverは各自の要件を所有する。一Server、一Workspace、一Ownerを導入単位にする。setupはinstallation serverごとのCapability選択、credential registration、logical mode、configから参照するsecret storage boundaryを明示する。全Y2 serverを自動installせず、Codexは公式installerで扱いbundleしない。secretは第六のXDG rootではなく、外部Secret Storeまたは保護されたconfig-scoped実装（具体方式は未決）に置き、平文をconfig、Event、Projection、journal、通常logへ出さない。doctorはSource、Wake、STT、SBERT、camera、TTS、Provider、Memory、Codex version/schemaの未設定・認証失敗・非互換・利用不能・readyとremedyを型付きに報告し、secretまたはconfigured authorizationのないexternal transferを露出・実行しない。最初の実機E2Eはclean setupとdoctor全readyの後、real wake、最初の発話、有限Conversation、最終Presentation、Homeを通す。

Codex app-serverはY2 Agent hostと同一hostの必須long-lived capabilityであり、公式installerから導入する。OpenAIはCodex経由のremote upstream、Hoshikage/Ollamaは選択host local-managedまたはLAN/Tailscale remoteまたはdisabledとする。その他adapterは対応するlocal-managed/remote/disabledを個別選択する。endpoint/binding、health、version、credentialのreadinessを満たさない行、または初期unsupported remote/WS Codexは型付きFailureである。SkillCreator/Search/Fetchは必須Codex workspace capabilityであってY2 plugin serviceではない。

第一基準かつ初期release必須実機はTapo TC70、第二基準はTapo C210とする。両方を対象に同時対応を目指すが、C210が未達ならTC70契約を弱めず後続device profileとして扱える。製品名はAdapter/bootstrap/profileに閉じ、Coreへ持ち込まない。TC70試験はY1環境へY2を混在させず、Y1 handle/session解放、実機排他、期限付きtest window、abort cleanup、Y1復帰確認を証明してから行う。

Quality Profileはversion付きでWake positive/near-negative/silence/self-audio、TTS全文Stop語あり/なしの利用者Stop・自己音声・同時発話・近似語・遅延buffer、SBERT single/composite/negative/unrelated、warm/cold、CPU、RAM、endurance、reconnectの測定条件・結果・Failureを機種別に記録する。365日objectiveは計画、hardware/profile、途中evidence、spike後soak thresholdが揃うときだけ主張できる。pre-roll/guard/settleは環境別の実測defaultをversion/configへ固定し、必要測定または閾値が未設定ならrelease-readyではない。具体的な数値・測定時間はspike後に決める。TC70の音声Stop採否はTC70 spike後にOwnerが明示し初期release gateとする。C210は対応を主張するprofileだけが同じgateを独立に満たし、未達でもTC70 releaseをblockしない。

## Consequences

Y1の測定値は根拠であってY2の合格閾値ではない。package/installer、secret store、doctor実装、サービス構成は未決である。

## Related requirements

REQ-SET-001、REQ-QPR-001、REQ-CFG-001–004、REQ-API-004。
