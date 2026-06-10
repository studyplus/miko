---
description: ビジネスルールの初回攻撃的検証。harae.md をゼロから生成する。
---

## 入力

```text
$ARGUMENTS
```

入力の形式: `<capability_name>`

- 例: `/miko.new_harae order_management`
- 空の場合はエラー: 「⛩️  ケイパビリティ名をお願いいたします（例: `/miko.new_harae order_management`）」

**`miko/<capability>/harae.md` が既に存在する場合はエラー:**

> ⛩️  `miko/<capability>/harae.md` は既に存在いたします。
> 既存の検証結果を更新する場合は `/miko.harae <capability>` をお使いください。

---

## このスキルの役割

ビジネスルールの定義自体に欠陥がないかを攻撃的に検証し、`miko/<capability>/harae.md` を新規生成する。

**「問題ないことの確認」ではなく「問題の発見」に全振りしたスキル。**

**成果物:** `miko/<capability>/harae.md` — 指摘リストとそのステータスを管理する。

**検証の6軸:** `.miko/guides/harae_guide.md` に定義された6軸（内部矛盾・不完全性・境界の曖昧さ・時間軸の破綻・ビジネス毀損・悪用耐性）で検証する。

**使用タイミング:**
- `/miko.new_cap` 後 — 定義したルールの初回検証

**フローでの位置づけ:**

```
/miko.new_cap → ルール定義
/miko.new_harae → ルールの弱点を探す（初回）
/miko.harae → 既存の harae.md を棚卸し・差分探索（2回目以降）
```

---

**harae.md のフォーマット・ステータス管理:** `.miko/guides/harae_format_guide.md` に従う。

---

## 手順

### 1. 資料の読み込み

- `.miko/guides/tone_guide.md` — 対話スタイル。**このファイルの口調・絵文字・出力言語ルールに従うこと**
- `.miko/guides/harae_format_guide.md` — harae.md のフォーマットとステータス管理ルール
- `miko/<capability>/business_rules.md` — **存在しない場合はエラー:**
  > ⛩️  `miko/<capability>/business_rules.md` が見つかりません。
  > まず `/miko.new_cap <capability>` でケイパビリティを定義してください。
- `miko/<capability>/high_level_design.md` — あれば
- `miko/glossary.md` — あれば

### 2. 攻撃的検証（サブエージェント並列）

3つのサブエージェントを並列で起動する。

**各サブエージェントに渡す情報:**
- `.miko/guides/harae_guide.md` のパス — 「このファイルの自分の担当セクション（A / B / C）を読み、その指示に正確に従え」と指示する
- `miko/<capability>/business_rules.md` のパス
- `miko/<capability>/high_level_design.md` のパス（あれば）
- `miko/glossary.md` のパス（あれば）
- 担当の識別子: `A`, `B`, `C`

| サブエージェント | 担当軸 | 共通する視点 |
|---|---|---|
| A | 内部矛盾 + 不完全性 | ルール体系の論理的整合性 |
| B | 境界の曖昧さ + 時間軸の破綻 | ルールの精度と堅牢性 |
| C | ビジネス毀損 + 悪用耐性 | ルール通りでも結果がまずい |

各サブエージェントは **指摘リストのみ** 返す。問題が見つからなければ「指摘なし」。

### 3. 結果統合・ファイル生成

サブエージェントの結果を統合し、重複を排除して `harae.md` を生成する。

**指摘がない場合も `harae.md` を生成する。** 指摘一覧テーブルは空にし、詳細セクションに「6軸すべてで指摘事項なし」と記載する。

### 4. 対話

指摘について主さまと対話し、対処を決める。

- **ルール修正が必要** → 軽微であれば business_rules.md の修正案を直接提示する。大きな変更であれば proposal の作成を提案する。対処後、該当指摘のステータスを `resolved` に更新し、解決内容を記録する
- **問題なしと判断** → ステータスを `dismissed` に更新し、却下理由を記録する
- **追加調査が必要** → コードを確認して追加情報を提供

対話の結果を harae.md に反映する。

**指摘がない場合はこのステップをスキップする。**

### 5. 完了

指摘数とステータス内訳（resolved/dismissed/open）をサマリーテーブルで提示する。open があれば `/miko.harae` による再検証をお勧めする。
