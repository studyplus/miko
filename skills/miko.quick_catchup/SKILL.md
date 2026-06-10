---
description: コード変更（git diff / PR）から proposal を作成し、business_rules.md と high_level_design.md を更新する。
---

## 入力

```text
$ARGUMENTS
```

入力の形式: `<capability_name> [diff_source]`

- 例: `/miko.quick_catchup order_management` — カレントブランチのベースブランチからの diff を使用
- 例: `/miko.quick_catchup order_management #8250` — PR の diff を使用
- 例: `/miko.quick_catchup order_management HEAD~3..HEAD` — git range を使用
- 空の場合はエラー: 「⛩️  ケイパビリティ名をお願いいたします（例: `/miko.quick_catchup order_management`）」

---

## このスキルの役割

miko フローを通さずに入ったコード変更（緊急 FIX 等）を、ドキュメントに追従させる。

`miko.catchup` がケイパビリティ全体をフルスキャンするのに対し、このスキルは **特定のコード差分だけ** を対象にする。差分から proposal を作成し、BR/HLD を更新する。

**出力:**
- `miko/<capability>/proposals/YYYY-MM-DD-<title>.md` — 変更の経緯を記録
- `miko/<capability>/business_rules.md` — 更新（必要な場合）
- `miko/<capability>/high_level_design.md` — 更新（必要な場合）

---

## 手順

### 1. system_high_level_design.md の追従確認

ユーザーに確認する:

> ⛩️  キャッチアップの前に確認でございます。`/miko.catchup_system_hld` は実施済みでしょうか？
> `system_high_level_design.md` が古いままですと、コード探索のスコープがずれる恐れがございます。

- ユーザーが「実施済み」「不要」等と回答した場合 → 次に進む
- ユーザーが「まだ」「やってほしい」等と回答した場合 → `/miko.catchup_system_hld` の実行を案内し、完了後に `/miko.quick_catchup` を再実行するよう伝えて中止する

### 2. 入力検証・資料読み込み

**入力検証:**
- `$ARGUMENTS` からケイパビリティ名を取得し、スネークケースに正規化する
- diff ソースを特定:
  - `#数字` → PR として `gh pr diff` で取得
  - `A..B` や `HEAD~N..HEAD` → git range として `git diff` で取得
  - 省略 → 主さまにベースブランチ名を確認し（例: 「ベースブランチ（マージ先）を教えてくださいませ」）、そこからの diff を使用。自動推定はしない

**読み込むファイル:**
- `.miko/guides/business_rules_guide.md` — ルールの書き方、判定テスト
- `.miko/guides/tone_guide.md` — 対話スタイル。**このファイルの口調・絵文字ルールに従うこと**
- `miko/system_high_level_design.md` — コード探索ガイド（着目点の参照）
- `miko/<capability>/business_rules.md` — 現在のビジネスルール。**存在しない場合はエラー:**
  > ⛩️  `miko/<capability>/business_rules.md` が見つかりません。
  > - 新規作成は `/miko.new_cap <capability>` をお使いください
- `miko/<capability>/high_level_design.md` — 現在の構造（あれば）

**探索対象外:** `.miko/` ディレクトリは miko の内部リソースであり、プロジェクトのコードではない。探索・精読の対象にしないこと。

### 3. diff の読み取り

diff を取得し、以下を整理する:

- **変更ファイル一覧**（テスト・ドキュメントを除く実装ファイル）
- **変更の要約** — 何がどう変わったか（追加・変更・削除）
- **変更の意図の推定** — コミットメッセージ、PR タイトル/本文があれば参照

### 4. ビジネスルールへの影響分析

diff の内容と既存の business_rules.md を突き合わせ、以下を特定する:

- **新設が必要なルール** — diff に新しいビジネス判断が含まれている場合
- **改訂が必要なルール** — 既存ルールの条件や振る舞いが変わっている場合
- **実装マッピングの更新** — ルール自体は変わらないがコードの場所が変わった場合
- **影響なし** — 技術的な変更のみでビジネスルールに影響しない場合

新設・改訂候補には `.miko/guides/business_rules_guide.md` の判定テストを適用する。

### 5. 【確認】影響分析の確認

diff ソース、変更の要約、ビジネスルールへの影響（新設/改訂/マッピング更新/HLD影響/影響なし）をユーザーに提示し、確認を取る。変更の意図や背景について補足があれば聞く（コードだけでは「なぜ」がわからないことがある）。

### 6. proposal 作成

確認を踏まえ、proposal を生成する。

**ファイル名:** `miko/<capability>/proposals/YYYY-MM-DD-<kebab-case-title>.md`

**構造:** `.miko/examples/proposal.md` に準ずる。quick_catchup 固有の違い:
- 冒頭に「このプロポーザルはコード変更から事後的に作成されたものです。」と付記
- 影響範囲に diff ソースと変更ファイル一覧を記載する

### 7. proposal 適用（business_rules.md 更新）

**読み込み:**
- `.miko/examples/business_rules.md` — 品質基準

**ステップ 6 で生成した proposal の内容を business_rules.md に反映する。**
- proposal の新設・改訂を適用する
- 実装マッピングを更新する
- 新しい用語があれば `miko/glossary.md` に追加する（`.miko/examples/glossary.md` のフォーマットに従う）

### 8. high_level_design.md 更新

- `.miko/examples/high_level_design.md` — 品質基準として読み込む
- 構造に変更があった場合のみ更新する

**更新内容を提示し、主さまの確認を取る。**

### 9. 完了報告

ケイパビリティ名、diff ソース、proposal パス、ルール変更件数（新設/改訂/マッピング更新）、HLD 更新有無をサマリーテーブルで提示する。
