#!/bin/bash
set -euo pipefail

REPO="studyplus/miko"
BRANCH="main"

# 配置先の検出: Claude Code は .claude/skills、Codex は .agents/skills。
# 存在するディレクトリ（.claude / .agents）すべてに配置する
SKILLS_DIRS=()
[ -d ".claude" ] && SKILLS_DIRS+=(".claude/skills")
[ -d ".agents" ] && SKILLS_DIRS+=(".agents/skills")

if [ ${#SKILLS_DIRS[@]} -eq 0 ]; then
  echo "⛩️  .claude / .agents ディレクトリが見つかりません。プロジェクトのルートで実行くださいませ。"
  echo "    (.claude / .agents directory not found. Please run this from your project root.)"
  exit 1
fi

# 言語選択: MIKO_LANG 環境変数 (ja/en) > 対話プロンプト > デフォルト ja
LANG_CHOICE="${MIKO_LANG:-}"
if [ -z "$LANG_CHOICE" ] && [ -t 0 ]; then
  echo "⛩️  出力言語を選択ください / Please select the output language:"
  echo "    1) 日本語 (ja)"
  echo "    2) English (en)"
  read -r -p "  [1/2] (default: 1): " ans
  case "$ans" in
    2|en|EN) LANG_CHOICE="en" ;;
    *) LANG_CHOICE="ja" ;;
  esac
fi
case "$LANG_CHOICE" in
  en) LANG_CHOICE="en" ;;
  *) LANG_CHOICE="ja" ;;
esac

# スキル名の区切り文字選択: 対話プロンプト > デフォルト -
# 一部の LLM プラットフォームは Agent Skills 準拠のハイフン区切りの名前しか使えないため、
# どこでも動くハイフン区切り (miko-setup) をデフォルトとし、ドット区切り (miko.setup) も選択できる。
# インストール後に変更する場合は、miko を削除して再インストールする
SEP="-"
if [ -t 0 ]; then
  if [ "$LANG_CHOICE" = "en" ]; then
    echo "⛩️  Please select the skill name separator:"
    echo "    1) hyphen (/miko-setup) — works on every platform"
    echo "    2) dot    (/miko.setup) — for platforms that support dots in skill names"
  else
    echo "⛩️  スキル名の区切り文字を選択ください:"
    echo "    1) ハイフン (/miko-setup) — どのプラットフォームでも動作"
    echo "    2) ドット   (/miko.setup) — ドット区切りに対応したプラットフォーム向け"
  fi
  read -r -p "  [1/2] (default: 1): " ans
  case "$ans" in
    2|.|dot) SEP="." ;;
    *) SEP="-" ;;
  esac
fi

# to_local <name> — 正規スキル名（. 区切り）を選択された区切り文字の名前に変換する
to_local() { echo "${1//./$SEP}"; }

# rewrite_skill_refs <path>... — ファイル中のスキル名参照 (miko.foo) を選択された区切り文字に書き換える
rewrite_skill_refs() {
  [ "$SEP" = "." ] && return 0
  local sed_script="" name esc
  for name in "${canonical_skills[@]}"; do
    esc="${name//./\\.}"
    sed_script="${sed_script}s/${esc}/$(to_local "$name")/g;"
  done
  find "$@" -type f -name '*.md' | while IFS= read -r f; do
    sed -i.mikobak "$sed_script" "$f" && rm -f "$f.mikobak"
  done
}

if [ "$LANG_CHOICE" = "en" ]; then
  echo "⛩️  Installing miko skills..."
else
  echo "⛩️  miko スキルをインストールいたします..."
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/miko"
curl -fsSL "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" | tar -xz -C "$tmpdir/miko" --strip-components=1

# 既存インストールの確認（VERSION ファイルまたは miko スキルが1つでもあれば既存とみなす）
already_installed=false
[ -f ".miko/VERSION" ] && already_installed=true
for SKILLS_DIR in "${SKILLS_DIRS[@]}"; do
  if ls -d "$SKILLS_DIR"/miko.* &> /dev/null || ls -d "$SKILLS_DIR"/miko-* &> /dev/null; then
    already_installed=true
  fi
done
if [ "$already_installed" = true ]; then
  if [ "$LANG_CHOICE" = "en" ]; then
    echo "⛩️  miko is already installed. Please use upgrade.sh to update:"
  else
    echo "⛩️  miko が既にインストールされております。"
    echo "   更新は upgrade.sh をお使いくださいませ:"
  fi
  echo ""
  echo "   bash <(curl -fsSL https://raw.githubusercontent.com/studyplus/miko/main/upgrade.sh)"
  exit 0
fi

# 正規スキル名（. 区切り）の一覧を収集し、選択された区切り文字の名前で配置する
canonical_skills=()
for d in "$tmpdir"/miko/skills/miko.*/; do
  canonical_skills+=("$(basename "$d")")
done
for SKILLS_DIR in "${SKILLS_DIRS[@]}"; do
  mkdir -p "$SKILLS_DIR"
  for s in "${canonical_skills[@]}"; do
    cp -r "$tmpdir/miko/skills/$s" "$SKILLS_DIR/$(to_local "$s")"
  done
done
cp -r "$tmpdir"/miko/ofuda .miko

# 言語・区切り文字設定の保存と tone_guide の解決
# リポジトリには tone_guide.md (ja) と tone_guide.en.md があり、
# 選択された言語のものを .miko/guides/tone_guide.md として配置する
{
  echo "language=$LANG_CHOICE"
  if [ "$SEP" = "." ]; then
    echo "separator=dot"
  else
    echo "separator=hyphen"
  fi
} > .miko/config
if [ "$LANG_CHOICE" = "en" ]; then
  cp .miko/guides/tone_guide.en.md .miko/guides/tone_guide.md
fi
rm -f .miko/guides/tone_guide.en.md

# ハイフン区切りの場合、配置済みファイル内のスキル名参照を書き換える
rewrite_skill_refs .miko
for SKILLS_DIR in "${SKILLS_DIRS[@]}"; do
  rewrite_skill_refs "$SKILLS_DIR"/miko"$SEP"*
done

if [ ! -f ".miko/protected_skills" ]; then
cat > .miko/protected_skills << EOF
# miko アップグレード時に削除・上書きされないスキルを1行ずつ指定します。
# miko${SEP}* という名前でご自身のカスタムスキルを作成している場合に使用してください。
# (Skills listed here, one per line, are preserved across miko upgrades.
#  Use this if you have created custom skills named miko${SEP}*.)
#
# 例 / Example:
# miko${SEP}my-custom-skill
# miko${SEP}another-skill
EOF
fi

if [ "$LANG_CHOICE" = "en" ]; then
  echo "✨ The miko skills have been delivered to: ${SKILLS_DIRS[*]}"
else
  echo "✨ miko スキルをお納めいたしました: ${SKILLS_DIRS[*]}"
fi
ls -1d "${SKILLS_DIRS[0]}"/miko"$SEP"* .miko 2>/dev/null | while read -r d; do
  echo "  - $(basename "$d")"
done
echo ""
if [ "$LANG_CHOICE" = "en" ]; then
  echo "⛩️  Start with /miko${SEP}setup to set up your project. If in doubt, ask /miko${SEP}miko."
else
  echo "⛩️  まずは /miko${SEP}setup でプロジェクトのセットアップを。迷ったら /miko${SEP}miko にお聞きくださいませ。"
fi
