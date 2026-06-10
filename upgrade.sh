#!/bin/bash
set -euo pipefail

REPO="studyplus/miko"
BRANCH="main"
SKILLS_DIR=".claude/skills"
VERSION_FILE=".miko/VERSION"
OLD_VERSION_FILE="$SKILLS_DIR/_miko/VERSION"

if [ ! -d ".claude" ]; then
  echo "⛩️  .claude ディレクトリが見つかりません。プロジェクトのルートで実行くださいませ。"
  exit 1
fi

if ! command -v claude &> /dev/null; then
  echo "⛩️  claude (Claude CLI) が必要です。https://claude.com/claude-code からインストールくださいませ。"
  exit 1
fi

# miko がインストールされているか確認（VERSION ファイルまたは miko スキルの存在）
if [ ! -f "$VERSION_FILE" ] && [ ! -f "$OLD_VERSION_FILE" ] && ! ls -d "$SKILLS_DIR"/miko.* &> /dev/null; then
  echo "⛩️  miko がインストールされていません。install.sh で初回インストールをお願いいたします。"
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
current_semver="${current_semver:-不明}"
current_ts="${current_ts:-0}"

echo "⛩️  現在のバージョン: $current_semver ($current_ts)"

echo "🌿 最新版を取得しております..."
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/miko"
curl -fsSL "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" | tar -xz -C "$tmpdir/miko" --strip-components=1

latest_semver=$(sed -n '1p' "$tmpdir/miko/ofuda/VERSION" | tr -d '[:space:]')
latest_ts=$(sed -n '2p' "$tmpdir/miko/ofuda/VERSION" | tr -d '[:space:]')

if [ "$current_ts" = "$latest_ts" ]; then
  echo "✨ 既に最新バージョン ($latest_semver) です。"
  exit 0
fi

echo "🌿 $current_semver → $latest_semver へ更新いたします"

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
  echo "📜 マイグレーションを実行いたします（${#migration_files[@]} 件）..."
  echo "   ※ マイグレーションは1件あたり数分かかることがございます。しばらくお待ちくださいませ。"
  for f in "${migration_files[@]}"; do
    ts=$(basename "$f" .md)
    echo "  ⛩️  $ts ..."
    # $MIKO_LATEST をマイグレーションプロンプト内のパス参照用に展開する
    prompt=$(cat "$f" | sed "s|\$MIKO_LATEST|$tmpdir/miko|g")
    if ! claude -p "$prompt" --allowedTools "Edit,Read,Write,Glob,Grep"; then
      echo "  ❌ $ts でエラーが発生しました。中断いたします。"
      exit 1
    fi
    echo "  ✨ $ts 完了"
  done
  echo ""
fi

# 旧ディレクトリの削除（v0.2.x 以前からの移行）
if [ -d "$SKILLS_DIR/_miko" ]; then
  echo "🌿 旧ディレクトリ $SKILLS_DIR/_miko を削除しております..."
  rm -rf "$SKILLS_DIR/_miko"
fi

# 最新版に存在する miko.* スキル名を収集
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
  echo "🔒 以下のスキルはプロテクト済みのため、更新対象から除外いたします:"
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

# 最新版にない miko.* スキルのうち、プロテクト済みでないものを削除候補として収集
removed_skills=()
for d in "$SKILLS_DIR"/miko.*/; do
  [ -d "$d" ] || continue
  name=$(basename "$d")
  is_protected "$name" && continue
  found=false
  for s in "${latest_skills[@]}"; do
    [ "$s" = "$name" ] && found=true && break
  done
  [ "$found" = false ] && removed_skills+=("$name")
done

# 削除されるスキルがあれば一覧表示して確認
if [ ${#removed_skills[@]} -gt 0 ]; then
  echo ""
  echo "🗑️  以下のスキルは最新版にないため削除されます:"
  for s in "${removed_skills[@]}"; do
    echo "    - $SKILLS_DIR/$s"
  done
  echo ""
  read -r -p "続行してよろしいですか? [y/N]: " ans
  case "$ans" in
    y|Y|yes|YES) ;;
    *)
      echo "中断いたしました。"
      exit 1
      ;;
  esac
fi

# スキルファイル更新
echo "🌿 スキルファイルを更新しております..."

# 削除が確定したスキルを個別に削除
for s in "${removed_skills[@]}"; do
  rm -rf "${SKILLS_DIR:?}/$s"
done

# miko 管理スキルを個別に更新（プロテクト済みはスキップ）
for s in "${latest_skills[@]}"; do
  if is_protected "$s"; then
    echo "  🔒 $s はプロテクト済みのためスキップいたします"
    continue
  fi
  rm -rf "${SKILLS_DIR:?}/$s"
  cp -r "$tmpdir/miko/skills/$s" "$SKILLS_DIR/"
done

# .miko/ を更新: ユーザー作成ファイル（protected_skills 等）を保持したまま上書き
# rm -rf は使わず、ofuda の中身を .miko/ にマージコピーする
cp -r "$tmpdir/miko/ofuda/." .miko/

echo ""
echo "✨ miko を $latest_semver ($latest_ts) に更新いたしました"
