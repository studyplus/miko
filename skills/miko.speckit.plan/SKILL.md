---
description: speckit.plan を拡張し、テスト設計（test_design.md）を追加生成する。
handoffs: 
  - label: Create Tasks
    agent: miko.speckit.tasks
    prompt: Break the plan into tasks
    send: true
  - label: Create Checklist
    agent: miko.speckit.checklist
    prompt: Create a checklist for the following domain...
---

## 入力

```text
$ARGUMENTS
```

---

## このスキルの役割

speckit.plan のワークフローを基盤として実行し、実装設計に加えて **テスト設計（test_design.md）** を生成する。

テスト設計は日本語で合意するレベルの粒度で、テストコードではない。「何をテストするか」をビジネスルールと紐づけて定義し、実装フェーズでのテスト作成の元ネタにする。

---

## 手順

### 1. speckit.plan の実行

speckit の `plan` の手順を以下の順で探索して読み込み、基盤として実行する:

1. `.claude/skills/speckit-plan/SKILL.md` — spec-kit の skills モード（`--ai claude` の現デフォルト）
2. `.claude/commands/speckit.plan.md` — commands モード（旧レイアウト）

どちらも存在しない場合はエラー中止する:
> ⛩️  speckit の `plan` スキルが見つかりません。`specify init --ai claude` を先にお願いいたします。

**以下の点を変更する:**

#### 追加の文脈読み込み（Load context に追加）

speckit.plan のステップ 2（Load context）で、以下のファイルも追加で読み込む:

- spec.md 内の「Miko コンテキスト」セクションからプロポーザルのパスとケイパビリティ名を取得
- `miko/<capability>/business_rules.md` — 現在のビジネスルール
- `miko/<capability>/high_level_design.md` — 現在の構造（なければスキップ）
- `miko/<capability>/harae.md` — 攻撃的検証の指摘リスト（なければスキップ。テスト設計で重点箇所の参考にする）
- プロポーザルファイル — ビジネスルール変更の詳細

**Miko コンテキストがない場合（speckit.specify から来た場合）:**
- ケイパビリティ名を spec.md の内容から推定する
- business_rules.md が見つかればそれを読み込む。見つからなければ Miko 文脈なしで続行する（speckit.plan と同じ動作）

#### Phase 1 の拡張

speckit.plan の Phase 1（Design & Contracts）の成果物に加えて、**test_design.md** を生成する（詳細は後述のステップ 2）。

#### それ以外の speckit.plan の手順

Phase 0（Research）、スクリプト実行、Constitution Check 等は speckit.plan の手順をそのまま実行する。

### 2. テスト設計の生成

Phase 1 完了後、以下の手順で `test_design.md` を生成する。

#### 2-1. テスト観点の抽出

spec.md の機能要件・ユーザーシナリオと、business_rules.md のルールを突き合わせて、テスト観点を抽出する。harae.md がある場合は、open / resolved の指摘を重点的にテストすべき箇所として参考にする。

**テスト観点の例:**
- 状態遷移: 遷移条件の充足/不充足
- 副作用: コールバック連鎖、ジョブ投入、メール送信
- 計算/導出: ビジネスルールに基づく計算ロジック
- 境界: 期間・数量の境界条件
- データ整合性: 複数モデル間の一貫性

#### 2-2. テストケース一覧の作成

各テスト観点について、1〜2行の日本語でテストケースを列挙する。

**テストケースの書き方:**
- ビジネスルール ID と紐づけられるものは紐づける（例: `（ORD-01）`）
- 操作/機能ごとにグルーピングする
- テストコードではなく、日本語で「何を確認するか」を書く

#### 2-3. テスト除外ルールの適用

以下はテストケースに **含めない**:

- **フレームワークが保証する振る舞い**: `validates` のパラメータチェック（`presence: true` に対する空値テスト等）
- **親クラス・共通基盤が担保する処理**: 認可チェック、認証チェック、403/401 レスポンス等
- **単純な CRUD の正常系**: ビジネスロジックが絡まないもの

**テストすべきもの:**

- ビジネスルール固有のロジック（状態遷移の条件、計算ロジック、期間判定等）
- 複数モデルにまたがる副作用（コールバック連鎖、関連レコードの生成/更新等）
- 条件分岐が絡む処理パターン（ステータスによる挙動の違い等）

#### 2-4. ファイル生成

spec.md と同じディレクトリに `test_design.md` を生成する。構造:
- **Miko コンテキスト** — ケイパビリティ名、参照ルール ID
- **テスト観点** — 該当するもののみ（状態遷移/副作用/計算・導出/境界/データ整合性）
- **テストケース一覧** — 操作・機能ごとにグルーピング。各ケースにルール ID を紐づける
- **テスト対象外** — 除外ルールに基づいて意図的に含めなかったもの。省略せず明記する

### 3. 完了報告

speckit.plan の報告に加えて、ケイパビリティ名、test_design.md パス、テスト観点数・テストケース数・テスト対象外数をサマリーテーブルで提示する。次のアクションとして `/miko.speckit.tasks` をご案内する。
