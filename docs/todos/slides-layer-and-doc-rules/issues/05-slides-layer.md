# 05 — 同じ意匠でスライドが組めるようになる

**What to build:** 文書と同じ意匠で投影できるスライドが組める。この層は版の骨格だけを持ち、部品を1つも足さない。面は 960×540 で、本文 18px のまま 1920px の画面で36px 相当になる。

**Blocked by:** 01(見本が新しい class 名を使うため)

**Status:** done

- [x] `slides/slides.css` が `gad-slide*` 以外の class を定義していない
- [x] 面の寸法が tokens.css の token になっている
- [x] `slides/deck.js` が面の移動と拡大を持ち、成果物へ埋め込める
- [x] `slides/deck-samples.html` が動き、面の型を見せる
- [x] 印刷で1面1ページの 16:9 になる

`検証:` `./check.sh`
`受入確認:` 見本を開き、← → で面が動き、表紙が残らないこと
