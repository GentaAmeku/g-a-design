# G.A Design

GentaAmeku の個人デザインシステム。HTML でもスライドでも同じ意匠で出せるように、色・書体・余白を1か所に置いてある。

| ファイル | 中身 |
|---|---|
| [STYLE-GUIDE.md](STYLE-GUIDE.md) | 人が読む正準。測った値と、その値にした根拠 |
| [tokens.css](tokens.css) | 色・書体・余白。すべての出力が読む1枚 |
| [document.css](document.css) | 長文の部品12種 |
| [component-samples.html](component-samples.html) | 部品の見本。ブラウザで開く |
| [profiles/](profiles/) | 顧客ごとの skin |
| [research/](research/) | 値の裏にある調査。書体は実測で選んである |
| [check.sh](check.sh) | STYLE-GUIDE.md の主張が実際に成り立つかを確かめる |

使う側は tokens.css と document.css を `<style>` にそのまま埋め込む。外部から読むのは Google Fonts だけにして、成果物が1ファイルで開ける状態を保つ。

```html
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=BIZ+UDPMincho:wght@400;700&family=Zen+Kaku+Gothic+New:wght@400;500;700&display=swap" rel="stylesheet">
```

値を触ったら `./check.sh` を回す。色・書体・部品の対応が STYLE-GUIDE.md の記述とずれていないかを見て、崩れていれば 1 で終わる。

## 使ってよいか

LICENSE は置いていない。著作権は GentaAmeku にあり、そのままの利用・改変・再配布には許可が要る。読むのと、考え方を参考にするのは自由。
