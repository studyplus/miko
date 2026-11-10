# 実装マッピング ガイド

business_rules.md の実装マッピング（ルールとコードの対応）の書き方を定める。ルール本文の書き方は `.miko/guides/business_rules_guide.md` に従う。

## 置き場所

ルール本体とは分離し、各カテゴリのルール一覧の直後に `<details>` タグで折りたたむ。ルール本文（`<details>` の外）にはコードの語彙を書かない。

```markdown
**ルール:**
- **PERM-01** [制約] AI質問機能を利用するには、有効な権限が存在しなければならない。

<details><summary>実装マッピング</summary>

- PERM-01 → `XxxConcern#method` / 説明

</details>
```

- 1 行の形式は `- {ルールID} → `{参照先}` / {説明}`
- 1 つのルールが複数箇所に実装されている場合は、同じルール ID で複数行を並べる

```markdown
- ORD-02 → `Ec::Order#cancellable?` / ステータス判定
- ORD-02 → `Ec::OrdersController#cancel` / キャンセル前のガード
```

- 実装マッピングは既存実装から生成する場合にのみ記載する。提案段階や未実装のルールは空、または `（未実装）` でよい

## 表記規約

所属先（クラス、モジュール、ファイル、パッケージなど）を「スコープ」と呼び、以下の記号で参照先の種別を区別する。Ruby の RDoc 慣習に由来するが、miko では言語を問わず適用する。

| 種別 | 表記 | 意味 | 例 |
|------|------|------|----|
| スコープに属するもの | `Scope#name` | インスタンスメソッド等、スコープのインスタンスに紐づく | `Order#cancellable?` |
| スコープ自体に紐づくもの | `Scope.name` | static メソッド、モジュール関数等、インスタンスを介さずアクセスする | `OrderService.bulk_cancel` |
| 定数 / 型定義 | `Scope::NAME` | 定数、enum、型エイリアスなど | `Order::CANCEL_GRACE_PERIOD` |
| スコープ単位 | `Scope` | 特定メンバを指さない場合 | `ExpireUnpaidOrdersJob` |

「スコープ」は言語に応じてクラス、モジュール、ファイル、パッケージ、名前空間などに読み替える。スコープは名前空間を含む完全修飾名で記述する（例: `App::Models::Order#cancellable?`、`com.example.order.OrderService.bulkCancel`）。
