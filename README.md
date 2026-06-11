# ⛩️  miko

日本語 | [English](./README.en.md)

<img src="./logos/miko.png" width="200px">

ビジネスルールドリブン開発のための [Claude Code](https://docs.anthropic.com/en/docs/claude-code) スキルセットでございます。ビジネスルールドリブン開発は一般的な用語ではなく、miko で定義した開発手法になります。

名前の由来は巫女。神社で神と人の間を取り持つ巫女のように、miko は、主さまと AI がドメイン知識を共有する基盤をお作りいたします。

## ⛩️  思想

### ビジネスルールとは何か

ビジネスルールとは「このビジネスでは何が真か」を記述するもの。「システムがどう振る舞うか」ではございません。

よく似た概念と混同されがちですので、違いをお示しいたします。

| | ビジネスルール | 仕様 | ビジネスロジック |
|---|---|---|---|
| **問い** | 「何が真か」 | 「どう振る舞うか」 | 「どう計算するか」 |
| **例** | 未決済の注文は出荷できない | キャンセルボタンを押すと確認ダイアログを表示する | 合計金額 = 商品価格 × 数量 − 割引額 |
| **実装が変わったら** | 変わらない（ビジネスの判断だから） | 変わりうる（実現方法だから） | 変わりうる（計算手順だから） |
| **置き場所** | `business_rules.md` | proposal の機能仕様 / spec.md | コード |

**迷ったときの判定**: 「実装技術やUIを変えても、この記述は変わらないか？」— Yes ならビジネスルール、No なら仕様でございます。

### なぜビジネスルールか — SDD からの到達

SDD（Specification-Driven Development）を試した結果、詳細すぎる仕様は実装とほぼ一対一になり、実装後はお役目を終えて朽ちてゆくことがわかりました。一方、コードだけでは「なぜ」が読み取れません。ビジネスルールは両方の問題を解決するちょうどいい抽象度にございます。

| レイヤー | 人間の理解 | AI の理解 | 実装後の価値 |
|---|---|---|---|
| SDD 仕様 | 詳細すぎる | 良い | なし（コードを読めばいい） |
| ビジネスルール | ちょうどいい | 良い | **あり（コードに書かれない「なぜ」）** |
| コード | 良い | 毎回読み直す必要あり | コードそのもの |

### ケイパビリティと機能

miko はドキュメントを**ケイパビリティ単位**で整理いたします。機能単位ではございません。

- **ケイパビリティ** = 「注文管理」「在庫管理」「通知配信」のような、ビジネス上の責務の大きなまとまり
- **機能** = 「注文キャンセル」「在庫引き当て」のような個別の操作。ケイパビリティの一部

ケイパビリティ単位にすることで、関連するビジネスルールが一箇所に集まり、ルール間の整合性を保ちやすくなります。

### その他の設計判断

- **speckit はお調べの道具** — speckit の成果物は使い捨て。重い変更のとき、Claude に深くコードを読ませるための仕掛けとして使います。普段の実装は `/miko.quick_impl` で speckit を通さず行います
- **ドキュメントの役割分担** — ルールそのもの（結論）は `business_rules.md` に、なぜそう決めたか（経緯）は proposals に書きます

## 🌿 前提

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) がインストール済みであること
- （Optional）[speckit](https://github.com/github/spec-kit) スキル — フルフロー（`/miko.speckit.*`）をお使いの場合のみ必要でございます。基本フローの `/miko.quick_impl` だけなら不要です

## ✨ インストール

プロジェクトのルートで以下を実行くださいませ。

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/studyplus/miko/main/install.sh)
```

`.claude/skills/` にスキルファイルが配置されます。

インストール時に出力言語（日本語 / English）の選択を求められます。選択した言語は `.miko/config` に保存され、miko の対話と生成ドキュメントがその言語に統一されます。プロンプトを省略したい場合は環境変数で指定できます。

```bash
MIKO_LANG=en bash <(curl -fsSL https://raw.githubusercontent.com/studyplus/miko/main/install.sh)
```

インストール後、プロジェクトのセットアップを行います。

```bash
/miko.setup
```

プロジェクトのコードベースをお調べし、`miko/system_high_level_design.md` を生成いたします。このファイルは miko の全スキルがコード探索の際に参照する手引きとなります。

### アップグレード

既にインストール済みの miko を最新版に更新する場合は、プロジェクトのルートで以下を実行くださいませ。

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/studyplus/miko/main/upgrade.sh)
```

スキルファイルの更新に加え、`miko/` 配下のドキュメント（BR・HLD 等）に必要なマイグレーションを自動で実行いたします。

### カスタムスキルのプロテクト

`miko.*` という名前でご自身のスキルを作成している場合、アップグレード時に削除されないよう **プロテクト** できます。`.miko/protected_skills` にスキル名を1行ずつ記述くださいませ。

```
# .miko/protected_skills
miko.my-custom-skill
miko.another-skill
```

アップグレード時にプロテクト済みスキルは更新対象から除外され、削除・上書きされません。

### 使い方

何をしたらいいか迷ったら `/miko.miko` にお尋ねくださいませ。使い方の案内から「これって BR に書くべき？」のようなご質問まで、何でもお答えいたします。

```bash
/miko.miko
```


## 🎍 ドキュメント体系

miko は `miko/` ディレクトリにケイパビリティ単位でドキュメントを管理いたします。

```
miko/
├── system_high_level_design.md       # システム全体のアーキテクチャ + コード探索ガイド
├── glossary.md                       # 用語集
└── <capability>/
    ├── business_rules.md             # ドメインの判断基準（主役）
    ├── high_level_design.md          # ケイパビリティの構造と全体像
    ├── harae.md                      # 攻撃的検証の指摘リスト
    └── proposals/
        └── YYYY-MM-DD-<title>.md     # 変更提案と経緯
```

| ファイル | 役割 | メンテ |
|---|---|---|
| `system_high_level_design.md` | システム全体のアーキテクチャ。コード探索ガイドを含む | `/miko.setup` で生成、`/miko.catchup_system_hld` で追従 |
| `glossary.md` | 用語の定義（ケイパビリティごとのセクションで管理） | miko がメンテ |
| `business_rules.md` | ドメインの判断基準。コードからは読み取れない「なぜ」を記録 | miko がメンテ |
| `high_level_design.md` | ケイパビリティの構造と全体像 | miko がメンテ |
| `harae.md` | 攻撃的検証の指摘リストとステータス管理 | `/miko.new_harae` が生成、`/miko.harae` が更新 |
| `proposals/` | ケイパビリティへの変更提案と経緯 | 主さまが元ネタを出し、miko と相談しながら書く |

## ⛩️  スキル一覧

### ガイド

| スキル | 用途 |
|---|---|
| `/miko.miko [やりたいこと]` | やりたいことに応じて適切なスキルとフローをご案内 |
| `/miko.version` | miko のバージョンを表示 |

### セットアップ

| スキル | 用途 |
|---|---|
| `/miko.setup [概要]` | プロジェクトに miko を導入。コードベースをお調べし `miko/system_high_level_design.md` を生成 |
| `/miko.catchup_system_hld` | `system_high_level_design.md` をコードベースの現状に追従。ディレクトリ構成の乖離を検出・更新 |

### ドキュメント作成

| スキル | 用途 |
|---|---|
| `/miko.new_cap <capability> [概要]` | 新規ケイパビリティの business_rules.md と high_level_design.md を対話しながら作成。既存コードがあれば活用 |
| `/miko.catchup <capability>` | 既存の business_rules.md と high_level_design.md をコード全体と突き合わせて追従 |
| `/miko.quick_catchup <capability> [diff]` | コード変更（git diff / PR）から proposal を作成し BR/HLD を更新。緊急 FIX 後などに |
| `/miko.propose <capability> [元ネタ]` | 変更プロポーザルを対話しながら作成 |
| `/miko.split_proposal <proposal>` | プロポーザルを親（umbrella）+ サブにフェーズ分割 |
| `/miko.new_harae <capability>` | ビジネスルールの初回攻撃的検証。harae.md をゼロから生成 |
| `/miko.harae <capability> [proposal]` | 既存 harae.md の棚卸し・差分探索。proposal 付きなら proposal 内に検証結果を記録 |

### 実装（基本フロー）

| スキル | 用途 |
|---|---|
| `/miko.quick_impl <proposal \| capability \| 変更指示>` | 変更を speckit を通さず直接実装する基本フロー。proposal なしの変更指示（リファクタリング等）も受け付ける。BR 本文の変更を伴う場合は proposal が必要。スコープを超える重い変更はフルフローにご誘導 |

### 実装（フルフロー — speckit 拡張、重い変更向け）

speckit がインストールされている場合のみ使えます。

| スキル | 用途 |
|---|---|
| `/miko.speckit.specify <proposal_path>` | プロポーザルから spec.md を生成 |
| `/miko.speckit.clarify` | spec.md の不明点を対話で明確化（Optional） |
| `/miko.speckit.plan [feature_dir]` | 実装計画 + テスト設計（test_design.md）を生成。引数はなくてもよい |
| `/miko.speckit.tasks [feature_dir]` | 縦割りタスク順序でタスク一覧を生成。引数はなくてもよい |
| `/miko.speckit.analyze` | ドキュメント間の整合性チェック（Optional） |
| `/miko.speckit.implement [feature_dir]` | フェーズごとの確認停止 + セルフレビュー付きで実装。引数はなくてもよい |

## 🌿 開発フロー

### 初期セットアップ（プロジェクトに miko を導入したとき）

```
/miko.setup
  → コードベースをお調べし、miko/system_high_level_design.md を生成
```

### 新規ケイパビリティの定義

```
/miko.new_cap <capability>
  → 対話しながら business_rules.md + high_level_design.md を作成

/miko.new_harae <capability>
  → 定義したルールの矛盾・穴を攻撃的に検証。harae.md を生成

→ 指摘を修正したら /miko.harae <capability> で再検証をお勧めする
```

### 既存ケイパビリティへの変更

**プロポーザルフェーズ**（チームで合意を取る）

```
/miko.propose <capability> <元ネタ>
  → プロポーザル作成

/miko.harae <capability> <proposal>
  → proposal 適用後のルール体系を攻撃的に検証。指摘は proposal 内に記録

# Optional
/miko.split_proposal <proposal>
  → 変更が大きい場合のみ、親（umbrella）+ サブにフェーズ分割
```

**実装フェーズ（基本: quick_impl）**

```
/miko.quick_impl <capability>
  → speckit を通さず直接実装（単一の意図・既存構造の範囲内の変更が対象）
  → 実装後、business_rules.md + high_level_design.md + harae.md を自動更新
  → スコープを超える場合はフルフローにご誘導
```

**実装フェーズ（フルフロー: speckit — 重い変更のとき）**

複数の意図が絡む、影響範囲の見極めに探索が要る、処理構造が大きく動く — そのような重い変更は speckit フローでお進みくださいませ。分割した場合は各サブ proposal に対して実行いたします。

```
/miko.speckit.specify <capability>
  → spec.md 生成

# Optional
/miko.speckit.clarify
  → 疑問点を明確化

/miko.speckit.plan
  → 実装計画 + テスト設計

/miko.speckit.tasks
  → タスク一覧生成

# Optional
/miko.speckit.analyze
  → 実装前の最終確認

/miko.speckit.implement
  → 実装（機能ごとにセルフレビュー + /simplify）
  → 最終フェーズ後、business_rules.md + high_level_design.md + harae.md を自動更新
```

### proposal を通さないリファクタリング

ビジネスルール本文を変えない変更（リネーム・移動・責務の再配置等）は、proposal を通さず `/miko.quick_impl` に変更指示を直接渡して実装できる。

```
/miko.quick_impl <変更指示>
  → 実装後、影響する実装マッピングを全ケイパビリティ横断で自動更新
  → BR 本文の変更が必要と判定された場合は /miko.propose にご誘導
  → スコープ（意図の単一性・影響範囲の明瞭さ・機械性 or 局所性）を超える場合はフルフローにご誘導
```

### 既存ドキュメントのキャッチアップ

```
# system_high_level_design.md の追従
/miko.catchup_system_hld
  → ディレクトリ構成の乖離を検出し、system_high_level_design.md を更新

# フルスキャン（ケイパビリティ全体を突き合わせ）
/miko.catchup <capability>
  → コード全体と BR/HLD を突き合わせて差分を検出・更新

# 差分ベース（特定のコード変更だけ反映）
/miko.quick_catchup <capability>
  → カレントブランチの diff から proposal 作成 + BR/HLD 更新

/miko.quick_catchup <capability> #8250
  → PR の diff から proposal 作成 + BR/HLD 更新
```

## 🌾 実装時の品質改善

`/miko.quick_impl` は実装後に、`/miko.speckit.implement` は機能ごとに、以下のセルフレビューを自動実行いたします:

1. **セルフレビュー** -- 責務の配置、命名、フレームワーク規約のチェック
2. **/simplify** -- コードの重複・品質・効率のチェック

`/miko.speckit.implement` はさらに、最終フェーズで機能横断のリファクタリングを実行いたします。
