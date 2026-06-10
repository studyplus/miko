---
description: ofuda/VERSION のバージョンとタイムスタンプを更新する。
---

## 入力

```text
$ARGUMENTS
```

入力の形式: `major` / `minor` / `patch`

- 例: `/bump-version patch` → 0.4.2 → 0.4.3
- 例: `/bump-version minor` → 0.4.2 → 0.5.0
- 例: `/bump-version major` → 0.4.2 → 1.0.0
- 空の場合はエラー: 「`major` / `minor` / `patch` のいずれかを指定してください」

## 手順

1. `ofuda/VERSION` を読み込む（1行目: バージョン、2行目: タイムスタンプ）
2. 指定されたレベルに応じてバージョンを上げる:
   - `major`: メジャーを +1、マイナーとパッチを 0 にリセット
   - `minor`: マイナーを +1、パッチを 0 にリセット
   - `patch`: パッチを +1
3. タイムスタンプを現在の UTC 時刻で更新する（フォーマット: `YYYYMMDDHHmm`、12桁、秒なし）
4. `ofuda/VERSION` を書き込む
5. `CHANGELOG.md` の先頭（`# Changelog` の直後）に新バージョンのセクションを追加する:
   - 見出し: `## v{新バージョン} ({YYYY-MM-DD})`（日付は今日の日付）
   - 直近の git log（前のバージョンタグまたは適切な範囲）を参考に、変更内容を `### New` / `### Changed` / `### Optimized` / `### Fixed` のうち該当するカテゴリで記述する
   - 既存の CHANGELOG のスタイルに合わせる
6. 更新前後を表示する
