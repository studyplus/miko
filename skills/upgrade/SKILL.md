---
name: upgrade
description: プラグインとしてインストールされた miko を最新版へ追従させる。.miko/ の資材を更新し、必要なマイグレーションを実行する。/plugin update の後に実行する。
---

## このスキルの役割

プラグインとしてインストールされた miko のアップグレード後処理。`/plugin update` でスキル本体は更新されるが、プロジェクトに配置された `.miko/`（ガイド・実例）と `miko/` 配下のドキュメントは自動では追従しない。このスキルが upgrade.sh 相当の処理を行う:

1. `miko/` 配下ドキュメントへのマイグレーション実行
2. `.miko/` 資材の更新

install.sh でインストールした場合は対象外（upgrade.sh を使う）。

---

## 手順

### 1. インストール形態の判定

この SKILL.md が置かれている場所を確認する。

- **プロジェクトの `.claude/skills/` 配下にある場合:** install.sh によるスクリプトインストール。以下を案内して終了する:
  > ⛩️  スクリプトでインストールされた miko の更新は upgrade.sh をお使いくださいませ:
  > ```
  > bash <(curl -fsSL https://raw.githubusercontent.com/studyplus/miko/main/upgrade.sh)
  > ```
- **それ以外（プラグインキャッシュ配下）の場合:** この SKILL.md の2階層上がプラグインルート。プラグインルート直下に `ofuda/` があることを確認して次に進む

### 2. `.miko/` の確認

プロジェクトルートに `.miko/` が存在するか確認する。存在しない場合は以下を案内して終了する:

> ⛩️  `.miko/` が見つかりません。まずは `/miko:setup` で初期化をお願いいたします。

### 3. バージョン比較

- `.miko/VERSION` を読む（1行目: セマンティックバージョン、2行目: タイムスタンプ `YYYYMMDDHHmm`）。タイムスタンプ行がない場合は `0` として扱う
- `<plugin_root>/ofuda/VERSION` を読む（同形式）
- タイムスタンプが同じ場合は以下を報告して終了する:
  > ✨ 既に最新バージョン（{バージョン}）です。
- 異なる場合は「{現在} → {最新} へ更新いたします」と伝えて次に進む

### 4. マイグレーション実行

`<plugin_root>/migrations/*.md` を昇順で確認し、ファイル名（タイムスタンプ）が `.miko/VERSION` の現在タイムスタンプより大きいものを対象とする。

対象があれば、古いものから順に:

1. マイグレーションファイルを読み込む
2. 本文中の `$MIKO_LATEST` はプラグインルートの絶対パスとして読み替える
3. 記載された指示をそのまま実行する（対象はプロジェクトの `miko/` 配下ドキュメント）

対象がなければこのステップをスキップする。

### 5. `.miko/` の更新

1. `cp -r <plugin_root>/ofuda/. .miko/` を実行する（マージコピー。`.miko/config` や `.miko/protected_skills` などユーザー作成ファイルは保持される）
2. `.miko/config` が存在しない場合は `language=ja` で作成する
3. `.miko/config` の `language` が `en` の場合は `cp .miko/guides/tone_guide.en.md .miko/guides/tone_guide.md` を実行する
4. 言語によらず `rm -f .miko/guides/tone_guide.en.md` を実行する

### 6. 完了報告

> ✨ miko を {新バージョン} ({新タイムスタンプ}) に更新いたしました

実行したマイグレーションがあれば件数と内容を添える。
