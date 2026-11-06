# 未分割プロポーザルの確認

分割（`/miko.split-proposal`）し忘れの `<needs-split>` プロポーザルがないかを確認する手順。呼び出し元のスキルの冒頭で実行する。シェルは使わず（OS 依存を避けるため）Grep / Glob のみ。プロポーザルの中身は読まない（トークン節約）。

1. Grep: `\A<needs-split>`、glob `miko/*/proposals/*.md`、multiline、files_with_matches
2. 0 件なら何も言わず呼び出し元の手順へ戻る。あれば Glob `miko/*/proposals/*-umbrella.md` を取り、同ディレクトリに `*-<slug>-umbrella.md`（slug は日付を除いたファイル名）があるものは分割済みとして除く
3. 残りがあれば、呼び出し元の入力への対応より先に報告する。報告後は呼び出し元の手順を続ける:
   > ⛩️  主さま、分割がお済みでない横断プロポーザルがございます: `<path>`（複数なら列挙）。`/miko.split-proposal` でフェーズ分割くださいませ。
