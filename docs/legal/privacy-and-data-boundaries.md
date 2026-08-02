# privacyとデータ境界

Yatagarasu 2はmicrophone audio、transcript、camera observation、Interaction text、diagnostic、capability設定を扱う可能性があります。この文書は設計上の境界を述べるもので、privacy policyまたは保証ではありません。

- domain modelは物理的不確実性を明示し、observationが確認済みだと仮定しない。
- secretをEvent、Projection、prompt、journal、通常ログへ書き込まない。
- 具体capabilityは明示的なAdapter/bindingを通じてのみlocalまたはremoteにできる。そのtransfer、retention、deletion、利用者同意、access controlの条件は未決である。
- Webは一Ownerの認証sessionと取消可能なaccess tokenを要求し、認証なしの直接Internet公開を既定にしない。具体session、token scope、TLS／reverse proxy、Tailscale identity連携には後続のsecurity設計が必要である。
- memory retention、remote Provider routing、利用者による削除制御には、後続のPolicyと法的reviewが必要である。

この作業が完了するまで、このrepositoryから同意、適合、暗号化範囲、保持期間、data residencyを推論してはなりません。
