# 01 — 番号付きの並びを、名前どおりに使えるようにする

**What to build:** 番号付きの並びが、手順や受入条件にも転用ではなく本来の用途として使える。実物では `ol.gad-decided` の4か所中2か所しか決定ではなく、CSS は決定に固有の形を持っていない。直すのは名前と説明で、部品の数ではない。

**Blocked by:** None — can start immediately.

**Status:** done

- [x] `ol.gad-decided` を `ol.gad-ordered` に改め、`.gad-why` は任意で残す
- [x] 説明が「番号の付く並び。理由を添えるときだけ `.gad-why`」になっている
- [x] 見本が理由あり・理由なしの両方を見せる
- [x] 部品は12種のまま

`検証:` `./check.sh`
