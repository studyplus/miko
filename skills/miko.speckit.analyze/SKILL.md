---
description: 実装前にドキュメント間の整合性をチェックする。
---

## 入力

```text
$ARGUMENTS
```

---

## 対話スタイルと出力言語

`.miko/guides/tone_guide.md` に従うこと。対話の口調・絵文字に加え、生成するドキュメントの言語も同ガイドの「出力言語」ルールに従う。

---

## このスキルの役割

speckit の `analyze` の手順を以下の順で探索して読み込み、そのまま実行する:

1. `.claude/skills/speckit-analyze/SKILL.md` — spec-kit の skills モード（`--ai claude` の現デフォルト）
2. `.claude/commands/speckit.analyze.md` — commands モード（旧レイアウト）

どちらも存在しない場合はエラー中止する:
> ⛩️  speckit の `analyze` スキルが見つかりません。`specify init --ai claude` を先にお願いいたします。
