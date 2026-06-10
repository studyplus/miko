---
description: speckit.tasks を拡張し、縦割りタスク順序と test_design.md の活用を追加する。
handoffs: 
  - label: Analyze For Consistency
    agent: miko.speckit.analyze
    prompt: Run a project analysis for consistency
    send: true
  - label: Implement Project
    agent: miko.speckit.implement
    prompt: Start the implementation in phases
    send: true
---

## 入力

```text
$ARGUMENTS
```

---

## 対話スタイルと出力言語

`.miko/guides/tone_guide.md` に従うこと。対話の口調・絵文字に加え、生成するドキュメントの言語も同ガイドの「出力言語」ルールに従う。

---

## このスキルの役割

speckit.tasks のワークフローを基盤として実行し、以下を変更する:

1. **縦割りタスク順序** — 操作/機能ごとに完結させてから次に進む
2. **test_design.md の活用** — テストタスクを合意済みテストケースから生成する

---

## 手順

### 1. speckit.tasks の実行（Miko 拡張）

speckit の `tasks` の手順を以下の順で探索して読み込み、基盤として実行する:

1. `.claude/skills/speckit-tasks/SKILL.md` — spec-kit の skills モード（`--ai claude` の現デフォルト）
2. `.claude/commands/speckit.tasks.md` — commands モード（旧レイアウト）

どちらも存在しない場合はエラー中止する:
> ⛩️  speckit の `tasks` スキルが見つかりません。`specify init --ai claude` を先にお願いいたします。

**以下の点を変更する:**

#### 追加の文脈読み込み（Load design documents に追加）

speckit.tasks のステップ 2 で、以下のファイルも追加で読み込む:

- `test_design.md`（FEATURE_DIR 内） — テスト観点とテストケース一覧
- spec.md 内の「Miko コンテキスト」からケイパビリティ名を取得
- `miko/<capability>/business_rules.md` — ルール ID の参照用

`test_design.md` が存在しない場合は警告を出すが続行する:
> ⛩️  `test_design.md が見つかりません。テストタスクは spec.md から生成いたします。`
> `テスト設計を含めるには、先に /miko.speckit.plan を実行くださいませ。`

#### タスク順序の変更: 機能単位で完結させる

speckit.tasks のタスク順序ルールに、以下の **原則** を追加する:

**原則: 複数の機能を開発する場合、実装の詳細は機能単位で完結させてから次の機能に進む。**

悪い例（横割り）:
```
機能Aの実装 → 機能Bの実装 → 機能Aのテスト → 機能Bのテスト
```

良い例:
```
設定・定義（まとめてOK）→ 機能Aの実装 → 機能Aのテスト → 機能Aのクリーンアップ → 機能Bの実装 → 機能Bのテスト → 機能Bのクリーンアップ → 最終フェーズ
```

**まとめてよいもの:**
- ルーティング定義、Swagger 定義、スキーマ変更、モデル定義など、設定・定義レベルのもの
- 行数が少なく、複数を見比べながら設定するほうが整合性を取りやすいもの

**機能単位で分けるもの:**
- コントローラー、サービス、ジョブ等の実装の詳細
- テスト
- 分ける理由: まとめるとレビュー負荷が高くなる

**機能ごとのセルフレビュー（各機能のテスト完了後に実行）:**
1. セルフレビュー — 責務の配置、命名、フレームワーク機能の活用をチェック・修正
2. /simplify 実行 — コードの重複・品質・効率をチェック・修正

**最終フェーズ（必須）:**
1. 機能横断のリファクタリング — 機能間の重複コード整理、命名の統一、モデルの調整等を行う

**補足:**
- 機能が1つしかない場合や、この原則が当てはまらないケースではそのまま speckit.tasks の順序に従う
- 「機能」の粒度は内容に応じて判断する（API エンドポイント、バッチ処理、イベントハンドラ等）

#### テストタスクの生成ルール

**test_design.md がある場合:**
- テストケース一覧の各項目を、対応する操作のテストタスクとして配置する
- テストケースに記載されていないテストは **追加しない**（合意済みケースのみ）
- ルール ID が紐づいているケースは、タスクの説明にルール ID を含める

**test_design.md がない場合:**
- speckit.tasks のデフォルト動作に従う

**テスト除外ルール（test_design.md の有無に関わらず適用）:**
- フレームワークが保証する振る舞い（validates のパラメータチェック等）のテストタスクは生成しない
- 親クラス・共通基盤が担保する処理（認可、認証）のテストタスクは生成しない

#### それ以外の speckit.tasks の手順

セットアップスクリプト実行、チェックリストフォーマット、タスク ID 採番、レポート等は speckit.tasks の手順をそのまま実行する。

### 2. 完了報告

speckit.tasks の報告に加えて、タスク総数・テストタスク数をサマリーテーブルで提示する。次のアクションとして `/miko.speckit.analyze` → `/miko.speckit.implement` をご案内する。
