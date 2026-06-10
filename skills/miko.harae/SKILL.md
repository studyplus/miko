---
description: 既存の harae.md を棚卸し・差分探索する。proposal 付きの場合は proposal 内に検証結果を記録する。
---

## 入力

```text
$ARGUMENTS
```

入力の形式: `<capability_name>` または `<capability_name> <proposal_path>`

- 例: `/miko.harae order_management`（現行 BR を再検証）
- 例: `/miko.harae order_management miko/order_management/proposals/2026-03-08-cancel-email.md`（proposal 適用後の BR を検証）
- 空の場合はエラー: 「⛩️  ケイパビリティ名をお願いいたします（例: `/miko.harae order_management`）」

**`miko/<capability>/harae.md` が存在しない場合はエラー:**

> ⛩️  `miko/<capability>/harae.md` が見つかりません。
> まず `/miko.new_harae <capability>` で初回検証を行ってください。

**proposal が指定されていない場合:**

```
⛩️  何を検証いたしましょうか？

1. 現行の business_rules.md を再検証する
2. proposal を適用した状態で検証する（proposal のパスをお願いいたします）
```

---

## このスキルの役割

既存の harae.md を起点に、ビジネスルールの検証を継続する。

**「問題ないことの確認」ではなく「問題の発見」に全振りしたスキル。** 問題が見つからなければ成果物はゼロ。

**成果物:**
- proposal なしの場合: `miko/<capability>/harae.md` を更新する
- proposal 付きの場合: **proposal ファイル内に「祓え検証」セクションを追記する。harae.md は更新しない。** proposal はまだ確定していないため、harae.md への永続化は実装完了時（miko.speckit.implement / miko.quick_impl）に行う

**検証の6軸:** `.miko/guides/harae_guide.md` に定義された6軸（内部矛盾・不完全性・境界の曖昧さ・時間軸の破綻・ビジネス毀損・悪用耐性）で検証する。proposal 付きの場合は6軸に加えて「既存への影響（proposal の変更で既存の本番エンティティが意図せず壊れないか）」も検証する。

**使用タイミング:**
- `/miko.propose` 後 — proposal 適用後のルール体系を検証
- 任意のタイミング — 既存ルールの健全性チェック

**フローでの位置づけ:**

```
/miko.propose → proposal 作成
/miko.harae <capability> <proposal> → proposal 適用後のルールを検証
→ OK なら speckit フローへ
```

---

## モード判定

| proposal | モード |
|---|---|
| なし | **再実行モード** — 棚卸し + 差分探索 |
| あり | **proposal 検証モード** — proposal を仮想適用して検証。**指摘は proposal に追記し、harae.md は更新しない** |

---

## 再実行モード

proposal が指定されていない場合。メインセッションで棚卸しと差分探索を行う。

### 1. 資料の読み込み

- `.miko/guides/tone_guide.md` — 対話スタイル。**このファイルの口調・絵文字ルールに従うこと**
- `.miko/guides/harae_guide.md` — 6軸の検査手順（差分探索で参照する）
- `miko/<capability>/business_rules.md`
- `miko/<capability>/high_level_design.md` — あれば
- `miko/<capability>/harae.md` — 既存の指摘リスト
- `miko/glossary.md` — あれば

### 2. 棚卸し

既存の harae.md の open 指摘を現在の business_rules.md と突き合わせる:

- **関連ルールが廃止・改訂されている** → ステータスを `obsolete` に変更
- **関連ルールが健在で指摘が依然として有効** → `open` のまま維持

棚卸し結果をユーザーに報告する。

### 3. 差分探索

メインセッションが6軸で新たな指摘を探索する。既存の指摘（全ステータス）と重複するものは除外する。

### 4. harae.md 更新

棚卸し結果と新たな指摘を harae.md に反映する。

### 5. 対話

指摘について主さまと対話し、対処を決める。

- **ルール修正が必要** → 軽微であれば business_rules.md の修正案を直接提示する。大きな変更であれば proposal の作成を提案する。対処後、該当指摘のステータスを `resolved` に更新し、解決内容を記録する
- **問題なしと判断** → ステータスを `dismissed` に更新し、却下理由を記録する
- **追加調査が必要** → コードを確認して追加情報を提供

対話の結果を harae.md に反映する。

**指摘がない場合はこのステップをスキップする。**

### 6. 完了

棚卸し結果（obsolete 件数）、新たな指摘数、ステータス内訳（resolved/dismissed/open）をサマリーテーブルで提示する。

---

## proposal 検証モード

proposal が指定されている場合。proposal を仮想適用した BR を検証し、**指摘は proposal に追記する。harae.md は更新しない。**

proposal はまだ確定していないため、harae.md への永続化は実装完了時に行う（miko.speckit.implement / miko.quick_impl のデザインドキュメント更新ステップで harae.md に転記される）。

### 1. 資料の読み込み

- `.miko/guides/tone_guide.md` — 対話スタイル。**このファイルの口調・絵文字ルールに従うこと**
- `.miko/guides/harae_guide.md` — 6軸の検査手順
- `miko/<capability>/business_rules.md`
- `miko/<capability>/high_level_design.md` — あれば
- `miko/<capability>/harae.md` — 既存の指摘リスト（重複排除の参照用）
- `miko/glossary.md` — あれば
- proposal ファイル

**親プロポーザル（umbrella proposal）の検出:**

proposal の先頭に `<umbrella-proposal>` マーカーがある場合、エラーとして中止する:
> ⛩️  親プロポーザル（umbrella proposal）は直接検証できません。
> 分割前の通常プロポーザル、またはサブプロポーザルを指定してください。

**横断プロポーザルの検出:**

proposal に「他ケイパビリティへの影響」セクションがある場合、影響先ケイパビリティごとに以下も読み込む:
- `miko/<affected_capability>/business_rules.md`
- `miko/<affected_capability>/high_level_design.md` — あれば
- `miko/<affected_capability>/harae.md` — あれば（重複排除の参照用）

### 2. 攻撃的検証

メインセッションとサブエージェントで役割を分担する:

**メインセッション — 6軸の差分探索:**
proposal のルール変更を仮想適用した BR 体系に対して、6軸で新たな指摘を探索する。既存の harae.md の指摘（全ステータス）と重複するものは除外する。

横断プロポーザルの場合は、影響先ケイパビリティの BR に対しても「他ケイパビリティへの影響」セクションの変更を仮想適用し、6軸で検証する。影響先の harae.md に既存の指摘がある場合は重複を除外する。

**サブエージェント — 既存エンティティへの影響検証:**
proposal の変更が既存の本番エンティティを意図せず壊さないかを検証する。メインの差分探索と並列で起動する。

サブエージェントに渡す情報:
- `.claude/skills/miko.harae/guides/review_entity_enumeration_guide.md` のパス — 「このファイルを読み、フェーズ 1〜3 の指示に正確に従え」と指示する
- `miko/<capability>/business_rules.md` のパス
- `miko/<capability>/high_level_design.md` のパス（あれば）
- `miko/system_high_level_design.md` のパス（あれば）
- `miko/glossary.md` のパス（あれば）
- proposal のパス

横断プロポーザルの場合は、影響先ケイパビリティごとにもサブエージェントを並列起動する。各サブエージェントには影響先の `business_rules.md`・`high_level_design.md`（あれば）のパスも渡し、proposal の「他ケイパビリティへの影響」セクションのうち該当ケイパビリティの変更を検証対象として指示する。

**結果の統合:**
サブエージェントの結果を受け取り、「ルール定義の欠陥」は proposal への指摘に追加、「実装との不整合」と「判断できない」は対話ステップでユーザーに報告・質問する。横断プロポーザルの場合は、指摘がどのケイパビリティに属するかを明示する。

### 3. 対話

指摘について主さまと対話し、対処を決める。

- **proposal の修正が必要** → proposal のビジネスルール変更セクションの修正を提案する。対処後、該当指摘のステータスを `resolved` に更新する
- **問題なしと判断** → ステータスを `dismissed` に更新し、却下理由を記録する
- **追加調査が必要** → コードを確認して追加情報を提供

**指摘がない場合はこのステップをスキップする。**

### 4. proposal に祓え検証セクションを追記

対話の結果を反映し、proposal ファイルの末尾に「祓え検証」セクションとして追記する。このセクションは **harae.md に対する差分操作** を記述するもので、実装完了時（miko.speckit.implement / miko.quick_impl）に harae.md へ適用される。

**フォーマット:** `.miko/examples/proposal.md` の「祓え検証」セクションに従う。注意点:
- 「既存指摘のステータス変更」は該当がなければ省略する
- 「新規指摘」は harae.md にコピペできる形式で書く。番号は転記時に採番するため書かない
- open の新規指摘にはステータス・解決フィールドを書かない（転記時に `open` / `—` として補完する）
- 対話で resolved / dismissed になった新規指摘のみ、ステータスと解決理由を含める
- 横断プロポーザルの場合、影響先ケイパビリティへの指摘は **対象ケイパビリティ名を明示して** 記載する（例: `### 影響先: notification` のようにケイパビリティごとにサブセクションを分ける）。転記時に各ケイパビリティの harae.md へ振り分けられる

### 5. 完了

proposal パス、新たな指摘数、ステータス内訳（resolved/dismissed/open）をサマリーテーブルで提示する。harae.md は実装完了時に転記される旨を注記する。
