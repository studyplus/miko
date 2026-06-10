---
description: Miko プロポーザルを入力として speckit.specify を拡張し、spec.md を生成する。
handoffs: 
  - label: Build Technical Plan
    agent: miko.speckit.plan
    prompt: Create a plan for the spec. I am building with...
  - label: Clarify Spec Requirements
    agent: miko.speckit.clarify
    prompt: Clarify specification requirements
    send: true
---

## 入力

```text
$ARGUMENTS
```

入力の形式: `<proposal_path>` または `<capability_name>` または `<proposal_path1> <proposal_path2> ...`（複数パス、スペース区切り）

- 例: `/miko.speckit.specify miko/order_management/proposals/2026-02-21-trial-expiry-notification.md`（パスからケイパビリティ名を自動取得）
- 例: `/miko.speckit.specify order_management`（最新のプロポーザルを自動選択）
- 例（クロスケイパビリティ）: `/miko.speckit.specify miko/order_management/proposals/2026-03-18-cancel-notify-phase1.md miko/notification/proposals/2026-03-18-cancel-notify-phase1.md`（同じ親の複数サブを統合 spec として処理）
- 空の場合はエラー: 「⛩️  プロポーザルのパスまたはケイパビリティ名をお願いいたします（例: `/miko.speckit.specify order_management`）」

---

## このスキルの役割

Miko プロポーザルの「機能仕様」セクションを speckit の specify ワークフローに橋渡しする。

**課題:** プロポーザルには「ビジネスルールの変更」と「機能仕様」が含まれるが、そのまま読むと business_rules.md を更新するだけに見える。このスキルが機能仕様を spec.md に展開し、実装フローにつなげる。

**speckit.specify との関係:** このスキルは speckit.specify を **基盤として使用** する。Miko 固有の入力処理・文脈付与を行った上で、speckit.specify のワークフローに合流する。

---

## 手順

### 1. 入力検証

- `$ARGUMENTS` がスペース区切りの複数ファイルパスの場合:
  - 各パスをサブプロポーザルとして使用する
  - すべてのサブプロポーザルが同じ親プロポーザルを持つことを検証する（`<sub-proposal@{親のmiko相対パス}>` マーカーのパスが一致すること）。一致しない場合はエラー:
    > ⛩️  指定されたサブプロポーザルの親が一致しません。同じ親のサブプロポーザルを指定してください。
  - メインケイパビリティ名は、`<sub-proposal@{親のmiko相対パス}>` マーカーのパスからケイパビリティ名を抽出する（例: `order_management/proposals/...` → `order_management`）
- `$ARGUMENTS` が単一のファイルパス（`miko/` で始まる or `.md` で終わる）の場合:
  - そのパスをプロポーザルとして使用
  - パスからケイパビリティ名を抽出（`miko/<capability>/proposals/...` の `<capability>` 部分）
- `$ARGUMENTS` がケイパビリティ名の場合:
  - スネークケースに正規化する
  - `miko/<capability>/proposals/` 内の最新ファイル（日付順）を自動選択する

**親プロポーザル（umbrella proposal）の検出:**
- 選択されたプロポーザルの先頭に `<umbrella-proposal>` マーカーがある場合、エラーとして中止する:
  > ⛩️  親プロポーザルは直接実装できません。サブプロポーザルを指定してください。

**未分割プロポーザルの検出:**
- 選択されたプロポーザルの先頭に `<needs-split>` マーカーがある場合、エラーとして中止する:
  > ⛩️  このプロポーザルは分割が必要です。
  > まず `/miko.split_proposal` でフェーズ分割してから、サブプロポーザルを指定してください。

### 2. プロポーザルと既存資料の読み込み

以下のファイルを読み込む。

**プロポーザル（必須）:**
- 指定された（または自動選択された）プロポーザルファイル（複数の場合はすべて）
- **存在しない場合はエラー:**
  > ⛩️  プロポーザルが見つかりません。
  > `- まず /miko.propose <capability> でプロポーザルを作成してください`

**システム全体の文脈:**
- `miko/system_high_level_design.md` — システム全体のアーキテクチャ、**コード探索ガイド**
- `miko/glossary.md` — 用語集（存在する場合）

**ケイパビリティの文脈:**
- `miko/<capability>/business_rules.md` — メインケイパビリティの現在のビジネスルール
- `miko/<capability>/high_level_design.md` — メインケイパビリティの現在の構造（なければスキップ）
- 複数サブプロポーザルの場合: 各サブのケイパビリティの `business_rules.md` も読み込む

**探索対象外:** `.miko/` ディレクトリは miko の内部リソースであり、プロジェクトのコードではない。探索・精読の対象にしないこと。

### 3. プロポーザルの分解

各プロポーザルから以下を抽出・整理する（複数プロポーザルの場合はすべてから抽出し統合する）:

**spec.md の元ネタにするもの:**
- 「機能仕様」セクション — API / バッチ / UI 等の具体的な振る舞い
- 「背景・動機」セクション — spec.md の文脈として使用
- 「影響範囲」セクション — スコープの定義に使用

**spec.md には入れないもの:**
- 「ビジネスルールの変更」セクション — 参照リンクのみ貼る（ルール本文は入れない）
- 「検討・却下した代替案」セクション — spec.md には不要（プロポーザルに残る）

**複数プロポーザルの統合方針:**
- 機能仕様は各ケイパビリティごとにサブセクションとして整理する
- 背景・動機は共通の親プロポーザルから引用し、各サブプロポーザルの固有動機を補足する
- 影響範囲は全プロポーザルを合算する

### 4. speckit.specify の実行（Miko 拡張）

speckit の `specify` の手順を以下の順で探索して読み込み、基盤として実行する:

1. `.claude/skills/speckit-specify/SKILL.md` — spec-kit の skills モード（`--ai claude` の現デフォルト）
2. `.claude/commands/speckit.specify.md` — commands モード（旧レイアウト）

どちらも存在しない場合はエラー中止する:
> ⛩️  speckit の `specify` スキルが見つかりません。`specify init --ai claude` を先にお願いいたします。

**以下の点を変更する:**

#### 入力の差し替え

speckit.specify の「ユーザーが `/speckit.specify` の後に書いたテキスト」の代わりに、ステップ 3 で抽出した機能仕様を feature description として使用する。

#### spec.md への追加セクション

speckit.specify が生成する spec.md に、以下のセクションを **冒頭（Feature Branch の直後）** に追加する:

```markdown
## Miko コンテキスト

- **ケイパビリティ**: {capability_name}
- **プロポーザル**:
  - [{proposal_filename_1}]({relative_path_1}) — {capability_1}
  - [{proposal_filename_2}]({relative_path_2}) — {capability_2}  ← 複数サブプロポーザルの場合のみ
- **ビジネスルール変更**:
  - {capability_1}: {新設 N 件 / 改訂 N 件 / 廃止 N 件}
  - {capability_2}: {新設 N 件 / 改訂 N 件 / 廃止 N 件}  ← 複数ケイパビリティの場合のみ
- **business_rules.md 更新**: 実装完了後に反映する
```

単一プロポーザルの場合はプロポーザル・ビジネスルール変更ともに1行でよい。

#### User Scenarios の生成方針

プロポーザルの機能仕様から User Scenarios を生成する際、以下を意識する:

- プロポーザルの「影響範囲 > 変更しないもの」は **スコープ外として明示**
- ビジネスルールに紐づく振る舞いは、ルール ID を Acceptance Scenarios 内に注記する
  - 例: `**Then** 注文がキャンセルされる（ORD-03: 猶予期間24時間）`
- 既存の business_rules.md のルールで、今回の変更に影響を受けるものがあれば Edge Cases に含める

#### それ以外の speckit.specify の手順

ブランチ作成、テンプレート読み込み、品質チェック等は speckit.specify の手順をそのまま実行する。

### 5. 完了報告

speckit.specify の報告に加えて、ケイパビリティ名、proposal パス、spec.md パス、ルール変更件数をサマリーテーブルで提示する。BR 更新は実装完了後である旨を注記し、次のアクションとして `/miko.speckit.clarify` → `/miko.speckit.plan` をご案内する。
