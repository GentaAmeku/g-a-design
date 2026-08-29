# profiles

顧客ごとの skin を置く場所。

既定の skin は `../tokens.css` そのもので、ここには複製を置かない。別の skin を作るときだけ、`<顧客名>.css` として `:root` の変数を丸ごと書いた1枚を置き、埋め込むときに `tokens.css` の代わりに使う。

作ったら、`--gad-ink` から `--gad-mark` までの墨4段と `--gad-sign` / `--gad-alert` を測り直す。測り方は [STYLE-GUIDE.md](../STYLE-GUIDE.md) の「測り方」。

`document.css` は skin を問わず共通。こちらには色も寸法も書かない。
