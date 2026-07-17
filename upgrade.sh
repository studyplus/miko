#!/bin/bash
set -euo pipefail

REPO="studyplus/miko"
BRANCH="main"
SKILLS_DIR=".claude/skills"
VERSION_FILE=".miko/VERSION"
OLD_VERSION_FILE="$SKILLS_DIR/_miko/VERSION"

# 言語設定: .miko/config の language (ja/en) を読む。なければ ja
LANG_CHOICE="ja"
if [ -f ".miko/config" ]; then
  LANG_CHOICE=$(grep -E '^language=' .miko/config | head -n 1 | cut -d= -f2 | tr -d '[:space:]')
  [ "$LANG_CHOICE" = "en" ] || LANG_CHOICE="ja"
fi

# スキル名の区切り文字設定: .miko/config の separator (./-) を読む。なければ .
SEP="."
if [ -f ".miko/config" ]; then
  sep_val=$(grep -E '^separator=' .miko/config | head -n 1 | cut -d= -f2 | tr -d '[:space:]' || true)
  [ "$sep_val" = "-" ] && SEP="-"
fi

# to_local <name> — 正規スキル名（. 区切り）を設定された区切り文字の名前に変換する
to_local() { echo "${1//./$SEP}"; }

# rewrite_skill_refs <path>... — ファイル中のスキル名参照 (miko.foo) を設定された区切り文字に書き換える
rewrite_skill_refs() {
  [ "$SEP" = "." ] && return 0
  local sed_script="" name esc
  for name in "${latest_skills[@]}"; do
    esc="${name//./\\.}"
    sed_script="${sed_script}s/${esc}/$(to_local "$name")/g;"
  done
  find "$@" -type f -name '*.md' | while IFS= read -r f; do
    sed -i.mikobak "$sed_script" "$f" && rm -f "$f.mikobak"
  done
}

# say <ja> <en> — 言語設定に応じたメッセージを出力する
say() {
  if [ "$LANG_CHOICE" = "en" ]; then echo "$2"; else echo "$1"; fi
}

if [ ! -d ".claude" ]; then
  say "⛩️  .claude ディレクトリが見つかりません。プロジェクトのルートで実行くださいませ。" \
      "⛩️  .claude directory not found. Please run this from your project root."
  exit 1
fi

if ! command -v claude &> /dev/null; then
  say "⛩️  claude (Claude CLI) が必要です。https://claude.com/claude-code からインストールくださいませ。" \
      "⛩️  claude (Claude CLI) is required. Please install it from https://claude.com/claude-code."
  exit 1
fi

# miko がインストールされているか確認（VERSION ファイルまたは miko スキルの存在）
if [ ! -f "$VERSION_FILE" ] && [ ! -f "$OLD_VERSION_FILE" ] && ! ls -d "$SKILLS_DIR"/miko.* &> /dev/null && ! ls -d "$SKILLS_DIR"/miko-* &> /dev/null; then
  say "⛩️  miko がインストールされていません。install.sh で初回インストールをお願いいたします。" \
      "⛩️  miko is not installed. Please run install.sh for the initial installation."
  exit 1
fi

# VERSION ファイル: 1行目=セマンティックバージョン, 2行目=タイムスタンプ(YYYYMMDDhhmm)
# VERSION がない or タイムスタンプ行がない場合は 0 として扱い、全マイグレーションを実行する
# 旧パス（.claude/skills/_miko/VERSION）にもフォールバック
if [ -f "$VERSION_FILE" ]; then
  current_semver=$(sed -n '1p' "$VERSION_FILE" | tr -d '[:space:]')
  current_ts=$(sed -n '2p' "$VERSION_FILE" | tr -d '[:space:]')
elif [ -f "$OLD_VERSION_FILE" ]; then
  current_semver=$(sed -n '1p' "$OLD_VERSION_FILE" | tr -d '[:space:]')
  current_ts=$(sed -n '2p' "$OLD_VERSION_FILE" | tr -d '[:space:]')
fi
if [ "$LANG_CHOICE" = "en" ]; then
  current_semver="${current_semver:-unknown}"
else
  current_semver="${current_semver:-不明}"
fi
current_ts="${current_ts:-0}"

say "⛩️  現在のバージョン: $current_semver ($current_ts)" \
    "⛩️  Current version: $current_semver ($current_ts)"

say "🌿 最新版を取得しております..." \
    "🌿 Fetching the latest version..."
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/miko"
curl -fsSL "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" | tar -xz -C "$tmpdir/miko" --strip-components=1

latest_semver=$(sed -n '1p' "$tmpdir/miko/ofuda/VERSION" | tr -d '[:space:]')
latest_ts=$(sed -n '2p' "$tmpdir/miko/ofuda/VERSION" | tr -d '[:space:]')

if [ "$current_ts" = "$latest_ts" ]; then
  say "✨ 既に最新バージョン ($latest_semver) です。" \
      "✨ Already on the latest version ($latest_semver)."
  exit 0
fi

say "🌿 $current_semver → $latest_semver へ更新いたします" \
    "🌿 Updating $current_semver → $latest_semver"

# 現在のタイムスタンプより大きいマイグレーションを昇順で収集
migrations_dir="$tmpdir/miko/migrations"
migration_files=()

if [ -d "$migrations_dir" ]; then
  for f in $(ls "$migrations_dir"/*.md 2>/dev/null | sort); do
    ts=$(basename "$f" .md)
    if [ "$ts" -gt "$current_ts" ]; then
      migration_files+=("$f")
    fi
  done
fi

# マイグレーション実行
if [ ${#migration_files[@]} -gt 0 ]; then
  echo ""
  say "📜 マイグレーションを実行いたします（${#migration_files[@]} 件）..." \
      "📜 Running migrations (${#migration_files[@]})..."
  say "   ※ マイグレーションは1件あたり数分かかることがございます。しばらくお待ちくださいませ。" \
      "   Note: each migration may take a few minutes. Please wait."
  for f in "${migration_files[@]}"; do
    ts=$(basename "$f" .md)
    echo "  ⛩️  $ts ..."
    # $MIKO_LATEST をマイグレーションプロンプト内のパス参照用に展開する
    prompt=$(cat "$f" | sed "s|\$MIKO_LATEST|$tmpdir/miko|g")
    if ! claude -p "$prompt" --allowedTools "Edit,Read,Write,Glob,Grep"; then
      say "  ❌ $ts でエラーが発生しました。中断いたします。" \
          "  ❌ Migration $ts failed. Aborting."
      exit 1
    fi
    say "  ✨ $ts 完了" \
        "  ✨ $ts done"
  done
  echo ""
fi

# 旧ディレクトリの削除（v0.2.x 以前からの移行）
if [ -d "$SKILLS_DIR/_miko" ]; then
  say "🌿 旧ディレクトリ $SKILLS_DIR/_miko を削除しております..." \
      "🌿 Removing the legacy directory $SKILLS_DIR/_miko..."
  rm -rf "$SKILLS_DIR/_miko"
fi

# 最新版に存在する miko.* スキル名（正規名、. 区切り）を収集
latest_skills=()
for d in "$tmpdir"/miko/skills/miko.*/; do
  [ -d "$d" ] || continue
  latest_skills+=("$(basename "$d")")
done

# .miko/protected_skills からプロテクト対象スキルを読み込む
# フォーマット: 1行1スキル名（# で始まる行はコメント、空行は無視）
PROTECTED_SKILLS_FILE=".miko/protected_skills"
protected_skills=()
if [ -f "$PROTECTED_SKILLS_FILE" ]; then
  while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    protected_skills+=("$line")
  done < "$PROTECTED_SKILLS_FILE"
fi

if [ ${#protected_skills[@]} -gt 0 ]; then
  echo ""
  say "🔒 以下のスキルはプロテクト済みのため、更新対象から除外いたします:" \
      "🔒 The following skills are protected and will be excluded from the update:"
  for s in "${protected_skills[@]}"; do
    echo "    - $SKILLS_DIR/$s"
  done
fi

# is_protected <name> — protected_skills に含まれるか判定するヘルパー
# 空配列の展開は bash 3.2 の set -u でエラーになるため、先に件数を確認する
is_protected() {
  local name="$1"
  [ ${#protected_skills[@]} -eq 0 ] && return 1
  for p in "${protected_skills[@]}"; do
    [ "$p" = "$name" ] && return 0
  done
  return 1
}

# 最新版にないローカルの miko スキルのうち、プロテクト済みでないものを削除候補として収集
# ローカルのスキル名は設定された区切り文字なので、正規名を to_local で変換して比較する
removed_skills=()
for d in "$SKILLS_DIR"/miko"$SEP"*/; do
  [ -d "$d" ] || continue
  name=$(basename "$d")
  is_protected "$name" && continue
  found=false
  for s in "${latest_skills[@]}"; do
    [ "$(to_local "$s")" = "$name" ] && found=true && break
  done
  [ "$found" = false ] && removed_skills+=("$name")
done

# 削除されるスキルがあれば一覧表示して確認
if [ ${#removed_skills[@]} -gt 0 ]; then
  echo ""
  say "🗑️  以下のスキルは最新版にないため削除されます:" \
      "🗑️  The following skills are not in the latest version and will be removed:"
  for s in "${removed_skills[@]}"; do
    echo "    - $SKILLS_DIR/$s"
  done
  echo ""
  if [ "$LANG_CHOICE" = "en" ]; then
    read -r -p "Continue? [y/N]: " ans
  else
    read -r -p "続行してよろしいですか? [y/N]: " ans
  fi
  case "$ans" in
    y|Y|yes|YES) ;;
    *)
      say "中断いたしました。" "Aborted."
      exit 1
      ;;
  esac
fi

# スキルファイル更新
say "🌿 スキルファイルを更新しております..." \
    "🌿 Updating skill files..."

# 削除が確定したスキルを個別に削除
if [ ${#removed_skills[@]} -gt 0 ]; then
  for s in "${removed_skills[@]}"; do
    rm -rf "${SKILLS_DIR:?}/$s"
  done
fi

# miko 管理スキルを個別に更新（プロテクト済みはスキップ）
# 配置先はローカル名（設定された区切り文字）
for s in "${latest_skills[@]}"; do
  local_name=$(to_local "$s")
  if is_protected "$local_name"; then
    say "  🔒 $local_name はプロテクト済みのためスキップいたします" \
        "  🔒 $local_name is protected — skipping"
    continue
  fi
  rm -rf "${SKILLS_DIR:?}/$local_name"
  cp -r "$tmpdir/miko/skills/$s" "$SKILLS_DIR/$local_name"
done

# .miko/ を更新: ユーザー作成ファイル（protected_skills, config 等）を保持したまま上書き
# rm -rf は使わず、ofuda の中身を .miko/ にマージコピーする
cp -r "$tmpdir/miko/ofuda/." .miko/

# 言語設定に応じて tone_guide を解決する（config がない既存インストールは ja として config を作成）
if [ ! -f ".miko/config" ]; then
  echo "language=$LANG_CHOICE" > .miko/config
fi
# v1.4.0 より前のインストールには separator 設定がないため補完する（既存はドット区切り）
if ! grep -qE '^separator=' .miko/config; then
  echo "separator=$SEP" >> .miko/config
fi
if [ "$LANG_CHOICE" = "en" ] && [ -f ".miko/guides/tone_guide.en.md" ]; then
  cp .miko/guides/tone_guide.en.md .miko/guides/tone_guide.md
fi
rm -f .miko/guides/tone_guide.en.md

# ハイフン区切りの場合、更新したファイル内のスキル名参照を書き換える
# プロテクト済みスキルはユーザー管理のため書き換えない
if [ "$SEP" != "." ]; then
  rewrite_paths=(.miko)
  for s in "${latest_skills[@]}"; do
    local_name=$(to_local "$s")
    is_protected "$local_name" && continue
    rewrite_paths+=("$SKILLS_DIR/$local_name")
  done
  rewrite_skill_refs "${rewrite_paths[@]}"
fi

echo ""
say "✨ miko を $latest_semver ($latest_ts) に更新いたしました" \
    "✨ miko has been updated to $latest_semver ($latest_ts)"
