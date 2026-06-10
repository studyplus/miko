# EC プラットフォーム ハイレベルデザイン — サンプル

> このファイルは miko スキルの品質基準を示すサンプルです。
> 実際のプロジェクトでは `miko/system_high_level_design.md` として配置します。

## システム概要

マルチテナント型の EC プラットフォーム。店舗オーナーが商品を登録・販売し、購入者が注文する。

## テナント構造

- **Shop（店舗）** がテナントの単位。全データは Shop に属する
- 管理者は自分の Shop のデータのみアクセス可能
- 購入者は複数の Shop をまたいで購入できるが、注文は Shop 単位で分割される

## API 構造

- 管理者向け API: `/api/admin/...` — 認証: セッションベース
- 購入者向け API: `/api/store/...` — 認証: JWT
- Webhook 受信: `/webhooks/...` — 認証: 署名検証

## ケイパビリティ一覧

| ケイパビリティ | 概要 | miko/ |
|---------------|------|---------|
| 注文管理 | 注文の作成〜完了のライフサイクル | `miko/order_management/` |
| 商品管理 | 商品の登録・公開・在庫管理 | `miko/product_management/` |
| 決済連携 | 決済プロバイダとの非同期連携 | `miko/payment/` |

---

## コード探索ガイド

> miko のスキル（catchup、new_cap、propose）がコードを探索・精読する際の手引き。
> プロジェクト固有のフレームワーク・構造・慣習をここに記述する。

### フレームワーク・言語

- Ruby 3.3 / Rails 7.1
- フロントエンド: なし（API only）
- ジョブ: Sidekiq
- テスト: RSpec

### ディレクトリ構成

```
app/
  models/          — ActiveRecord モデル。ビジネスロジックの中心
  controllers/
    api/admin/     — 管理者向け API
    api/store/     — 購入者向け API
  services/        — 複数モデルをまたぐ処理、外部連携
  jobs/            — 非同期ジョブ（Sidekiq）
  forms/           — フォームオブジェクト（複合バリデーション）
  policies/        — 認可ルール（Pundit）
  serializers/     — JSON レスポンス構造

config/routes.rb   — ルーティング定義
db/schema.rb       — スキーマ定義
```

### レイヤー構成と責務

| レイヤー | 責務 | 置き場 |
|---------|------|--------|
| ルーティング | エンドポイントとコントローラーの対応 | `config/routes.rb` |
| コントローラー | リクエスト受付・レスポンス返却 | `app/controllers/` |
| フォーム | 入力の複合バリデーション | `app/forms/` |
| サービス | ユースケースの実行、複数モデルの協調 | `app/services/` |
| モデル | データ定義、単体バリデーション、状態遷移 | `app/models/` |
| ポリシー | 認可判定 | `app/policies/` |
| ジョブ | 非同期処理 | `app/jobs/` |

### ファイル命名規約

- モデル: `app/models/order.rb` → `Order`
- コントローラー: `app/controllers/api/admin/orders_controller.rb` → `Api::Admin::OrdersController`
- サービス: `app/services/cancel_order_service.rb` → `CancelOrderService`
- ジョブ: `app/jobs/expire_unpaid_orders_job.rb` → `ExpireUnpaidOrdersJob`

### ビジネスルール抽出の着目点

コードからビジネスルールを抽出する際に着目すべきパターン:

| 着目点 | このプロジェクトでの表現 | 例 |
|--------|----------------------|-----|
| 入力制約 | `validates` / `validate` メソッド / フォームオブジェクト | `validates :email, uniqueness: { scope: :shop_id }` |
| ライフサイクルフック | `before_*` / `after_*` / `around_*` コールバック | `after_create :notify_shop_owner` |
| 状態・種別の定義 | `enum` 宣言 | `enum :status, { draft: 0, confirmed: 1 }` |
| データのフィルタリング | `scope` / `default_scope` | `scope :active, -> { where(deleted_at: nil) }` |
| 条件分岐 | `if` / `unless` / `case` + ビジネス条件 | `if order.within_grace_period?` |
| 外部通信 | サービス内の API クライアント呼び出し、ジョブ投入 | `PaymentGateway.charge(order)` |
| 状態遷移 | ステータス変更メソッド、state machine | `def confirm!` |
| 認可 | Pundit ポリシーの条件 | `def cancel?; record.cancellable?; end` |
