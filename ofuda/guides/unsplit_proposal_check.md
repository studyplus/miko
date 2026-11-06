# 未分割プロポーザルの確認

分割（`/miko.split-proposal`）し忘れの `<needs-split>` プロポーザルがないかを確認する手順。呼び出し元のスキルの冒頭で実行する。

## 共通の手順

利用環境のファイル検索・内容検索機能を使用する。トークン節約のため、検索結果はファイルパスのみ取得し、本文全体は出力しない。

1. `miko/*/proposals/*.md` を対象に、ファイル先頭が `<needs-split>` で始まるファイルのパスを取得する。本文途中のマーカーは対象外とする。
2. 0 件なら何も言わず呼び出し元の手順へ戻る。あれば `miko/*/proposals/*-umbrella.md` のパスを取得し、同ディレクトリに `*-<slug>-umbrella.md`（slug は先頭の `YYYY-MM-DD-` と末尾の `.md` を除いたファイル名）があるものは分割済みとして除く。
3. 残りがあれば、呼び出し元の入力への対応より先に報告する。報告後は呼び出し元の手順を続ける:
   > ⛩️  主さま、分割がお済みでない横断プロポーザルがございます: `<path>`（複数なら列挙）。`/miko.split-proposal` でフェーズ分割くださいませ。

検索に失敗した場合は「0 件」と扱わず、確認できなかった旨を報告する。

## 環境別の実行例

以下は共通の手順を実行するための例。同等の検索機能を使用してもよい。

### Claude Code の場合

- 手順 1: Grep ツールで以下を指定する。
  - pattern: `\A<needs-split>`
  - glob: `miko/*/proposals/*.md`
  - multiline: `true`
  - output_mode: `files_with_matches`
- 手順 2: Glob ツールで `miko/*/proposals/*-umbrella.md` を検索する。

### Codex の場合

シェル実行ツールから `rg` を使用する。プロジェクトルートで実行する。

- 手順 1:
  `rg --files-with-matches --multiline '\A<needs-split>' --glob 'miko/*/proposals/*.md' .`
- 手順 2:
  `rg --files --glob 'miko/*/proposals/*-umbrella.md' .`

`rg` の終了コード 1 は該当なしとして扱い、検索エラーと区別する。
