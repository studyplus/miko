#!/bin/bash
set -euo pipefail

REPO="studyplus/miko"
BRANCH="main"
SKILLS_DIR=".github/skills"

if [ ! -d ".github" ]; then
  echo "⛩️  .github ディレクトリが見つかりません。プロジェクトのルートで実行くださいませ。"
  echo "    (.github directory not found. Please run this from your project root.)"
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

if [ "$LANG_CHOICE" = "en" ]; then
  echo "⛩️  Installing miko skills for GitHub Copilot..."
else
  echo "⛩️  GitHub Copilot 向けに miko スキルをインストールいたします..."
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/miko"
curl -fsSL "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" | tar -xz -C "$tmpdir/miko" --strip-components=1

mkdir -p "$SKILLS_DIR"

# 既存インストールの確認（VERSION ファイルまたは miko スキルが1つでもあれば既存とみなす）
if [ -f ".miko/VERSION" ] || ls -d "$SKILLS_DIR"/miko.* &> /dev/null; then
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

cp -r "$tmpdir"/miko/skills/miko.* "$SKILLS_DIR/"
cp -r "$tmpdir"/miko/ofuda .miko

# 言語設定の保存と tone_guide の解決
# リポジトリには tone_guide.md (ja) と tone_guide.en.md があり、
# 選択された言語のものを .miko/guides/tone_guide.md として配置する
echo "language=$LANG_CHOICE" > .miko/config
if [ "$LANG_CHOICE" = "en" ]; then
  cp .miko/guides/tone_guide.en.md .miko/guides/tone_guide.md
fi
rm -f .miko/guides/tone_guide.en.md

if [ ! -f ".miko/protected_skills" ]; then
cat > .miko/protected_skills << 'EOF'
# miko アップグレード時に削除・上書きされないスキルを1行ずつ指定します。
# miko.* という名前でご自身のカスタムスキルを作成している場合に使用してください。
# (Skills listed here, one per line, are preserved across miko upgrades.
#  Use this if you have created custom skills named miko.*.)
#
# 例 / Example:
# miko.my-custom-skill
# miko.another-skill
EOF
fi

if [ "$LANG_CHOICE" = "en" ]; then
  echo "✨ The miko skills have been delivered to: $SKILLS_DIR/"
else
  echo "✨ miko スキルをお納めいたしました: $SKILLS_DIR/"
fi
ls -1d "$SKILLS_DIR"/miko.* .miko 2>/dev/null | while read -r d; do
  echo "  - $(basename "$d")"
done
echo ""
if [ "$LANG_CHOICE" = "en" ]; then
  echo "⛩️  Start with /miko.setup to set up your project. If in doubt, ask /miko.miko."
else
  echo "⛩️  まずは /miko.setup でプロジェクトのセットアップを。迷ったら /miko.miko にお聞きくださいませ。"
fi
