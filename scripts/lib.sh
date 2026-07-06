# shellcheck shell=bash
# miko 配布用の共通関数。install.sh / upgrade.sh が tarball 展開後に source する。
# 例: source "$tmpdir/miko/scripts/lib.sh"

# localize_miko_refs <dir>...
# 配下の .md 中のスキル参照をスクリプト版の名前へ変換する（/miko:xxx → /miko-xxx）。
# リポジトリのソースはプラグイン版の表記（/miko:xxx）で統一されているため、
# スクリプト配布時のみこの変換を行う。
localize_miko_refs() {
  find "$@" -name '*.md' -print0 | xargs -0 perl -i -pe 's{/miko:}{/miko-}g'
}

# install_skill <src_skill_dir> <bare_name>
# リポジトリの skills/<name>/ を $SKILLS_DIR/miko-<name>/ に配置し、
# フラットな名前空間で衝突しないよう配布用の名前へ変換する:
#   - frontmatter の name: を miko-<name> に
#   - handoffs の agent: <x> を miko-<x> に
#   - 本文中のスキル参照 /miko:xxx を /miko-xxx に
# （プラグイン版は miko: 名前空間が付くため変換せず素の名前を使う。スクリプト版のみこの変換を行う）
install_skill() {
  local src="${1%/}" name="$2"
  local dest="$SKILLS_DIR/miko-$name"
  rm -rf "$dest"
  cp -r "$src" "$dest"
  perl -i -pe 'if (!$seen && /^name:\s/) { $_ = "name: miko-'"$name"'\n"; $seen = 1 }' "$dest/SKILL.md"
  perl -i -pe 's{^(\s*agent:\s*)([A-Za-z0-9][A-Za-z0-9-]*)\s*$}{$1 . "miko-" . $2 . "\n"}e' "$dest/SKILL.md"
  localize_miko_refs "$dest"
}
