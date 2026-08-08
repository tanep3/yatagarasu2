# 設計義務台帳

この台帳は、受入条件を実装可能な設計義務へ分解し、要件の一部だけを設計して「網羅した」と誤認しないために使います。

## 二層の追跡

全214 ACの入口は[全受入条件入口索引](ac-inventory.md)に固定します。

### AC index

一つのACにつき一行を持つ入口索引です。この行だけではcoverageを証明しません。

| Requirement | AC | Source file / anchor | Obligation group | Accounting status | Coverage status |
| --- | --- | --- | --- | --- |

### Atomic Design Obligation

ACに含まれる独立した義務、否定条件、障害条件、実機条件を分解します。

| Obligation ID | Parent AC | Parent source | Joint group | Parent contribution | Obligation | Canonical Design IDs | Proof type | Negative case | Target profile / scope | Accounting status | Design status | Proof status | Blocker |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

## 分解規則

- Atomic Design Obligationは、独立した合否判定、異なるcanonical contract、Proof type、対象Profile、またはBlocker状態を必要とする最小単位まで分解する。同じ証拠と設計契約で一体として合否判定できる条件を、文章表現だけを理由に分割しない。
- `Parent AC`は実在する単一のAC IDだけを持つ。複数ACが同じproofを共有する場合も兄弟Obligationへ分け、`Joint group`で関係を示す。
- `Parent contribution`は、その行と既存兄弟だけで親AC全体を扱える場合に`full`、別Pilot／別Layerの兄弟義務が必要な場合に`partial`とする。`partial`が一つでも残る親ACをcoveredにしない。
- 親ACのfile、section、AC IDを保持する。
- 原文の意味を弱めたり、条件を削ったりしない。
- 同時に成立すべき義務は同じ`Joint group`へ置く。
- success pathだけでなく、拒否、Failure、取消、OutcomeUnknown、restart、late resultを分ける。
- Fakeで証明できる範囲と、実機だけが証明できる範囲を分ける。
- 初期release、将来revision、spike、Owner判断を同じstatusへ畳まない。
- 一つの義務が複数Design IDを必要としてよい。一つのDesign IDが複数義務を支えてよい。
- canonical contractとproof designがなければ`designed`にしない。
- 全atomic obligationの所在が判明し、初期scope、正式な将来scope、spike待ち、Owner判断待ちのいずれかに分類された場合だけ、親ACを`accounted-for`と表示できる。
- 初期scope内の全atomic obligationが`designed`でなければ、親ACを`covered`と表示しない。`blocked-by-spike`、`blocked-by-owner`、`deferred`は`covered`へ数えない。

## 状態の二軸

設計状態と証拠状態を同じ列へ畳みません。

| 軸 | 値 | 意味 |
| --- | --- | --- |
| Accounting | `unaccounted` / `accounted-for` | 義務の所在を把握したか |
| Design | `undesign` / `designed` / `blocked-by-spike` / `blocked-by-owner` / `deferred` | canonical contractとproof designを確定できたか |
| Proof | `unplanned` / `planned` / `implemented` / `passing` / `blocked-by-spike` / `blocked-by-owner` / `not-applicable` | 実装・試験・実機証拠がどこまで存在するか |

canonical contractが確定し、実機証拠だけを待つ義務は、Design=`designed`、Proof=`blocked-by-spike`です。Design=`blocked-by-spike`は、実測結果がState所有やDomain法則を変え得るため設計自体を確定できない場合だけに使います。

## Proof type

| Proof type | 証明対象 |
| --- | --- |
| `pure` | I/OなしのRule、Transition、Policy |
| `architecture` | 依存方向、単一owner、到達不能性、製品名漏洩 |
| `contract` | Port、Adapter、API schema、DTO変換 |
| `integration` | 複数Contextと外部境界の因果関係 |
| `crash-recovery` | commit／dispatch境界、restart、late result、冪等性 |
| `real-device` | 実カメラ、実音声、実外部I/O |
| `measurement` | latency、CPU、RAM、quality、soak |
| `owner-gate` | 実測後のOwner採否 |

## 現在の状態

全214 ACの入口索引は、要件基準commit `4df6fb1`からpilot設計前に固定します。Requirement、AC、source anchorを一対一で記録し、要件側の[トレーサビリティ](../../requirements/traceability.md)と機械照合します。

atomic obligationへの分解は三本のpilot sliceから開始します。pilot Gate通過後に分解を全ACへ横展開します。入口索引の追加、脱落、重複、source移動は、基準commitとの差分として明示しない限りGateを通しません。
