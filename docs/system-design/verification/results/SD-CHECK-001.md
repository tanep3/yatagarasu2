# SD-CHECK-001 — Pilot A設計整合検査

## 対象

- 要件基準commit: `4df6fb1`
- 設計対象: Pilot A（カメラ移動・撮影・画像解釈）
- 実行状態: `4df6fb1`を基準とする未commit worktree
- 検査日: 2026-08-09

## 再現command

```text
docs/system-design/verification/check-system-design.sh
git diff --check
```

## 結果

```text
PASS REQ=62 AC=214 canonical=86 parentAC=49 obligations=52
git diff --check: PASS
```

このPASSは、要件／受入条件入口の一対一対応、Design IDとcanonical anchor、親ACとAtomic Design Obligation、相対Markdown link、差分形式の機械整合を示します。実装、実機挙動、Recoveryの成立を証明するものではありません。

## Gate状態

- 設計規約: FIX
- Pilot A architecture review: PASS（Critical／Highなし）
- Proof: production code未実装のため`planned`または`blocked-by-spike`
- Pilot A Gate: 未通過

独立architecture challengerは、planned／dispatch Effectの分離、結果根拠の全域変換、lease解放と資源非再利用化の原子性、DEX送信境界を含めてPASSと判定しました。

正式Gateには、TC70／C210実機E2E、start／settle実測、DEX handle／session解放、single-use permitとexpiryの競合、Y1復帰確認、latency／欠測計測の証拠が必要です。これらは設計不合格ではなく、実機でしか証明できない`blocked-by-spike`です。
