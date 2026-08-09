# SD-CHECK-001 — Pilot A設計整合検査

## 対象

- 要件基準commit: `4df6fb1`
- 設計対象: Pilot A（カメラ移動・撮影・画像解釈）
- 実行状態: 下記System design content revisionで固定
- 検査日: 2026-08-09

## 再現command

```text
docs/system-design/verification/check-system-design.sh
git diff --check
```

## 結果

```text
PASS(structural-index) REQ=62 AC=214 canonical=207 states=12 stateOwners=12 parentAC=92 obligations=112 revision=sha256:6bee5a20c90b9bd47630ba1b5ed2b8d06573e30f065239c694d586776ace1fe1
git diff --check: PASS
verification revision: sha256:b35fc20740ab1578cda56aa61cbd7e1d7615d1c9d64b68b27714d39b7a8b6ee9
```

結果値は現在の設計規約・Pilot A/Bを含む全system designを対象に再生成し、
`system-design-revision.sh`が算出する設計内容hashと、`verification-revision.sh`が算出する
検査規則hashを一緒に保存します。旧`canonical=86`の記録は、
後続Pilot追加後の同じcommandでは再現できないためGate根拠として使用しません。

このPASSは表と参照の構造整合だけを示します。Atomic Design Obligationの意味的完全性、
Stateの意味上の重複、実装、実機挙動、Recovery成立はarchitecture reviewまたは別Proofで判定します。

## Gate状態

- 設計規約: FIX
- Pilot A architecture review: PASS（Critical／Highなし）
- Proof: production code未実装のため`planned`または`blocked-by-spike`
- Pilot A Design slice: PASS
- 三本全体のDesign Pilot Gate: Pilot C完了待ち
- Implementation / Evidence Gate: 未評価

独立architecture challengerは、planned／dispatch Effectの分離、結果根拠の全域変換、lease解放と資源非再利用化の原子性、DEX送信境界を含めてPASSと判定しました。

TC70／C210実機E2E、start／settle実測、DEX handle／session解放、single-use permitと
expiryの競合、Y1復帰確認、latency／欠測計測はImplementation / Evidence Gateで必要です。
これらは設計不合格ではなく、実機でしか証明できないProof=`blocked-by-spike`です。
