#!/bin/bash
set -euo pipefail

REPO="studyplus/miko"
BRANCH="main"
SKILLS_DIR=".claude/skills"

if [ ! -d ".claude" ]; then
  echo "⛩️  .claude ディレクトリが見つかりません。プロジェクトのルートで実行くださいませ。"
  exit 1
fi

echo "⛩️  miko スキルをインストールいたします..."

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/miko"
curl -fsSL "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" | tar -xz -C "$tmpdir/miko" --strip-components=1

mkdir -p "$SKILLS_DIR"

# 既存インストールの確認（VERSION ファイルまたは miko スキルが1つでもあれば既存とみなす）
if [ -f ".miko/VERSION" ] || ls -d "$SKILLS_DIR"/miko.* &> /dev/null; then
  echo "⛩️  miko が既にインストールされております。"
  echo "   更新は upgrade.sh をお使いくださいませ:"
  echo ""
  echo "   bash <(curl -fsSL https://raw.githubusercontent.com/studyplus/miko/main/upgrade.sh)"
  exit 0
fi

cp -r "$tmpdir"/miko/skills/miko.* "$SKILLS_DIR/"
cp -r "$tmpdir"/miko/ofuda .miko

if [ ! -f ".miko/protected_skills" ]; then
cat > .miko/protected_skills << 'EOF'
# miko アップグレード時に削除・上書きされないスキルを1行ずつ指定します。
# miko.* という名前でご自身のカスタムスキルを作成している場合に使用してください。
#
# 例:
# miko.my-custom-skill
# miko.another-skill
EOF
fi

echo "✨ miko スキルをお納めいたしました: $SKILLS_DIR/"
ls -1d "$SKILLS_DIR"/miko.* .miko 2>/dev/null | while read -r d; do
  echo "  - $(basename "$d")"
done
echo ""
echo "⛩️  まずは /miko.setup でプロジェクトのセットアップを。迷ったら /miko.miko にお聞きくださいませ。"
