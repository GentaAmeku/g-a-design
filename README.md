# G.A Design

GentaAmeku の個人デザインシステム。HTML でもスライドでも同じ意匠で出せるように、色・書体・余白を1か所に置いてある。

| ファイル | 中身 |
|---|---|
| [STYLE-GUIDE.md](STYLE-GUIDE.md) | 人が読む正準。測った値と、その値にした根拠 |
| [tokens.css](tokens.css) | 色・書体・余白。すべての出力が読む1枚 |
| [tokens-figure.css](tokens-figure.css) | 図だけが読む系列5色。文書からは参照しない |
| [document.css](document.css) | 長文の部品12種 |
| [component-samples.html](component-samples.html) | 部品の見本。ブラウザで開く |
| [figure/](figure/) | 流れの図の生成器。小さな JSON から SVG を出す |
| [slides/](slides/) | スライドの版。部品は足さず、面と切り替えだけを持つ |
| [profiles/](profiles/) | 顧客ごとの skin |
| [research/](research/) | 値の裏にある調査。書体は実測で選んである |
| [check.sh](check.sh) | STYLE-GUIDE.md の主張が実際に成り立つかを確かめる |

使う側は tokens.css と document.css を `<style>` にそのまま埋め込む。外部から読むのは Google Fonts だけにして、成果物が1ファイルで開ける状態を保つ。

```html
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=BIZ+UDPMincho:wght@400;700&family=Zen+Kaku+Gothic+New:wght@400;500;700&display=swap" rel="stylesheet">
```

## 図

流れの図(縦の連鎖・枝分かれ・合流)は手で描かず、生成器に出させる。座標も色も入力に書かない。

```bash
node figure/deliver.mjs figure/examples/triage.json                 # 貼り込む断片
node figure/deliver.mjs 入力.json --as page --out 図.html            # 単体で開ける HTML
```

検査を通らなければ何も書かず、規則id・場所・数値・直し方を持つ診断を出して 1 で終わる。入力の形は [figure/schema.json](figure/schema.json)、記法の根拠は STYLE-GUIDE.md の「図の記法」にある。

値を触ったら `./check.sh` を回す。色・書体・部品の対応が STYLE-GUIDE.md の記述とずれていないか、図の生成器が実際に動くかを見て、崩れていれば 1 で終わる(要るのは python3 と node)。

## スライド

文書と同じ意匠で投影できる。面は 960×540 で、本文 18px のまま 1920px の画面で 36px 相当に拡大して出る。**スライド用の部品は無い。**表も決定も注意も document.css のものがそのまま載る。

```bash
open slides/deck-samples.html                    # 面の見本
```

組むときは [slides/slides.css](slides/slides.css) と [slides/deck.js](slides/deck.js) を、tokens.css・document.css と一緒に埋め込む。根拠は STYLE-GUIDE.md の「面」にある。

## 使ってよいか

LICENSE は置いていない。著作権は GentaAmeku にあり、そのままの利用・改変・再配布には許可が要る。読むのと、考え方を参考にするのは自由。
