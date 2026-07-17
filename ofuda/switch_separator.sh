#!/bin/bash
set -euo pipefail

# miko スキル名の区切り文字（. / -）を切り替えるスクリプト。
# プロジェクトのルートで実行する:
#   bash .miko/switch_separator.sh .   # ドット区切り (/miko.setup) にする
#   bash .miko/switch_separator.sh -   # ハイフン区切り (/miko-setup) にする
#
# 対象は .miko/skills_manifest に列挙された miko 管理スキルのみ。
# ユーザー作成のカスタムスキルには触れない。

SKILLS_DIR=".claude/skills"
CONFIG=".miko/config"
MANIFEST=".miko/skills_manifest"

usage() {
  echo "usage: bash .miko/switch_separator.sh <.|->"
  exit 1
}

[ $# -eq 1 ] || usage
case "$1" in
  .|-) TARGET="$1" ;;
  *) usage ;;
esac

if [ ! -f "$CONFIG" ] || [ ! -f "$MANIFEST" ]; then
  echo "⛩️  $CONFIG または $MANIFEST が見つかりません。プロジェクトのルートで実行くださいませ。"
  echo "    ($CONFIG or $MANIFEST not found. Please run this from your project root.)"
  exit 1
fi

LANG_CHOICE=$(grep -E '^language=' "$CONFIG" | head -n 1 | cut -d= -f2 | tr -d '[:space:]' || true)

# say <ja> <en> — 言語設定に応じたメッセージを出力する
say() {
  if [ "$LANG_CHOICE" = "en" ]; then echo "$2"; else echo "$1"; fi
}

CURRENT=$(grep -E '^separator=' "$CONFIG" | head -n 1 | cut -d= -f2 | tr -d '[:space:]' || true)
[ "$CURRENT" = "-" ] || CURRENT="."

# set_config <key> <value> — config のキーを更新する（なければ追記）
set_config() {
  local key="$1" value="$2"
  if grep -qE "^${key}=" "$CONFIG"; then
    sed -i.mikobak "s/^${key}=.*/${key}=${value}/" "$CONFIG" && rm -f "$CONFIG.mikobak"
  else
    echo "${key}=${value}" >> "$CONFIG"
  fi
}

if [ "$TARGET" = "$CURRENT" ]; then
  say "✨ 既に区切り文字は「${TARGET}」です。変更はございません。" \
      "✨ The separator is already \"$TARGET\". Nothing to change."
  exit 0
fi

# マニフェストから正規スキル名（. 区切り）を読み込む
canonical=()
while IFS= read -r line; do
  [ -z "$line" ] && continue
  canonical+=("$line")
done < "$MANIFEST"

if [ ${#canonical[@]} -eq 0 ]; then
  say "⛩️  $MANIFEST が空です。upgrade.sh の再実行をお願いいたします。" \
      "⛩️  $MANIFEST is empty. Please re-run upgrade.sh."
  exit 1
fi

# スキルディレクトリのリネームと、参照書き換え用の sed スクリプトの構築
sed_script=""
renamed=0
for name in "${canonical[@]}"; do
  cur="${name//./$CURRENT}"
  tgt="${name//./$TARGET}"
  if [ -d "$SKILLS_DIR/$cur" ]; then
    mv "$SKILLS_DIR/$cur" "$SKILLS_DIR/$tgt"
    renamed=$((renamed + 1))
  fi
  esc="${cur//./\\.}"
  sed_script="${sed_script}s/${esc}/${tgt}/g;"
done

# ファイル中のスキル名参照を書き換える（miko 管理スキルと .miko 配下のみ）
rewrite_targets=(".miko")
for name in "${canonical[@]}"; do
  tgt="${name//./$TARGET}"
  if [ -d "$SKILLS_DIR/$tgt" ]; then
    rewrite_targets+=("$SKILLS_DIR/$tgt")
  fi
done
find "${rewrite_targets[@]}" -type f -name '*.md' | while IFS= read -r f; do
  sed -i.mikobak "$sed_script" "$f" && rm -f "$f.mikobak"
done

set_config separator "$TARGET"

say "✨ スキル名の区切り文字を「${TARGET}」に変更いたしました（${renamed} スキル）。" \
    "✨ The skill name separator has been changed to \"$TARGET\" ($renamed skills)."
say "⛩️  新しいスキル名が認識されるのは、新しいセッションからとなる場合がございます。" \
    "⛩️  The renamed skills may only be recognized from a new session."
