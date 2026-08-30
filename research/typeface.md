# G.A Design — 和文書体の選定(調査)

2026-08-29 / 対象: 文書デザインシステムの本文と見出し / 制約: 自己完結、外部は Google Fonts のみ

## 結論

本文は **Zen Kaku Gothic New 18px**、見出しは **BIZ UDPMincho 700**。実測では BIZ UDPGothic + Zen Old Mincho を推したが、見本を並べて比べた結果、本人が上の組を選んだ(2026-08-29)。測定そのものは下に残す。選んだ書体が実寸で最小のため、本文サイズを 17px から 18px へ上げて釣り合いを取っている。

## 母集団

Google Fonts の一次データ(`https://fonts.google.com/metadata/fonts`)で、`subsets` に `japanese` を含む family は **68**。うち Display・Handwriting・単一ウェイトを除くと、長文の本文に使えるのは実質7つ、明朝の見出しに使えるのは4つ。

## 測定

Chrome の `canvas.measureText` で、`font-size: 100px` に対する実寸(インクの高さ)と、同一文の描画幅を測った。数値は px。和文の送り幅はどの書体も 100(全角)で、差は出ない。

### 本文候補(サンセリフ)

| 書体 | 漢字インク高 | かなインク高 | 一文の幅 | ウェイト | 出自 |
|---|---|---|---|---|---|
| BIZ UDPGothic | **89.7** | **87.4** | **2282** | 400 / 700 | Type Bank + モリサワ |
| IBM Plex Sans JP | 88.3 | 84.7 | 2383 | 100–700 | Mike Abbink + Bold Monday |
| Noto Sans JP | 87.5 | 84.4 | 2390 | 100–900(可変) | Google(ブランド書体) |
| Murecho | 87.3 | 85.9 | 2400 | 100–900(可変) | Neil Summerour |
| M PLUS 2 | 87.0 | 85.7 | 2400 | 100–900(可変) | Coji Morishita |
| LINE Seed JP | 85.1 | 86.0 | 2377 | 100 / 400 / 700 / 800 | LY Corporation ほか |
| Zen Kaku Gothic New | 83.6 | 85.7 | 2400 | 300 / 400 / 500 / 700 / 900 | Yoshimichi Ohira |

### 見出し候補(明朝)

| 書体 | 漢字インク高 | かなインク高 | ウェイト |
|---|---|---|---|
| BIZ UDPMincho | 89.9 | 85.8 | 400 / 700 のみ |
| Shippori Mincho | 89.8 | 86.7 | 400–800 |
| Noto Serif JP | 89.8 | 82.9 | 200–900(可変、ブランド書体) |
| Zen Old Mincho | 89.0 | 81.8 | 400 / 500 / 600 / 700 / 900 |

## 読み取れたこと

**同じ `font-size` でも実効サイズが 7% 違う。** 漢字のインク高は 83.6 から 89.9 まで開く。当初 A案で使っていた Zen Kaku Gothic New は母集団の最小で、BIZ UDPGothic に替えるだけで 16px が実質 17.1px 相当になる。「大きめの文字」という要求には、サイズを上げるより先に書体を替えるほうが効く。

**BIZ UDP 系だけ行が締まる。** 同一文の幅が 2282(明朝は 2219)で、他より 5〜8% 短い。P はプロポーショナルの意味で、約物と仮名を詰めて送るため。同じ行長により多くの文字が収まり、行末の凸凹も減る。

**BIZ UD はユニバーサルデザイン書体。** Type Bank とモリサワが、判読性を目的に設計したもの。装飾ではなく読みやすさを設計目標に置いた数少ない選択肢で、公共文書や教科書で使われてきた系統にあたる。

**BIZ UD の弱点はウェイトが2つしかないこと。** 400 と 700 だけで、500 も 600 も無い。600 を指定すると 700 に解決されるので、CSS には 700 と書く。中間ウェイトを前提にした設計はできない。

**Zen Old Mincho は 600 を実装している。** かなが小さい(81.8)ぶん漢字が引き立つ。見本では最も端正に出たが、採用には至らなかった。

**Noto Sans JP と Noto Serif JP は Google のブランド書体**(メタデータの `isBrandFont` が true)。他社へ配る文書の書体として、この事実は一度確認しておく価値がある。

## 決めた値

| 役割 | 書体 | サイズ | ウェイト |
|---|---|---|---|
| 題名 | BIZ UDPMincho | 34px | 700 |
| 見出し | BIZ UDPMincho | 22px | 700 |
| 小見出し | BIZ UDPMincho | 17px | 700 |
| 本文 | Zen Kaku Gothic New | 18px | 400 |
| 強い本文・行見出し | Zen Kaku Gothic New | 18px | 500 |
| 注記・脇 | Zen Kaku Gothic New | 14px | 400 |

行送り 1.95、字間 0.03em、行長は全角34〜36字(本文幅 640px 前後)。

**BIZ UDPMincho に 600 は無い。**400 と 700 の2つだけなので、`font-weight: 600` はブラウザ側で 700 に解決される。CSS には 700 と書く。本文の Zen Kaku Gothic New は 500 を持つので、行見出しや強調はそちらを使う。

## 出典

- Google Fonts family メタデータ(一次) — `https://fonts.google.com/metadata/fonts`
- 実寸と描画幅 — Chrome 上の `canvas.measureText`(`actualBoundingBoxAscent` + `actualBoundingBoxDescent`)による自測、2026-08-29
