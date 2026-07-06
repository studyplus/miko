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

# スキル名の配布用変換に perl を使う（macOS/Linux で挙動が同一のため）
if ! command -v perl &> /dev/null; then
  say "⛩️  perl が必要です。スキル名の変換に使用いたします。" \
      "⛩️  perl is required; it is used to transform skill names for distribution."
  exit 1
fi

# miko がインストールされているか確認（VERSION ファイルまたは miko スキルの存在。旧命名 miko.* も対象）
if [ ! -f "$VERSION_FILE" ] && [ ! -f "$OLD_VERSION_FILE" ] && ! ls -d "$SKILLS_DIR"/miko-* &> /dev/null && ! ls -d "$SKILLS_DIR"/miko.* &> /dev/null; then
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

# 配布用の共通関数（install_skill, localize_miko_refs）を読み込む
source "$tmpdir/miko/scripts/lib.sh"

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

# 最新版に存在するスキルの配布名（miko-<name>）を収集
latest_skills=()
for d in "$tmpdir"/miko/skills/*/; do
  [ -d "$d" ] || continue
  latest_skills+=("miko-$(basename "$d")")
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
is_protected() {
  local name="$1"
  for p in "${protected_skills[@]}"; do
    [ "$p" = "$name" ] && return 0
  done
  return 1
}

# 旧命名（miko.*）の「標準」スキル一覧を読み込む。
# これに載っている miko.* のみ新命名への移行で削除し、それ以外の miko.*（＝カスタム）は保持する。
legacy_standard=()
if [ -f "$tmpdir/miko/scripts/legacy_skills.txt" ]; then
  while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    legacy_standard+=("$line")
  done < "$tmpdir/miko/scripts/legacy_skills.txt"
fi

# is_legacy_standard <name> — 旧標準スキル（削除して差し支えない）か判定する
is_legacy_standard() {
  local name="$1"
  for l in "${legacy_standard[@]}"; do
    [ "$l" = "$name" ] && return 0
  done
  return 1
}

# 削除候補の収集:
#   - miko-*（現行命名）: プロテクト済みでなく最新版にないもの（miko 管理の名前空間）
#   - miko.*（旧命名）  : 旧標準スキルのみ。未知の miko.* はカスタムとみなし保持する
removed_skills=()
preserved_legacy=()
for d in "$SKILLS_DIR"/miko-*/; do
  [ -d "$d" ] || continue
  name=$(basename "$d")
  is_protected "$name" && continue
  found=false
  for s in "${latest_skills[@]}"; do
    [ "$s" = "$name" ] && found=true && break
  done
  [ "$found" = false ] && removed_skills+=("$name")
done
for d in "$SKILLS_DIR"/miko.*/; do
  [ -d "$d" ] || continue
  name=$(basename "$d")
  is_protected "$name" && continue
  if is_legacy_standard "$name"; then
    removed_skills+=("$name")
  else
    preserved_legacy+=("$name")
  fi
done

# 旧命名のまま保持するカスタムスキルがあれば通知する
if [ ${#preserved_legacy[@]} -gt 0 ]; then
  echo ""
  say "🛡️  以下は miko 標準スキルではないため、旧命名のまま保持いたします（不要であれば手動で削除ください）:" \
      "🛡️  The following are not miko standard skills, so they are kept under their old names (remove them manually if unneeded):"
  for s in "${preserved_legacy[@]}"; do
    echo "    - $SKILLS_DIR/$s"
  done
fi

# 削除されるスキルがあれば一覧表示して確認
if [ ${#removed_skills[@]} -gt 0 ]; then
  echo ""
  say "🗑️  以下の旧標準スキルは新命名（miko-*）へ移行するため削除されます:" \
      "🗑️  The following legacy standard skills will be removed as they migrate to the new names (miko-*):"
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

# miko 管理スキルを個別に更新（プロテクト済みはスキップ）。配布名 miko-<name> へ変換して配置する
for d in "$tmpdir"/miko/skills/*/; do
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  if is_protected "miko-$name"; then
    say "  🔒 miko-$name はプロテクト済みのためスキップいたします" \
        "  🔒 miko-$name is protected — skipping"
    continue
  fi
  install_skill "$d" "$name"
done

# .miko/ を更新: ユーザー作成ファイル（protected_skills, config 等）を保持したまま上書き
# rm -rf は使わず、ofuda の中身を .miko/ にマージコピーする
cp -r "$tmpdir/miko/ofuda/." .miko/

# ガイド・実例中のスキル参照もスクリプト版の名前（/miko-xxx）へ変換する
localize_miko_refs .miko/guides .miko/examples

# 言語設定に応じて tone_guide を解決する（config がない既存インストールは ja として config を作成）
if [ ! -f ".miko/config" ]; then
  echo "language=$LANG_CHOICE" > .miko/config
fi
if [ "$LANG_CHOICE" = "en" ] && [ -f ".miko/guides/tone_guide.en.md" ]; then
  cp .miko/guides/tone_guide.en.md .miko/guides/tone_guide.md
fi
rm -f .miko/guides/tone_guide.en.md

echo ""
say "✨ miko を $latest_semver ($latest_ts) に更新いたしました" \
    "✨ miko has been updated to $latest_semver ($latest_ts)"
